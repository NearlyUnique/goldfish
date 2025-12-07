import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:goldfish/core/auth/auth_exceptions.dart';
import 'package:goldfish/core/auth/auth_service.dart';
import 'package:goldfish/core/logging/app_logger.dart';

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
  String? _errorMessage;

  /// Current authentication state.
  AuthState get state => _state;

  /// Current authenticated user, or `null` if not authenticated.
  firebase_auth.User? get user => _user;

  /// Error message from the last authentication operation, or `null`.
  String? get errorMessage => _errorMessage;

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
    _errorMessage = null;
    notifyListeners();

    AppLogger.info({
      'event': 'auth_state_changed',
      'authenticated': user != null,
      'uid': user?.uid,
    });
  }

  /// Signs in with Google.
  ///
  /// Sets state to [AuthState.loading] during the operation.
  /// Throws [AuthException] if sign-in fails.
  Future<void> signInWithGoogle() async {
    try {
      _setState(AuthState.loading);
      _errorMessage = null;

      await _authService.signInWithGoogle();

      // State will be updated by _onAuthStateChanged
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _state = AuthState.unauthenticated;
      notifyListeners();
      rethrow;
    } on Exception catch (e) {
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      _state = AuthState.unauthenticated;
      notifyListeners();
      throw FirebaseAuthException(_errorMessage!, null);
    }
  }

  /// Signs out the current user.
  ///
  /// Sets state to [AuthState.loading] during the operation.
  Future<void> signOut() async {
    try {
      _setState(AuthState.loading);
      _errorMessage = null;

      await _authService.signOut();

      // State will be updated by _onAuthStateChanged
    } catch (e) {
      _errorMessage = 'Sign-out failed: ${e.toString()}';
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

