import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:goldfish/core/auth/auth_notifier.dart';

/// Fake implementation of [AuthNotifier] for testing.
///
/// Provides function fields that tests can configure to control behavior.
/// This is a test double that extends [ChangeNotifier] to match the interface.
class FakeAuthNotifier extends ChangeNotifier implements AuthNotifier {
  /// Creates a new [FakeAuthNotifier].
  ///
  /// Optionally accepts function handlers for each method. If not provided,
  /// uses default implementations that return safe defaults.
  FakeAuthNotifier({
    AuthState? initialState,
    firebase_auth.User? initialUser,
    Future<SignInResponse> Function()? onSignInWithGoogle,
    Future<void> Function()? onSignOut,
  }) : _state = initialState ?? AuthState.unauthenticated,
       _user = initialUser,
       onSignInWithGoogle = onSignInWithGoogle ?? _defaultSignInWithGoogle,
       onSignOut = onSignOut ?? _defaultSignOut;

  final AuthState _state;
  final firebase_auth.User? _user;

  /// Handler for [signInWithGoogle].
  Future<SignInResponse> Function() onSignInWithGoogle;

  /// Handler for [signOut].
  Future<void> Function() onSignOut;

  @override
  AuthState get state => _state;

  @override
  firebase_auth.User? get user => _user;

  @override
  bool get isAuthenticated => _state == AuthState.authenticated;

  @override
  bool get isLoading => _state == AuthState.loading;

  @override
  Future<SignInResponse> signInWithGoogle() => onSignInWithGoogle();

  @override
  Future<void> signOut() => onSignOut();

  // Default implementations
  static Future<SignInResponse> _defaultSignInWithGoogle() async {
    return const SignInResponse(
      uid: 'test-user-id',
      authState: AuthState.authenticated,
      provider: 'google',
    );
  }

  static Future<void> _defaultSignOut() async {
    // No-op by default
  }
}
