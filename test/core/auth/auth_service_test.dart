import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:goldfish/core/auth/auth_exceptions.dart';
import 'package:goldfish/core/auth/auth_service.dart';
import 'package:goldfish/core/auth/repositories/user_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements firebase_auth.FirebaseAuth {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockUserRepository extends Mock implements UserRepository {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

class MockUserCredential extends Mock implements firebase_auth.UserCredential {}

class MockUser extends Mock implements firebase_auth.User {}

void main() {
  group('AuthService', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockGoogleSignIn mockGoogleSignIn;
    late MockUserRepository mockUserRepository;
    late AuthService authService;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockGoogleSignIn = MockGoogleSignIn();
      mockUserRepository = MockUserRepository();
      authService = AuthService(
        firebaseAuth: mockFirebaseAuth,
        googleSignIn: mockGoogleSignIn,
        userRepository: mockUserRepository,
      );
    });

    group('signInWithGoogle', () {
      test('successfully signs in with Google', () async {
        // Arrange
        final mockGoogleAccount = MockGoogleSignInAccount();
        final mockGoogleAuth = MockGoogleSignInAuthentication();
        final mockUser = MockUser();
        final mockUserCredential = MockUserCredential();

        when(
          () => mockGoogleSignIn.signIn(),
        ).thenAnswer((_) async => mockGoogleAccount);
        when(
          () => mockGoogleAccount.authentication,
        ).thenAnswer((_) async => mockGoogleAuth);
        when(() => mockGoogleAuth.accessToken).thenReturn('access_token');
        when(() => mockGoogleAuth.idToken).thenReturn('id_token');
        when(
          () => mockFirebaseAuth.signInWithCredential(any()),
        ).thenAnswer((_) async => mockUserCredential);
        when(() => mockUserCredential.user).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn('test_uid');
        when(() => mockUser.email).thenReturn('test@example.com');
        when(
          () => mockUserRepository.getUser(any()),
        ).thenAnswer((_) async => null);
        when(
          () => mockUserRepository.createOrUpdateUser(any()),
        ).thenAnswer((_) async => {});

        // Act
        final result = await authService.signInWithGoogle();

        // Assert
        expect(result, equals(mockUser));
        verify(() => mockGoogleSignIn.signIn()).called(1);
        verify(() => mockFirebaseAuth.signInWithCredential(any())).called(1);
      });

      test('throws GoogleSignInCancelledException when user cancels', () async {
        // Arrange
        when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => authService.signInWithGoogle(),
          throwsA(isA<GoogleSignInCancelledException>()),
        );
      });

      test('throws FirebaseAuthException on Firebase error', () async {
        // Arrange
        final mockGoogleAccount = MockGoogleSignInAccount();
        final mockGoogleAuth = MockGoogleSignInAuthentication();

        when(
          () => mockGoogleSignIn.signIn(),
        ).thenAnswer((_) async => mockGoogleAccount);
        when(
          () => mockGoogleAccount.authentication,
        ).thenAnswer((_) async => mockGoogleAuth);
        when(() => mockGoogleAuth.accessToken).thenReturn('access_token');
        when(() => mockGoogleAuth.idToken).thenReturn('id_token');
        when(() => mockFirebaseAuth.signInWithCredential(any())).thenThrow(
          firebase_auth.FirebaseAuthException(
            code: 'auth/error',
            message: 'Firebase error',
          ),
        );

        // Act & Assert
        expect(
          () => authService.signInWithGoogle(),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('signOut', () {
      test('successfully signs out', () async {
        // Arrange
        when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async => {});
        when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

        // Act
        await authService.signOut();

        // Assert
        verify(() => mockFirebaseAuth.signOut()).called(1);
        verify(() => mockGoogleSignIn.signOut()).called(1);
      });
    });

    group('authStateChanges', () {
      test('returns stream from Firebase Auth', () {
        // Arrange
        final stream = Stream<firebase_auth.User?>.value(null);
        when(
          () => mockFirebaseAuth.authStateChanges(),
        ).thenAnswer((_) => stream);

        // Act
        final result = authService.authStateChanges;

        // Assert
        expect(result, equals(stream));
      });
    });
  });
}
