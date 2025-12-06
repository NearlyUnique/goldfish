import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goldfish/core/auth/auth_notifier.dart';
import 'package:goldfish/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:goldfish/features/home/presentation/screens/home_screen.dart';
import 'package:goldfish/features/visits/presentation/screens/record_visit_screen.dart';

/// Configuration for app navigation with authentication guards.
///
/// Handles routing and redirects based on authentication state.
class AppRouter {
  /// Creates a new [AppRouter] with the given [authNotifier].
  AppRouter({required AuthNotifier authNotifier})
    : _authNotifier = authNotifier;

  final AuthNotifier _authNotifier;

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
        builder: (context, state) => HomeScreen(authNotifier: _authNotifier),
      ),
      GoRoute(
        path: '/record-visit',
        name: 'record-visit',
        builder: (context, state) => RecordVisitScreen(
          authNotifier: _authNotifier,
        ),
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
