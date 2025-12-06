import 'package:flutter_test/flutter_test.dart';
import 'package:goldfish/core/logging/app_logger.dart';

/// Bootstrap test suite to verify test infrastructure is working.
///
/// This test verifies that:
/// - The test framework is properly configured
/// - Logging works in tests
/// - Tests can be executed with `flutter test`
void main() {
  test('AppLogger can log info and error events', () {
    // Verify logging doesn't throw exceptions
    expect(() {
      AppLogger.info({
        'event': 'test_started',
        'test_name': 'App bootstrap test',
      });
    }, returnsNormally);

    expect(() {
      AppLogger.error({
        'event': 'test_error',
        'error': 'Test error message',
      });
    }, returnsNormally);

    // Verify test framework works
    expect(true, isTrue);
  });
}
