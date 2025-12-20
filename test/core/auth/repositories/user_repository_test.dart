import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldfish/core/auth/models/user_model.dart';
import 'package:goldfish/core/auth/repositories/user_repository.dart';

void main() {
  group('UserRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late UserRepository userRepository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      userRepository = UserRepository(firestore: fakeFirestore);
    });

    group('createUser', () {
      test('successfully creates a user', () async {
        // Arrange
        final user = UserModel(
          uid: 'test_uid',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final result = await userRepository.createUser(user);

        // Assert: document was written to the fake Firestore.
        final snapshot = await fakeFirestore
            .collection('users')
            .doc('test_uid')
            .get();

        expect(snapshot.exists, isTrue);
        final data = snapshot.data();
        expect(data?['email'], equals('test@example.com'));
        expect(result.eventName, equals('user_create'));
        expect(result.uid, equals('test_uid'));
        expect(result.succeeded, isTrue);
      });

      // Note: Testing error handling with FakeFirebaseFirestore is difficult
      // as it doesn't provide a way to simulate errors. Error handling is
      // tested indirectly through integration tests and the error paths
      // are covered by the exception being thrown on actual failures.
    });

    group('updateUser', () {
      test('successfully updates an existing user', () async {
        // Arrange
        final now = DateTime.now();
        final timestamp = Timestamp.fromDate(now);
        await fakeFirestore.collection('users').doc('test_uid').set({
          'email': 'old@example.com',
          'display_name': 'Old Name',
          'created_at': timestamp,
          'updated_at': timestamp,
        });

        final updatedUser = UserModel(
          uid: 'test_uid',
          email: 'new@example.com',
          displayName: 'New Name',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final result = await userRepository.updateUser(updatedUser);

        // Assert
        expect(result.eventName, equals('user_update'));
        expect(result.uid, equals('test_uid'));
        expect(result.succeeded, isTrue);

        final snapshot = await fakeFirestore
            .collection('users')
            .doc('test_uid')
            .get();
        final data = snapshot.data();
        expect(data?['email'], equals('new@example.com'));
        expect(data?['display_name'], equals('New Name'));
      });

      // Note: Testing error handling with FakeFirebaseFirestore is difficult
      // as it doesn't provide a way to simulate errors. Error handling is
      // tested indirectly through integration tests and the error paths
      // are covered by the exception being thrown on actual failures.
    });

    group('getUser', () {
      test(
        'returns UserRepositoryResult with user when document exists',
        () async {
          // Arrange
          final now = DateTime.now();
          final timestamp = Timestamp.fromDate(now);

          await fakeFirestore.collection('users').doc('test_uid').set({
            'email': 'test@example.com',
            'display_name': 'Test User',
            'photo_url': null,
            'created_at': timestamp,
            'updated_at': timestamp,
          });

          // Act
          final result = await userRepository.getUser('test_uid');

          // Assert
          expect(result.eventName, equals('user_get'));
          expect(result.uid, equals('test_uid'));
          expect(result.succeeded, isTrue);
          expect(result.user, isNotNull);
          expect(result.user?.uid, equals('test_uid'));
          expect(result.user?.email, equals('test@example.com'));
        },
      );

      test(
        'returns UserRepositoryResult with null user when document does not exist',
        () async {
          // Act
          final result = await userRepository.getUser('test_uid');

          // Assert
          expect(result.eventName, equals('user_get_not_found'));
          expect(result.uid, equals('test_uid'));
          expect(result.succeeded, isFalse);
          expect(result.user, isNull);
        },
      );

      // Note: Testing error handling with FakeFirebaseFirestore is difficult
      // as it doesn't provide a way to simulate errors. Error handling is
      // tested indirectly through integration tests and the error paths
      // are covered by the exception being thrown on actual failures.
    });

    group('createOrUpdateUser', () {
      test('creates user when user does not exist', () async {
        // Arrange
        final user = UserModel(
          uid: 'test_uid',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final result = await userRepository.createOrUpdateUser(user);

        // Assert
        expect(result.eventName, equals('user_create'));
        expect(result.uid, equals('test_uid'));
        expect(result.succeeded, isTrue);

        final snapshot = await fakeFirestore
            .collection('users')
            .doc('test_uid')
            .get();
        expect(snapshot.exists, isTrue);
      });

      test('updates user when user exists', () async {
        // Arrange
        final now = DateTime.now();
        final timestamp = Timestamp.fromDate(now);
        await fakeFirestore.collection('users').doc('test_uid').set({
          'email': 'old@example.com',
          'created_at': timestamp,
          'updated_at': timestamp,
        });

        final updatedUser = UserModel(
          uid: 'test_uid',
          email: 'new@example.com',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final result = await userRepository.createOrUpdateUser(updatedUser);

        // Assert
        expect(result.eventName, equals('user_update'));
        expect(result.uid, equals('test_uid'));

        final snapshot = await fakeFirestore
            .collection('users')
            .doc('test_uid')
            .get();
        final data = snapshot.data();
        expect(data?['email'], equals('new@example.com'));
      });

      // Note: Testing error handling with FakeFirebaseFirestore is difficult
      // as it doesn't provide a way to simulate errors. Error handling is
      // tested indirectly through integration tests and the error paths
      // are covered by the exception being thrown on actual failures.
    });
  });
}
