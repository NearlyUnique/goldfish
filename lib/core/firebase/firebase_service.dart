import 'package:firebase_core/firebase_core.dart';
import 'package:goldfish/core/logging/app_logger.dart';

/// Service for initializing and managing Firebase.
///
/// Handles Firebase initialization on app startup and provides
/// error handling for initialization failures.
class FirebaseService {
  /// Initializes Firebase for the application.
  ///
  /// Should be called before [runApp] in [main].
  ///
  /// Throws [FirebaseException] if initialization fails.
  static Future<void> initialize() async {
    try {
      AppLogger.info({'event': 'firebase_initialization_start'});
      await Firebase.initializeApp();
      AppLogger.info({'event': 'firebase_initialization_success'});
    } on FirebaseException catch (e) {
      AppLogger.error({
        'event': 'firebase_initialization_failure',
        'code': e.code,
        'message': e.message,
      });
      rethrow;
    } catch (e) {
      AppLogger.error({
        'event': 'firebase_initialization_error',
        'error': e.toString(),
      });
      rethrow;
    }
  }
}

