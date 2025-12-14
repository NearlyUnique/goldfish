import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:goldfish/core/auth/auth_exceptions.dart';
import 'package:goldfish/core/auth/auth_service.dart';

/// State of authentication.
enum AuthState {
  /// Initial state, authentication status unknown.
  initial,

  /// User is authenticated.
  authenticated,

  /// User is not authenticated.
  unauthenticated,

  /// Authentication operation in progress.
  loading,
}

/// Response from a sign-in operation.
class SignInResponse {
  /// Creates a new [SignInResponse].
  const SignInResponse({
    required this.uid,
    required this.authState,
    required this.provider,
  });

  /// The user ID, or `null` if not logged in.
  final String? uid;

  /// The authentication state after the sign-in operation.
  final AuthState authState;

  /// The authentication provider (e.g., 'google', 'firebase').
  final String provider;
}

/// Notifier for managing authentication state.
///
/// Listens to authentication state changes and provides reactive state
/// to the UI layer.
class AuthNotifier extends ChangeNotifier {
  /// Creates a new [AuthNotifier].
  AuthNotifier({required AuthService authService})
    : _authService = authService {
    _initialize();
  }

  final AuthService _authService;
  AuthState _state = AuthState.initial;
  firebase_auth.User? _user;

  /// Current authentication state.
  AuthState get state => _state;

  /// Current authenticated user, or `null` if not authenticated.
  firebase_auth.User? get user => _user;

  /// Whether the user is currently authenticated.
  bool get isAuthenticated => _state == AuthState.authenticated;

  /// Whether an authentication operation is in progress.
  bool get isLoading => _state == AuthState.loading;

  /// Initializes the notifier by listening to auth state changes.
  void _initialize() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  /// Handles authentication state changes from Firebase Auth.
  void _onAuthStateChanged(firebase_auth.User? user) {
    _user = user;
    _state = user != null ? AuthState.authenticated : AuthState.unauthenticated;
    notifyListeners();
  }

  /// Signs in with Google.
  ///
  /// Sets state to [AuthState.loading] during the operation.
  /// Returns a [SignInResponse] with the user ID and auth state.
  /// Throws [AuthException] if sign-in fails with an error.
  Future<SignInResponse> signInWithGoogle() async {
    _setState(AuthState.loading);

    try {
      final user = await _authService.signInWithGoogle();

      // State will be updated by _onAuthStateChanged
      return SignInResponse(
        uid: user.uid,
        authState: AuthState.authenticated,
        provider: 'google',
      );
    } on SignInCancelledException {
      _setState(AuthState.unauthenticated);
      return const SignInResponse(
        uid: null,
        authState: AuthState.unauthenticated,
        provider: 'google',
      );
    } on AuthException {
      _setState(AuthState.unauthenticated);
      notifyListeners();
      rethrow;
    }
  }

  /// Signs out the current user.
  ///
  /// Sets state to [AuthState.loading] during the operation.
  Future<void> signOut() async {
    try {
      _setState(AuthState.loading);

      await _authService.signOut();

      // State will be updated by _onAuthStateChanged
    } catch (e) {
      notifyListeners();
      rethrow;
    }
  }

  /// Sets the authentication state and notifies listeners.
  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }
}
