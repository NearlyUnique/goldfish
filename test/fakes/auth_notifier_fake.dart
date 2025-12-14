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
    String? initialErrorMessage,
    Future<void> Function()? onSignInWithGoogle,
    Future<void> Function()? onSignOut,
  }) : _state = initialState ?? AuthState.unauthenticated,
       _user = initialUser,
       _errorMessage = initialErrorMessage,
       onSignInWithGoogle = onSignInWithGoogle ?? _defaultSignInWithGoogle,
       onSignOut = onSignOut ?? _defaultSignOut;

  final AuthState _state;
  final firebase_auth.User? _user;
  final String? _errorMessage;

  /// Handler for [signInWithGoogle].
  Future<void> Function() onSignInWithGoogle;

  /// Handler for [signOut].
  Future<void> Function() onSignOut;

  @override
  AuthState get state => _state;

  @override
  firebase_auth.User? get user => _user;

  @override
  String? get errorMessage => _errorMessage;

  @override
  bool get isAuthenticated => _state == AuthState.authenticated;

  @override
  bool get isLoading => _state == AuthState.loading;

  @override
  Future<void> signInWithGoogle() => onSignInWithGoogle();

  @override
  Future<void> signOut() => onSignOut();

  // Default implementations
  static Future<void> _defaultSignInWithGoogle() async {
    // No-op by default
  }

  static Future<void> _defaultSignOut() async {
    // No-op by default
  }
}
