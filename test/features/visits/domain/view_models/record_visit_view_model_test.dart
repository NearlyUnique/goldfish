import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:goldfish/core/auth/auth_notifier.dart';
import 'package:goldfish/core/data/models/place_suggestion_model.dart';
import 'package:goldfish/features/visits/domain/view_models/record_visit_view_model.dart';

import '../../../../fakes/auth_service_fake.dart';
import '../../../../fakes/location_service_fake.dart';
import 'test_helpers.dart';

/// Simple test user implementation.
class TestUser implements firebase_auth.User {
  TestUser(this._uid);

  final String _uid;

  @override
  String get uid => _uid;

  @override
  String? get email => null;

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
  String? get photoURL => null;

  @override
  List<firebase_auth.UserInfo> get providerData =>
      throw UnimplementedError('Not used in tests');

  @override
  String? get refreshToken => null;

  @override
  String? get tenantId => null;

  @override
  String? get displayName => null;

  @override
  Future<void> delete() => throw UnimplementedError('Not used in tests');

  @override
  Future<String> getIdToken([bool forceRefresh = false]) =>
      throw UnimplementedError('Not used in tests');

  @override
  Future<firebase_auth.IdTokenResult> getIdTokenResult([
    bool forceRefresh = false,
  ]) => throw UnimplementedError('Not used in tests');

  @override
  Future<void> reload() => throw UnimplementedError('Not used in tests');

  @override
  Future<void> sendEmailVerification([
    firebase_auth.ActionCodeSettings? actionCodeSettings,
  ]) => throw UnimplementedError('Not used in tests');

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
    firebase_auth.PhoneAuthCredential phoneCredential,
  ) => throw UnimplementedError('Not used in tests');

  @override
  Future<void> updatePhotoURL(String? photoURL) =>
      throw UnimplementedError('Not used in tests');

  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) =>
      throw UnimplementedError('Not used in tests');

  @override
  Future<void> verifyBeforeUpdateEmail(
    String newEmail, [
    firebase_auth.ActionCodeSettings? actionCodeSettings,
  ]) => throw UnimplementedError('Not used in tests');

  @override
  Future<firebase_auth.UserCredential> linkWithCredential(
    firebase_auth.AuthCredential credential,
  ) => throw UnimplementedError('Not used in tests');

  @override
  Future<firebase_auth.ConfirmationResult> linkWithPhoneNumber(
    String phoneNumber, [
    firebase_auth.RecaptchaVerifier? verifier,
  ]) => throw UnimplementedError('Not used in tests');

  @override
  Future<firebase_auth.UserCredential> linkWithPopup(
    firebase_auth.AuthProvider provider,
  ) => throw UnimplementedError('Not used in tests');

  @override
  Future<firebase_auth.UserCredential> linkWithProvider(
    firebase_auth.AuthProvider provider,
  ) => throw UnimplementedError('Not used in tests');

  @override
  Future<firebase_auth.UserCredential> reauthenticateWithCredential(
    firebase_auth.AuthCredential credential,
  ) => throw UnimplementedError('Not used in tests');

  @override
  Future<firebase_auth.UserCredential> reauthenticateWithPopup(
    firebase_auth.AuthProvider provider,
  ) => throw UnimplementedError('Not used in tests');

  @override
  Future<firebase_auth.UserCredential> reauthenticateWithProvider(
    firebase_auth.AuthProvider provider,
  ) => throw UnimplementedError('Not used in tests');

  Future<firebase_auth.ConfirmationResult> reauthenticateWithPhoneNumber(
    String phoneNumber, [
    firebase_auth.RecaptchaVerifier? verifier,
  ]) => throw UnimplementedError('Not used in tests');

  @override
  Future<void> linkWithRedirect(firebase_auth.AuthProvider provider) =>
      throw UnimplementedError('Not used in tests');

  @override
  Future<void> reauthenticateWithRedirect(
    firebase_auth.AuthProvider provider,
  ) => throw UnimplementedError('Not used in tests');

  @override
  firebase_auth.MultiFactor get multiFactor =>
      throw UnimplementedError('Not used in tests');
}

