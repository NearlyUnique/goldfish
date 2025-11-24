# Goldfish - Bootstrap Project Setup

## Overview

This document outlines the tasks required to create a minimal, viable Flutter application that can be built as an APK and side-loaded onto an Android device. This bootstrap phase establishes the project foundation without implementing actual features from the main outline.

## Goals

- Create a Flutter project structure following best practices
- Configure Android build for API level 33+ (Android 13+)
- Set up Material 3 theming with light/dark mode support
- Implement basic app structure with navigation placeholder
- Add structured logging using `dart:developer`
- Create a simple test that verifies app lifecycle (start/stop)
- Ensure the app builds a viable APK that can be side-loaded

## Tasks

### Task 1: Initialize Flutter Project
**Description**: Create a new Flutter project with proper structure.

**Requirements**:
- Initialize Flutter project in the workspace root
- Ensure Flutter SDK is available and configured
- Verify project structure follows Flutter conventions
- Set up proper `.gitignore` for Flutter projects

**Deliverables**:
- `pubspec.yaml` with basic dependencies
- Standard Flutter project structure (`lib/`, `test/`, `android/`, etc.)
- `.gitignore` file

---

### Task 2: Configure Android Build
**Description**: Configure Android build settings for Android 13+ (API level 33+).

**Note on Build System**: Gradle is the standard and required build system for Android in Flutter. There is no alternative - Flutter's Android tooling is built on Gradle. The `android/` directory contains Gradle build files that Flutter uses to compile and package the Android app.

**Requirements**:
- Set `minSdkVersion` to 33 (Android 13)
- Set `targetSdkVersion` to latest stable (or 33+)
- Configure `compileSdkVersion` appropriately
- Set up proper app name and package identifier
- Configure app icon placeholder
- Enable proper signing configuration for debug builds
- Ensure APK can be built and side-loaded

**Files to Modify**:
- `android/app/build.gradle`
- `android/app/src/main/AndroidManifest.xml`
- `android/build.gradle`

**Deliverables**:
- Android build configuration for API 33+
- Proper manifest with app metadata
- Debug signing configuration

---

### Task 3: Set Up Project Structure
**Description**: Create the basic folder structure using a domain-centric (feature-based) approach rather than technology-centric layers.

**Requirements**:
- Create domain-centric directory structure:
  - `lib/core/` - Shared utilities, constants, extensions, theme, logging
  - `lib/features/` - Feature-based organization (each feature is self-contained)
    - Each feature will have its own subdirectory (e.g., `visits/`, `places/`, `settings/`)
    - Within each feature: `data/`, `domain/`, `presentation/` as needed
  - `lib/main.dart` - App entry point
- For bootstrap phase, create minimal structure:
  - `lib/core/theme/` - Theme configuration
  - `lib/core/logging/` - Logging utilities
  - `lib/features/home/` - Home screen placeholder (minimal feature structure)
- Create placeholder files to establish structure
- Follow feature-based organization - each feature is self-contained with its own data/domain/presentation layers

**Example Structure**:
```
lib/
  core/
    theme/
    logging/
  features/
    home/
      presentation/
        screens/
  main.dart
```

**Deliverables**:
- Domain-centric directory structure
- Placeholder files with basic documentation
- Structure ready for feature-based development

---

### Task 4: Implement Material 3 Theming
**Description**: Set up Material 3 theming with light and dark mode support.

**Requirements**:
- Create theme configuration file in `lib/presentation/theme/`
- Use `ColorScheme.fromSeed()` for color generation
- Define light and dark themes
- Configure `ThemeData` with Material 3 components
- Set up theme mode management (light/dark/system)
- Apply theme to `MaterialApp`

**Files to Create**:
- `lib/core/theme/app_theme.dart`
- `lib/core/theme/app_colors.dart` (if needed)

**Deliverables**:
- Material 3 theme configuration
- Light and dark theme support
- Theme mode toggle capability (structure only, no UI yet)

---

### Task 5: Create Basic App Structure
**Description**: Implement minimal app structure with navigation placeholder.

**Requirements**:
- Create main entry point (`lib/main.dart`)
- Set up `MaterialApp` with theme configuration
- Create a simple home screen placeholder
- Add app bar with app name
- Display a simple message indicating bootstrap phase
- Ensure app runs without errors

**Files to Create**:
- `lib/main.dart`
- `lib/features/home/presentation/screens/home_screen.dart` (placeholder)

**Deliverables**:
- Working Flutter app that launches
- Basic home screen with Material 3 styling
- App bar with proper theming

---

### Task 6: Implement Structured Logging
**Description**: Set up structured logging using `dart:developer` for app lifecycle tracking.

**Requirements**:
- Create logging utility in `lib/core/`
- Use `log()` function from `dart:developer`
- Log app lifecycle events:
  - App initialization
  - App start
  - App stop/pause
  - App resume
- Use appropriate log levels (info, warning, error)
- Include timestamps and context in log messages

**Files to Create**:
- `lib/core/logging/app_logger.dart`

**Deliverables**:
- Logging utility class
- Lifecycle logging in main app
- Log messages visible in debug console

---

