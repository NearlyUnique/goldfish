import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldfish/core/auth/auth_notifier.dart';
import 'package:goldfish/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthNotifier extends Mock implements AuthNotifier {}

void main() {
  group('SignInScreen', () {
    late MockAuthNotifier mockAuthNotifier;

    setUp(() {
      mockAuthNotifier = MockAuthNotifier();
      when(() => mockAuthNotifier.isLoading).thenReturn(false);
      when(() => mockAuthNotifier.isAuthenticated).thenReturn(false);
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: SignInScreen(authNotifier: mockAuthNotifier),
      );
    }

    testWidgets('displays app title and sign-in button', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('Goldfish'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
    });

    testWidgets('calls signInWithGoogle when button is tapped', (tester) async {
      // Arrange
      when(() => mockAuthNotifier.signInWithGoogle())
          .thenAnswer((_) async => {});
      await tester.pumpWidget(createWidgetUnderTest());

      // Act
      await tester.tap(find.text('Sign in with Google'));
      await tester.pump();

      // Assert
      verify(() => mockAuthNotifier.signInWithGoogle()).called(1);
    });

    testWidgets('shows loading state when signing in', (tester) async {
      // Arrange
      when(() => mockAuthNotifier.isLoading).thenReturn(true);
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('Signing in...'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsNothing);
    });

    testWidgets('shows error message on sign-in failure', (tester) async {
      // Arrange
      when(() => mockAuthNotifier.signInWithGoogle())
          .thenThrow(Exception('Sign-in failed'));
      await tester.pumpWidget(createWidgetUnderTest());

      // Act
      await tester.tap(find.text('Sign in with Google'));
      await tester.pump();

      // Assert
      expect(
        find.text('An unexpected error occurred. Please try again.'),
        findsOneWidget,
      );
    });
  });
}