void main() {
  group('RecordVisitViewModel', () {
    late FakeLocationService fakeLocationService;
    late FakeAuthService fakeAuthService;
    late AuthNotifier authNotifier;
    late FakeFirebaseFirestore fakeFirestore;
    late RecordVisitViewModel viewModel;

    setUp(() {
      fakeLocationService = FakeLocationService();
      fakeAuthService = FakeAuthService();
      authNotifier = AuthNotifier(authService: fakeAuthService);
      fakeFirestore = FakeFirebaseFirestore();

      viewModel = createRecordVisitViewModel(
        locationService: fakeLocationService,
        authNotifier: authNotifier,
        firestore: fakeFirestore,
      );
    });

    tearDown(() {
      viewModel.dispose();
      authNotifier.dispose();
    });

    test('initial state has null currentLocation', () {
      expect(viewModel.currentLocation, isNull);
    });

    test('initial state has empty suggestions', () {
      expect(viewModel.suggestions, isEmpty);
    });

    test('initial state has null selectedSuggestion', () {
      expect(viewModel.selectedSuggestion, isNull);
    });

    test('initial state has empty placeName', () {
      expect(viewModel.placeName, isEmpty);
    });

    test('initial state has isLoadingLocation false', () {
      expect(viewModel.isLoadingLocation, isFalse);
    });

    test('initial state has isLoadingSuggestions false', () {
      expect(viewModel.isLoadingSuggestions, isFalse);
    });

    test('initial state has isSaving false', () {
      expect(viewModel.isSaving, isFalse);
    });

    test('initial state has null error', () {
      expect(viewModel.error, isNull);
    });

    test('initial state has canSave false', () {
      expect(viewModel.canSave, isFalse);
    });

    group('refreshLocation', () {
      test('sets currentLocation when location is retrieved', () async {
        // Arrange
        final testPosition = createExampleTestPosition();
        setupLocationServiceWithPermission(fakeLocationService, testPosition);

        // Act
        await viewModel.refreshLocation();

        // Assert
        expect(viewModel.currentLocation, equals(testPosition));
      });

      test('sets isLoadingLocation to false after refresh', () async {
        // Arrange
        final testPosition = createExampleTestPosition();
        setupLocationServiceWithPermission(fakeLocationService, testPosition);

        // Act
        await viewModel.refreshLocation();

        // Assert
        expect(viewModel.isLoadingLocation, isFalse);
      });

      test('clears error when location is retrieved successfully', () async {
        // Arrange
        final testPosition = createExampleTestPosition();
        setupLocationServiceWithPermission(fakeLocationService, testPosition);

        // Act
        await viewModel.refreshLocation();

        // Assert
        expect(viewModel.error, isNull);
      });

      test('sets currentLocation to null when permission denied', () async {
        // Arrange
        setupLocationServicePermissionDenied(fakeLocationService);

        // Act
        await viewModel.refreshLocation();

        // Assert
        expect(viewModel.currentLocation, isNull);
      });

      test('sets error message when permission denied', () async {
        // Arrange
        setupLocationServicePermissionDenied(fakeLocationService);

        // Act
        await viewModel.refreshLocation();

        // Assert
        expect(viewModel.error, contains('permission'));
      });

      test('sets currentLocation to null when location unavailable', () async {
        // Arrange
        setupLocationServiceUnavailable(fakeLocationService);

        // Act
        await viewModel.refreshLocation();

        // Assert
        expect(viewModel.currentLocation, isNull);
      });

      test('sets error message when location unavailable', () async {
        // Arrange
        setupLocationServiceUnavailable(fakeLocationService);

        // Act
        await viewModel.refreshLocation();

        // Assert
        expect(viewModel.error, contains('unavailable'));
      });
    });

    group('selectSuggestion', () {
      test('sets selectedSuggestion', () {
        // Arrange
        const suggestion = PlaceSuggestion(
          name: 'Test Place',
          latitude: 45.0,
          longitude: -90.0,
          tags: {},
        );

        // Act
        viewModel.selectSuggestion(suggestion);

        // Assert
        expect(viewModel.selectedSuggestion, equals(suggestion));
      });

      test('updates placeName to suggestion name', () {
        // Arrange
        const suggestion = PlaceSuggestion(
          name: 'Test Place',
          latitude: 45.0,
          longitude: -90.0,
          tags: {},
        );

        // Act
        viewModel.selectSuggestion(suggestion);

        // Assert
        expect(viewModel.placeName, equals('Test Place'));
      });
    });

    group('updatePlaceName', () {
      test('updates place name', () {
        // Act
        viewModel.updatePlaceName('New Place Name');

        // Assert
        expect(viewModel.placeName, equals('New Place Name'));
      });

      test('clears selectedSuggestion when name changes', () {
        // Arrange
        const suggestion = PlaceSuggestion(
          name: 'Original Name',
          latitude: 45.0,
          longitude: -90.0,
          tags: {},
        );
        viewModel.selectSuggestion(suggestion);

        // Act
        viewModel.updatePlaceName('Different Name');

        // Assert
        expect(viewModel.selectedSuggestion, isNull);
      });

      test('keeps selected suggestion when name matches', () {
        // Arrange
        const suggestion = PlaceSuggestion(
          name: 'Test Place',
          latitude: 45.0,
          longitude: -90.0,
          tags: {},
        );
        viewModel.selectSuggestion(suggestion);

        // Act
        viewModel.updatePlaceName('Test Place');

        // Assert
        expect(viewModel.selectedSuggestion, equals(suggestion));
      });
    });

    group('canSave', () {
      test('returns false when place name is empty', () async {
        // Arrange
        final testPosition = createExampleTestPosition();
        setupLocationServiceWithPermission(fakeLocationService, testPosition);
        await viewModel.refreshLocation();
        viewModel.updatePlaceName('');

        // Assert
        expect(viewModel.canSave, isFalse);
      });

      test('returns false when location is null', () {
        // Arrange
        viewModel.updatePlaceName('Test Place');

        // Assert
        expect(viewModel.canSave, isFalse);
      });

      test('returns true when both place name and location are set', () async {
        // Arrange
        final testPosition = createExampleTestPosition();
        setupLocationServiceWithPermission(fakeLocationService, testPosition);
        await viewModel.refreshLocation();
        viewModel.updatePlaceName('Test Place');

        // Assert
        expect(viewModel.canSave, isTrue);
      });
    });

    group('saveVisit', () {
      test('throws StateError when form is not valid', () {
        // Act & Assert
        expect(() => viewModel.saveVisit(), throwsA(isA<StateError>()));
      });

      test('throws StateError when user is not authenticated', () async {
        // Arrange
        final testPosition = createExampleTestPosition();
        setupLocationServiceWithPermission(fakeLocationService, testPosition);
        final noUserAuthService = FakeAuthService();
        final noUserAuthNotifier = AuthNotifier(authService: noUserAuthService);
        viewModel = createRecordVisitViewModel(
          locationService: fakeLocationService,
          authNotifier: noUserAuthNotifier,
          firestore: fakeFirestore,
        );
        await viewModel.refreshLocation();
        viewModel.updatePlaceName('Test Place');

        // Act & Assert
        expect(() => viewModel.saveVisit(), throwsA(isA<StateError>()));

        noUserAuthNotifier.dispose();
      });

      test('sets isSaving to false after successful save', () async {
        // Arrange
        final testUser = TestUser('user123');
        setupAuthenticatedUser(fakeAuthService, testUser);
        final testPosition = createExampleTestPosition();
        setupLocationServiceWithPermission(fakeLocationService, testPosition);
        final userAuthNotifier = AuthNotifier(authService: fakeAuthService);
        await Future.delayed(const Duration(milliseconds: 10));
        viewModel = createRecordVisitViewModel(
          locationService: fakeLocationService,
          authNotifier: userAuthNotifier,
          firestore: fakeFirestore,
        );
        await viewModel.refreshLocation();
        viewModel.updatePlaceName('Test Place');

        // Act
        await viewModel.saveVisit();

        // Assert
        expect(viewModel.isSaving, isFalse);

        userAuthNotifier.dispose();
      });

      test('clears error after successful save', () async {
        // Arrange
        final testUser = TestUser('user123');
        setupAuthenticatedUser(fakeAuthService, testUser);
        final testPosition = createExampleTestPosition();
        setupLocationServiceWithPermission(fakeLocationService, testPosition);
        final userAuthNotifier = AuthNotifier(authService: fakeAuthService);
        await Future.delayed(const Duration(milliseconds: 10));
        viewModel = createRecordVisitViewModel(
          locationService: fakeLocationService,
          authNotifier: userAuthNotifier,
          firestore: fakeFirestore,
        );
        await viewModel.refreshLocation();
        viewModel.updatePlaceName('Test Place');

        // Act
        await viewModel.saveVisit();

        // Assert
        expect(viewModel.error, isNull);

        userAuthNotifier.dispose();
      });

      test('saves visit with selected suggestion data', () async {
        // Arrange
        final testUser = TestUser('user123');
        setupAuthenticatedUser(fakeAuthService, testUser);
        final testPosition = createExampleTestPosition();
        setupLocationServiceWithPermission(fakeLocationService, testPosition);
        const suggestion = PlaceSuggestion(
          name: 'Test Pub',
          amenityType: 'amenity:pub',
          latitude: 52.1994,
          longitude: 0.1391,
          address: '123 Main St',
          tags: {
            'amenity': 'pub',
            'name': 'Test Pub',
            'addr:street': 'Main St',
            'addr:housenumber': '123',
          },
        );
        final userAuthNotifier = AuthNotifier(authService: fakeAuthService);
        await Future.delayed(const Duration(milliseconds: 10));
        viewModel = createRecordVisitViewModel(
          locationService: fakeLocationService,
          authNotifier: userAuthNotifier,
          firestore: fakeFirestore,
        );
        await viewModel.refreshLocation();
        viewModel.selectSuggestion(suggestion);

        // Act
        await viewModel.saveVisit();

        // Assert
        expect(viewModel.isSaving, isFalse);
        expect(viewModel.error, isNull);

        userAuthNotifier.dispose();
      });
    });

    group('cancel', () {
      test('clears placeName', () {
        // Arrange
        viewModel.updatePlaceName('Test Place');

        // Act
        viewModel.cancel();

        // Assert
        expect(viewModel.placeName, isEmpty);
      });

      test('clears selectedSuggestion', () {
        // Arrange
        const suggestion = PlaceSuggestion(
          name: 'Test Place',
          latitude: 45.0,
          longitude: -90.0,
          tags: {},
        );
        viewModel.selectSuggestion(suggestion);

        // Act
        viewModel.cancel();

        // Assert
        expect(viewModel.selectedSuggestion, isNull);
      });

      test('clears error', () {
        // Arrange
        viewModel.updatePlaceName('Test Place');

        // Act
        viewModel.cancel();

        // Assert
        expect(viewModel.error, isNull);
      });
    });
  });
}
