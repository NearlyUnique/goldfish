import 'package:goldfish/core/exceptions/goldfish_exception.dart';

/// Exception thrown when visit data operations fail.
class VisitDataException extends GoldfishException {
  /// Creates a new [VisitDataException] with the given [provider], [eventName],
  /// and optional [visitId], [userId], and [innerError] for diagnostics.
  const VisitDataException(
    this.provider,
    String eventName, {
    this.visitId,
    this.userId,
    Object? innerError,
  }) : super(eventName, innerError);

  /// The provider name (e.g., 'firestore').
  final String provider;

  /// The visit ID, if available, for diagnostic purposes.
  final String? visitId;

  /// The user ID, if available, for diagnostic purposes.
  final String? userId;

  /// Gets the display message for the exception including [visitId] and [userId]
  @override
  String toString() =>
      '${super.toString()}, provider=$provider, visitId=$visitId, userId=$userId';
}
