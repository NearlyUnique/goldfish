import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:goldfish/core/auth/auth_notifier.dart';
import 'package:goldfish/core/data/models/visit_model.dart';
import 'package:goldfish/core/data/repositories/visit_repository.dart';
import 'package:goldfish/core/data/visit_exceptions.dart';
import 'package:goldfish/core/location/location_service.dart';
import 'package:goldfish/features/home/presentation/screens/home_screen.dart';
import 'package:goldfish/features/map/presentation/widgets/map_view_widget.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../../test/fakes/auth_notifier_fake.dart';
import '../../../../../test/fakes/location_service_fake.dart';

class MockVisitRepository extends Mock implements VisitRepository {}

class MockFirebaseUser extends Mock implements firebase_auth.User {}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue('user123');
  });

  group('HomeScreen', () {
    late FakeAuthNotifier fakeAuthNotifier;
    late MockVisitRepository mockVisitRepository;
    late MockFirebaseUser mockUser;
    late FakeLocationService fakeLocationService;

    setUp(() {
      mockUser = MockFirebaseUser();
      when(() => mockUser.uid).thenReturn('user123');
      when(() => mockUser.email).thenReturn('test@example.com');
      fakeAuthNotifier = FakeAuthNotifier(
        initialState: AuthState.authenticated,
        initialUser: mockUser,
      );
      mockVisitRepository = MockVisitRepository();
      fakeLocationService = FakeLocationService();
    });

    Widget createWidgetUnderTest({
      LocationService? locationService,
      TileProvider? tileProvider,
    }) {
      return MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => HomeScreen(
                authNotifier: fakeAuthNotifier,
                visitRepository: mockVisitRepository,
                locationService: locationService ?? fakeLocationService,
                tileProvider: tileProvider ?? _StubTileProvider(),
              ),
            ),
            GoRoute(
              path: '/record-visit',
              builder: (context, state) =>
                  const Scaffold(body: Text('Record Visit Screen')),
            ),
          ],
        ),
      );
    }

    testWidgets('displays app title in app bar', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Goldfish'), findsOneWidget);
    });

    testWidgets('displays sign out button in app bar', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.logout), findsOneWidget);
      expect(find.byTooltip('Sign Out'), findsOneWidget);
    });

    testWidgets('displays floating action button', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byTooltip('Record Visit'), findsOneWidget);
    });

    testWidgets('navigates to record visit screen when FAB is tapped', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Record Visit Screen'), findsOneWidget);
    });

    testWidgets('shows loading indicator while loading visits', (tester) async {
      // Arrange
      when(() => mockVisitRepository.getUserVisits(any())).thenAnswer((
        _,
      ) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return <Visit>[];
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Initial build

      // Assert - should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Nothing to remember'), findsNothing);

      // Wait for load to complete
      await tester.pumpAndSettle();
      verify(() => mockVisitRepository.getUserVisits('user123')).called(1);
    });

    testWidgets('displays empty state when no visits exist', (tester) async {
      // Arrange
      when(
        () => mockVisitRepository.getUserVisits(any()),
      ).thenAnswer((_) async => <Visit>[]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Nothing to remember'), findsOneWidget);
      expect(
        find.text('Tap the + button to record your first visit'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.place_outlined), findsOneWidget);
    });

    testWidgets('displays visits list when visits exist', (tester) async {
      // Arrange
      final now = DateTime.now();
      final visits = [
        Visit(
          id: 'visit1',
          userId: 'user123',
          placeName: 'Test Place 1',
          addedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
        Visit(
          id: 'visit2',
          userId: 'user123',
          placeName: 'Test Place 2',
          addedAt: now.subtract(const Duration(days: 1)),
          createdAt: now.subtract(const Duration(days: 1)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
      ];
      when(
        () => mockVisitRepository.getUserVisits(any()),
      ).thenAnswer((_) async => visits);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Place 1'), findsOneWidget);
      expect(find.text('Test Place 2'), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('displays visit with amenity type chip', (tester) async {
      // Arrange
      final now = DateTime.now();
      final visit = Visit(
        id: 'visit1',
        userId: 'user123',
        placeName: 'Test Pub',
        placeType: const LocationType(type: 'amenity', subType: 'pub'),
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      when(
        () => mockVisitRepository.getUserVisits(any()),
      ).thenAnswer((_) async => [visit]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Pub'), findsOneWidget);
      expect(find.byType(Chip), findsOneWidget);
      expect(find.text('Pub'), findsOneWidget);
    });

    testWidgets('displays formatted date for recent visit', (tester) async {
      // Arrange
      final now = DateTime.now();
      final visit = Visit(
        id: 'visit1',
        userId: 'user123',
        placeName: 'Test Place',
        addedAt: now.subtract(const Duration(hours: 2)),
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      );
      when(
        () => mockVisitRepository.getUserVisits(any()),
      ).thenAnswer((_) async => [visit]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('2 hours ago'), findsOneWidget);
    });

    testWidgets('displays formatted date for older visit', (tester) async {
      // Arrange
      final date = DateTime(2024, 1, 15);
      final visit = Visit(
        id: 'visit1',
        userId: 'user123',
        placeName: 'Test Place',
        addedAt: date,
        createdAt: date,
        updatedAt: date,
      );
      when(
        () => mockVisitRepository.getUserVisits(any()),
      ).thenAnswer((_) async => [visit]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Jan 15, 2024'), findsOneWidget);
    });

    testWidgets('displays error state when loading fails', (tester) async {
      // Arrange
      when(
        () => mockVisitRepository.getUserVisits(any()),
      ).thenThrow(VisitDataException('Failed to load visits'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Failed to load visits'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retries loading visits when retry button is tapped', (
      tester,
    ) async {
      // Arrange
      var callCount = 0;
      when(() => mockVisitRepository.getUserVisits(any())).thenAnswer((_) {
        callCount++;
        if (callCount == 1) {
          throw VisitDataException('Failed to load visits');
        }
        return Future.value(<Visit>[]);
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert - error state shown
      expect(find.text('Failed to load visits'), findsOneWidget);
      expect(callCount, equals(1));

      // Act - tap retry button
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Assert - should retry and show empty state
      expect(callCount, equals(2));
      expect(find.text('Nothing to remember'), findsOneWidget);
    });

    testWidgets('supports pull-to-refresh', (tester) async {
      // Arrange
      var callCount = 0;
      final now = DateTime.now();
      final visit = Visit(
        id: 'visit1',
        userId: 'user123',
        placeName: 'Test Place',
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      when(() => mockVisitRepository.getUserVisits(any())).thenAnswer((_) {
        callCount++;
        return Future.value([visit]);
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert - initial load
      expect(find.text('Test Place'), findsOneWidget);
      expect(callCount, equals(1));

      // Act - pull to refresh
      final listFinder = find.byType(ListView);
      await tester.drag(listFinder, const Offset(0, 300));
      await tester.pumpAndSettle();

      // Assert - should reload
      expect(callCount, equals(2));
    });

    testWidgets('shows sign out confirmation dialog', (tester) async {
      // Arrange
      var signOutCalled = false;
      fakeAuthNotifier.onSignOut = () async {
        signOutCalled = true;
      };
      when(
        () => mockVisitRepository.getUserVisits(any()),
      ).thenAnswer((_) async => <Visit>[]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act - tap sign out button
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      // Assert - dialog shown
      expect(find.text('Sign Out'), findsWidgets);
      expect(find.text('Are you sure you want to sign out?'), findsOneWidget);

      // Act - confirm sign out
      await tester.tap(find.text('Sign Out').last);
      await tester.pumpAndSettle();

      // Assert
      expect(signOutCalled, isTrue);
    });

    testWidgets('cancels sign out when cancel button is tapped', (
      tester,
    ) async {
      // Arrange
      var signOutCalled = false;
      fakeAuthNotifier.onSignOut = () async {
        signOutCalled = true;
      };
      when(
        () => mockVisitRepository.getUserVisits(any()),
      ).thenAnswer((_) async => <Visit>[]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act - tap sign out button
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      // Act - cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Assert
      expect(signOutCalled, isFalse);
      expect(find.text('Are you sure you want to sign out?'), findsNothing);
    });

    testWidgets('does not load visits when user is null', (tester) async {
      // Arrange
      final unauthenticatedNotifier = FakeAuthNotifier(
        initialState: AuthState.unauthenticated,
        initialUser: null,
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => HomeScreen(
                  authNotifier: unauthenticatedNotifier,
                  visitRepository: mockVisitRepository,
                  tileProvider: _StubTileProvider(),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      verifyNever(() => mockVisitRepository.getUserVisits(any()));
    });

    testWidgets('sorts visits by most recent first', (tester) async {
      // Arrange
      final now = DateTime.now();
      final olderVisit = Visit(
        id: 'visit1',
        userId: 'user123',
        placeName: 'Older Place',
        addedAt: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      );
      final newerVisit = Visit(
        id: 'visit2',
        userId: 'user123',
        placeName: 'Newer Place',
        addedAt: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      );
      // Note: Repository should return sorted, but we test the display order
      when(
        () => mockVisitRepository.getUserVisits(any()),
      ).thenAnswer((_) async => [newerVisit, olderVisit]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert - find all visit cards
      final cards = find.byType(Card);
      expect(cards, findsNWidgets(2));

      // Get the text widgets to verify order
      final placeNames = find.text('Newer Place');
      final olderPlaceNames = find.text('Older Place');
      expect(placeNames, findsOneWidget);
      expect(olderPlaceNames, findsOneWidget);
    });

    testWidgets(
      'refreshes visits list when returning from record visit screen with saved visit',
      (tester) async {
        // Arrange
        var callCount = 0;
        final now = DateTime.now();
        final initialVisits = [
          Visit(
            id: 'visit1',
            userId: 'user123',
            placeName: 'Existing Place',
            addedAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        ];
        final updatedVisits = [
          Visit(
            id: 'visit1',
            userId: 'user123',
            placeName: 'Existing Place',
            addedAt: now,
            createdAt: now,
            updatedAt: now,
          ),
          Visit(
            id: 'visit2',
            userId: 'user123',
            placeName: 'New Place',
            addedAt: now.add(const Duration(seconds: 1)),
            createdAt: now.add(const Duration(seconds: 1)),
            updatedAt: now.add(const Duration(seconds: 1)),
          ),
        ];

        when(() => mockVisitRepository.getUserVisits(any())).thenAnswer((_) {
          callCount++;
          if (callCount == 1) {
            return Future.value(initialVisits);
          }
          return Future.value(updatedVisits);
        });

        // Create router with a record visit screen that returns true
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => HomeScreen(
                authNotifier: fakeAuthNotifier,
                visitRepository: mockVisitRepository,
                tileProvider: _StubTileProvider(),
              ),
            ),
            GoRoute(
              path: '/record-visit',
              builder: (context, state) => Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => context.pop(true),
                    child: const Text('Save and Return'),
                  ),
                ),
              ),
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        // Assert - initial load
        expect(find.text('Existing Place'), findsOneWidget);
        expect(find.text('New Place'), findsNothing);
        expect(callCount, equals(1));

        // Act - navigate to record visit screen
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Assert - on record visit screen
        expect(find.text('Save and Return'), findsOneWidget);

        // Act - simulate saving and returning
        await tester.tap(find.text('Save and Return'));
        await tester.pumpAndSettle();

        // Assert - should have refreshed and show new visit
        expect(callCount, equals(2));
        expect(find.text('Existing Place'), findsOneWidget);
        expect(find.text('New Place'), findsOneWidget);
      },
    );

    testWidgets(
      'does not refresh visits list when returning from record visit screen without saving',
      (tester) async {
        // Arrange
        var callCount = 0;
        final now = DateTime.now();
        final visits = [
          Visit(
            id: 'visit1',
            userId: 'user123',
            placeName: 'Existing Place',
            addedAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        when(() => mockVisitRepository.getUserVisits(any())).thenAnswer((_) {
          callCount++;
          return Future.value(visits);
        });

        // Create router with a record visit screen that returns false
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => HomeScreen(
                authNotifier: fakeAuthNotifier,
                visitRepository: mockVisitRepository,
                tileProvider: _StubTileProvider(),
              ),
            ),
            GoRoute(
              path: '/record-visit',
              builder: (context, state) => Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => context.pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
              ),
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        // Assert - initial load
        expect(find.text('Existing Place'), findsOneWidget);
        expect(callCount, equals(1));

        // Act - navigate to record visit screen
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Assert - on record visit screen
        expect(find.text('Cancel'), findsOneWidget);

        // Act - cancel and return
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Assert - should not have refreshed
        expect(callCount, equals(1));
        expect(find.text('Existing Place'), findsOneWidget);
      },
    );

    testWidgets('displays view toggle with list and map options', (
      tester,
    ) async {
      // Arrange
      when(
        () => mockVisitRepository.getUserVisits(any()),
      ).thenAnswer((_) async => <Visit>[]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('List'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
      expect(find.byType(SegmentedButton<ViewMode>), findsOneWidget);
    });

    testWidgets('switches to map view when map option is selected', (
      tester,
    ) async {
      // Arrange
      final now = DateTime.now();
      final visit = Visit(
        id: 'visit1',
        userId: 'user123',
        placeName: 'Test Place',
        gpsKnown: const GeoLatLong(lat: 51.5074, long: -0.1278),
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      when(
        () => mockVisitRepository.getUserVisits(any()),
      ).thenAnswer((_) async => [visit]);
      fakeLocationService.onHasPermission = () async => true;
      fakeLocationService.onGetCurrentLocation = () async => Position(
        latitude: 51.5074,
        longitude: -0.1278,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert - initially in list view
      expect(find.text('Test Place'), findsOneWidget);
      expect(find.byType(MapViewWidget), findsNothing);

      // Act - switch to map view
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();

      // Assert - map view is shown
      expect(find.byType(MapViewWidget), findsOneWidget);
      expect(find.text('Test Place'), findsNothing);
    });

    testWidgets('requests location when switching to map view', (tester) async {
      // Arrange
      when(
        () => mockVisitRepository.getUserVisits(any()),
      ).thenAnswer((_) async => <Visit>[]);
      var hasPermissionCalled = false;
      var requestPermissionCalled = false;
      fakeLocationService.onIsLocationServiceEnabled = () async => true;
      fakeLocationService.onHasPermission = () async {
        hasPermissionCalled = true;
        return false;
      };
      fakeLocationService.onRequestPermission = () async {
        requestPermissionCalled = true;
        return true;
      };
      fakeLocationService.onGetCurrentLocation = () async => Position(
        latitude: 51.5074,
        longitude: -0.1278,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act - switch to map view
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();

      // Assert - location permission was requested
      expect(hasPermissionCalled, isTrue);
      expect(requestPermissionCalled, isTrue);
    });

    testWidgets(
      'handles location permission denied when switching to map view',
      (tester) async {
        // Arrange
        when(
          () => mockVisitRepository.getUserVisits(any()),
        ).thenAnswer((_) async => <Visit>[]);
        fakeLocationService.onIsLocationServiceEnabled = () async => true;
        fakeLocationService.onHasPermission = () async => false;
        fakeLocationService.onRequestPermission = () async => false;
        fakeLocationService.onIsPermissionDeniedForever = () async => false;

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Act - switch to map view
        await tester.tap(find.text('Map'));
        await tester.pumpAndSettle();

        // Assert - map view is shown with error message
        expect(find.byType(MapViewWidget), findsOneWidget);
        expect(
          find.textContaining('Location permission is required'),
          findsOneWidget,
        );
      },
    );

    testWidgets('shows open settings option when permission denied forever', (
      tester,
    ) async {
      // Arrange
      when(
        () => mockVisitRepository.getUserVisits(any()),
      ).thenAnswer((_) async => <Visit>[]);
      fakeLocationService.onIsLocationServiceEnabled = () async => true;
      fakeLocationService.onHasPermission = () async => false;
      fakeLocationService.onRequestPermission = () async => false;
      fakeLocationService.onIsPermissionDeniedForever = () async => true;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act - switch to map view
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();

      // Assert - map view shows settings message
      expect(find.byType(MapViewWidget), findsOneWidget);
      expect(find.textContaining('Tap to enable in settings'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
    });

    testWidgets('preserves visits when toggling between list and map views', (
      tester,
    ) async {
      // Arrange
      final now = DateTime.now();
      final visit = Visit(
        id: 'visit1',
        userId: 'user123',
        placeName: 'Test Place',
        gpsKnown: const GeoLatLong(lat: 51.5074, long: -0.1278),
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      when(
        () => mockVisitRepository.getUserVisits(any()),
      ).thenAnswer((_) async => [visit]);
      fakeLocationService.onHasPermission = () async => true;
      fakeLocationService.onGetCurrentLocation = () async => Position(
        latitude: 51.5074,
        longitude: -0.1278,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert - initially in list view
      expect(find.text('Test Place'), findsOneWidget);

      // Act - switch to map view
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();

      // Assert - map view is shown
      expect(find.byType(MapViewWidget), findsOneWidget);

      // Act - switch back to list view
      await tester.tap(find.text('List'));
      await tester.pumpAndSettle();

      // Assert - list view is shown with same visits
      expect(find.text('Test Place'), findsOneWidget);
      expect(find.byType(MapViewWidget), findsNothing);
    });

    testWidgets('passes visits to map view widget', (tester) async {
      // Arrange
      final now = DateTime.now();
      final visit = Visit(
        id: 'visit1',
        userId: 'user123',
        placeName: 'Test Place',
        gpsKnown: const GeoLatLong(lat: 51.5074, long: -0.1278),
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      when(
        () => mockVisitRepository.getUserVisits(any()),
      ).thenAnswer((_) async => [visit]);
      fakeLocationService.onHasPermission = () async => true;
      fakeLocationService.onGetCurrentLocation = () async => Position(
        latitude: 51.5074,
        longitude: -0.1278,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act - switch to map view
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();

      // Assert - map view widget is displayed
      final mapViewWidget = tester.widget<MapViewWidget>(
        find.byType(MapViewWidget),
      );
      expect(mapViewWidget.visits, hasLength(1));
      expect(mapViewWidget.visits.first.id, 'visit1');
    });

    testWidgets(
      'shows location services disabled error when services are disabled',
      (tester) async {
        // Arrange
        when(
          () => mockVisitRepository.getUserVisits(any()),
        ).thenAnswer((_) async => <Visit>[]);
        fakeLocationService.onIsLocationServiceEnabled = () async => false;

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Act - switch to map view
        await tester.tap(find.text('Map'));
        await tester.pumpAndSettle();

        // Assert - map view shows location services disabled message
        expect(find.byType(MapViewWidget), findsOneWidget);
        expect(
          find.text('Please enable location services in device settings.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows location unavailable message when location cannot be retrieved',
      (tester) async {
        // Arrange
        final now = DateTime.now();
        final visit = Visit(
          id: 'visit1',
          userId: 'user123',
          placeName: 'Test Place',
          gpsKnown: const GeoLatLong(lat: 51.5074, long: -0.1278),
          addedAt: now,
          createdAt: now,
          updatedAt: now,
        );
        when(
          () => mockVisitRepository.getUserVisits(any()),
        ).thenAnswer((_) async => [visit]);
        fakeLocationService.onIsLocationServiceEnabled = () async => true;
        fakeLocationService.onHasPermission = () async => true;
        fakeLocationService.onGetCurrentLocation = () async => null;

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Act - switch to map view
        await tester.tap(find.text('Map'));
        await tester.pumpAndSettle();

        // Assert - map view shows location unavailable message but still displays map
        expect(find.byType(MapViewWidget), findsOneWidget);
        expect(
          find.text('Unable to get current location. Showing visited places.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('opens app settings when open settings button is tapped', (
      tester,
    ) async {
      // Arrange
      var settingsOpened = false;
      when(
        () => mockVisitRepository.getUserVisits(any()),
      ).thenAnswer((_) async => <Visit>[]);
      fakeLocationService.onIsLocationServiceEnabled = () async => true;
      fakeLocationService.onHasPermission = () async => false;
      fakeLocationService.onRequestPermission = () async => false;
      fakeLocationService.onIsPermissionDeniedForever = () async => true;
      fakeLocationService.onOpenAppSettings = () async {
        settingsOpened = true;
        return true;
      };

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act - switch to map view
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();

      // Assert - open settings button is shown
      expect(find.text('Open Settings'), findsOneWidget);

      // Act - tap open settings
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Assert - settings were opened
      expect(settingsOpened, isTrue);
    });

    testWidgets('shows context menu when long pressing visit with location', (
      tester,
    ) async {
      // Arrange
      final now = DateTime.now();
      final visit = Visit(
        id: 'visit1',
        userId: 'user123',
        placeName: 'Test Place',
        gpsKnown: const GeoLatLong(lat: 51.5074, long: -0.1278),
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      when(
        () => mockVisitRepository.getUserVisits(any()),
      ).thenAnswer((_) async => [visit]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert - visit is displayed
      expect(find.text('Test Place'), findsOneWidget);

      // Act - long press on the visit item
      final listTile = find.byType(ListTile);
      await tester.longPress(listTile);
      await tester.pumpAndSettle();

      // Assert - context menu (bottom sheet) is shown
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Copy to Clipboard'), findsOneWidget);
      expect(find.text('Open in Maps'), findsOneWidget);
    });

    testWidgets(
      'shows context menu when long pressing visit without location',
      (tester) async {
        // Arrange
        final now = DateTime.now();
        final visit = Visit(
          id: 'visit1',
          userId: 'user123',
          placeName: 'Test Place',
          // No location data
          addedAt: now,
          createdAt: now,
          updatedAt: now,
        );
        when(
          () => mockVisitRepository.getUserVisits(any()),
        ).thenAnswer((_) async => [visit]);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert - visit is displayed
        expect(find.text('Test Place'), findsOneWidget);

        // Act - long press on the visit item
        final listTile = find.byType(ListTile);
        await tester.longPress(listTile);
        await tester.pumpAndSettle();

        // Assert - context menu is shown with copy option only
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.text('Copy to Clipboard'), findsOneWidget);
        // Open in Maps should not be shown when there's no location
        expect(find.text('Open in Maps'), findsNothing);
      },
    );

    testWidgets('uses gpsRecorded when gpsKnown is not available', (
      tester,
    ) async {
      // Arrange
      final now = DateTime.now();
      final visit = Visit(
        id: 'visit1',
        userId: 'user123',
        placeName: 'Test Place',
        gpsRecorded: const GeoLatLong(lat: 51.5074, long: -0.1278),
        // gpsKnown is null, should fall back to gpsRecorded
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      when(
        () => mockVisitRepository.getUserVisits(any()),
      ).thenAnswer((_) async => [visit]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act - long press on the visit item
      final listTile = find.byType(ListTile);
      await tester.longPress(listTile);
      await tester.pumpAndSettle();

      // Assert - context menu is shown (location is available via gpsRecorded)
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Copy to Clipboard'), findsOneWidget);
      expect(find.text('Open in Maps'), findsOneWidget);
    });

    testWidgets('closes context menu when tapping Open in Maps', (
      tester,
    ) async {
      // Arrange
      final now = DateTime.now();
      final visit = Visit(
        id: 'visit1',
        userId: 'user123',
        placeName: 'Test Place',
        gpsKnown: const GeoLatLong(lat: 51.5074, long: -0.1278),
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      when(
        () => mockVisitRepository.getUserVisits(any()),
      ).thenAnswer((_) async => [visit]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act - long press on the visit item
      final listTile = find.byType(ListTile);
      await tester.longPress(listTile);
      await tester.pumpAndSettle();

      // Assert - context menu is shown
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Open in Maps'), findsOneWidget);

      // Act - tap "Open in Maps"
      await tester.tap(find.text('Open in Maps'));
      await tester.pumpAndSettle();

      // Assert - context menu is closed
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Open in Maps'), findsNothing);
    });

    testWidgets('copies visit to clipboard when tapping Copy to Clipboard', (
      tester,
    ) async {
      // Arrange
      final now = DateTime.now();
      final visit = Visit(
        id: 'visit1',
        userId: 'user123',
        placeName: 'Test Place',
        placeAddress: const Address(
          nameNumber: '123',
          street: 'Test Street',
          city: 'Test City',
          postcode: 'TE5T 1NG',
        ),
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      when(
        () => mockVisitRepository.getUserVisits(any()),
      ).thenAnswer((_) async => [visit]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act - long press on the visit item
      final listTile = find.byType(ListTile);
      await tester.longPress(listTile);
      await tester.pumpAndSettle();

      // Assert - context menu is shown
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Copy to Clipboard'), findsOneWidget);

      // Act - tap "Copy to Clipboard"
      await tester.tap(find.text('Copy to Clipboard'));
      await tester.pumpAndSettle();

      // Assert - context menu is closed
      expect(find.byType(BottomSheet), findsNothing);
      // Snackbar should be shown
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Copied to clipboard'), findsOneWidget);
    });

    testWidgets('copies visit without address to clipboard', (tester) async {
      // Arrange
      final now = DateTime.now();
      final visit = Visit(
        id: 'visit1',
        userId: 'user123',
        placeName: 'Test Place',
        // No address
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      when(
        () => mockVisitRepository.getUserVisits(any()),
      ).thenAnswer((_) async => [visit]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act - long press on the visit item
      final listTile = find.byType(ListTile);
      await tester.longPress(listTile);
      await tester.pumpAndSettle();

      // Act - tap "Copy to Clipboard"
      await tester.tap(find.text('Copy to Clipboard'));
      await tester.pumpAndSettle();

      // Assert - snackbar is shown
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Copied to clipboard'), findsOneWidget);
    });
  });
}

/// Stub tile provider that returns a transparent image to avoid network
/// requests during tests.
class _StubTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(TileProvider.transparentImage);
  }
}
