import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:goldfish/core/auth/auth_service.dart';

/// Fake implementation of [AuthService] for testing.
///
/// Provides function fields that tests can configure to control behavior.
/// Default implementations return safe defaults so tests only need to
/// configure the behavior they care about.
class FakeAuthService implements AuthService {
  /// Creates a new [FakeAuthService].
  ///
  /// Optionally accepts function handlers for each method. If not provided,
  /// uses default implementations that return safe defaults.
  FakeAuthService({
    Stream<firebase_auth.User?> Function()? onAuthStateChanges,
    firebase_auth.User? Function()? onCurrentUser,
    Future<firebase_auth.User> Function()? onSignInWithGoogle,
    Future<void> Function()? onSignOut,
  }) : onAuthStateChanges = onAuthStateChanges ?? _defaultAuthStateChanges,
       onCurrentUser = onCurrentUser ?? _defaultCurrentUser,
       onSignInWithGoogle = onSignInWithGoogle ?? _defaultSignInWithGoogle,
       onSignOut = onSignOut ?? _defaultSignOut;

  /// Handler for [authStateChanges].
  Stream<firebase_auth.User?> Function() onAuthStateChanges;

  /// Handler for [currentUser].
  firebase_auth.User? Function() onCurrentUser;

  /// Handler for [signInWithGoogle].
  Future<firebase_auth.User> Function() onSignInWithGoogle;

  /// Handler for [signOut].
  Future<void> Function() onSignOut;

  @override
  Stream<firebase_auth.User?> get authStateChanges => onAuthStateChanges();

  @override
  firebase_auth.User? get currentUser => onCurrentUser();

  @override
  Future<firebase_auth.User> signInWithGoogle() => onSignInWithGoogle();

  @override
  Future<void> signOut() => onSignOut();

  // Default implementations
  static Stream<firebase_auth.User?> _defaultAuthStateChanges() {
    return Stream<firebase_auth.User?>.value(null);
  }

  static firebase_auth.User? _defaultCurrentUser() => null;

  static Future<firebase_auth.User> _defaultSignInWithGoogle() async {
    throw UnimplementedError('signInWithGoogle not configured in test');
  }

  static Future<void> _defaultSignOut() async {
    // No-op by default
  }
}
