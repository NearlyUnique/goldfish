import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goldfish/core/api/overpass_client.dart';
import 'package:goldfish/core/auth/auth_notifier.dart';
import 'package:goldfish/core/data/repositories/visit_repository.dart';
import 'package:goldfish/core/location/location_service.dart';
import 'package:goldfish/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:goldfish/features/home/presentation/screens/home_screen.dart';
import 'package:goldfish/features/visits/domain/view_models/record_visit_view_model.dart';
import 'package:goldfish/features/visits/presentation/screens/record_visit_screen.dart';

/// Configuration for app navigation with authentication guards.
///
/// Handles routing and redirects based on authentication state.
class AppRouter {
  /// Creates a new [AppRouter] with the given dependencies.
  ///
  /// All services, clients, and repositories are injected for testability.
  /// Optionally accepts a [visitRepository] for dependency injection.
  /// If not provided, creates a default [VisitRepository] instance using [firestore].
  AppRouter({
    required AuthNotifier authNotifier,
    required FirebaseFirestore firestore,
    required LocationService locationService,
    required OverpassClient overpassClient,
    VisitRepository? visitRepository,
  }) : _authNotifier = authNotifier,
       _locationService = locationService,
       _overpassClient = overpassClient,
       _visitRepository =
           visitRepository ?? VisitRepository(firestore: firestore);

  final AuthNotifier _authNotifier;
  final LocationService _locationService;
  final OverpassClient _overpassClient;
  final VisitRepository _visitRepository;

  /// The configured [GoRouter] instance.
  late final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: _handleRedirect,
    refreshListenable: _authNotifier,
    routes: [
      GoRoute(
        path: '/sign-in',
        name: 'sign-in',
        builder: (context, state) => SignInScreen(authNotifier: _authNotifier),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) {
          return HomeScreen(
            authNotifier: _authNotifier,
            visitRepository: _visitRepository,
            locationService: _locationService,
          );
        },
      ),
      GoRoute(
        path: '/record-visit',
        name: 'record-visit',
        builder: (context, state) {
          // Create ViewModel with all required dependencies injected from main.dart
          final viewModel = RecordVisitViewModel(
            locationService: _locationService,
            overpassClient: _overpassClient,
            visitRepository: _visitRepository,
            authNotifier: _authNotifier,
          );

          return RecordVisitScreen(viewModel: viewModel);
        },
      ),
    ],
  );

  /// Handles route redirects based on authentication state.
  ///
  /// Redirects unauthenticated users to `/sign-in` and authenticated
  /// users away from `/sign-in` to `/`.
  String? _handleRedirect(BuildContext context, GoRouterState state) {
    final isAuthenticated = _authNotifier.isAuthenticated;
    final isSignInRoute = state.matchedLocation == '/sign-in';

    // If not authenticated and not on sign-in page, redirect to sign-in
    if (!isAuthenticated && !isSignInRoute) {
      return '/sign-in';
    }

    // If authenticated and on sign-in page, redirect to home
    if (isAuthenticated && isSignInRoute) {
      return '/';
    }

    // No redirect needed
    return null;
  }
}