### Task 7: Add App Lifecycle Logging
**Description**: Integrate logging into app lifecycle to track start/stop events.

**Requirements**:
- Use `WidgetsBindingObserver` to observe app lifecycle
- Log when app enters foreground (started)
- Log when app enters background (stopped/paused)
- Log when app resumes
- Use structured logging from Task 6

**Files to Modify**:
- `lib/main.dart` or create `lib/core/app_lifecycle_observer.dart`

**Deliverables**:
- App lifecycle observer
- Log messages for app start/stop events
- Logs visible in `adb logcat` or Flutter console

---

### Task 8: Create Basic Test Suite
**Description**: Set up test infrastructure with a simple test that verifies app can start.

**Requirements**:
- Create test file in `test/` directory
- Write a test that uses `assert(true)` to verify test framework works
- Add logging in test to verify test execution
- Test should log "App test started" and "App test completed"
- Ensure tests can be run with `flutter test`

**Files to Create**:
- `test/app_test.dart` or `test/bootstrap_test.dart`

**Test Structure**:
```dart
void main() {
  test('App bootstrap test', () {
    // Log test start
    // Assert true
    // Log test completion
  });
}
```

**Deliverables**:
- Working test file
- Test that passes with `assert(true)`
- Logging in test output

---

### Task 9: Configure Analysis Options
**Description**: Set up Dart analysis options following Flutter best practices.

**Requirements**:
- Create `analysis_options.yaml` in project root
- Include `flutter_lints` package
- Configure recommended lint rules
- Ensure code follows Dart style guide

**Files to Create**:
- `analysis_options.yaml`

**Deliverables**:
- Analysis configuration file
- Linting rules enabled
- Code style enforcement

---

### Task 10: Update Dependencies
**Description**: Add necessary dependencies to `pubspec.yaml`.

**Requirements**:
- Add `flutter_lints` as dev dependency
- Ensure all dependencies are compatible
- Run `flutter pub get` to resolve dependencies
- Verify no dependency conflicts

**Files to Modify**:
- `pubspec.yaml`

**Deliverables**:
- Updated `pubspec.yaml` with required dependencies
- Dependencies resolved and locked

---

### Task 11: Build APK and Verify
**Description**: Build a release APK and verify it can be side-loaded.

**Requirements**:
- Build release APK using `flutter build apk`
- Verify APK is generated in `build/app/outputs/flutter-apk/`
- Test APK can be installed on Android device (via `adb install` or manual)
- Verify app launches on device
- Verify logging appears in `adb logcat`
- Document build and installation process

**Commands to Run**:
```bash
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
adb logcat | grep -i goldfish
```

**Deliverables**:
- Release APK file
- Verification that APK installs and runs
- Log output showing app lifecycle events

---

### Task 12: Create Bootstrap Documentation
**Description**: Document the bootstrap setup and next steps.

**Note**: A skeleton `README.md` with tooling setup instructions should be created before starting implementation (see project root).

**Requirements**:
- Update `README.md` in project root with:
  - Project structure documentation
  - How to build and install APK
  - How to run tests
  - How to view logs
  - Next steps for feature implementation

**Files to Update**:
- `README.md` (should already exist from pre-bootstrap setup)

**Deliverables**:
- Complete project documentation
- Build and installation instructions
- Development workflow documentation

---

## Success Criteria

The bootstrap project is complete when:

1. ✅ Flutter project initializes without errors
2. ✅ Android build configured for API 33+
3. ✅ App structure follows planned architecture
4. ✅ Material 3 theming with light/dark mode is configured
5. ✅ App launches and displays a basic home screen
6. ✅ Structured logging is implemented and working
7. ✅ App lifecycle events are logged (start/stop)
8. ✅ Test suite exists with `assert(true)` test that passes
9. ✅ Test includes logging that appears in test output
10. ✅ Release APK can be built successfully
11. ✅ APK can be side-loaded onto Android device
12. ✅ App runs on device and logs are visible in `adb logcat`
13. ✅ All code follows Flutter/Dart best practices
14. ✅ Analysis options configured and passing

## Verification Checklist

Before considering bootstrap complete, verify:

- [ ] `flutter doctor` shows no critical issues
- [ ] `flutter analyze` passes with no errors
- [ ] `flutter test` runs and all tests pass
- [ ] `flutter build apk --release` completes successfully
- [ ] APK installs on Android 13+ device
- [ ] App launches on device
- [ ] Logs appear in `adb logcat` showing app lifecycle
- [ ] Test output shows logging messages
- [ ] Project structure matches planned architecture
- [ ] Theme switches between light/dark modes (if toggle implemented)

## Next Steps

After bootstrap completion:

1. Begin Phase 1 implementation (see `00_outline.md`)
2. Set up local database (SQLite)
3. Implement data models
4. Create first feature (Record a New Visit)

## Notes

- This bootstrap phase does NOT implement any features from the main outline
- Focus is on establishing a solid foundation
- All code should follow Flutter best practices from `.cursor/rules/flutter.mdc`
- Keep dependencies minimal - only add what's necessary for bootstrap
- Ensure all code is properly formatted and linted

