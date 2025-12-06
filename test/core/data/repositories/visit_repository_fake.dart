import 'package:goldfish/core/data/models/visit_model.dart';

/// Fake implementation of [VisitRepository] for testing.
///
/// Provides function fields that tests can configure to control behavior.
/// Default implementations return safe defaults so tests only need to
/// configure the behavior they care about.
///
/// Note: This is a test double that matches the interface of VisitRepository
/// but cannot implement it since VisitRepository is a concrete class.
class FakeVisitRepository {
  /// Creates a new [FakeVisitRepository].
  ///
  /// Optionally accepts function handlers for each method. If not provided,
  /// uses default implementations that return safe defaults.
  FakeVisitRepository({
    Future<String> Function(Visit visit)? onCreateVisit,
    Future<List<Visit>> Function(String userId)? onGetUserVisits,
    Future<Visit?> Function(String id, String userId)? onGetVisitById,
  })  : onCreateVisit = onCreateVisit ?? _defaultCreateVisit,
        onGetUserVisits = onGetUserVisits ?? _defaultGetUserVisits,
        onGetVisitById = onGetVisitById ?? _defaultGetVisitById;

  /// Handler for [createVisit].
  Future<String> Function(Visit visit) onCreateVisit;

  /// Handler for [getUserVisits].
  Future<List<Visit>> Function(String userId) onGetUserVisits;

  /// Handler for [getVisitById].
  Future<Visit?> Function(String id, String userId) onGetVisitById;

  /// Creates a visit. Matches [VisitRepository.createVisit] interface.
  Future<String> createVisit(Visit visit) => onCreateVisit(visit);

  /// Gets user visits. Matches [VisitRepository.getUserVisits] interface.
  Future<List<Visit>> getUserVisits(String userId) =>
      onGetUserVisits(userId);

  /// Gets visit by ID. Matches [VisitRepository.getVisitById] interface.
  Future<Visit?> getVisitById(String id, String userId) =>
      onGetVisitById(id, userId);

  // Default implementations
  static Future<String> _defaultCreateVisit(Visit visit) async {
    return 'fake-visit-id';
  }

  static Future<List<Visit>> _defaultGetUserVisits(String userId) async {
    return [];
  }

  static Future<Visit?> _defaultGetVisitById(String id, String userId) async {
    return null;
  }
}

