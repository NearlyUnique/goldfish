import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:goldfish/core/auth/auth_exceptions.dart';
import 'package:goldfish/core/auth/models/user_model.dart';
import 'package:goldfish/core/logging/app_logger.dart';

/// Repository for managing user data in Firestore.
///
/// Handles creating, reading, and updating user documents in the cloud.
class UserRepository {
  /// Creates a new [UserRepository].
  ///
  /// The [firestore] parameter can be a real [FirebaseFirestore] instance or
  /// a compatible fake such as `FakeFirebaseFirestore` for tests, following
  /// the Firebase testing guidance at
  /// https://firebase.flutter.dev/docs/testing/testing/.
  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Underlying Firestore instance (real or fake).
  final FirebaseFirestore _firestore;

  /// Collection name for users in Firestore.
  static const String _usersCollection = 'users';

  /// Creates a new user document in Firestore.
  ///
  /// Throws [UserDataException] if the operation fails.
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(user.toMap());

      AppLogger.info({'event': 'user_create', 'uid': user.uid});
    } catch (e) {
      AppLogger.error({
        'event': 'user_create',
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
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .update(user.toMap());

      AppLogger.info({'event': 'user_update', 'uid': user.uid});
    } catch (e) {
      AppLogger.error({
        'event': 'user_update',
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
      final doc = await (_firestore as dynamic)
          .collection(_usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists) {
        AppLogger.info({'event': 'user_get_not_found', 'uid': uid});
        return null;
      }

      // Use map-based factory to support both real Firestore snapshots and
      // simple test doubles (duck-typed objects with `id` and `data()`).
      final user = UserModel.fromMap(
        (doc.data() as Map<String, dynamic>),
        doc.id as String,
      );
      AppLogger.info({'event': 'user_get', 'uid': uid});
      return user;
    } catch (e) {
      AppLogger.error({'event': 'user_get', 'uid': uid, 'error': e.toString()});
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
