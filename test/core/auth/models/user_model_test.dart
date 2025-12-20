import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldfish/core/auth/models/user_model.dart';

/// Tests for [UserModel] serialization and deserialization.
void main() {
  group('UserModel', () {
    test('creates instance with required fields', () {
      // Arrange
      final now = DateTime.now();

      // Act
      final user = UserModel(
        uid: 'test_uid',
        email: 'test@example.com',
        createdAt: now,
        updatedAt: now,
      );

      // Assert
      expect(user.uid, equals('test_uid'));
      expect(user.email, equals('test@example.com'));
      expect(user.createdAt, equals(now));
      expect(user.updatedAt, equals(now));
      expect(user.displayName, isNull);
      expect(user.photoUrl, isNull);
    });

    test('creates instance with all fields', () {
      // Arrange
      final now = DateTime.now();

      // Act
      final user = UserModel(
        uid: 'test_uid',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
        createdAt: now,
        updatedAt: now,
      );

      // Assert
      expect(user.uid, equals('test_uid'));
      expect(user.email, equals('test@example.com'));
      expect(user.displayName, equals('Test User'));
      expect(user.photoUrl, equals('https://example.com/photo.jpg'));
    });

    group('fromMap', () {
      test('creates UserModel from map with all fields', () {
        // Arrange
        final now = DateTime.now();
        final timestamp = Timestamp.fromDate(now);
        final map = {
          'email': 'test@example.com',
          'display_name': 'Test User',
          'photo_url': 'https://example.com/photo.jpg',
          'created_at': timestamp,
          'updated_at': timestamp,
        };

        // Act
        final user = UserModel.fromMap(map, 'test_uid');

        // Assert
        expect(user.uid, equals('test_uid'));
        expect(user.email, equals('test@example.com'));
        expect(user.displayName, equals('Test User'));
        expect(user.photoUrl, equals('https://example.com/photo.jpg'));
        expect(user.createdAt, equals(now));
        expect(user.updatedAt, equals(now));
      });

      test('creates UserModel from map with null optional fields', () {
        // Arrange
        final now = DateTime.now();
        final timestamp = Timestamp.fromDate(now);
        final map = {
          'email': 'test@example.com',
          'display_name': null,
          'photo_url': null,
          'created_at': timestamp,
          'updated_at': timestamp,
        };

        // Act
        final user = UserModel.fromMap(map, 'test_uid');

        // Assert
        expect(user.uid, equals('test_uid'));
        expect(user.email, equals('test@example.com'));
        expect(user.displayName, isNull);
        expect(user.photoUrl, isNull);
      });

      test('creates UserModel from map with missing optional fields', () {
        // Arrange
        final now = DateTime.now();
        final timestamp = Timestamp.fromDate(now);
        final map = {
          'email': 'test@example.com',
          'created_at': timestamp,
          'updated_at': timestamp,
        };

        // Act
        final user = UserModel.fromMap(map, 'test_uid');

        // Assert
        expect(user.uid, equals('test_uid'));
        expect(user.email, equals('test@example.com'));
        expect(user.displayName, isNull);
        expect(user.photoUrl, isNull);
      });
    });

    group('fromFirestore', () {
      test('creates UserModel from Firestore document snapshot', () async {
        // Arrange
        final fakeFirestore = FakeFirebaseFirestore();
        final now = DateTime.now();
        final timestamp = Timestamp.fromDate(now);
        await fakeFirestore.collection('users').doc('test_uid').set({
          'email': 'test@example.com',
          'display_name': 'Test User',
          'photo_url': 'https://example.com/photo.jpg',
          'created_at': timestamp,
          'updated_at': timestamp,
        });
        final snapshot = await fakeFirestore
            .collection('users')
            .doc('test_uid')
            .get();

        // Act
        final user = UserModel.fromFirestore(snapshot);

        // Assert
        expect(user.uid, equals('test_uid'));
        expect(user.email, equals('test@example.com'));
        expect(user.displayName, equals('Test User'));
        expect(user.photoUrl, equals('https://example.com/photo.jpg'));
        expect(user.createdAt, equals(now));
        expect(user.updatedAt, equals(now));
      });

      test('creates UserModel from Firestore with null optional fields',
          () async {
        // Arrange
        final fakeFirestore = FakeFirebaseFirestore();
        final now = DateTime.now();
        final timestamp = Timestamp.fromDate(now);
        await fakeFirestore.collection('users').doc('test_uid').set({
          'email': 'test@example.com',
          'display_name': null,
          'photo_url': null,
          'created_at': timestamp,
          'updated_at': timestamp,
        });
        final snapshot = await fakeFirestore
            .collection('users')
            .doc('test_uid')
            .get();

        // Act
        final user = UserModel.fromFirestore(snapshot);

        // Assert
        expect(user.uid, equals('test_uid'));
        expect(user.email, equals('test@example.com'));
        expect(user.displayName, isNull);
        expect(user.photoUrl, isNull);
      });
    });

    group('toMap', () {
      test('converts UserModel to map with all fields', () {
        // Arrange
        final now = DateTime.now();
        final user = UserModel(
          uid: 'test_uid',
          email: 'test@example.com',
          displayName: 'Test User',
          photoUrl: 'https://example.com/photo.jpg',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final map = user.toMap();

        // Assert
        expect(map['email'], equals('test@example.com'));
        expect(map['display_name'], equals('Test User'));
        expect(map['photo_url'], equals('https://example.com/photo.jpg'));
        expect(map['created_at'], isA<Timestamp>());
        expect(map['updated_at'], isA<Timestamp>());
        expect((map['created_at'] as Timestamp).toDate(), equals(now));
        expect((map['updated_at'] as Timestamp).toDate(), equals(now));
      });

      test('converts UserModel to map with null optional fields', () {
        // Arrange
        final now = DateTime.now();
        final user = UserModel(
          uid: 'test_uid',
          email: 'test@example.com',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final map = user.toMap();

        // Assert
        expect(map['email'], equals('test@example.com'));
        expect(map['display_name'], isNull);
        expect(map['photo_url'], isNull);
      });
    });

    group('serialization round-trip', () {
      test('fromMap and toMap are inverse operations', () {
        // Arrange
        final now = DateTime.now();
        final timestamp = Timestamp.fromDate(now);
        final originalMap = {
          'email': 'test@example.com',
          'display_name': 'Test User',
          'photo_url': 'https://example.com/photo.jpg',
          'created_at': timestamp,
          'updated_at': timestamp,
        };

        // Act
        final user = UserModel.fromMap(originalMap, 'test_uid');
        final roundTripMap = user.toMap();

        // Assert
        expect(roundTripMap['email'], equals(originalMap['email']));
        expect(roundTripMap['display_name'], equals(originalMap['display_name']));
        expect(roundTripMap['photo_url'], equals(originalMap['photo_url']));
        expect(
          (roundTripMap['created_at'] as Timestamp).toDate(),
          equals((originalMap['created_at'] as Timestamp).toDate()),
        );
        expect(
          (roundTripMap['updated_at'] as Timestamp).toDate(),
          equals((originalMap['updated_at'] as Timestamp).toDate()),
        );
      });

      test('fromMap and toMap handle null fields correctly', () {
        // Arrange
        final now = DateTime.now();
        final timestamp = Timestamp.fromDate(now);
        final originalMap = {
          'email': 'test@example.com',
          'display_name': null,
          'photo_url': null,
          'created_at': timestamp,
          'updated_at': timestamp,
        };

        // Act
        final user = UserModel.fromMap(originalMap, 'test_uid');
        final roundTripMap = user.toMap();

        // Assert
        expect(roundTripMap['email'], equals(originalMap['email']));
        expect(roundTripMap['display_name'], isNull);
        expect(roundTripMap['photo_url'], isNull);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        // Arrange
        final now = DateTime.now();
        final user = UserModel(
          uid: 'test_uid',
          email: 'test@example.com',
          displayName: 'Original Name',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final updated = user.copyWith(displayName: 'Updated Name');

        // Assert
        expect(updated.uid, equals('test_uid'));
        expect(updated.email, equals('test@example.com'));
        expect(updated.displayName, equals('Updated Name'));
        expect(updated.createdAt, equals(now));
        expect(updated.updatedAt, equals(now));
      });

      test('copyWith does not replace with null due to null-aware operator', () {
        // Arrange
        final now = DateTime.now();
        final user = UserModel(
          uid: 'test_uid',
          email: 'test@example.com',
          displayName: 'Original Name',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        // Note: copyWith uses ?? operator, so passing null won't replace the value
        final updated = user.copyWith(displayName: null);

        // Assert
        // The ?? operator means null values are ignored, so original value is kept
        expect(updated.displayName, equals('Original Name'));
        expect(updated.email, equals('test@example.com'));
      });
    });

    group('equality', () {
      test('two UserModels with same fields are equal', () {
        // Arrange
        final now = DateTime.now();
        final user1 = UserModel(
          uid: 'test_uid',
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );
        final user2 = UserModel(
          uid: 'test_uid',
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );

        // Assert
        expect(user1, equals(user2));
        expect(user1.hashCode, equals(user2.hashCode));
      });

      test('two UserModels with different fields are not equal', () {
        // Arrange
        final now = DateTime.now();
        final user1 = UserModel(
          uid: 'test_uid',
          email: 'test@example.com',
          createdAt: now,
          updatedAt: now,
        );
        final user2 = UserModel(
          uid: 'test_uid',
          email: 'different@example.com',
          createdAt: now,
          updatedAt: now,
        );

        // Assert
        expect(user1, isNot(equals(user2)));
      });
    });

    group('toString', () {
      test('includes uid, email, and displayName', () {
        // Arrange
        final now = DateTime.now();
        final user = UserModel(
          uid: 'test_uid',
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final result = user.toString();

        // Assert
        expect(result, contains('test_uid'));
        expect(result, contains('test@example.com'));
        expect(result, contains('Test User'));
      });
    });
  });
}

