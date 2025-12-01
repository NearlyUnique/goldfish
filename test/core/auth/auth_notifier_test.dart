import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:goldfish/core/auth/auth_exceptions.dart';
import 'package:goldfish/core/auth/auth_notifier.dart';
import 'package:goldfish/core/auth/auth_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUser extends Mock implements firebase_auth.User {}

void main() {
  group('AuthNotifier', () {
    late MockAuthService mockAuthService;
    late AuthNotifier authNotifier;

    setUp(() {
      mockAuthService = MockAuthService();
      // Set up authStateChanges stream before creating notifier
      // because it's called in the constructor
      when(() => mockAuthService.authStateChanges)
          .thenAnswer((_) => Stream<firebase_auth.User?>.value(null));
      authNotifier = AuthNotifier(authService: mockAuthService);
    });

    tearDown(() {
      authNotifier.dispose();
    });

    test('initial state is initial', () {
      // Wait a bit for the stream to initialize
      expect(authNotifier.state, isA<AuthState>());
      expect(authNotifier.isAuthenticated, isFalse);
      expect(authNotifier.isLoading, isFalse);
    });

    group('signInWithGoogle', () {
      test('sets loading state during sign-in', () async {
        // Arrange
        final mockUser = MockUser();
        when(
          () => mockAuthService.signInWithGoogle(),
        ).thenAnswer((_) async => mockUser);
        // Update the stream to emit the user after sign-in
        when(
          () => mockAuthService.authStateChanges,
        ).thenAnswer((_) => Stream.value(mockUser));

        // Act
        final future = authNotifier.signInWithGoogle();

        // Assert - should be loading
        expect(authNotifier.isLoading, isTrue);
        expect(authNotifier.state, equals(AuthState.loading));

        await future;

        // State will be updated by auth state changes
      });

      test('handles sign-in success', () async {
        // Arrange
        final mockUser = MockUser();
        when(
          () => mockAuthService.signInWithGoogle(),
        ).thenAnswer((_) async => mockUser);
        // Update stream to emit user
        when(
          () => mockAuthService.authStateChanges,
        ).thenAnswer((_) => Stream.value(mockUser));

        // Act
        await authNotifier.signInWithGoogle();

        // Assert
        verify(() => mockAuthService.signInWithGoogle()).called(1);
      });

      test('handles sign-in error', () async {
        // Arrange
        when(
          () => mockAuthService.signInWithGoogle(),
        ).thenThrow(const GoogleSignInCancelledException());
        // Keep stream as null (unauthenticated)
        when(
          () => mockAuthService.authStateChanges,
        ).thenAnswer((_) => Stream<firebase_auth.User?>.value(null));

        // Act & Assert
        expect(
          () => authNotifier.signInWithGoogle(),
          throwsA(isA<GoogleSignInCancelledException>()),
        );
        // After error, state should be unauthenticated
        expect(authNotifier.state, equals(AuthState.unauthenticated));
      });
    });

    group('signOut', () {
      test('successfully signs out', () async {
        // Arrange
        when(() => mockAuthService.signOut()).thenAnswer((_) async => {});
        // Stream should emit null after sign out
        when(
          () => mockAuthService.authStateChanges,
        ).thenAnswer((_) => Stream<firebase_auth.User?>.value(null));

        // Act
        await authNotifier.signOut();

        // Assert
        verify(() => mockAuthService.signOut()).called(1);
      });
    });
  });
}
