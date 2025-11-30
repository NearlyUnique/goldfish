/// Base exception for authentication-related errors.
abstract class AuthException implements Exception {
  /// Creates a new [AuthException] with the given [message].
  const AuthException(this.message);

  /// The error message.
  final String message;

  @override
  String toString() => message;
}

/// Exception thrown when Google Sign-In is cancelled by the user.
class GoogleSignInCancelledException extends AuthException {
  /// Creates a new [GoogleSignInCancelledException].
  const GoogleSignInCancelledException()
    : super('Google Sign-In was cancelled');
}

/// Exception thrown when Google Sign-In fails due to network issues.
class GoogleSignInNetworkException extends AuthException {
  /// Creates a new [GoogleSignInNetworkException].
  const GoogleSignInNetworkException()
    : super('Network error during Google Sign-In');
}

/// Exception thrown when Google Sign-In fails due to permission denial.
class GoogleSignInPermissionException extends AuthException {
  /// Creates a new [GoogleSignInPermissionException].
  const GoogleSignInPermissionException()
    : super('Permission denied for Google Sign-In');
}

/// Exception thrown when Firebase authentication fails.
class FirebaseAuthException extends AuthException {
  /// Creates a new [FirebaseAuthException] with the given [message] and [code].
  const FirebaseAuthException(super.message, this.code);

  /// The Firebase error code.
  final String? code;
}

/// Exception thrown when user data operations fail.
class UserDataException extends AuthException {
  /// Creates a new [UserDataException] with the given [message].
  const UserDataException(super.message);
}
