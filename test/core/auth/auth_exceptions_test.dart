import 'package:flutter_test/flutter_test.dart';
import 'package:goldfish/core/auth/auth_exceptions.dart';

/// Tests for authentication exception classes.
void main() {
  group('AuthException', () {
    test('toString includes provider and eventName', () {
      // Arrange
      const exception = AuthException('google', 'sign_in_failed');

      // Act
      final result = exception.toString();

      // Assert
      expect(result, contains('sign_in_failed'));
      expect(result, contains('provider=google'));
    });

    test('toString format is correct', () {
      // Arrange
      const exception = AuthException('firebase', 'auth_error');

      // Act
      final result = exception.toString();

      // Assert
      expect(result, equals('auth_error, provider=firebase'));
    });

    test('provider is accessible', () {
      // Arrange
      const exception = AuthException('test_provider', 'event');

      // Assert
      expect(exception.provider, equals('test_provider'));
    });

    test('eventName is accessible', () {
      // Arrange
      const exception = AuthException('provider', 'test_event');

      // Assert
      expect(exception.eventName, equals('test_event'));
    });

    test('innerError can be provided', () {
      // Arrange
      final innerError = Exception('test error');
      final exception = AuthException(
        'provider',
        'event',
        innerError: innerError,
      );

      // Assert
      expect(exception.innerError, equals(innerError));
    });

    test('displayMessage includes innerError when present', () {
      // Arrange
      final innerError = Exception('inner error');
      final exception = AuthException(
        'provider',
        'event',
        innerError: innerError,
      );

      // Act
      final result = exception.displayMessage;

      // Assert
      expect(result, contains('event'));
      expect(result, contains('inner error'));
    });
  });

  group('SignInCancelledException', () {
    test('creates exception with correct provider', () {
      // Arrange & Act
      const exception = SignInCancelledException('google');

      // Assert
      expect(exception.provider, equals('google'));
      expect(exception.eventName, equals('sign_in_cancelled'));
    });

    test('toString includes provider', () {
      // Arrange
      const exception = SignInCancelledException('google');

      // Act
      final result = exception.toString();

      // Assert
      expect(result, contains('sign_in_cancelled'));
      expect(result, contains('provider=google'));
    });
  });

  group('SignInNetworkException', () {
    test('creates exception with correct provider', () {
      // Arrange & Act
      const exception = SignInNetworkException('google');

      // Assert
      expect(exception.provider, equals('google'));
      expect(exception.eventName, equals('sign_in_network_error'));
    });

    test('toString includes provider', () {
      // Arrange
      const exception = SignInNetworkException('google');

      // Act
      final result = exception.toString();

      // Assert
      expect(result, contains('sign_in_network_error'));
      expect(result, contains('provider=google'));
    });
  });

  group('SignInPermissionException', () {
    test('creates exception with correct provider', () {
      // Arrange & Act
      const exception = SignInPermissionException('google');

      // Assert
      expect(exception.provider, equals('google'));
      expect(exception.eventName, equals('sign_in_permission_denied'));
    });

    test('toString includes provider', () {
      // Arrange
      const exception = SignInPermissionException('google');

      // Act
      final result = exception.toString();

      // Assert
      expect(result, contains('sign_in_permission_denied'));
      expect(result, contains('provider=google'));
    });
  });

  group('AuthenticationException', () {
    test('creates exception with provider and eventName', () {
      // Arrange & Act
      const exception = AuthenticationException('firebase', 'auth_error');

      // Assert
      expect(exception.provider, equals('firebase'));
      expect(exception.eventName, equals('auth_error'));
    });

    test('toString includes code when provided', () {
      // Arrange
      const exception = AuthenticationException(
        'firebase',
        'auth_error',
        code: 'auth/network-error',
      );

      // Act
      final result = exception.toString();

      // Assert
      expect(result, contains('auth_error'));
      expect(result, contains('provider=firebase'));
      expect(result, contains('code=auth/network-error'));
    });

    test('toString includes userId when provided', () {
      // Arrange
      const exception = AuthenticationException(
        'firebase',
        'auth_error',
        userId: 'user123',
      );

      // Act
      final result = exception.toString();

      // Assert
      expect(result, contains('auth_error'));
      expect(result, contains('provider=firebase'));
      expect(result, contains('userId=user123'));
    });

    test('toString includes all fields when provided', () {
      // Arrange
      const exception = AuthenticationException(
        'firebase',
        'auth_error',
        code: 'auth/error',
        userId: 'user123',
      );

      // Act
      final result = exception.toString();

      // Assert
      expect(result, contains('auth_error'));
      expect(result, contains('provider=firebase'));
      expect(result, contains('code=auth/error'));
      expect(result, contains('userId=user123'));
    });

    test('code can be null', () {
      // Arrange
      const exception = AuthenticationException('firebase', 'auth_error');

      // Assert
      expect(exception.code, isNull);
    });

    test('userId can be null', () {
      // Arrange
      const exception = AuthenticationException('firebase', 'auth_error');

      // Assert
      expect(exception.userId, isNull);
    });

    test('innerError can be provided', () {
      // Arrange
      final innerError = Exception('test');
      final exception = AuthenticationException(
        'firebase',
        'auth_error',
        innerError: innerError,
      );

      // Assert
      expect(exception.innerError, equals(innerError));
    });
  });

  group('UserDataException', () {
    test('creates exception with provider and eventName', () {
      // Arrange & Act
      const exception = UserDataException('firestore', 'user_get_error');

      // Assert
      expect(exception.provider, equals('firestore'));
      expect(exception.eventName, equals('user_get_error'));
    });

    test('toString includes uid when provided', () {
      // Arrange
      const exception = UserDataException(
        'firestore',
        'user_get_error',
        uid: 'user123',
      );

      // Act
      final result = exception.toString();

      // Assert
      expect(result, contains('user_get_error'));
      expect(result, contains('provider=firestore'));
      expect(result, contains('uid=user123'));
    });

    test('uid can be null', () {
      // Arrange
      const exception = UserDataException('firestore', 'user_get_error');

      // Assert
      expect(exception.uid, isNull);
    });

    test('innerError can be provided', () {
      // Arrange
      final innerError = Exception('test');
      final exception = UserDataException(
        'firestore',
        'user_get_error',
        innerError: innerError,
      );

      // Assert
      expect(exception.innerError, equals(innerError));
    });

    test('toString format is correct with all fields', () {
      // Arrange
      const exception = UserDataException(
        'firestore',
        'user_get_error',
        uid: 'user123',
      );

      // Act
      final result = exception.toString();

      // Assert
      expect(result, equals('user_get_error, provider=firestore, uid=user123'));
    });
  });
}
