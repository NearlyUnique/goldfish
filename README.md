# Goldfish - Visit Tracking App

A mobile app (Android 13+) designed to make it easy to record visits to pubs, bars, restaurants, and places of interest.

## Project Status

🚧 **Bootstrap Phase** - Project foundation is being established. See `prompts/01_bootstrap_project.md` for bootstrap tasks.

## Tooling Setup

Before you can build and run this project, you need to set up the following tools:

### Required Tools

#### 1. Flutter SDK

**Installation**:
- **Linux/WSL**: 
  ```bash
  # Download Flutter SDK
  cd ~/development
  git clone https://github.com/flutter/flutter.git -b stable
  export PATH="$PATH:`pwd`/flutter/bin"
  
  # Add to your shell profile (~/.zshrc or ~/.bashrc)
  echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc
  source ~/.zshrc
  ```

- **macOS**: 
  ```bash
  # Using Homebrew
  brew install --cask flutter
  ```

- **Windows**: Download from [flutter.dev](https://flutter.dev/docs/get-started/install/windows)

**Verify Installation**:
```bash
flutter doctor
```

**Expected Output**: Should show Flutter SDK installed. Address any critical issues (marked with ❌).

#### 2. Android Development Tools

**Android Studio** (Recommended):
- Download from [developer.android.com/studio](https://developer.android.com/studio)
- Install Android SDK (API level 33+)
- Install Android SDK Platform-Tools
- Accept Android licenses: `flutter doctor --android-licenses`

**Android SDK Command Line Tools** (Alternative):
```bash
# Install SDK via command line
# See: https://developer.android.com/studio#command-tools
```

**Verify**:
```bash
flutter doctor
# Should show Android toolchain configured
```

#### 3. Android Device or Emulator

**Physical Device**:
- Enable Developer Options on Android device
- Enable USB Debugging
- Connect via USB
- Verify: `adb devices` should show your device

**Android Emulator**:
- Create via Android Studio AVD Manager
- Or via command line:
  ```bash
  flutter emulators --create
  flutter emulators --launch <emulator_id>
  ```

#### 4. ADB (Android Debug Bridge)

**Installation**:
- Usually included with Android SDK Platform-Tools
- Verify: `adb version`

**For WSL/Linux**:
```bash
# If using WSL with Windows ADB
# Install adb on Windows, then in WSL:
export ADB_SERVER_SOCKET=tcp:127.0.0.1:5037
```

#### 5. Git (for version control)

**Installation**:
- **Linux/WSL**: `sudo apt install git`
- **macOS**: `brew install git` or included with Xcode
- **Windows**: Download from [git-scm.com](https://git-scm.com/)

**Verify**: `git --version`

### Optional but Recommended Tools

#### Code Editor
- **VS Code** with Flutter extension
- **Android Studio** with Flutter plugin
- **Cursor** (current editor)

#### Additional Tools
- **Dart SDK**: Included with Flutter, but can be installed separately
- **Java Development Kit (JDK)**: Required for Android builds (usually auto-installed with Android Studio)

### Verification Checklist

Before starting development, verify all tools are set up:

```bash
# Run Flutter doctor to check everything
flutter doctor -v

# Check Flutter version (should be stable channel)
flutter --version

# Check connected devices
flutter devices

# Verify ADB can see devices
adb devices
```

**Expected `flutter doctor` output**:
- ✅ Flutter (Channel stable)
- ✅ Android toolchain (Android SDK)
- ✅ Android Studio (or VS Code)
- ⚠️  Any warnings are usually fine, but address ❌ errors

### Troubleshooting

**Flutter doctor shows issues**:
- Follow the suggested commands in the output
- For Android licenses: `flutter doctor --android-licenses`
- For missing tools: Install via Android Studio SDK Manager

**ADB not finding device (WSL)**:
- Install ADB on Windows host
- In WSL: `export ADB_SERVER_SOCKET=tcp:127.0.0.1:5037`
- Or use `adb.exe` from Windows path

**Build errors**:
- Ensure Android SDK API 33+ is installed
- Check `android/app/build.gradle` for correct SDK versions
- Run `flutter clean` and `flutter pub get`

## Project Structure

```
lib/
  core/           # Shared utilities, theme, logging
    theme/        # Material 3 theme configuration
    logging/      # Logging utilities
  features/       # Feature-based organization
    home/         # Home feature (placeholder)
      presentation/
        screens/
  main.dart       # App entry point
```

## Getting Started

Once tooling is set up:

1. **Clone/Initialize Project**:
   ```bash
   # If not already initialized
   flutter create .
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run on Device/Emulator**:
   ```bash
   flutter run
   ```

4. **Run Tests**:
   ```bash
   flutter test
   ```

5. **Build APK**:
   ```bash
   flutter build apk --release
   ```

6. **Install APK on Device**:
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

## Development Workflow

### Running the App
```bash
# Run in debug mode
flutter run

# Run in release mode
flutter run --release

# Run on specific device
flutter run -d <device_id>
```

### Viewing Logs
```bash
# Flutter logs
flutter logs

# Android logs (filtered)
adb logcat | grep -i goldfish

# All Android logs
adb logcat
```

### Testing
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/bootstrap_test.dart
```

### Building
```bash
# Build APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Build with specific flavor (if configured)
flutter build apk --release --flavor production
```

## Documentation

- **Project Overview**: See `prompts/00_outline.md`
- **Bootstrap Tasks**: See `prompts/01_bootstrap_project.md`
- **Flutter Best Practices**: See `.cursor/rules/flutter.mdc`

## Next Steps

After bootstrap completion:
1. Implement Phase 1 features (see `prompts/00_outline.md`)
2. Set up local database (SQLite)
3. Implement data models
4. Create first feature (Record a New Visit)

## License

[To be determined]

