import 'package:flutter/material.dart';
import 'package:goldfish/core/app_lifecycle_observer.dart';
import 'package:goldfish/core/auth/auth_notifier.dart';
import 'package:goldfish/core/firebase/firebase_service.dart';
import 'package:goldfish/core/logging/app_logger.dart';
import 'package:goldfish/core/router/app_router.dart';
import 'package:goldfish/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.logAppInitialization();

  // Initialize Firebase
  try {
    await FirebaseService.initialize();
  } on Exception catch (e) {
    AppLogger.error({
      'event': 'firebase_initialization_failed',
      'error': e.toString(),
    });
    // Continue app startup even if Firebase initialization fails
    // The app will show errors when trying to use Firebase features
  }

  runApp(const MyApp());
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
  late final AuthNotifier _authNotifier = AuthNotifier();
  late final AppRouter _router = AppRouter(authNotifier: _authNotifier);

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
