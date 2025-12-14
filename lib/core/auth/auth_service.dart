import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:goldfish/core/auth/auth_exceptions.dart';
import 'package:goldfish/core/auth/models/user_model.dart';
import 'package:goldfish/core/auth/repositories/user_repository.dart';

/// Service for handling authentication operations.
///
/// Provides methods for Google Sign-In, sign-out, and authentication
/// state management.
class AuthService {
  /// Creates a new [AuthService].
  AuthService({
    required firebase_auth.FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    required UserRepository userRepository,
  }) : _firebaseAuth = firebaseAuth,
       _googleSignIn = googleSignIn,
       _userRepository = userRepository;

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final UserRepository _userRepository;

  /// Stream of authentication state changes.
  ///
  /// Emits the current [firebase_auth.User] when signed in, or `null` when
  /// signed out.
  Stream<firebase_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  /// Gets the current authenticated user, or `null` if not signed in.
  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  /// Signs in with Google.
  ///
  /// Returns the authenticated [firebase_auth.User] on success.
  /// Throws [SignInCancelledException] if the user cancels.
  /// Throws [AuthException] if sign-in fails.
  Future<firebase_auth.User> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw const SignInCancelledException('google');
      }

      // Create Firebase credential from Google authentication
      final credential = await _createFirebaseCredential(googleUser);

      // Sign in to Firebase with the Google credential
      final user = await _signInWithCredential(credential);

      // Create or update user document in Firestore
      await _createOrUpdateUserDocument(user);

      return user;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthenticationException('firebase', 'auth_error', code: e.code);
    } on UserDataException {
      throw const AuthenticationException(
        'firestore',
        'user_document_creation_failed',
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw const AuthenticationException('google', 'sign_in_unexpected_error');
    }
  }

  /// Creates a Firebase credential from a Google Sign-In account.
  Future<firebase_auth.AuthCredential> _createFirebaseCredential(
    GoogleSignInAccount googleUser,
  ) async {
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    return firebase_auth.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
  }

  /// Signs in to Firebase with the given credential.
  Future<firebase_auth.User> _signInWithCredential(
    firebase_auth.AuthCredential credential,
  ) async {
    final userCredential = await _firebaseAuth.signInWithCredential(credential);

    final user = userCredential.user;
    if (user == null) {
      throw const AuthenticationException(
        'firebase',
        'auth_no_user',
        code: 'no-user',
      );
    }

    return user;
  }

  /// Handles PlatformException from Google Sign-In.
  AuthException _handlePlatformException(PlatformException e) {
    switch (e.code) {
      case 'sign_in_canceled':
        return const SignInCancelledException('google');
      case 'sign_in_failed':
        // Check the error message for more specific error types
        final message = e.message ?? '';
        if (message.contains('network') || message.contains('Network')) {
          return const SignInNetworkException('google');
        }
        return AuthenticationException(
          'google',
          'sign_in_failed',
          code: e.code,
        );
      default:
        return AuthenticationException(
          'google',
          'sign_in_platform_error',
          code: e.code,
        );
    }
  }

  /// Signs out the current user.
  ///
  /// Signs out from both Firebase and Google Sign-In.
  Future<void> signOut() async {
    await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
  }

  /// Creates or updates a user document in Firestore.
  ///
  /// Throws [UserDataException] if the operation fails.
  Future<void> _createOrUpdateUserDocument(
    firebase_auth.User firebaseUser,
  ) async {
    final now = DateTime.now();

    // Check if user already exists
    final existingUser = await _userRepository.getUser(firebaseUser.uid);

    final userModel = UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      createdAt: existingUser?.createdAt ?? now,
      updatedAt: now,
    );

    await _userRepository.createOrUpdateUser(userModel);
  }
}
