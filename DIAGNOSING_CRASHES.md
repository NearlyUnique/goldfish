# Diagnosing App Crashes

When the app crashes on an emulator or device without visible debug output, use these diagnostic steps.

## 1. Check Flutter Logs

### Using Flutter CLI

Run the app with verbose logging:

```bash
flutter run --verbose
```

This will show detailed output including:
- App initialization
- Error messages
- Stack traces
- Native platform logs

### Using VS Code Debug Console

When running from VS Code with the debugger attached, check the Debug Console for:
- Error messages logged via `AppLogger`
- Flutter framework errors
- Stack traces

## 2. Check Android Logcat

For Android emulators/devices, use `adb logcat` to view system logs:

```bash
# View all logs
adb logcat

# Filter for Flutter/Dart logs only
adb logcat | grep -E "(flutter|dart|goldfish)"

# Filter for errors only
adb logcat *:E

# Clear log buffer and watch for new entries
adb logcat -c && adb logcat

# Save logs to a file
adb logcat > crash_logs.txt
```

### Useful Logcat Filters

```bash
# Flutter framework errors
adb logcat | grep -i "flutter"

# Your app's logs (goldfish.app)
adb logcat | grep "goldfish.app"

# All errors
adb logcat *:E

# Combined filter for your app
adb logcat | grep -E "(goldfish|flutter|ERROR)"
```

## 3. Check Device-Specific Logs

### Android Emulator

```bash
# List connected devices
adb devices

# View logs for specific device
adb -s emulator-5554 logcat

# View crash logs
adb logcat | grep -i "fatal\|crash\|exception"
```

### iOS Simulator

```bash
# View system logs
xcrun simctl spawn booted log stream --level=error

# View crash reports
ls ~/Library/Logs/DiagnosticReports/
```

## 4. Common Crash Causes

### Firebase Initialization Issues

- Check if `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is properly configured
- Verify Firebase project settings match your app's package name
- Check network connectivity (Firebase needs internet on first launch)

### Permission Issues

- Location permissions may cause crashes if not handled properly
- Check AndroidManifest.xml for required permissions

### Null Safety Issues

- Dart null safety violations can cause crashes
- Run `flutter analyze` to check for static analysis issues

### Memory Issues

- Large images or memory leaks can cause crashes
- Check for proper disposal of controllers and listeners

## 5. Enable Additional Debugging

### Verbose Mode

Run with maximum verbosity:

```bash
flutter run --verbose --debug
```

### Enable Assertions

The app already has error handlers that log to `AppLogger`. Check the debug console for entries like:
- `event: flutter_error`
- `event: platform_error`
- `event: unhandled_async_error`
- `event: error_widget_built`

## 6. Check Recent Changes

If the crash started after a recent change:

1. Review recent commits: `git log --oneline -10`
2. Check for syntax errors: `flutter analyze`
3. Run tests: `flutter test`
4. Try reverting recent changes to isolate the issue

## 7. Reproduce the Crash

1. Note the exact steps that cause the crash
2. Check if it happens on app startup or during a specific action
3. Try on a different emulator/device to rule out device-specific issues
4. Check if it happens in release mode vs debug mode

## 8. Error Handler Coverage

The app now has comprehensive error handlers in `main.dart`:

- **FlutterError.onError**: Catches Flutter framework errors (widget build errors, etc.)
- **PlatformDispatcher.instance.onError**: Catches platform/native errors
- **runZonedGuarded**: Catches unhandled async errors
- **ErrorWidget.builder**: Custom error widget for UI errors

All errors are logged via `AppLogger` with structured data including:
- Event type
- Exception details
- Stack traces
- Context information

## 9. Quick Diagnostic Checklist

- [ ] Run `flutter doctor` to check for environment issues
- [ ] Run `flutter clean && flutter pub get` to reset dependencies
- [ ] Check `flutter analyze` for static analysis errors
- [ ] Review `adb logcat` output for Android crashes
- [ ] Check VS Code Debug Console for logged errors
- [ ] Verify Firebase configuration files are present
- [ ] Check if crash occurs on app startup or during specific actions
- [ ] Try running on a different emulator/device

## 10. Getting Help

When reporting a crash, include:

1. **Error logs**: Output from `adb logcat` or Debug Console
2. **Steps to reproduce**: What actions led to the crash
3. **Environment**:
   - Flutter version: `flutter --version`
   - Device/emulator details
   - OS version
4. **Recent changes**: What was modified before the crash started
5. **Error handler output**: Any logs from `AppLogger` showing error events

