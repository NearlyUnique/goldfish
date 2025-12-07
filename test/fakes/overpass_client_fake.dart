import 'package:goldfish/core/api/overpass_client.dart';
import 'package:goldfish/core/data/models/place_suggestion_model.dart';

/// Fake implementation of [OverpassClient] for testing.
///
/// Provides function fields that tests can configure to control behavior.
/// Default implementations return safe defaults so tests only need to
/// configure the behavior they care about.
class FakeOverpassClient implements OverpassClient {
  /// Creates a new [FakeOverpassClient].
  ///
  /// Optionally accepts function handlers for each method. If not provided,
  /// uses default implementations that return safe defaults.
  FakeOverpassClient({
    Future<List<PlaceSuggestion>> Function(
      double latitude,
      double longitude, {
      double radiusMeters,
    })? onFindNearbyPlaces,
  }) : onFindNearbyPlaces = onFindNearbyPlaces ?? _defaultFindNearbyPlaces;

  /// Handler for [findNearbyPlaces].
  Future<List<PlaceSuggestion>> Function(
    double latitude,
    double longitude, {
    double radiusMeters,
  }) onFindNearbyPlaces;

  @override
  Future<List<PlaceSuggestion>> findNearbyPlaces(
    double latitude,
    double longitude, {
    double radiusMeters = 20,
  }) =>
      onFindNearbyPlaces(latitude, longitude, radiusMeters: radiusMeters);

  static Future<List<PlaceSuggestion>> _defaultFindNearbyPlaces(
    double latitude,
    double longitude, {
    double radiusMeters = 20,
  }) async =>
      [];
}


