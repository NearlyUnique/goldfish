import 'package:flutter_test/flutter_test.dart';
import 'package:goldfish/core/data/models/visit_model.dart';
import 'package:goldfish/features/map/domain/models/map_marker.dart';

void main() {
  final now = DateTime.now();

  group('MapMarker', () {
    test('creates instance with required fields', () {
      const coordinates = GeoLatLong(lat: 45.0, long: -90.0);
      final visit = Visit(
        id: 'visit123',
        userId: 'user123',
        placeName: 'Test Place',
        gpsKnown: coordinates,
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final marker = MapMarker(
        visitId: 'visit123',
        placeName: 'Test Place',
        coordinates: coordinates,
        visit: visit,
      );

      expect(marker.visitId, 'visit123');
      expect(marker.placeName, 'Test Place');
      expect(marker.coordinates, coordinates);
      expect(marker.visit, visit);
    });

    test('copyWith creates new instance with updated fields', () {
      const coordinates = GeoLatLong(lat: 45.0, long: -90.0);
      final visit = Visit(
        id: 'visit123',
        userId: 'user123',
        placeName: 'Test Place',
        gpsKnown: coordinates,
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final marker = MapMarker(
        visitId: 'visit123',
        placeName: 'Test Place',
        coordinates: coordinates,
        visit: visit,
      );

      const newCoordinates = GeoLatLong(lat: 52.5, long: -1.0);
      final updated = marker.copyWith(
        placeName: 'Updated Place',
        coordinates: newCoordinates,
      );

      expect(updated.visitId, 'visit123');
      expect(updated.placeName, 'Updated Place');
      expect(updated.coordinates, newCoordinates);
      expect(updated.visit, visit);
    });

    test('equality works correctly', () {
      const coordinates = GeoLatLong(lat: 45.0, long: -90.0);
      final visit1 = Visit(
        id: 'visit123',
        userId: 'user123',
        placeName: 'Test Place',
        gpsKnown: coordinates,
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final visit2 = Visit(
        id: 'visit123',
        userId: 'user123',
        placeName: 'Test Place',
        gpsKnown: coordinates,
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final marker1 = MapMarker(
        visitId: 'visit123',
        placeName: 'Test Place',
        coordinates: coordinates,
        visit: visit1,
      );
      final marker2 = MapMarker(
        visitId: 'visit123',
        placeName: 'Test Place',
        coordinates: coordinates,
        visit: visit2,
      );
      final marker3 = MapMarker(
        visitId: 'visit456',
        placeName: 'Test Place',
        coordinates: coordinates,
        visit: visit1,
      );

      expect(marker1, marker2);
      expect(marker1, isNot(marker3));
    });

    test('toString returns formatted string', () {
      const coordinates = GeoLatLong(lat: 45.0, long: -90.0);
      final visit = Visit(
        id: 'visit123',
        userId: 'user123',
        placeName: 'Test Place',
        gpsKnown: coordinates,
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final marker = MapMarker(
        visitId: 'visit123',
        placeName: 'Test Place',
        coordinates: coordinates,
        visit: visit,
      );

      expect(
        marker.toString(),
        'MapMarker(visitId: visit123, placeName: Test Place, '
        'coordinates: GeoLatLong(lat: 45.0, long: -90.0))',
      );
    });
  });

  group('MapMarker.fromVisits', () {
    test('converts visits with gpsKnown to markers', () {
      const gpsKnown = GeoLatLong(lat: 45.0, long: -90.0);
      final visit = Visit(
        id: 'visit123',
        userId: 'user123',
        placeName: 'Test Place',
        gpsKnown: gpsKnown,
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final markers = MapMarker.fromVisits([visit]);

      expect(markers, hasLength(1));
      expect(markers.first.visitId, 'visit123');
      expect(markers.first.placeName, 'Test Place');
      expect(markers.first.coordinates, gpsKnown);
      expect(markers.first.visit, visit);
    });

    test('converts visits with gpsRecorded to markers', () {
      const gpsRecorded = GeoLatLong(lat: 45.0, long: -90.0);
      final visit = Visit(
        id: 'visit123',
        userId: 'user123',
        placeName: 'Test Place',
        gpsRecorded: gpsRecorded,
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final markers = MapMarker.fromVisits([visit]);

      expect(markers, hasLength(1));
      expect(markers.first.coordinates, gpsRecorded);
    });

    test('prefers gpsKnown over gpsRecorded', () {
      const gpsKnown = GeoLatLong(lat: 45.0, long: -90.0);
      const gpsRecorded = GeoLatLong(lat: 52.5, long: -1.0);
      final visit = Visit(
        id: 'visit123',
        userId: 'user123',
        placeName: 'Test Place',
        gpsKnown: gpsKnown,
        gpsRecorded: gpsRecorded,
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final markers = MapMarker.fromVisits([visit]);

      expect(markers, hasLength(1));
      expect(markers.first.coordinates, gpsKnown);
      expect(markers.first.coordinates, isNot(gpsRecorded));
    });

    test('filters out visits without coordinates', () {
      final visit1 = Visit(
        id: 'visit1',
        userId: 'user123',
        placeName: 'Place with GPS',
        gpsKnown: const GeoLatLong(lat: 45.0, long: -90.0),
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final visit2 = Visit(
        id: 'visit2',
        userId: 'user123',
        placeName: 'Place without GPS',
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final visit3 = Visit(
        id: 'visit3',
        userId: 'user123',
        placeName: 'Another place with GPS',
        gpsRecorded: const GeoLatLong(lat: 52.5, long: -1.0),
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final markers = MapMarker.fromVisits([visit1, visit2, visit3]);

      expect(markers, hasLength(2));
      expect(markers.map((m) => m.visitId), containsAll(['visit1', 'visit3']));
      expect(markers.map((m) => m.visitId), isNot(contains('visit2')));
    });

    test('filters out visits without id', () {
      final visit = Visit(
        userId: 'user123',
        placeName: 'Place without ID',
        gpsKnown: const GeoLatLong(lat: 45.0, long: -90.0),
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final markers = MapMarker.fromVisits([visit]);

      expect(markers, isEmpty);
    });

    test('returns empty list for empty input', () {
      final markers = MapMarker.fromVisits([]);

      expect(markers, isEmpty);
    });

    test('handles multiple visits correctly', () {
      final visit1 = Visit(
        id: 'visit1',
        userId: 'user123',
        placeName: 'Place 1',
        gpsKnown: const GeoLatLong(lat: 45.0, long: -90.0),
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final visit2 = Visit(
        id: 'visit2',
        userId: 'user123',
        placeName: 'Place 2',
        gpsRecorded: const GeoLatLong(lat: 52.5, long: -1.0),
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final visit3 = Visit(
        id: 'visit3',
        userId: 'user123',
        placeName: 'Place 3',
        gpsKnown: const GeoLatLong(lat: 51.5, long: -0.1),
        gpsRecorded: const GeoLatLong(lat: 51.6, long: -0.2),
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final markers = MapMarker.fromVisits([visit1, visit2, visit3]);

      expect(markers, hasLength(3));
      expect(markers[0].coordinates, visit1.gpsKnown);
      expect(markers[1].coordinates, visit2.gpsRecorded);
      expect(markers[2].coordinates, visit3.gpsKnown); // Prefers gpsKnown
    });
  });
}
