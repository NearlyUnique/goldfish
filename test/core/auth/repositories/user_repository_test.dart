import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldfish/core/auth/auth_exceptions.dart';
import 'package:goldfish/core/auth/models/user_model.dart';
import 'package:goldfish/core/auth/repositories/user_repository.dart';
import 'package:mocktail/mocktail.dart';

// Note: Firestore classes are sealed, so we use Mock with no implements
// This is acceptable for testing purposes
class MockFirestore extends Mock {}

class MockCollectionReference extends Mock {}

class MockDocumentReference extends Mock {}

class MockDocumentSnapshot extends Mock {}

void main() {
  group('UserRepository', () {
    late MockFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocument;
    late UserRepository userRepository;

    setUp(() {
      mockFirestore = MockFirestore();
      mockCollection = MockCollectionReference();
      mockDocument = MockDocumentReference();
      userRepository = UserRepository(firestore: mockFirestore as FirebaseFirestore);

      when(() => (mockFirestore as dynamic).collection('users'))
          .thenReturn(mockCollection);
      when(() => (mockCollection as dynamic).doc(any())).thenReturn(mockDocument);
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

        when(() => (mockDocument as dynamic).set(any())).thenAnswer((_) async => {});

        // Act
        await userRepository.createUser(user);

        // Assert
        verify(() => (mockDocument as dynamic).set(any())).called(1);
      });

      test('throws UserDataException on error', () async {
        // Arrange
        final user = UserModel(
          uid: 'test_uid',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(() => (mockDocument as dynamic).set(any())).thenThrow(Exception('Firestore error'));

        // Act & Assert
        expect(
          () => userRepository.createUser(user),
          throwsA(isA<UserDataException>()),
        );
      });
    });

    group('getUser', () {
      test('returns user when document exists', () async {
        // Arrange
        final mockSnapshot = MockDocumentSnapshot();
        final now = DateTime.now();
        final timestamp = Timestamp.fromDate(now);

        when(() => (mockDocument as dynamic).get()).thenAnswer((_) async => mockSnapshot);
        when(() => (mockSnapshot as dynamic).exists).thenReturn(true);
        when(() => (mockSnapshot as dynamic).id).thenReturn('test_uid');
        when(() => (mockSnapshot as dynamic).data()).thenReturn({
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
        // Arrange
        final mockSnapshot = MockDocumentSnapshot();

        when(() => (mockDocument as dynamic).get()).thenAnswer((_) async => mockSnapshot);
        when(() => (mockSnapshot as dynamic).exists).thenReturn(false);

        // Act
        final result = await userRepository.getUser('test_uid');

        // Assert
        expect(result, isNull);
      });

      test('throws UserDataException on error', () async {
        // Arrange
        when(() => (mockDocument as dynamic).get()).thenThrow(Exception('Firestore error'));

        // Act & Assert
        expect(
          () => userRepository.getUser('test_uid'),
          throwsA(isA<UserDataException>()),
        );
      });
    });
  });
}

