import 'package:flutter/material.dart';
import 'package:goldfish/core/app_lifecycle_observer.dart';
import 'package:goldfish/core/logging/app_logger.dart';
import 'package:goldfish/core/theme/app_theme.dart';
import 'package:goldfish/features/home/presentation/screens/home_screen.dart';

void main() {
  AppLogger.logAppInitialization();
  runApp(const MyApp());
}

/// Main application widget.
///
/// Sets up the MaterialApp with theme configuration and navigation.
/// Observes app lifecycle events and logs them.
class MyApp extends StatefulWidget {
  /// Creates a new [MyApp].
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLifecycleObserver _lifecycleObserver = AppLifecycleObserver();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goldfish',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
