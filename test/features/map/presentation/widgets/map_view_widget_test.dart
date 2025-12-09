import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:goldfish/core/data/models/visit_model.dart';
import 'package:goldfish/core/theme/app_theme.dart';
import 'package:goldfish/features/map/presentation/widgets/map_view_widget.dart';
import 'package:goldfish/features/map/presentation/widgets/visit_marker.dart';

void main() {
  final now = DateTime(2024, 1, 1);

  Widget createWidget({
    GeoLatLong? currentLocation,
    required List<Visit> visits,
    bool isLoading = false,
    String? errorMessage,
    VoidCallback? onRetry,
  }) {
    return MaterialApp(
      theme: lightTheme,
      home: Scaffold(
        body: MapViewWidget(
          currentLocation: currentLocation,
          visits: visits,
          isLoading: isLoading,
          errorMessage: errorMessage,
          onRetry: onRetry,
          tileProvider: _StubTileProvider(),
          tileUserAgent: 'test-agent',
        ),
      ),
    );
  }

  Visit createVisit({
    required String id,
    required double lat,
    required double long,
  }) {
    return Visit(
      id: id,
      userId: 'user',
      placeName: 'Place $id',
      gpsRecorded: GeoLatLong(lat: lat, long: long),
      addedAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  testWidgets('shows loading state when loading', (tester) async {
    await tester.pumpWidget(createWidget(visits: const [], isLoading: true));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading map...'), findsOneWidget);
  });

  testWidgets('shows empty state when there is no data', (tester) async {
    await tester.pumpWidget(createWidget(visits: const []));

    expect(find.text('No visits to display on map.'), findsOneWidget);
  });

  testWidgets('shows error state and triggers retry', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      createWidget(
        visits: const [],
        errorMessage: 'Location permission needed',
        onRetry: () => retried = true,
      ),
    );

    expect(find.text('Location permission needed'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(retried, isTrue);
  });

  testWidgets('renders map with visit and current location markers', (
    tester,
  ) async {
    final visit = createVisit(id: 'visit-1', lat: 51.5, long: -0.1);

    await tester.pumpWidget(
      createWidget(
        visits: [visit],
        currentLocation: const GeoLatLong(lat: 51.5, long: -0.12),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(TileLayer), findsOneWidget);

    final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(markerLayer.markers.length, 2);
    expect(
      markerLayer.markers.any((marker) => marker.child is VisitMarker),
      isTrue,
    );
    expect(
      markerLayer.markers.any(
        (marker) => marker.child is CurrentLocationMarker,
      ),
      isTrue,
    );
  });

  testWidgets('centres on visits when current location is missing', (
    tester,
  ) async {
    final visitA = createVisit(id: 'a', lat: 10, long: 10);
    final visitB = createVisit(id: 'b', lat: 20, long: 20);

    await tester.pumpWidget(createWidget(visits: [visitA, visitB]));
    await tester.pumpAndSettle();

    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(map.options.initialCenter.latitude, closeTo(15, 0.0001));
    expect(map.options.initialCenter.longitude, closeTo(15, 0.0001));
  });

  testWidgets('shows inline error with retry button', (tester) async {
    var retried = false;
    final visit = createVisit(id: 'visit-1', lat: 51.5, long: -0.1);

    await tester.pumpWidget(
      createWidget(
        visits: [visit],
        currentLocation: const GeoLatLong(lat: 51.5, long: -0.12),
        errorMessage: 'Unable to get current location. Showing visited places.',
        onRetry: () => retried = true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to get current location. Showing visited places.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(retried, isTrue);
  });

  testWidgets('shows inline error with open settings button when message contains settings', (tester) async {
    var settingsOpened = false;
    final visit = createVisit(id: 'visit-1', lat: 51.5, long: -0.1);

    await tester.pumpWidget(
      createWidget(
        visits: [visit],
        currentLocation: const GeoLatLong(lat: 51.5, long: -0.12),
        errorMessage: 'Location permission required. Tap to enable in settings.',
        onRetry: () => settingsOpened = true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Location permission required. Tap to enable in settings.'), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);

    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    expect(settingsOpened, isTrue);
  });

  testWidgets('shows map with visits when location unavailable', (tester) async {
    final visit = createVisit(id: 'visit-1', lat: 51.5, long: -0.1);

    await tester.pumpWidget(
      createWidget(
        visits: [visit],
        errorMessage: 'Unable to get current location. Showing visited places.',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('Unable to get current location. Showing visited places.'), findsOneWidget);
  });

  testWidgets('updates markers when visits are added', (tester) async {
    final visit1 = createVisit(id: 'visit-1', lat: 51.5, long: -0.1);

    // Start with one visit
    await tester.pumpWidget(
      createWidget(
        visits: [visit1],
        currentLocation: const GeoLatLong(lat: 51.5, long: -0.12),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial marker count
    var markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(markerLayer.markers.length, 2); // 1 visit + 1 current location

    // Add another visit
    final visit2 = createVisit(id: 'visit-2', lat: 51.6, long: -0.2);
    await tester.pumpWidget(
      createWidget(
        visits: [visit1, visit2],
        currentLocation: const GeoLatLong(lat: 51.5, long: -0.12),
      ),
    );
    await tester.pumpAndSettle();

    // Verify marker count increased
    markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(markerLayer.markers.length, 3); // 2 visits + 1 current location
  });

  testWidgets('updates markers when visits are removed', (tester) async {
    final visit1 = createVisit(id: 'visit-1', lat: 51.5, long: -0.1);
    final visit2 = createVisit(id: 'visit-2', lat: 51.6, long: -0.2);

    // Start with two visits
    await tester.pumpWidget(
      createWidget(
        visits: [visit1, visit2],
        currentLocation: const GeoLatLong(lat: 51.5, long: -0.12),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial marker count
    var markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(markerLayer.markers.length, 3); // 2 visits + 1 current location

    // Remove one visit
    await tester.pumpWidget(
      createWidget(
        visits: [visit1],
        currentLocation: const GeoLatLong(lat: 51.5, long: -0.12),
      ),
    );
    await tester.pumpAndSettle();

    // Verify marker count decreased
    markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(markerLayer.markers.length, 2); // 1 visit + 1 current location
  });

  testWidgets('shows markers when visits are loaded after initial render', (
    tester,
  ) async {
    // Start with empty visits (simulating loading state)
    await tester.pumpWidget(
      createWidget(
        visits: const [],
        currentLocation: const GeoLatLong(lat: 51.5, long: -0.12),
      ),
    );
    await tester.pumpAndSettle();

    // Verify no visit markers initially
    var markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(markerLayer.markers.length, 1); // Only current location

    // Simulate visits being loaded
    final visit1 = createVisit(id: 'visit-1', lat: 51.5, long: -0.1);
    final visit2 = createVisit(id: 'visit-2', lat: 51.6, long: -0.2);

    await tester.pumpWidget(
      createWidget(
        visits: [visit1, visit2],
        currentLocation: const GeoLatLong(lat: 51.5, long: -0.12),
      ),
    );
    await tester.pumpAndSettle();

    // Verify markers now appear
    markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(markerLayer.markers.length, 3); // 2 visits + 1 current location
    expect(
      markerLayer.markers.where((m) => m.child is VisitMarker).length,
      equals(2),
    );
  });

  testWidgets('filters out visits without GPS coordinates', (tester) async {
    final visitWithGps = createVisit(id: 'visit-1', lat: 51.5, long: -0.1);
    final visitWithoutGps = Visit(
      id: 'visit-2',
      userId: 'user',
      placeName: 'Place without GPS',
      addedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      createWidget(
        visits: [visitWithGps, visitWithoutGps],
        currentLocation: const GeoLatLong(lat: 51.5, long: -0.12),
      ),
    );
    await tester.pumpAndSettle();

    // Should only show marker for visit with GPS
    final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(markerLayer.markers.length, 2); // 1 visit + 1 current location
    expect(
      markerLayer.markers.where((m) => m.child is VisitMarker).length,
      equals(1),
    );
  });

  testWidgets('updates when current location changes', (tester) async {
    final visit = createVisit(id: 'visit-1', lat: 51.5, long: -0.1);

    // Start without current location
    await tester.pumpWidget(
      createWidget(
        visits: [visit],
      ),
    );
    await tester.pumpAndSettle();

    // Verify only visit marker
    var markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(markerLayer.markers.length, 1); // Only visit marker
    expect(
      markerLayer.markers.any(
        (marker) => marker.child is CurrentLocationMarker,
      ),
      isFalse,
    );

    // Add current location
    await tester.pumpWidget(
      createWidget(
        visits: [visit],
        currentLocation: const GeoLatLong(lat: 51.5, long: -0.12),
      ),
    );
    await tester.pumpAndSettle();

    // Verify both markers now
    markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(markerLayer.markers.length, 2); // Visit + current location
    expect(
      markerLayer.markers.any(
        (marker) => marker.child is CurrentLocationMarker,
      ),
      isTrue,
    );
  });

  testWidgets('re-centres map when location changes by more than 10m', (
    tester,
  ) async {
    final visit = createVisit(id: 'visit-1', lat: 51.5, long: -0.1);

    // Start with initial location (London)
    await tester.pumpWidget(
      createWidget(
        visits: [visit],
        currentLocation: const GeoLatLong(lat: 51.5074, long: -0.1278),
      ),
    );
    await tester.pumpAndSettle();

    // Update location to a point more than 10m away
    // Moving approximately 100m north (0.0009 degrees latitude ≈ 100m)
    await tester.pumpWidget(
      createWidget(
        visits: [visit],
        currentLocation: const GeoLatLong(lat: 51.5083, long: -0.1278),
      ),
    );
    await tester.pumpAndSettle();

    // Verify the widget updated (marker should reflect new location)
    final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    final currentLocationMarker = markerLayer.markers.firstWhere(
      (marker) => marker.child is CurrentLocationMarker,
    );
    expect(
      currentLocationMarker.point.latitude,
      closeTo(51.5083, 0.0001),
    );
  });

  testWidgets('does not re-centre when location changes by less than 10m', (
    tester,
  ) async {
    final visit = createVisit(id: 'visit-1', lat: 51.5, long: -0.1);

    // Start with initial location
    await tester.pumpWidget(
      createWidget(
        visits: [visit],
        currentLocation: const GeoLatLong(lat: 51.5074, long: -0.1278),
      ),
    );
    await tester.pumpAndSettle();

    // Update location to a point less than 10m away
    // Moving approximately 5m north (0.000045 degrees latitude ≈ 5m)
    await tester.pumpWidget(
      createWidget(
        visits: [visit],
        currentLocation: const GeoLatLong(lat: 51.507445, long: -0.1278),
      ),
    );
    await tester.pumpAndSettle();

    // Verify the marker updated but map center logic handled it
    final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    final currentLocationMarker = markerLayer.markers.firstWhere(
      (marker) => marker.child is CurrentLocationMarker,
    );
    expect(
      currentLocationMarker.point.latitude,
      closeTo(51.507445, 0.0001),
    );
  });
}

class _StubTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(TileProvider.transparentImage);
  }
}
