import 'dart:developer' as developer;

/// Centralized logging utility for the application.
///
/// Provides structured logging using [developer.log] with key-value pairs.
/// All logs have a name and key-value pairs. There are two log levels:
/// [info] for informational entries and [error] for error entries.
class AppLogger {
  /// Default log name for application logs.
  static const String _logName = 'goldfish.app';

  /// Logs an informational entry with key-value pairs.
  ///
  /// Use for general information about app state and flow.
  ///
  /// [data] contains the key-value pairs to log.
  static void info(Map<String, dynamic> data) {
    final message = _formatKeyValuePairs(data);
    developer.log(
      message,
      name: _logName,
      level: 800, // INFO level
    );
  }

  /// Logs an error entry with key-value pairs.
  ///
  /// Use for error conditions that need attention.
  ///
  /// [data] contains the key-value pairs to log.
  static void error(Map<String, dynamic> data) {
    final message = _formatKeyValuePairs(data);
    developer.log(
      '❌ [ERROR] $message',
      name: _logName,
      level: 1000, // ERROR level
    );
  }

  /// Formats key-value pairs into a log message string.
  static String _formatKeyValuePairs(Map<String, dynamic> data) {
    final entries = data.entries.map((e) => '${e.key}=${e.value}');
    return entries.join(' ');
  }

  /// Logs app initialization.
  ///
  /// Call this when the app is initializing.
  static void logAppInitialization() {
    info({'event': 'app_initialization'});
  }

  /// Logs app start event.
  ///
  /// Call this when the app starts or enters the foreground.
  static void logAppStart() {
    info({'event': 'app_start'});
  }

  /// Logs app stop/pause event.
  ///
  /// Call this when the app stops or enters the background.
  static void logAppStop() {
    info({'event': 'app_stop'});
  }

  /// Logs app resume event.
  ///
  /// Call this when the app resumes from a paused state.
  static void logAppResume() {
    info({'event': 'app_resume'});
  }
}
