import 'package:goldfish/core/exceptions/goldfish_exception.dart';

/// Base exception for authentication-related errors.
class AuthException extends GoldfishException {
  /// Creates a new [AuthException] with the given [provider] and [eventName].
  const AuthException(this.provider, eventName, {Object? innerError})
    : super(eventName, innerError);

  /// The provider name (e.g., 'google', 'firebase', 'firestore').
  final String provider;

  /// Gets the error message in the format 'provider: eventName'.
  @override
  String toString() => '${super.toString()}, provider=$provider';
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
    String super.eventName, {
    this.code,
    this.userId,
    super.innerError,
  });

  /// The error code, if available (e.g., 'auth/network-request-failed').
  final String? code;

  /// The user ID, if available, for diagnostic purposes.
  final String? userId;

  /// Gets the display message for the exception including [code], [userId]
  @override
  String toString() => '${super.toString()}, code=$code, userId=$userId';
}

/// Exception thrown when user data operations fail.
class UserDataException extends AuthException {
  /// Creates a new [UserDataException] with the given [provider], [eventName],
  /// and optional [uid] and [innerError] for diagnostics.
  const UserDataException(
    super.provider,
    String super.eventName, {
    this.uid,
    super.innerError,
  });

  /// The user ID, if available, for diagnostic purposes.
  final String? uid;

  /// Gets the display message for the exception including [uid]
  @override
  String toString() => '${super.toString()}, uid=$uid';
}
