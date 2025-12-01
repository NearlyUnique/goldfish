/// Exception thrown when visit data operations fail.
class VisitDataException implements Exception {
  /// Creates a new [VisitDataException] with the given [message].
  const VisitDataException(this.message);

  /// The error message.
  final String message;

  @override
  String toString() => message;
}

