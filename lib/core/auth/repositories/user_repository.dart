import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:goldfish/core/auth/auth_exceptions.dart';
import 'package:goldfish/core/auth/models/user_model.dart';

/// Result of a user repository operation.
///
/// Contains the event name for logging purposes, the user ID, and optionally
/// the user model (for retrieval operations).
class UserResult {
  /// Creates a new [UserResult].
  const UserResult({required this.eventName, required this.uid, this.user});

  /// The event name for logging (e.g., 'user_create', 'user_update', 'user_get').
  final String eventName;

  /// The user ID involved in the operation.
  final String uid;

  /// The user model, if available (typically only for retrieval operations).
  final UserModel? user;

  /// Whether the operation succeeded.
  ///
  /// For retrieval operations, this is `true` if the user was found.
  /// For create/update operations, this is always `true` (they throw on failure).
  bool get succeeded => user != null || eventName != 'user_get_not_found';
}

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
  UserRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  /// Underlying Firestore instance (real or fake).
  final FirebaseFirestore _firestore;

  /// Collection name for users in Firestore.
  static const String _usersCollection = 'users';

  /// Creates a new user document in Firestore.
  ///
  /// Returns [UserResult] on success.
  /// Throws [UserDataException] if the operation fails.
  Future<UserResult> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(user.toMap());

      return UserResult(eventName: 'user_create', uid: user.uid);
    } catch (e) {
      throw UserDataException(
        'firestore',
        'user_create_error',
        uid: user.uid,
        innerError: e,
      );
    }
  }

  /// Updates an existing user document in Firestore.
  ///
  /// Returns [UserResult] on success.
  /// Throws [UserDataException] if the operation fails.
  Future<UserResult> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .update(user.toMap());

      return UserResult(eventName: 'user_update', uid: user.uid);
    } catch (e) {
      throw UserDataException(
        'firestore',
        'user_update_error',
        uid: user.uid,
        innerError: e,
      );
    }
  }

  /// Gets a user document from Firestore by UID.
  ///
  /// Returns [UserResult] with [UserResult.user] set if
  /// the user exists, or `null` if not found.
  /// Throws [UserDataException] if the operation fails.
  Future<UserResult> getUser(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();

      if (!doc.exists) {
        return UserResult(eventName: 'user_get_not_found', uid: uid);
      }

      // Use map-based factory to support both real Firestore snapshots and
      // simple test doubles (duck-typed objects with `id` and `data()`).
      final user = UserModel.fromMap(
        (doc.data() as Map<String, dynamic>),
        doc.id,
      );
      return UserResult(eventName: 'user_get', uid: uid, user: user);
    } catch (e) {
      throw UserDataException(
        'firestore',
        'user_get_error',
        uid: uid,
        innerError: e,
      );
    }
  }

  /// Creates or updates a user document in Firestore.
  ///
  /// If the user exists, updates it. Otherwise, creates a new one.
  /// Returns [UserResult] with the appropriate event name.
  /// Throws [UserDataException] if the operation fails.
  Future<UserResult> createOrUpdateUser(UserModel user) async {
    try {
      final existingUserResult = await getUser(user.uid);
      if (!existingUserResult.succeeded) {
        return await createUser(user);
      } else {
        return await updateUser(user);
      }
    } catch (e) {
      if (e is UserDataException) {
        rethrow;
      }
      throw UserDataException(
        'firestore',
        'user_create_or_update_error',
        uid: user.uid,
        innerError: e,
      );
    }
  }
}
