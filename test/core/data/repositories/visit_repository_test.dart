import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldfish/core/data/models/visit_model.dart';
import 'package:goldfish/core/data/repositories/visit_repository.dart';
import 'package:goldfish/core/data/visit_exceptions.dart';

void main() {
  group('VisitRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late VisitRepository visitRepository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      visitRepository = VisitRepository(firestore: fakeFirestore);
    });

    group('createVisit', () {
      test('successfully creates a visit with auto-generated ID', () async {
        // Arrange
        final now = DateTime.now();
        final visit = Visit(
          userId: 'user123',
          placeName: 'Test Place',
          addedAt: now,
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final visitId = await visitRepository.createVisit(visit);

        // Assert
        expect(visitId, isNotEmpty);
        final snapshot = await fakeFirestore
            .collection('visits')
            .doc(visitId)
            .get();

        expect(snapshot.exists, isTrue);
        final data = snapshot.data();
        expect(data?['user_id'], equals('user123'));
        expect(data?['place_name'], equals('Test Place'));
      });

      test('successfully creates a visit with provided ID', () async {
        // Arrange
        final now = DateTime.now();
        final visit = Visit(
          id: 'custom-visit-id',
          userId: 'user123',
          placeName: 'Test Place',
          addedAt: now,
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final visitId = await visitRepository.createVisit(visit);

        // Assert
        expect(visitId, equals('custom-visit-id'));
        final snapshot = await fakeFirestore
            .collection('visits')
            .doc('custom-visit-id')
            .get();

        expect(snapshot.exists, isTrue);
        final data = snapshot.data();
        expect(data?['user_id'], equals('user123'));
        expect(data?['place_name'], equals('Test Place'));
      });

      test('successfully creates a visit with all optional fields', () async {
        // Arrange
        final now = DateTime.now();
        final visit = Visit(
          userId: 'user123',
          placeName: 'Test Place',
          placeAddress: const Address(
            nameNumber: '123',
            street: 'Main St',
            city: 'Test City',
            postcode: '12345',
          ),
          gpsRecorded: const GeoLatLong(lat: 51.5074, long: -0.1278),
          gpsKnown: const GeoLatLong(lat: 51.5075, long: -0.1279),
          placeType: const LocationType(type: 'amenity', subType: 'pub'),
          addedAt: now,
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final visitId = await visitRepository.createVisit(visit);

        // Assert
        expect(visitId, isNotEmpty);
        final snapshot = await fakeFirestore
            .collection('visits')
            .doc(visitId)
            .get();

        expect(snapshot.exists, isTrue);
        final data = snapshot.data();
        expect(data?['place_address'], isNotNull);
        expect(data?['gps_recorded'], isNotNull);
        expect(data?['gps_known'], isNotNull);
        expect(data?['place_type'], isNotNull);
      });

      test('throws VisitDataException when visit is invalid', () async {
        // Arrange
        final now = DateTime.now();
        final visit = Visit(
          userId: '', // Invalid: empty userId
          placeName: 'Test Place',
          addedAt: now,
          createdAt: now,
          updatedAt: now,
        );

        // Act & Assert
        expect(
          () => visitRepository.createVisit(visit),
          throwsA(isA<VisitDataException>()),
        );
      });

      test('throws VisitDataException when place name is empty', () async {
        // Arrange
        final now = DateTime.now();
        final visit = Visit(
          userId: 'user123',
          placeName: '   ', // Invalid: whitespace only
          addedAt: now,
          createdAt: now,
          updatedAt: now,
        );

        // Act & Assert
        expect(
          () => visitRepository.createVisit(visit),
          throwsA(isA<VisitDataException>()),
        );
      });
    });

    group('getUserVisits', () {
      test('returns visits for user ordered by most recent first', () async {
        // Arrange
        final now = DateTime.now();
        final earlier = now.subtract(const Duration(days: 2));
        final later = now.subtract(const Duration(days: 1));

        // Add visits in non-chronological order
        await fakeFirestore.collection('visits').doc('visit1').set({
          'user_id': 'user123',
          'place_name': 'Older Place',
          'added_at': Timestamp.fromDate(earlier),
          'created_at': Timestamp.fromDate(earlier),
          'updated_at': Timestamp.fromDate(earlier),
        });

        await fakeFirestore.collection('visits').doc('visit2').set({
          'user_id': 'user123',
          'place_name': 'Newer Place',
          'added_at': Timestamp.fromDate(later),
          'created_at': Timestamp.fromDate(later),
          'updated_at': Timestamp.fromDate(later),
        });

        // Act
        final visits = await visitRepository.getUserVisits('user123');

        // Assert
        expect(visits, hasLength(2));
        expect(visits[0].placeName, equals('Newer Place'));
        expect(visits[1].placeName, equals('Older Place'));
      });

      test('returns only visits for specified user', () async {
        // Arrange
        final now = DateTime.now();

        await fakeFirestore.collection('visits').doc('visit1').set({
          'user_id': 'user123',
          'place_name': 'User 123 Place',
          'added_at': Timestamp.fromDate(now),
          'created_at': Timestamp.fromDate(now),
          'updated_at': Timestamp.fromDate(now),
        });

        await fakeFirestore.collection('visits').doc('visit2').set({
          'user_id': 'user456',
          'place_name': 'User 456 Place',
          'added_at': Timestamp.fromDate(now),
          'created_at': Timestamp.fromDate(now),
          'updated_at': Timestamp.fromDate(now),
        });

        // Act
        final visits = await visitRepository.getUserVisits('user123');

        // Assert
        expect(visits, hasLength(1));
        expect(visits[0].placeName, equals('User 123 Place'));
        expect(visits[0].userId, equals('user123'));
      });

      test('returns empty list when user has no visits', () async {
        // Act
        final visits = await visitRepository.getUserVisits('user123');

        // Assert
        expect(visits, isEmpty);
      });

      test('handles visits with optional fields', () async {
        // Arrange
        final now = DateTime.now();

        await fakeFirestore.collection('visits').doc('visit1').set({
          'user_id': 'user123',
          'place_name': 'Test Place',
          'place_address': {
            'name_number': '123',
            'street': 'Main St',
            'city': 'Test City',
            'postcode': '12345',
          },
          'gps_recorded': {'lat': 51.5074, 'long': -0.1278},
          'gps_known': {'lat': 51.5075, 'long': -0.1279},
          'place_type': {'type': 'amenity', 'sub_type': 'pub'},
          'added_at': Timestamp.fromDate(now),
          'created_at': Timestamp.fromDate(now),
          'updated_at': Timestamp.fromDate(now),
        });

        // Act
        final visits = await visitRepository.getUserVisits('user123');

        // Assert
        expect(visits, hasLength(1));
        final visit = visits[0];
        expect(visit.placeAddress, isNotNull);
        expect(visit.gpsRecorded, isNotNull);
        expect(visit.gpsKnown, isNotNull);
        expect(visit.placeType, isNotNull);
        expect(visit.placeType?.type, equals('amenity'));
        expect(visit.placeType?.subType, equals('pub'));
      });
    });

    group('getVisitById', () {
      test('returns visit when it exists and belongs to user', () async {
        // Arrange
        final now = DateTime.now();

        await fakeFirestore.collection('visits').doc('visit123').set({
          'user_id': 'user123',
          'place_name': 'Test Place',
          'added_at': Timestamp.fromDate(now),
          'created_at': Timestamp.fromDate(now),
          'updated_at': Timestamp.fromDate(now),
        });

        // Act
        final visit = await visitRepository.getVisitById('visit123', 'user123');

        // Assert
        expect(visit, isNotNull);
        expect(visit?.id, equals('visit123'));
        expect(visit?.userId, equals('user123'));
        expect(visit?.placeName, equals('Test Place'));
      });

      test('returns null when visit does not exist', () async {
        // Act
        final visit = await visitRepository.getVisitById('nonexistent', 'user123');

        // Assert
        expect(visit, isNull);
      });

      test('returns null when visit belongs to different user', () async {
        // Arrange
        final now = DateTime.now();

        await fakeFirestore.collection('visits').doc('visit123').set({
          'user_id': 'user456', // Different user
          'place_name': 'Test Place',
          'added_at': Timestamp.fromDate(now),
          'created_at': Timestamp.fromDate(now),
          'updated_at': Timestamp.fromDate(now),
        });

        // Act
        final visit = await visitRepository.getVisitById('visit123', 'user123');

        // Assert
        expect(visit, isNull);
      });

      test('returns visit with all optional fields', () async {
        // Arrange
        final now = DateTime.now();

        await fakeFirestore.collection('visits').doc('visit123').set({
          'user_id': 'user123',
          'place_name': 'Test Place',
          'place_address': {
            'name_number': '123',
            'street': 'Main St',
            'city': 'Test City',
            'postcode': '12345',
          },
          'gps_recorded': {'lat': 51.5074, 'long': -0.1278},
          'gps_known': {'lat': 51.5075, 'long': -0.1279},
          'place_type': {'type': 'amenity', 'sub_type': 'pub'},
          'added_at': Timestamp.fromDate(now),
          'created_at': Timestamp.fromDate(now),
          'updated_at': Timestamp.fromDate(now),
        });

        // Act
        final visit = await visitRepository.getVisitById('visit123', 'user123');

        // Assert
        expect(visit, isNotNull);
        expect(visit?.placeAddress, isNotNull);
        expect(visit?.gpsRecorded, isNotNull);
        expect(visit?.gpsKnown, isNotNull);
        expect(visit?.placeType, isNotNull);
      });
    });
  });
}

