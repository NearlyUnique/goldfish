/// Base exception for authentication-related errors.
abstract class AuthException implements Exception {
  /// Creates a new [AuthException] with the given [provider] and [eventName].
  const AuthException(this.provider, this.eventName);

  /// The provider name (e.g., 'google', 'firebase', 'firestore').
  final String provider;

  /// The event name for logging purposes (e.g., 'sign_in_failed').
  final String eventName;

  /// Gets the error message in the format 'provider: eventName'.
  String get displayMessage => '$provider: $eventName';

  @override
  String toString() => displayMessage;
}

/// Exception thrown when sign-in is cancelled by the user.
class SignInCancelledException extends AuthException {
  /// Creates a new [SignInCancelledException].
  const SignInCancelledException(String provider)
    : super(provider, 'sign_in_cancelled');
}

/// Exception thrown when sign-in fails due to network issues.
class SignInNetworkException extends AuthException {
  /// Creates a new [SignInNetworkException].
  const SignInNetworkException(String provider)
    : super(provider, 'sign_in_network_error');
}

/// Exception thrown when sign-in fails due to permission denial.
class SignInPermissionException extends AuthException {
  /// Creates a new [SignInPermissionException].
  const SignInPermissionException(String provider)
    : super(provider, 'sign_in_permission_denied');
}

/// Exception thrown when authentication fails.
///
/// This is a domain exception that wraps underlying authentication failures
/// (e.g., from Firebase) without exposing implementation details.
class AuthenticationException extends AuthException {
  /// Creates a new [AuthenticationException] with the given [provider], [eventName],
  /// and optional [code], [userId], and [innerError] for diagnostics.
  const AuthenticationException(
    super.provider,
    super.eventName, {
    this.code,
    this.userId,
    this.innerError,
  });

  /// The error code, if available (e.g., 'auth/network-request-failed').
  final String? code;

  /// The user ID, if available, for diagnostic purposes.
  final String? userId;

  /// The underlying error that caused this exception, if available.
  final Object? innerError;
}

/// Exception thrown when user data operations fail.
class UserDataException extends AuthException {
  /// Creates a new [UserDataException] with the given [provider], [eventName],
  /// and optional [uid] and [innerError] for diagnostics.
  const UserDataException(
    super.provider,
    super.eventName, {
    this.uid,
    this.innerError,
  });

  /// The user ID, if available, for diagnostic purposes.
  final String? uid;

  /// The underlying error that caused this exception, if available.
  final Object? innerError;
}
