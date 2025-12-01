import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:goldfish/core/auth/auth_exceptions.dart';
import 'package:goldfish/core/auth/models/user_model.dart';
import 'package:goldfish/core/auth/repositories/user_repository.dart';
import 'package:goldfish/core/logging/app_logger.dart';

/// Service for handling authentication operations.
///
/// Provides methods for Google Sign-In, sign-out, and authentication
/// state management.
class AuthService {
  /// Creates a new [AuthService].
  AuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    UserRepository? userRepository,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn(),
       _userRepository = userRepository ?? UserRepository();

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
  /// Throws [AuthException] if sign-in fails.
  Future<firebase_auth.User> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        AppLogger.info({'event': 'google_sign_in_cancelled'});
        throw const GoogleSignInCancelledException();
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      final user = userCredential.user;
      if (user == null) {
        throw const FirebaseAuthException(
          'Sign-in succeeded but no user returned',
          'no-user',
        );
      }

      // Create or update user document in Firestore
      await _createOrUpdateUserDocument(user);

      AppLogger.info({'event': 'google_sign_in', 'uid': user.uid});

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      AppLogger.error({
        'event': 'google_sign_in',
        'code': e.code,
        'message': e.message,
      });
      throw FirebaseAuthException(
        e.message ?? 'Firebase authentication failed',
        e.code,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      AppLogger.error({'event': 'google_sign_in', 'error': e.toString()});

      // Handle specific Google Sign-In errors
      if (e.toString().contains('network_error') ||
          e.toString().contains('NetworkError')) {
        throw const GoogleSignInNetworkException();
      }

      if (e.toString().contains('sign_in_canceled') ||
          e.toString().contains('SIGN_IN_CANCELLED')) {
        throw const GoogleSignInCancelledException();
      }

      throw FirebaseAuthException('Sign-in failed: ${e.toString()}', null);
    }
  }

  /// Signs out the current user.
  ///
  /// Signs out from both Firebase and Google Sign-In.
  Future<void> signOut() async {
    try {
      await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);

      AppLogger.info({'event': 'sign_out'});
    } catch (e) {
      AppLogger.error({'event': 'sign_out', 'error': e.toString()});
      rethrow;
    }
  }

  /// Creates or updates a user document in Firestore.
  Future<void> _createOrUpdateUserDocument(
    firebase_auth.User firebaseUser,
  ) async {
    try {
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
    } on Exception catch (e) {
      // Log error but don't fail sign-in if user document creation fails
      AppLogger.error({
        'event': 'user_document_creation_error',
        'uid': firebaseUser.uid,
        'error': e.toString(),
      });
    }
  }
}
