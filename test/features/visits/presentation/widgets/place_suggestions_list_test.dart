import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldfish/core/api/http_client.dart';
import 'package:goldfish/core/api/overpass_client.dart';
import 'package:goldfish/features/visits/domain/view_models/record_visit_view_model.dart';
import 'package:goldfish/features/visits/presentation/widgets/place_suggestions_list.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../../fakes/location_service_fake.dart';
import '../../domain/view_models/test_helpers.dart';

void main() {
  group('PlaceSuggestionsList', () {
    late RecordVisitViewModel viewModel;
    late FakeLocationService fakeLocationService;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeLocationService = FakeLocationService();
      fakeFirestore = FakeFirebaseFirestore();
    });

    tearDown(() {
      viewModel.dispose();
    });

    testWidgets('displays loading state when loading suggestions', (tester) async {
      // Set up location service to return a position quickly
      fakeLocationService.onIsLocationServiceEnabled = () async => true;
      fakeLocationService.onHasPermission = () async => true;
      fakeLocationService.onGetCurrentLocation = () async =>
          createExampleTestPosition();

      // Create a mock client that delays to show loading state
      final mockHttpClient = MockClient(
        (request) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return http.Response('{"elements": []}', 200);
        },
      );
      final mockClient = OverpassClient(
        httpClient: HttpPackageClient(client: mockHttpClient),
      );

      viewModel = createRecordVisitViewModel(
        locationService: fakeLocationService,
        overpassClient: mockClient,
        firestore: fakeFirestore,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaceSuggestionsList(viewModel: viewModel),
          ),
        ),
      );

      // Trigger loading by calling refreshLocation
      viewModel.refreshLocation();

      // Pump until location is loaded and suggestions loading starts
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Should show loading indicator for suggestions
      expect(find.text('Finding nearby places...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for all async operations to complete
      await tester.pumpAndSettle();
    });

    testWidgets('displays error state when error exists and no suggestions',
        (tester) async {
      // Set up location service to deny permission, which will set an error
      fakeLocationService.onIsLocationServiceEnabled = () async => true;
      fakeLocationService.onHasPermission = () async => false;
      fakeLocationService.onRequestPermission = () async => false;

      viewModel = createRecordVisitViewModel(
        locationService: fakeLocationService,
        firestore: fakeFirestore,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaceSuggestionsList(viewModel: viewModel),
          ),
        ),
      );

      // Trigger refresh which will cause an error
      viewModel.refreshLocation();
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays empty state when no suggestions', (tester) async {
      // Set up location service to return a position, but Overpass will return empty
      // (default mock client returns empty)
      fakeLocationService.onIsLocationServiceEnabled = () async => true;
      fakeLocationService.onHasPermission = () async => true;
      fakeLocationService.onGetCurrentLocation = () async =>
          createExampleTestPosition();

      viewModel = createRecordVisitViewModel(
        locationService: fakeLocationService,
        firestore: fakeFirestore,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaceSuggestionsList(viewModel: viewModel),
          ),
        ),
      );

      // Trigger refresh which will fetch location and query Overpass
      viewModel.refreshLocation();
      await tester.pumpAndSettle();

      expect(find.text('No nearby places found'), findsOneWidget);
      expect(
        find.text('You can enter a place name manually below'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.location_searching), findsOneWidget);
    });

    testWidgets('displays list of suggestions', (tester) async {
      // Set up location service
      fakeLocationService.onIsLocationServiceEnabled = () async => true;
      fakeLocationService.onHasPermission = () async => true;
      fakeLocationService.onGetCurrentLocation = () async =>
          createExampleTestPosition();

      // Create mock Overpass client that returns suggestions
      final mockResponse = {
        'elements': [
          {
            'type': 'node',
            'id': 123,
            'lat': 45.0,
            'lon': -90.0,
            'tags': {
              'name': 'Test Restaurant',
              'amenity': 'restaurant',
              'addr:street': 'Main St',
              'addr:housenumber': '123',
            },
          },
          {
            'type': 'node',
            'id': 456,
            'lat': 45.1,
            'lon': -90.1,
            'tags': {
              'name': 'Test Cafe',
              'amenity': 'cafe',
            },
          },
        ],
      };

      final mockHttpClient = MockClient(
        (request) async => http.Response(jsonEncode(mockResponse), 200),
      );
      final mockClient = OverpassClient(
        httpClient: HttpPackageClient(client: mockHttpClient),
      );

      viewModel = createRecordVisitViewModel(
        locationService: fakeLocationService,
        overpassClient: mockClient,
        firestore: fakeFirestore,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaceSuggestionsList(viewModel: viewModel),
          ),
        ),
      );

      // Trigger refresh to load suggestions
      viewModel.refreshLocation();
      await tester.pumpAndSettle();

      expect(find.text('Nearby Places'), findsOneWidget);
      expect(find.text('Test Restaurant'), findsOneWidget);
      expect(find.text('Test Cafe'), findsOneWidget);
      // Address should be formatted as "123, Main St" (comma-separated)
      expect(find.textContaining('123'), findsOneWidget);
      expect(find.textContaining('Main St'), findsOneWidget);
    });

    testWidgets('highlights selected suggestion', (tester) async {
      // Set up location service
      fakeLocationService.onIsLocationServiceEnabled = () async => true;
      fakeLocationService.onHasPermission = () async => true;
      fakeLocationService.onGetCurrentLocation = () async =>
          createExampleTestPosition();

      // Create mock Overpass client
      final mockResponse = {
        'elements': [
          {
            'type': 'node',
            'id': 123,
            'lat': 45.0,
            'lon': -90.0,
            'tags': {
              'name': 'Selected Place',
              'amenity': 'pub',
            },
          },
          {
            'type': 'node',
            'id': 456,
            'lat': 45.1,
            'lon': -90.1,
            'tags': {
              'name': 'Other Place',
            },
          },
        ],
      };

      final mockHttpClient = MockClient(
        (request) async => http.Response(jsonEncode(mockResponse), 200),
      );
      final mockClient = OverpassClient(
        httpClient: HttpPackageClient(client: mockHttpClient),
      );

      viewModel = createRecordVisitViewModel(
        locationService: fakeLocationService,
        overpassClient: mockClient,
        firestore: fakeFirestore,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaceSuggestionsList(viewModel: viewModel),
          ),
        ),
      );

      // Load suggestions
      viewModel.refreshLocation();
      await tester.pumpAndSettle();

      // Select the first suggestion
      final suggestions = viewModel.suggestions;
      expect(suggestions, isNotEmpty);
      viewModel.selectSuggestion(suggestions.first);
      await tester.pump();

      // Check that selected suggestion has check icon
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('calls selectSuggestion when suggestion is tapped',
        (tester) async {
      // Set up location service
      fakeLocationService.onIsLocationServiceEnabled = () async => true;
      fakeLocationService.onHasPermission = () async => true;
      fakeLocationService.onGetCurrentLocation = () async =>
          createExampleTestPosition();

      // Create mock Overpass client
      final mockResponse = {
        'elements': [
          {
            'type': 'node',
            'id': 123,
            'lat': 45.0,
            'lon': -90.0,
            'tags': {
              'name': 'Tappable Place',
            },
          },
        ],
      };

      final mockHttpClient = MockClient(
        (request) async => http.Response(jsonEncode(mockResponse), 200),
      );
      final mockClient = OverpassClient(
        httpClient: HttpPackageClient(client: mockHttpClient),
      );

      viewModel = createRecordVisitViewModel(
        locationService: fakeLocationService,
        overpassClient: mockClient,
        firestore: fakeFirestore,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaceSuggestionsList(viewModel: viewModel),
          ),
        ),
      );

      // Load suggestions
      viewModel.refreshLocation();
      await tester.pumpAndSettle();

      // Verify initial state
      expect(viewModel.selectedSuggestion, isNull);

      // Tap on the suggestion
      await tester.tap(find.text('Tappable Place'));
      await tester.pump();

      // Verify that selectSuggestion was called
      expect(viewModel.selectedSuggestion, isNotNull);
      expect(viewModel.selectedSuggestion?.name, 'Tappable Place');
    });

    testWidgets('displays amenity type chip when available', (tester) async {
      // Set up location service
      fakeLocationService.onIsLocationServiceEnabled = () async => true;
      fakeLocationService.onHasPermission = () async => true;
      fakeLocationService.onGetCurrentLocation = () async =>
          createExampleTestPosition();

      // Create mock Overpass client
      final mockResponse = {
        'elements': [
          {
            'type': 'node',
            'id': 123,
            'lat': 45.0,
            'lon': -90.0,
            'tags': {
              'name': 'Test Place',
              'amenity': 'restaurant',
            },
          },
        ],
      };

      final mockHttpClient = MockClient(
        (request) async => http.Response(jsonEncode(mockResponse), 200),
      );
      final mockClient = OverpassClient(
        httpClient: HttpPackageClient(client: mockHttpClient),
      );

      viewModel = createRecordVisitViewModel(
        locationService: fakeLocationService,
        overpassClient: mockClient,
        firestore: fakeFirestore,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaceSuggestionsList(viewModel: viewModel),
          ),
        ),
      );

      // Load suggestions
      viewModel.refreshLocation();
      await tester.pumpAndSettle();

      // Check that the formatted type is displayed
      expect(find.text('Restaurant'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });

    testWidgets('displays address when available', (tester) async {
      // Set up location service
      fakeLocationService.onIsLocationServiceEnabled = () async => true;
      fakeLocationService.onHasPermission = () async => true;
      fakeLocationService.onGetCurrentLocation = () async =>
          createExampleTestPosition();

      // Create mock Overpass client
      final mockResponse = {
        'elements': [
          {
            'type': 'node',
            'id': 123,
            'lat': 45.0,
            'lon': -90.0,
            'tags': {
              'name': 'Test Place',
              'addr:street': 'Oak Avenue',
              'addr:housenumber': '456',
              'addr:city': 'City',
            },
          },
        ],
      };

      final mockHttpClient = MockClient(
        (request) async => http.Response(jsonEncode(mockResponse), 200),
      );
      final mockClient = OverpassClient(
        httpClient: HttpPackageClient(client: mockHttpClient),
      );

      viewModel = createRecordVisitViewModel(
        locationService: fakeLocationService,
        overpassClient: mockClient,
        firestore: fakeFirestore,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaceSuggestionsList(viewModel: viewModel),
          ),
        ),
      );

      // Load suggestions
      viewModel.refreshLocation();
      await tester.pumpAndSettle();

      // Address should be formatted (check for parts of the address)
      expect(find.textContaining('456'), findsOneWidget);
      expect(find.textContaining('Oak Avenue'), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets('updates when view model changes', (tester) async {
      viewModel = createRecordVisitViewModel(
        locationService: fakeLocationService,
        firestore: fakeFirestore,
      );

      // Start with loading
      viewModel.refreshLocation();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaceSuggestionsList(viewModel: viewModel),
          ),
        ),
      );

      // Set up location and mock client with suggestions
      fakeLocationService.onIsLocationServiceEnabled = () async => true;
      fakeLocationService.onHasPermission = () async => true;
      fakeLocationService.onGetCurrentLocation = () async =>
          createExampleTestPosition();

      final mockResponse = {
        'elements': [
          {
            'type': 'node',
            'id': 123,
            'lat': 45.0,
            'lon': -90.0,
            'tags': {
              'name': 'New Place',
            },
          },
        ],
      };

      final mockHttpClient = MockClient(
        (request) async => http.Response(jsonEncode(mockResponse), 200),
      );
      final mockClient = OverpassClient(
        httpClient: HttpPackageClient(client: mockHttpClient),
      );

      viewModel = createRecordVisitViewModel(
        locationService: fakeLocationService,
        overpassClient: mockClient,
        firestore: fakeFirestore,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaceSuggestionsList(viewModel: viewModel),
          ),
        ),
      );

      // Load suggestions
      viewModel.refreshLocation();
      await tester.pumpAndSettle();

      // Should show the suggestion
      expect(find.text('New Place'), findsOneWidget);
    });
  });
}
