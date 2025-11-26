import 'package:flutter/material.dart';
import 'package:goldfish/core/theme/app_theme.dart';
import 'package:goldfish/features/home/presentation/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

/// Main application widget.
///
/// Sets up the MaterialApp with theme configuration and navigation.
class MyApp extends StatelessWidget {
  /// Creates a new [MyApp].
  const MyApp({super.key});

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
