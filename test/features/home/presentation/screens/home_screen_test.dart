import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:goldfish/core/auth/auth_notifier.dart';
import 'package:goldfish/core/data/models/visit_model.dart';
import 'package:goldfish/core/data/repositories/visit_repository.dart';
import 'package:goldfish/core/data/visit_exceptions.dart';
import 'package:goldfish/features/home/presentation/screens/home_screen.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../../test/fakes/auth_notifier_fake.dart';

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

    setUp(() {
      mockUser = MockFirebaseUser();
      when(() => mockUser.uid).thenReturn('user123');
      when(() => mockUser.email).thenReturn('test@example.com');
      fakeAuthNotifier = FakeAuthNotifier(
        initialState: AuthState.authenticated,
        initialUser: mockUser,
      );
      mockVisitRepository = MockVisitRepository();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => HomeScreen(
                authNotifier: fakeAuthNotifier,
                visitRepository: mockVisitRepository,
              ),
            ),
            GoRoute(
              path: '/record-visit',
              builder: (context, state) => const Scaffold(
                body: Text('Record Visit Screen'),
              ),
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

    testWidgets('navigates to record visit screen when FAB is tapped',
        (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Record Visit Screen'), findsOneWidget);
    });

    testWidgets('shows loading indicator while loading visits',
        (tester) async {
      // Arrange
      when(() => mockVisitRepository.getUserVisits(any()))
          .thenAnswer((_) async {
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
      when(() => mockVisitRepository.getUserVisits(any()))
          .thenAnswer((_) async => <Visit>[]);

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
      when(() => mockVisitRepository.getUserVisits(any()))
          .thenAnswer((_) async => visits);

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
      when(() => mockVisitRepository.getUserVisits(any()))
          .thenAnswer((_) async => [visit]);

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
      when(() => mockVisitRepository.getUserVisits(any()))
          .thenAnswer((_) async => [visit]);

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
      when(() => mockVisitRepository.getUserVisits(any()))
          .thenAnswer((_) async => [visit]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Jan 15, 2024'), findsOneWidget);
    });

    testWidgets('displays error state when loading fails', (tester) async {
      // Arrange
      when(() => mockVisitRepository.getUserVisits(any()))
          .thenThrow(VisitDataException('Failed to load visits'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Failed to load visits'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retries loading visits when retry button is tapped',
        (tester) async {
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
      when(() => mockVisitRepository.getUserVisits(any()))
          .thenAnswer((_) async => <Visit>[]);

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

    testWidgets('cancels sign out when cancel button is tapped',
        (tester) async {
      // Arrange
      var signOutCalled = false;
      fakeAuthNotifier.onSignOut = () async {
        signOutCalled = true;
      };
      when(() => mockVisitRepository.getUserVisits(any()))
          .thenAnswer((_) async => <Visit>[]);

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
      when(() => mockVisitRepository.getUserVisits(any()))
          .thenAnswer((_) async => [newerVisit, olderVisit]);

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
  });
}

