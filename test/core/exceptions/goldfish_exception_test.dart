import 'package:flutter_test/flutter_test.dart';
import 'package:goldfish/core/exceptions/goldfish_exception.dart';

/// Tests for [GoldfishException] base class.
void main() {
  group('GoldfishException', () {
    test('toString returns eventName', () {
      // Arrange
      final exception = _TestGoldfishException('test_event', null);

      // Act
      final result = exception.toString();

      // Assert
      expect(result, equals('test_event'));
    });

    test('displayMessage returns eventName when innerError is null', () {
      // Arrange
      final exception = _TestGoldfishException('test_event', null);

      // Act
      final result = exception.displayMessage;

      // Assert
      expect(result, equals('test_event'));
    });

    test('displayMessage includes innerError when present', () {
      // Arrange
      final innerError = Exception('inner error message');
      final exception = _TestGoldfishException('test_event', innerError);

      // Act
      final result = exception.displayMessage;

      // Assert
      expect(result, contains('test_event'));
      expect(result, contains('inner error message'));
      expect(result, contains(':'));
    });

    test('displayMessage handles string innerError', () {
      // Arrange
      const innerError = 'string error';
      final exception = _TestGoldfishException('test_event', innerError);

      // Act
      final result = exception.displayMessage;

      // Assert
      expect(result, contains('test_event'));
      expect(result, contains('string error'));
    });

    test('displayMessage handles object innerError', () {
      // Arrange
      final innerError = {'key': 'value'};
      final exception = _TestGoldfishException('test_event', innerError);

      // Act
      final result = exception.displayMessage;

      // Assert
      expect(result, contains('test_event'));
      expect(result, contains(':'));
    });

    test('eventName is accessible', () {
      // Arrange
      final exception = _TestGoldfishException('my_event', null);

      // Assert
      expect(exception.eventName, equals('my_event'));
    });

    test('innerError is accessible', () {
      // Arrange
      final innerError = Exception('test');
      final exception = _TestGoldfishException('event', innerError);

      // Assert
      expect(exception.innerError, equals(innerError));
    });

    test('innerError can be null', () {
      // Arrange
      final exception = _TestGoldfishException('event', null);

      // Assert
      expect(exception.innerError, isNull);
    });
  });
}

/// Concrete implementation of [GoldfishException] for testing.
class _TestGoldfishException extends GoldfishException {
  const _TestGoldfishException(super.eventName, super.innerError);
}
