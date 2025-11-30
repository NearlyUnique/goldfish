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
      authNotifier = AuthNotifier(authService: mockAuthService);
    });

    tearDown(() {
      authNotifier.dispose();
    });

    test('initial state is initial', () {
      expect(authNotifier.state, equals(AuthState.initial));
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
        when(
          () => mockAuthService.authStateChanges,
        ).thenAnswer((_) => Stream.value(null));

        // Act & Assert
        expect(
          () => authNotifier.signInWithGoogle(),
          throwsA(isA<GoogleSignInCancelledException>()),
        );
        expect(authNotifier.state, equals(AuthState.unauthenticated));
      });
    });

    group('signOut', () {
      test('successfully signs out', () async {
        // Arrange
        when(() => mockAuthService.signOut()).thenAnswer((_) async => {});
        when(
          () => mockAuthService.authStateChanges,
        ).thenAnswer((_) => Stream.value(null));

        // Act
        await authNotifier.signOut();

        // Assert
        verify(() => mockAuthService.signOut()).called(1);
      });
    });
  });
}
