/// Base exception for all Goldfish exceptions. Do not throw or catch.
abstract class GoldfishException implements Exception {
  /// Creates a new [GoldfishException].
  const GoldfishException(this.eventName, this.innerError);

  /// The event name for logging purposes (e.g., 'sign_in_failed').
  final String eventName;

  /// The underlying error that caused this exception, if available.
  final Object? innerError;

  @override
  String toString() => eventName;

  /// Gets the display message for the exception including [innerError]s
  String get displayMessage {
    if (innerError == null) {
      return toString();
    }
    return '$toString() : $innerError.toString()';
  }
}
