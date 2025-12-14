import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldfish/core/auth/auth_notifier.dart';
import 'package:goldfish/features/auth/presentation/screens/sign_in_screen.dart';
import '../../../../../test/fakes/auth_notifier_fake.dart';

void main() {
  group('SignInScreen', () {
    late FakeAuthNotifier fakeAuthNotifier;

    setUp(() {
      fakeAuthNotifier = FakeAuthNotifier(
        initialState: AuthState.unauthenticated,
      );
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(home: SignInScreen(authNotifier: fakeAuthNotifier));
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
      var signInCalled = false;
      fakeAuthNotifier.onSignInWithGoogle = () async {
        signInCalled = true;
        return const SignInResponse(
          uid: 'test-user-id',
          authState: AuthState.authenticated,
          provider: 'google',
        );
      };
      await tester.pumpWidget(createWidgetUnderTest());

      // Act
      await tester.tap(find.text('Sign in with Google'));
      await tester.pump();

      // Assert
      expect(signInCalled, isTrue);
    });

    testWidgets('shows loading state when signing in', (tester) async {
      // Arrange
      final loadingNotifier = FakeAuthNotifier(initialState: AuthState.loading);
      await tester.pumpWidget(
        MaterialApp(home: SignInScreen(authNotifier: loadingNotifier)),
      );

      // Assert
      expect(find.text('Signing in...'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsNothing);
    });

    testWidgets('shows error message on sign-in failure', (tester) async {
      // Arrange
      fakeAuthNotifier.onSignInWithGoogle = () async {
        throw Exception('Sign-in failed');
      };
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

    testWidgets('does not show error message on cancellation', (tester) async {
      // Arrange
      fakeAuthNotifier.onSignInWithGoogle = () async {
        return const SignInResponse(
          uid: null,
          authState: AuthState.unauthenticated,
          provider: 'google',
        );
      };
      await tester.pumpWidget(createWidgetUnderTest());

      // Act
      await tester.tap(find.text('Sign in with Google'));
      await tester.pump();

      // Assert - no error message should be shown
      expect(
        find.text('An unexpected error occurred. Please try again.'),
        findsNothing,
      );
    });
  });
}
