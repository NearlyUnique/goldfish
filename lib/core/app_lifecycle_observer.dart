import 'package:flutter/widgets.dart';
import 'package:goldfish/core/logging/app_logger.dart';

/// Observes and logs application lifecycle events.
///
/// Uses [WidgetsBindingObserver] to track when the app enters foreground,
/// background, or resumes from a paused state.
class AppLifecycleObserver extends WidgetsBindingObserver {
  /// Creates a new [AppLifecycleObserver].
  AppLifecycleObserver();

  AppLifecycleState? _previousState;
  bool _hasLoggedStart = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // Log app start on first resume, otherwise log resume
        if (!_hasLoggedStart) {
          AppLogger.logAppStart();
          _hasLoggedStart = true;
        } else if (_previousState == AppLifecycleState.paused ||
            _previousState == AppLifecycleState.inactive) {
          AppLogger.logAppResume();
        }
        break;
      case AppLifecycleState.inactive:
        // App is transitioning between states, not typically logged
        break;
      case AppLifecycleState.paused:
        AppLogger.logAppStop();
        break;
      case AppLifecycleState.detached:
        // App is being terminated, not typically logged
        break;
      case AppLifecycleState.hidden:
        // App is hidden (new in Flutter 3.13+), treat as paused
        AppLogger.logAppStop();
        break;
    }

    _previousState = state;
  }
}

