import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:goldfish/core/api/http_client.dart';
import 'package:goldfish/core/api/overpass_client.dart';
import 'package:goldfish/core/app_lifecycle_observer.dart';
import 'package:goldfish/core/auth/auth_notifier.dart';
import 'package:goldfish/core/auth/auth_service.dart';
import 'package:goldfish/core/auth/repositories/user_repository.dart';
import 'package:goldfish/core/firebase/firebase_service.dart';
import 'package:goldfish/core/location/location_service.dart';
import 'package:goldfish/core/logging/app_logger.dart';
import 'package:goldfish/core/router/app_router.dart';
import 'package:goldfish/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up global error handlers to catch and log all errors
  _setupErrorHandlers();

  AppLogger.logAppInitialization();

  // Initialize Firebase
  try {
    await FirebaseService.initialize();
  } on Exception catch (e) {
    AppLogger.error({'event': 'firebase_initialization_failed', 'error': e});
    // Continue app startup even if Firebase initialization fails
    // The app will show errors when trying to use Firebase features
  }

  // Run app in a zone to catch async errors
  runZonedGuarded(
    () {
      runApp(const MyApp());
    },
    (error, stackTrace) {
      AppLogger.error({
        'event': 'unhandled_async_error',
        'error': error,
        'stackTrace': stackTrace.toString(),
      });
      // In debug mode, also print to console for immediate visibility
      if (kDebugMode) {
        debugPrint('Unhandled async error: $error');
        debugPrint('Stack trace: $stackTrace');
      }
    },
  );
}

/// Sets up global error handlers for Flutter framework errors and platform errors.
///
/// This ensures all errors are caught and logged, even if they occur outside
/// of try-catch blocks. This is critical for diagnosing crashes that appear
/// to have no debug output.
void _setupErrorHandlers() {
  // Handle Flutter framework errors (e.g., widget build errors)
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error({
      'event': 'flutter_error',
      'exception': details.exception.toString(),
      'library': details.library,
      'stack': details.stack.toString(),
      'context': details.context?.toString(),
    });
    // In debug mode, also use the default handler which shows red screen
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };

  // Handle platform errors (e.g., native code errors)
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error({
      'event': 'platform_error',
      'error': error.toString(),
      'stackTrace': stack.toString(),
    });
    // In debug mode, also print to console
    if (kDebugMode) {
      debugPrint('Platform error: $error');
      debugPrint('Stack trace: $stack');
    }
    // Return true to indicate the error was handled
    return true;
  };

  // Custom error widget builder to show errors in the UI
  ErrorWidget.builder = (FlutterErrorDetails details) {
    AppLogger.error({
      'event': 'error_widget_built',
      'exception': details.exception.toString(),
      'library': details.library,
    });
    // In debug mode, show detailed error widget
    if (kDebugMode) {
      return ErrorWidget(details.exception);
    }
    // In release mode, show a user-friendly message
    return const Material(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Please restart the app',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  };
}

/// Main application widget.
///
/// Sets up the MaterialApp with theme configuration, navigation, and
/// authentication. Observes app lifecycle events and logs them.
class MyApp extends StatefulWidget {
  /// Creates a new [MyApp].
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLifecycleObserver _lifecycleObserver = AppLifecycleObserver();
  // Single Firestore instance created in main.dart and passed via dependency injection
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final AuthNotifier _authNotifier = AuthNotifier(
    authService: AuthService(
      firebaseAuth: firebase_auth.FirebaseAuth.instance,
      googleSignIn: GoogleSignIn(signInOption: SignInOption.standard),
      userRepository: UserRepository(firestore: _firestore),
    ),
  );
  // Services, clients, and repositories created in main.dart and passed via dependency injection
  late final LocationService _locationService = GeolocatorLocationService();
  late final HttpClient _httpClient = HttpPackageClient();
  late final OverpassClient _overpassClient = OverpassClient(
    httpClient: _httpClient,
  );
  late final AppRouter _router = AppRouter(
    authNotifier: _authNotifier,
    firestore: _firestore,
    locationService: _locationService,
    overpassClient: _overpassClient,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _authNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Goldfish',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router.router,
    );
  }
}
