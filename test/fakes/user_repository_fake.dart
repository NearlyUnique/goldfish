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
    Future<CreateUserResult> Function(UserModel user)? onCreateUser,
    Future<UpdateUserResult> Function(UserModel user)? onUpdateUser,
    Future<GetUserResult> Function(String uid)? onGetUser,
    Future<CreateUserResult | UpdateUserResult> Function(UserModel user)?
        onCreateOrUpdateUser,
  })  : onCreateUser = onCreateUser ?? _defaultCreateUser,
        onUpdateUser = onUpdateUser ?? _defaultUpdateUser,
        onGetUser = onGetUser ?? _defaultGetUser,
        onCreateOrUpdateUser =
            onCreateOrUpdateUser ?? _defaultCreateOrUpdateUser;

  /// Handler for [createUser].
  Future<UserResult> Function(UserModel user) onCreateUser;

  /// Handler for [updateUser].
  Future<UserResult> Function(UserModel user) onUpdateUser;

  /// Handler for [getUser].
  Future<UserResult> Function(String uid) onGetUser;

  /// Handler for [createOrUpdateUser].
  Future<UserResult> Function(UserModel user) onCreateOrUpdateUser;

  @override
  Future<UserResult> createUser(UserModel user) => onCreateUser(user);

  @override
  Future<UserResult> updateUser(UserModel user) => onUpdateUser(user);

  @override
  Future<UserResult> getUser(String uid) => onGetUser(uid);

  @override
  Future<UserResult> createOrUpdateUser(UserModel user) =>
      onCreateOrUpdateUser(user);

  // Default implementations
  static Future<UserResult> _defaultCreateUser(UserModel user) async {
    return UserResult(eventName: 'user_create', uid: user.uid);
  }

  static Future<UserResult> _defaultUpdateUser(UserModel user) async {
    return UserResult(eventName: 'user_update', uid: user.uid);
  }

  static Future<UserResult> _defaultGetUser(String uid) async {
    return UserResult(
      eventName: 'user_get_not_found',
      uid: uid,
      user: null,
    );
  }

  static Future<UserResult> _defaultCreateOrUpdateUser(
    UserModel user,
  ) async {
    return UserResult(eventName: 'user_create', uid: user.uid);
  }
}


