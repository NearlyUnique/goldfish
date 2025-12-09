import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:goldfish/core/data/models/visit_model.dart';
import 'package:goldfish/core/theme/app_theme.dart';
import 'package:goldfish/features/map/presentation/widgets/map_view_widget.dart';
import 'package:goldfish/features/map/presentation/widgets/visit_marker.dart';
import 'package:latlong2/latlong.dart';

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

    expect(find.text('No locations to show yet.'), findsOneWidget);
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
}

class _StubTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(TileProvider.transparentImage);
  }
}
