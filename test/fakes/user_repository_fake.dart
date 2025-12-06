import 'package:goldfish/core/auth/models/user_model.dart';
import 'package:goldfish/core/auth/repositories/user_repository.dart';

/// Fake implementation of [UserRepository] for testing.
///
/// Provides function fields that tests can configure to control behavior.
/// Default implementations return safe defaults so tests only need to
/// configure the behavior they care about.
class FakeUserRepository implements UserRepository {
  /// Creates a new [FakeUserRepository].
  ///
  /// Optionally accepts function handlers for each method. If not provided,
  /// uses default implementations that return safe defaults.
  FakeUserRepository({
    Future<void> Function(UserModel user)? onCreateUser,
    Future<void> Function(UserModel user)? onUpdateUser,
    Future<UserModel?> Function(String uid)? onGetUser,
    Future<void> Function(UserModel user)? onCreateOrUpdateUser,
  })  : onCreateUser = onCreateUser ?? _defaultCreateUser,
        onUpdateUser = onUpdateUser ?? _defaultUpdateUser,
        onGetUser = onGetUser ?? _defaultGetUser,
        onCreateOrUpdateUser =
            onCreateOrUpdateUser ?? _defaultCreateOrUpdateUser;

  /// Handler for [createUser].
  Future<void> Function(UserModel user) onCreateUser;

  /// Handler for [updateUser].
  Future<void> Function(UserModel user) onUpdateUser;

  /// Handler for [getUser].
  Future<UserModel?> Function(String uid) onGetUser;

  /// Handler for [createOrUpdateUser].
  Future<void> Function(UserModel user) onCreateOrUpdateUser;

  @override
  Future<void> createUser(UserModel user) => onCreateUser(user);

  @override
  Future<void> updateUser(UserModel user) => onUpdateUser(user);

  @override
  Future<UserModel?> getUser(String uid) => onGetUser(uid);

  @override
  Future<void> createOrUpdateUser(UserModel user) =>
      onCreateOrUpdateUser(user);

  // Default implementations
  static Future<void> _defaultCreateUser(UserModel user) async {
    // No-op by default
  }

  static Future<void> _defaultUpdateUser(UserModel user) async {
    // No-op by default
  }

  static Future<UserModel?> _defaultGetUser(String uid) async => null;

  static Future<void> _defaultCreateOrUpdateUser(UserModel user) async {
    // No-op by default
  }
}


