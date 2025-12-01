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
        await userRepository.createUser(user);

        // Assert: document was written to the fake Firestore.
        final snapshot = await fakeFirestore
            .collection('users')
            .doc('test_uid')
            .get();

        expect(snapshot.exists, isTrue);
        final data = snapshot.data();
        expect(data?['email'], equals('test@example.com'));
      });
    });

    group('getUser', () {
      test('returns user when document exists', () async {
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
        expect(result, isNotNull);
        expect(result?.uid, equals('test_uid'));
        expect(result?.email, equals('test@example.com'));
      });

      test('returns null when document does not exist', () async {
        // Act
        final result = await userRepository.getUser('test_uid');

        // Assert
        expect(result, isNull);
      });
    });
  });
}
