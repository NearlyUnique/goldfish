/// Exception thrown when visit data operations fail.
class VisitDataException implements Exception {
  /// Creates a new [VisitDataException] with the given [provider], [eventName],
  /// and optional [visitId], [userId], and [innerError] for diagnostics.
  const VisitDataException(
    this.provider,
    this.eventName, {
    this.visitId,
    this.userId,
    this.innerError,
  });

  /// The provider name (e.g., 'firestore').
  final String provider;

  /// The event name for logging purposes (e.g., 'visit_create_error').
  final String eventName;

  /// The visit ID, if available, for diagnostic purposes.
  final String? visitId;

  /// The user ID, if available, for diagnostic purposes.
  final String? userId;

  /// The underlying error that caused this exception, if available.
  final Object? innerError;

  /// Gets the error message in the format 'provider: eventName'.
  String get displayMessage => '$provider: $eventName';

  @override
  String toString() => displayMessage;
}
