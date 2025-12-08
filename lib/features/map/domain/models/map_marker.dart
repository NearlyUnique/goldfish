import 'package:goldfish/core/data/models/visit_model.dart';

/// Represents a map marker for a visit location.
///
/// Contains the visit data and coordinates needed to display the visit
/// on a map. Coordinates are selected from the visit's GPS data, preferring
/// [gpsKnown] over [gpsRecorded] when available.
class MapMarker {
  /// Creates a new [MapMarker].
  const MapMarker({
    required this.visitId,
    required this.placeName,
    required this.coordinates,
    required this.visit,
  });

  /// The visit's document ID.
  final String visitId;

  /// The name of the place visited.
  final String placeName;

  /// The coordinates to display on the map.
  ///
  /// This is selected from the visit's GPS data, preferring [gpsKnown]
  /// over [gpsRecorded] when available.
  final GeoLatLong coordinates;

  /// The full visit data for info windows and details.
  final Visit visit;

  /// Creates a list of [MapMarker]s from a list of [Visit]s.
  ///
  /// Filters out visits that don't have GPS coordinates (neither
  /// [gpsKnown] nor [gpsRecorded]). When both are available, prefers
  /// [gpsKnown] over [gpsRecorded].
  ///
  /// Returns an empty list if no visits have coordinates.
  static List<MapMarker> fromVisits(List<Visit> visits) {
    final markers = <MapMarker>[];

    for (final visit in visits) {
      // Prefer gpsKnown over gpsRecorded
      final coordinates = visit.gpsKnown ?? visit.gpsRecorded;

      // Skip visits without coordinates
      if (coordinates == null) {
        continue;
      }

      // Skip visits without an ID (shouldn't happen for saved visits)
      if (visit.id == null) {
        continue;
      }

      markers.add(
        MapMarker(
          visitId: visit.id!,
          placeName: visit.placeName,
          coordinates: coordinates,
          visit: visit,
        ),
      );
    }

    return markers;
  }

  /// Creates a copy of this [MapMarker] with the given fields replaced.
  MapMarker copyWith({
    String? visitId,
    String? placeName,
    GeoLatLong? coordinates,
    Visit? visit,
  }) {
    return MapMarker(
      visitId: visitId ?? this.visitId,
      placeName: placeName ?? this.placeName,
      coordinates: coordinates ?? this.coordinates,
      visit: visit ?? this.visit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapMarker &&
        other.visitId == visitId &&
        other.placeName == placeName &&
        other.coordinates == coordinates &&
        other.visit == visit;
  }

  @override
  int get hashCode => Object.hash(visitId, placeName, coordinates, visit);

  @override
  String toString() =>
      'MapMarker(visitId: $visitId, placeName: $placeName, '
      'coordinates: $coordinates)';
}

