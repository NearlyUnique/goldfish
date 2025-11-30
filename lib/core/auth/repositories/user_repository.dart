import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:goldfish/core/auth/auth_exceptions.dart';
import 'package:goldfish/core/auth/models/user_model.dart';
import 'package:goldfish/core/logging/app_logger.dart';

/// Repository for managing user data in Firestore.
///
/// Handles creating, reading, and updating user documents in the cloud.
class UserRepository {
  /// Creates a new [UserRepository].
  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Collection name for users in Firestore.
  static const String _usersCollection = 'users';

  /// Creates a new user document in Firestore.
  ///
  /// Throws [UserDataException] if the operation fails.
  Future<void> createUser(UserModel user) async {
    try {
      AppLogger.info({'event': 'user_create_start', 'uid': user.uid});

      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(user.toMap());

      AppLogger.info({'event': 'user_create_success', 'uid': user.uid});
    } catch (e) {
      AppLogger.error({
        'event': 'user_create_failure',
        'uid': user.uid,
        'error': e.toString(),
      });
      throw UserDataException('Failed to create user: ${e.toString()}');
    }
  }

  /// Updates an existing user document in Firestore.
  ///
  /// Throws [UserDataException] if the operation fails.
  Future<void> updateUser(UserModel user) async {
    try {
      AppLogger.info({'event': 'user_update_start', 'uid': user.uid});

      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .update(user.toMap());

      AppLogger.info({'event': 'user_update_success', 'uid': user.uid});
    } catch (e) {
      AppLogger.error({
        'event': 'user_update_failure',
        'uid': user.uid,
        'error': e.toString(),
      });
      throw UserDataException('Failed to update user: ${e.toString()}');
    }
  }

  /// Gets a user document from Firestore by UID.
  ///
  /// Returns `null` if the user doesn't exist.
  /// Throws [UserDataException] if the operation fails.
  Future<UserModel?> getUser(String uid) async {
    try {
      AppLogger.info({'event': 'user_get_start', 'uid': uid});

      final doc = await _firestore.collection(_usersCollection).doc(uid).get();

      if (!doc.exists) {
        AppLogger.info({'event': 'user_get_not_found', 'uid': uid});
        return null;
      }

      final user = UserModel.fromFirestore(doc);
      AppLogger.info({'event': 'user_get_success', 'uid': uid});
      return user;
    } catch (e) {
      AppLogger.error({
        'event': 'user_get_failure',
        'uid': uid,
        'error': e.toString(),
      });
      throw UserDataException('Failed to get user: ${e.toString()}');
    }
  }

  /// Creates or updates a user document in Firestore.
  ///
  /// If the user exists, updates it. Otherwise, creates a new one.
  /// Throws [UserDataException] if the operation fails.
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      final existingUser = await getUser(user.uid);
      if (existingUser == null) {
        await createUser(user);
      } else {
        await updateUser(user);
      }
    } catch (e) {
      if (e is UserDataException) {
        rethrow;
      }
      throw UserDataException(
        'Failed to create or update user: ${e.toString()}',
      );
    }
  }
}
