import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldfish/core/data/models/visit_model.dart';

void main() {
  group('GeoLatLong', () {
    test('creates instance with required fields', () {
      const geo = GeoLatLong(lat: 45.0, long: -90.0);
      expect(geo.lat, 45.0);
      expect(geo.long, -90.0);
    });

    test('converts to and from map', () {
      const geo = GeoLatLong(lat: 45.0, long: -90.0);
      final map = geo.toMap();
      final restored = GeoLatLong.fromMap(map);
      expect(restored, geo);
    });

    test('copyWith creates new instance with updated fields', () {
      const geo = GeoLatLong(lat: 45.0, long: -90.0);
      final updated = geo.copyWith(lat: 52.5);
      expect(updated.lat, 52.5);
      expect(updated.long, -90.0);
    });

    test('equality works correctly', () {
      const geo1 = GeoLatLong(lat: 45.0, long: -90.0);
      const geo2 = GeoLatLong(lat: 45.0, long: -90.0);
      const geo3 = GeoLatLong(lat: 52.5, long: -90.0);
      expect(geo1, geo2);
      expect(geo1, isNot(geo3));
    });
  });

  group('LocationType', () {
    test('creates instance with required fields', () {
      const locationType = LocationType(type: 'amenity', subType: 'pub');
      expect(locationType.type, 'amenity');
      expect(locationType.subType, 'pub');
    });

    test('converts to and from map', () {
      const locationType = LocationType(type: 'amenity', subType: 'pub');
      final map = locationType.toMap();
      final restored = LocationType.fromMap(map);
      expect(restored, locationType);
    });

    test('copyWith creates new instance with updated fields', () {
      const locationType = LocationType(type: 'amenity', subType: 'pub');
      final updated = locationType.copyWith(subType: 'restaurant');
      expect(updated.type, 'amenity');
      expect(updated.subType, 'restaurant');
    });

    test('equality works correctly', () {
      const type1 = LocationType(type: 'amenity', subType: 'pub');
      const type2 = LocationType(type: 'amenity', subType: 'pub');
      const type3 = LocationType(type: 'tourism', subType: 'pub');
      expect(type1, type2);
      expect(type1, isNot(type3));
    });
  });

  group('Address', () {
    test('creates instance with all fields', () {
      const address = Address(
        nameNumber: '123',
        street: 'Main Street',
        city: 'Example City',
        postcode: 'CB1 1AA',
      );
      expect(address.nameNumber, '123');
      expect(address.street, 'Main Street');
      expect(address.city, 'Example City');
      expect(address.postcode, 'CB1 1AA');
    });

    test('creates instance with null fields', () {
      const address = Address();
      expect(address.nameNumber, isNull);
      expect(address.street, isNull);
      expect(address.city, isNull);
      expect(address.postcode, isNull);
    });

    test('converts to and from map', () {
      const address = Address(
        nameNumber: '123',
        street: 'Main Street',
        city: 'Example City',
        postcode: 'CB1 1AA',
      );
      final map = address.toMap();
      final restored = Address.fromMap(map);
      expect(restored, address);
    });

    test('toFormattedString formats address correctly', () {
      const address = Address(
        nameNumber: '123',
        street: 'Main Street',
        city: 'Example City',
        postcode: 'CB1 1AA',
      );
      expect(
        address.toFormattedString(),
        '123, Main Street, Example City, CB1 1AA',
      );
    });

    test('toFormattedString handles null fields', () {
      const address = Address(street: 'Main Street', city: 'Example City');
      expect(address.toFormattedString(), 'Main Street, Example City');
    });

    test('copyWith creates new instance with updated fields', () {
      const address = Address(street: 'Main Street', city: 'Example City');
      final updated = address.copyWith(postcode: 'EX1 1AA');
      expect(updated.street, 'Main Street');
      expect(updated.city, 'Example City');
      expect(updated.postcode, 'EX1 1AA');
    });
  });

  group('Visit', () {
    final now = DateTime.now();
    final timestamp = Timestamp.fromDate(now);

    test('creates instance with required fields', () {
      final visit = Visit(
        userId: 'user123',
        placeName: 'Test Place',
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      expect(visit.userId, 'user123');
      expect(visit.placeName, 'Test Place');
      expect(visit.id, isNull);
    });

    test('creates instance with all fields', () {
      const gps = GeoLatLong(lat: 45.0, long: -90.0);
      const address = Address(street: 'Main Street', city: 'Cambridge');
      const placeType = LocationType(type: 'amenity', subType: 'pub');
      final visit = Visit(
        id: 'visit123',
        userId: 'user123',
        placeName: 'Test Pub',
        placeAddress: address,
        gpsRecorded: gps,
        gpsKnown: gps,
        placeType: placeType,
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      expect(visit.id, 'visit123');
      expect(visit.placeName, 'Test Pub');
      expect(visit.placeAddress, address);
      expect(visit.gpsRecorded, gps);
      expect(visit.placeType, placeType);
    });

    test('fromMap creates instance from map', () {
      final data = {
        'user_id': 'user123',
        'place_name': 'Test Place',
        'gps_recorded': {'lat': 45.0, 'long': -90.0},
        'place_type': {'type': 'amenity', 'sub_type': 'pub'},
        'added_at': timestamp,
        'created_at': timestamp,
        'updated_at': timestamp,
      };
      final visit = Visit.fromMap(data, 'visit123');
      expect(visit.id, 'visit123');
      expect(visit.userId, 'user123');
      expect(visit.placeName, 'Test Place');
      expect(visit.gpsRecorded?.lat, 45.0);
      expect(visit.placeType?.type, 'amenity');
    });

    test('toMap converts to Firestore format', () {
      const gps = GeoLatLong(lat: 45.0, long: -90.0);
      final visit = Visit(
        userId: 'user123',
        placeName: 'Test Place',
        gpsRecorded: gps,
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final map = visit.toMap();
      expect(map['user_id'], 'user123');
      expect(map['place_name'], 'Test Place');
      expect(map['gps_recorded'], isA<Map<String, dynamic>>());
      expect(map['added_at'], isA<Timestamp>());
    });

    test('validate returns empty list for valid visit', () {
      final visit = Visit(
        userId: 'user123',
        placeName: 'Test Place',
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      expect(visit.validate(), isEmpty);
      expect(visit.isValid, isTrue);
    });

    test('validate returns errors for invalid visit', () {
      final visit1 = Visit(
        userId: '',
        placeName: 'Test Place',
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      expect(visit1.validate(), isNotEmpty);
      expect(visit1.isValid, isFalse);

      final visit2 = Visit(
        userId: 'user123',
        placeName: '   ',
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      expect(visit2.validate(), isNotEmpty);
      expect(visit2.isValid, isFalse);
    });

    test('copyWith creates new instance with updated fields', () {
      final visit = Visit(
        userId: 'user123',
        placeName: 'Test Place',
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final updated = visit.copyWith(placeName: 'Updated Place');
      expect(updated.placeName, 'Updated Place');
      expect(updated.userId, 'user123');
    });

    test('equality works correctly', () {
      final visit1 = Visit(
        id: 'visit123',
        userId: 'user123',
        placeName: 'Test Place',
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final visit2 = Visit(
        id: 'visit123',
        userId: 'user123',
        placeName: 'Test Place',
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final visit3 = Visit(
        id: 'visit123',
        userId: 'user123',
        placeName: 'Different Place',
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      expect(visit1, visit2);
      expect(visit1, isNot(visit3));
    });
  });
}
