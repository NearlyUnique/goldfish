import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:goldfish/core/auth/auth_exceptions.dart';
import 'package:goldfish/core/auth/auth_notifier.dart';
import '../../fakes/auth_service_fake.dart';

void main() {
  group('AuthNotifier', () {
    late FakeAuthService fakeAuthService;
    late AuthNotifier authNotifier;

    setUp(() {
      fakeAuthService = FakeAuthService(
        onAuthStateChanges: () => Stream<firebase_auth.User?>.value(null),
      );
      authNotifier = AuthNotifier(authService: fakeAuthService);
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
        final testUser = _TestUser();
        var signInCalled = false;
        fakeAuthService.onSignInWithGoogle = () async {
          signInCalled = true;
          return testUser;
        };
        fakeAuthService.onAuthStateChanges = () => Stream.value(testUser);

        // Act
        final future = authNotifier.signInWithGoogle();

        // Assert - should be loading
        expect(authNotifier.isLoading, isTrue);
        expect(authNotifier.state, equals(AuthState.loading));

        await future;

        // Assert - sign in was called
        expect(signInCalled, isTrue);
        // State will be updated by auth state changes
      });

      test('handles sign-in success', () async {
        // Arrange
        final testUser = _TestUser();
        var signInCalled = false;
        fakeAuthService.onSignInWithGoogle = () async {
          signInCalled = true;
          return testUser;
        };
        fakeAuthService.onAuthStateChanges = () => Stream.value(testUser);

        // Act
        await authNotifier.signInWithGoogle();

        // Assert
        expect(signInCalled, isTrue);
      });

      test('handles sign-in error', () async {
        // Arrange
        fakeAuthService.onSignInWithGoogle = () async {
          throw const GoogleSignInCancelledException();
        };
        fakeAuthService.onAuthStateChanges = () =>
            Stream<firebase_auth.User?>.value(null);

        // Act & Assert
        try {
          await authNotifier.signInWithGoogle();
          fail('Expected exception to be thrown');
        } catch (e) {
          expect(e, isA<GoogleSignInCancelledException>());
        }
        // After error, state should be unauthenticated
        expect(authNotifier.state, equals(AuthState.unauthenticated));
      });
    });

    group('signOut', () {
      test('successfully signs out', () async {
        // Arrange
        var signOutCalled = false;
        fakeAuthService.onSignOut = () async {
          signOutCalled = true;
        };
        fakeAuthService.onAuthStateChanges = () =>
            Stream<firebase_auth.User?>.value(null);

        // Act
        await authNotifier.signOut();

        // Assert
        expect(signOutCalled, isTrue);
      });
    });
  });
}

/// Test double for firebase_auth.User.
class _TestUser implements firebase_auth.User {
  _TestUser({String? uid, String? email})
      : _uid = uid ?? 'test_uid',
        _email = email ?? 'test@example.com';

  final String _uid;
  final String? _email;

  @override
  String get uid => _uid;

  @override
  String? get email => _email;

  @override
  String? get displayName => null;

  @override
  String? get photoURL => null;

  @override
  bool get emailVerified => false;

  @override
  bool get isAnonymous => false;

  @override
  firebase_auth.UserMetadata get metadata =>
      throw UnimplementedError('Not used in tests');

  @override
  String? get phoneNumber => null;

  @override
  List<firebase_auth.UserInfo> get providerData =>
      throw UnimplementedError('Not used in tests');

  @override
  String? get refreshToken => null;

  @override
  String? get tenantId => null;

  @override
  firebase_auth.MultiFactor get multiFactor =>
      throw UnimplementedError('Not used in tests');

  @override
  Future<void> delete() => throw UnimplementedError('Not used in tests');

  @override
  Future<String> getIdToken([bool forceRefresh = false]) =>
      throw UnimplementedError('Not used in tests');

  @override
  Future<firebase_auth.IdTokenResult> getIdTokenResult(
      [bool forceRefresh = false]) =>
      throw UnimplementedError('Not used in tests');

  @override
  Future<firebase_auth.UserCredential> linkWithCredential(
          firebase_auth.AuthCredential credential) =>
      throw UnimplementedError('Not used in tests');

  @override
  Future<firebase_auth.ConfirmationResult> linkWithPhoneNumber(
          String phoneNumber,
          [firebase_auth.RecaptchaVerifier? verifier]) =>
      throw UnimplementedError('Not used in tests');

  @override
  Future<firebase_auth.UserCredential> linkWithPopup(
          firebase_auth.AuthProvider provider) =>
      throw UnimplementedError('Not used in tests');

  @override
  Future<void> linkWithRedirect(firebase_auth.AuthProvider provider) =>
      throw UnimplementedError('Not used in tests');

  @override
  Future<firebase_auth.UserCredential> linkWithProvider(
          firebase_auth.AuthProvider provider) =>
      throw UnimplementedError('Not used in tests');

  @override
  Future<firebase_auth.UserCredential> reauthenticateWithCredential(
          firebase_auth.AuthCredential credential) =>
      throw UnimplementedError('Not used in tests');

  @override
  Future<firebase_auth.UserCredential> reauthenticateWithPopup(
          firebase_auth.AuthProvider provider) =>
      throw UnimplementedError('Not used in tests');

  @override
  Future<void> reauthenticateWithRedirect(
          firebase_auth.AuthProvider provider) =>
      throw UnimplementedError('Not used in tests');

  @override
  Future<firebase_auth.UserCredential> reauthenticateWithProvider(
          firebase_auth.AuthProvider provider) =>
      throw UnimplementedError('Not used in tests');

  @override
  Future<void> reload() => throw UnimplementedError('Not used in tests');

  @override
  Future<void> sendEmailVerification([
    firebase_auth.ActionCodeSettings? actionCodeSettings,
  ]) =>
      throw UnimplementedError('Not used in tests');

  @override
  Future<firebase_auth.User> unlink(String providerId) =>
      throw UnimplementedError('Not used in tests');

  @override
  Future<void> updateDisplayName(String? displayName) =>
      throw UnimplementedError('Not used in tests');

  @override
  Future<void> updateEmail(String newEmail) =>
      throw UnimplementedError('Not used in tests');

  @override
  Future<void> updatePassword(String newPassword) =>
      throw UnimplementedError('Not used in tests');

  @override
  Future<void> updatePhoneNumber(
          firebase_auth.PhoneAuthCredential phoneCredential) =>
      throw UnimplementedError('Not used in tests');

  @override
  Future<void> updatePhotoURL(String? photoURL) =>
      throw UnimplementedError('Not used in tests');

  @override
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) =>
      throw UnimplementedError('Not used in tests');

  @override
  Future<void> verifyBeforeUpdateEmail(
    String newEmail, [
    firebase_auth.ActionCodeSettings? actionCodeSettings,
  ]) =>
      throw UnimplementedError('Not used in tests');
}
