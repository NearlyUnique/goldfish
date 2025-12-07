import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:geolocator/geolocator.dart';
import 'package:goldfish/core/api/http_client.dart';
import 'package:goldfish/core/api/overpass_client.dart';
import 'package:goldfish/core/auth/auth_notifier.dart';
import 'package:goldfish/core/data/repositories/visit_repository.dart';
import 'package:goldfish/features/visits/domain/view_models/record_visit_view_model.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../../core/location/test_helpers.dart';
import '../../../../fakes/auth_service_fake.dart';
import '../../../../fakes/location_service_fake.dart';

/// Creates a [MockClient] that returns an empty Overpass response.
MockClient createEmptyOverpassMockClient() {
  return MockClient((request) async {
    return http.Response('{"elements": []}', 200);
  });
}

/// Creates an [OverpassClient] with a mock HTTP client.
OverpassClient createMockOverpassClient({MockClient? mockClient}) {
  final client = mockClient ?? createEmptyOverpassMockClient();
  final httpClient = HttpPackageClient(client: client);
  return OverpassClient(httpClient: httpClient);
}

/// Creates a [RecordVisitViewModel] with mocked dependencies.
RecordVisitViewModel createRecordVisitViewModel({
  FakeLocationService? locationService,
  OverpassClient? overpassClient,
  VisitRepository? visitRepository,
  AuthNotifier? authNotifier,
  FakeFirebaseFirestore? firestore,
}) {
  final fakeLocationService = locationService ?? FakeLocationService();
  final fakeFirestore = firestore ?? FakeFirebaseFirestore();
  final fakeAuthService = FakeAuthService();
  final authNotifierInstance =
      authNotifier ?? AuthNotifier(authService: fakeAuthService);
  final overpassClientInstance = overpassClient ?? createMockOverpassClient();
  final visitRepositoryInstance =
      visitRepository ?? VisitRepository(firestore: fakeFirestore);

  return RecordVisitViewModel(
    locationService: fakeLocationService,
    overpassClient: overpassClientInstance,
    visitRepository: visitRepositoryInstance,
    authNotifier: authNotifierInstance,
  );
}

/// Creates a test [Position] with example coordinates.
Position createExampleTestPosition() {
  return createTestPosition(lat: 45.0, lon: -90.0);
}

/// Sets up location service to return a position with permission granted.
void setupLocationServiceWithPermission(
  FakeLocationService locationService,
  Position position,
) {
  locationService.onIsLocationServiceEnabled = () async => true;
  locationService.onHasPermission = () async => true;
  locationService.onGetCurrentLocation = () async => position;
}

/// Sets up location service to deny permission.
void setupLocationServicePermissionDenied(FakeLocationService locationService) {
  locationService.onIsLocationServiceEnabled = () async => true;
  locationService.onHasPermission = () async => false;
  locationService.onRequestPermission = () async => false;
}

/// Sets up location service to return null location.
void setupLocationServiceUnavailable(FakeLocationService locationService) {
  locationService.onIsLocationServiceEnabled = () async => true;
  locationService.onHasPermission = () async => true;
  locationService.onGetCurrentLocation = () async => null;
}

/// Sets up auth service with an authenticated user.
void setupAuthenticatedUser(
  FakeAuthService authService,
  firebase_auth.User user,
) {
  authService.onAuthStateChanges = () =>
      Stream<firebase_auth.User?>.value(user);
  authService.onCurrentUser = () => user;
}
