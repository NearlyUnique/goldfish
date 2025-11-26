import 'package:flutter/material.dart';

/// Seed color for generating the color scheme.
/// Using a vibrant blue that works well in both light and dark themes.
const Color _seedColor = Color(0xFF1976D2);

/// Light theme configuration using Material 3.
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.light,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 57.0, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(fontSize: 45.0, fontWeight: FontWeight.bold),
    displaySmall: TextStyle(fontSize: 36.0, fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
    headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w500),
    titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
    titleSmall: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontSize: 16.0, height: 1.5),
    bodyMedium: TextStyle(fontSize: 14.0, height: 1.4),
    bodySmall: TextStyle(fontSize: 12.0, height: 1.4),
    labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w500),
  ),
  appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    filled: true,
  ),
);

/// Dark theme configuration using Material 3.
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.dark,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 57.0, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(fontSize: 45.0, fontWeight: FontWeight.bold),
    displaySmall: TextStyle(fontSize: 36.0, fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
    headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w500),
    titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
    titleSmall: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontSize: 16.0, height: 1.5),
    bodyMedium: TextStyle(fontSize: 14.0, height: 1.4),
    bodySmall: TextStyle(fontSize: 12.0, height: 1.4),
    labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w500),
  ),
  appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    filled: true,
  ),
);

/// Theme mode manager for handling theme switching.
///
/// This class provides a structure for managing theme mode (light/dark/system)
/// but does not include UI components. The UI for theme toggling will be
/// implemented in a later phase.
class ThemeModeManager {
  /// Current theme mode.
  ThemeMode _themeMode = ThemeMode.system;

  /// Get the current theme mode.
  ThemeMode get themeMode => _themeMode;

  /// Set the theme mode.
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
  }

  /// Toggle between light and dark themes.
  ///
  /// If current mode is system, switches to light.
  /// If current mode is light, switches to dark.
  /// If current mode is dark, switches to light.
  void toggleTheme() {
    switch (_themeMode) {
      case ThemeMode.system:
        _themeMode = ThemeMode.light;
        break;
      case ThemeMode.light:
        _themeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _themeMode = ThemeMode.light;
        break;
    }
  }
}
