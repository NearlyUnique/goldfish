# Goldfish - Visit Tracking App

A mobile app (Android 13+) designed to make it easy to record visits to pubs, bars, restaurants, and places of interest.

## Project Status

🚧 **Bootstrap Phase** - Project foundation is being established. See `prompts/01_bootstrap_project.md` for bootstrap tasks.

## Version Requirements

- **Flutter SDK**: 3.24.0 (stable channel)
- **Dart SDK**: Included with Flutter (3.4.0+)
- **Android SDK**: API Level 33+ (Android 13+)
- **Java JDK**: 17+ (required for Android builds)

Verify your Flutter version:
```bash
flutter --version
```

If you need to switch to the correct Flutter version:
```bash
flutter channel stable
flutter upgrade
```

## Tooling Setup

Before you can build and run this project, you need to set up the following tools:

### Required Tools

#### 1. Flutter SDK

**Installation**:
- **WSL2 (Windows Subsystem for Linux)**:
  ```bash
  # Update system packages
  sudo apt update && sudo apt upgrade -y

  # Install required dependencies
  sudo apt install -y curl git unzip xz-utils zip libglu1-mesa

  # Create development directory (optional, can use any location)
  mkdir -p ~/development
  cd ~/development

  # Download Flutter SDK
  git clone https://github.com/flutter/flutter.git -b stable

  # Add Flutter to PATH for current session
  export PATH="$PATH:$HOME/development/flutter/bin"

  # Add to your shell profile permanently
  # For zsh (default in many WSL2 setups):
  echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc
  source ~/.zshrc

  # For bash:
  # echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.bashrc
  # source ~/.bashrc
  ```

- **macOS**:
  ```bash
  # Using Homebrew
  brew install --cask flutter
  ```

- **Windows (Native)**: Download from [flutter.dev](https://flutter.dev/docs/get-started/install/windows)

**Verify Installation**:
```bash
flutter doctor
```

**Expected Output**: Should show Flutter SDK installed. Address any critical issues (marked with ❌).

#### 2. Android Development Tools

**For WSL2**:

**Option A: Android Studio on Windows (Recommended for WSL2)**:
- Install Android Studio on your Windows host (not in WSL2)
- In Android Studio, go to **Tools → SDK Manager** and install:
  - **SDK Platforms** tab: Select **Android 13.0 (Tiramisu)** - API Level 33
    - Install the base platform package (you don't need the "Google APIs" or extension packages for basic Flutter development)
  - **SDK Tools** tab: Select:
    - Android SDK Platform-Tools
    - Android SDK Build-Tools (latest 33.x version)
- Set environment variable in WSL2 to point to Windows Android SDK:
  ```bash
  # Add to ~/.zshrc or ~/.bashrc
  # Replace <username> with your Windows username
  export ANDROID_HOME="/mnt/c/Users/<username>/AppData/Local/Android/Sdk"
  export PATH="$PATH:$ANDROID_HOME/platform-tools"
  export PATH="$PATH:$ANDROID_HOME/tools"
  export PATH="$PATH:$ANDROID_HOME/tools/bin"
  source ~/.zshrc  # or ~/.bashrc
  ```
- Accept Android licenses:
  ```bash
  flutter doctor --android-licenses
  # Or manually: $ANDROID_HOME/tools/bin/sdkmanager --licenses
  ```

**Option B: Android SDK Command Line Tools in WSL2**:
```bash
# Install Java Development Kit (required for Android SDK)
sudo apt install -y openjdk-17-jdk

# Set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.zshrc

# Create Android SDK directory
mkdir -p ~/Android/Sdk
cd ~/Android/Sdk

# Download command line tools
wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
unzip commandlinetools-linux-9477386_latest.zip
mkdir -p cmdline-tools/latest
mv cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true
rm commandlinetools-linux-9477386_latest.zip

# Set ANDROID_HOME
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
echo 'export ANDROID_HOME="$HOME/Android/Sdk"' >> ~/.zshrc
echo 'export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"' >> ~/.zshrc
echo 'export PATH="$PATH:$ANDROID_HOME/platform-tools"' >> ~/.zshrc
source ~/.zshrc

# Install required SDK components
# For Flutter development, you need:
# - platform-tools: ADB and other essential tools
# - platforms;android-33: Android 13 (API level 33) platform (base package only)
# - build-tools;33.0.0: Build tools for compiling Android apps
# Note: The "ext4" and "ext5" packages are Google Play services extensions
#       and are NOT required for basic Flutter development
sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

# Optional: List available packages to see all options
# sdkmanager --list | grep android-33

# Accept licenses
yes | sdkmanager --licenses
```

**Package Explanation**:
- `platforms;android-33`: Base Android 13 platform (required)
- `platforms;android-33-ext4` / `platforms;android-33-ext5`: Google Play services extensions (optional, only needed if using Google Play services)
- `build-tools;33.0.0`: Build tools for compiling Android apps (required)
- `platform-tools`: ADB and other essential tools (required)

**For Flutter development, you only need the base `platforms;android-33` package, not the extension packages.**

**Verify**:
```bash
flutter doctor
# Should show Android toolchain configured
```

#### 3. Android Device or Emulator

**Physical Device (WSL2)**:
- Enable Developer Options on Android device
- Enable USB Debugging
- Connect device via USB to Windows host
- **WSL2 Setup**: Install ADB on Windows, then connect from WSL2:
  ```bash
  # On Windows: Install ADB (usually via Android Studio or Platform Tools)
  # In WSL2: Configure ADB to use Windows ADB server
  export ADB_SERVER_SOCKET=tcp:127.0.0.1:5037
  echo 'export ADB_SERVER_SOCKET=tcp:127.0.0.1:5037' >> ~/.zshrc

  # Or use Windows ADB directly
  alias adb='/mnt/c/Users/<username>/AppData/Local/Android/Sdk/platform-tools/adb.exe'
  ```
- Verify: `adb devices` should show your device

**Android Emulator (WSL2)**:
- **Recommended**: Run emulator on Windows host, connect from WSL2
  - Create AVD in Android Studio on Windows
  - Start emulator from Windows
  - WSL2 can connect to it via ADB (see above)
- **Alternative**: Use emulator in WSL2 (requires additional setup):
  ```bash
  # Note: Emulator performance in WSL2 may be limited
  # Consider using Windows-hosted emulator instead
  flutter emulators --create
  flutter emulators --launch <emulator_id>
  ```

#### 4. ADB (Android Debug Bridge)

**For WSL2**:

**Option A: Use Windows ADB (Recommended)**:
```bash
# Set up ADB to connect to Windows ADB server
export ADB_SERVER_SOCKET=tcp:127.0.0.1:5037
echo 'export ADB_SERVER_SOCKET=tcp:127.0.0.1:5037' >> ~/.zshrc
source ~/.zshrc

# Create alias for Windows ADB (optional, for convenience)
# Replace <username> with your Windows username
alias adb='/mnt/c/Users/<username>/AppData/Local/Android/Sdk/platform-tools/adb.exe'
echo 'alias adb="/mnt/c/Users/<username>/AppData/Local/Android/Sdk/platform-tools/adb.exe"' >> ~/.zshrc

# Verify: adb version
```

**Option B: Use WSL2 ADB** (if Android SDK installed in WSL2):
- ADB is included with Android SDK Platform-Tools
- Verify: `adb version`

**Important for WSL2**: Ensure ADB server is running on Windows:
- Start ADB server on Windows: `adb.exe start-server`
- Or start it automatically when Windows starts

#### 5. Git (for version control)

**Installation**:
- **WSL2**:
  ```bash
  sudo apt update
  sudo apt install -y git
  ```
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
- **Java Development Kit (JDK)**: Required for Android builds
  - **WSL2**: Install via `sudo apt install -y openjdk-17-jdk`
  - Set `JAVA_HOME` environment variable (see Android SDK setup above)

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
- For missing tools: Install via Android Studio SDK Manager (on Windows) or command line tools (in WSL2)

**Android toolchain not found**:
- Symptom: `✗ Unable to locate Android SDK`
- Fix (Windows-hosted SDK):
  ```bash
  # Install Android Studio on Windows, then inside WSL2:
  win_user=<username>
  flutter config --android-sdk /mnt/c/Users/$win_user/AppData/Local/Android/Sdk
  export ANDROID_HOME=/mnt/c/Users/$win_user/AppData/Local/Android/Sdk
  echo "export ANDROID_HOME=/mnt/c/Users/$win_user/AppData/Local/Android/Sdk" >> ~/.zshrc
  ```

Also

```bash
sdkmanager --install 'platforms;android-36'
sdkmanager --install 'build-tools;28.0.3'
```

- Fix (WSL2-managed SDK):
  ```bash
  # After running the sdkmanager steps above:
  flutter config --android-sdk $HOME/Android/Sdk
  export ANDROID_HOME=$HOME/Android/Sdk
  echo 'export ANDROID_HOME=$HOME/Android/Sdk' >> ~/.zshrc
  ```
- Re-run `flutter doctor` to confirm the Android toolchain is detected.

**Chrome not found (web builds)**:
- Symptom: `✗ Chrome - develop for the web (Cannot find Chrome executable)`
- Install Chrome or Chromium in WSL2 (pick one):
  ```bash
  # Option 1: Google Chrome stable
  wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo apt install -y ./google-chrome-stable_current_amd64.deb

  # Option 2: Chromium (open-source build)
  sudo apt update
  sudo apt install -y chromium-browser
  ```
- Point Flutter to the installed browser if needed:
Note use path from WSL2, e.g.

```bash
export CHROME_EXECUTABLE="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"
```

  ```bash
  export CHROME_EXECUTABLE=/usr/bin/google-chrome
  # or
  export CHROME_EXECUTABLE=/usr/bin/chromium-browser
  echo 'export CHROME_EXECUTABLE=/usr/bin/google-chrome' >> ~/.zshrc
  ```

**Linux desktop toolchain incomplete**:
- Symptom: `✗ clang++`, `✗ ninja`, or `Unable to access driver information using 'eglinfo'`
- Install required build tools and GPU diagnostics:
  ```bash
  sudo apt update
  sudo apt install -y build-essential clang ninja-build libgtk-3-dev \
                      liblzma-dev pkg-config libglu1-mesa mesa-utils
  ```
- If `eglinfo` still fails, run `sudo apt install -y mesa-utils` and verify graphics drivers with `eglinfo`.
- After installing packages, rerun `flutter doctor` to ensure the Linux toolchain passes.

**ADB not finding device (WSL2)**:
- Ensure ADB server is running on Windows: `adb.exe start-server` (run in Windows PowerShell/CMD)
- In WSL2: `export ADB_SERVER_SOCKET=tcp:127.0.0.1:5037`
- Verify Windows firewall allows port 5037
- Try using Windows ADB directly: `/mnt/c/Users/<username>/AppData/Local/Android/Sdk/platform-tools/adb.exe devices`
- If still not working, restart ADB server: `adb.exe kill-server && adb.exe start-server`

**ANDROID_HOME not set (WSL2)**:
- Verify environment variable is set: `echo $ANDROID_HOME`
- Check path exists: `ls $ANDROID_HOME`
- If using Windows Android SDK, ensure path uses `/mnt/c/` format
- Reload shell: `source ~/.zshrc` or `source ~/.bashrc`

**Java/JDK issues (WSL2)**:
- Verify Java is installed: `java -version`
- Set JAVA_HOME: `export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64`
- Add to shell profile for persistence

**Build errors**:
- Ensure Android SDK API 33+ is installed
- Check `android/app/build.gradle` for correct SDK versions
- Run `flutter clean` and `flutter pub get`
- Verify ANDROID_HOME and JAVA_HOME are set correctly

**WSL2-specific issues**:
- File system performance: Keep project files in WSL2 filesystem (`~/`), not Windows filesystem (`/mnt/c/`)
- If using Windows Android Studio, ensure SDK path is accessible from WSL2
- For better performance, consider using Windows-hosted emulator with WSL2 development

## Project Structure

This project uses a **domain-centric (feature-based)** architecture rather than technology-centric layers. Each feature is self-contained with its own data, domain, and presentation layers.

```
lib/
  core/                    # Shared utilities, constants, extensions
    theme/                 # Material 3 theme configuration
    logging/               # Structured logging utilities
  features/                # Feature-based organization
    home/                  # Home feature (placeholder)
      data/                # Data layer (repositories, data sources)
      domain/              # Domain layer (business logic, models)
      presentation/        # Presentation layer (UI, widgets, screens)
        screens/
  main.dart                # App entry point
```

### Architecture Philosophy

- **Feature-based organization**: Each feature (e.g., `visits/`, `places/`, `settings/`) is self-contained
- **Separation of concerns**: Each feature has its own `data/`, `domain/`, and `presentation/` subdirectories
- **Shared code in core**: Common utilities, theme, logging, and constants live in `lib/core/`
- **Scalability**: New features can be added without affecting existing ones

This structure makes the codebase more maintainable and easier to navigate as the project grows.

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

#### Debug Mode (Development)
Debug mode includes hot reload, debugging tools, and verbose logging:
```bash
# Run in debug mode (default)
flutter run

# Run on specific device
flutter run -d <device_id>

# List available devices
flutter devices
```

**Hot Reload & Hot Restart**:
- Press `r` in the terminal to hot reload (preserves app state)
- Press `R` to hot restart (resets app state)
- Press `q` to quit

**When to use Debug Mode**:
- During active development
- When you need debugging tools and breakpoints
- When you want hot reload for rapid iteration
- For testing and development

#### Release Mode (Production)
Release mode is optimized for performance and size:
```bash
# Run in release mode
flutter run --release

# Run on specific device in release mode
flutter run --release -d <device_id>
```

**When to use Release Mode**:
- Testing production-like performance
- Verifying app behavior without debug overhead
- Before building APK for distribution
- Performance profiling

**Key Differences**:
- **Debug**: Larger APK, slower performance, includes debugging symbols, hot reload enabled
- **Release**: Smaller APK, optimized performance, no debugging symbols, no hot reload

### Viewing Logs

The app uses structured logging via `dart:developer` to track app lifecycle and important events.

#### Flutter Logs (Recommended for Development)
```bash
# View Flutter logs (includes app lifecycle events)
flutter logs

# View logs for specific device
flutter logs -d <device_id>
```

**What you'll see**:
- App initialization messages
- App lifecycle events (start, stop, pause, resume)
- Structured log messages with timestamps
- Error messages and stack traces

#### Android Logs (adb logcat)
```bash
# Filter logs for Goldfish app only
adb logcat | grep -i goldfish

# View all Android logs
adb logcat

# Clear log buffer and view new logs
adb logcat -c && adb logcat | grep -i goldfish

# View logs with specific tag (if using custom tags)
adb logcat -s GoldfishApp:D

# Save logs to file
adb logcat | grep -i goldfish > goldfish_logs.txt
```

**App Lifecycle Events Logged**:
- `App initialized` - When the app starts up
- `App started` - When app enters foreground
- `App paused` - When app goes to background
- `App resumed` - When app returns to foreground
- `App stopped` - When app is terminated

**Log Levels**:
- `INFO` - General information (app lifecycle, normal operations)
- `WARNING` - Warnings (non-critical issues)
- `SEVERE` - Errors (critical issues requiring attention)

### Testing
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/bootstrap_test.dart

# Run tests in watch mode (auto-rerun on file changes)
flutter test --watch

# Run tests with verbose output
flutter test --verbose
```

**Test Output**:
- Tests log "App test started" and "App test completed" messages
- Use `assert(true)` to verify test framework is working
- Check test output for logging messages from test execution

### Building
```bash
# Build APK (release)
flutter build apk --release

# Build APK (debug - for testing)
flutter build apk --debug

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Build with specific flavor (if configured)
flutter build apk --release --flavor production

# Clean build artifacts before building
flutter clean && flutter build apk --release
```

**APK Location**: `build/app/outputs/flutter-apk/app-release.apk`

**Installation**:
```bash
# Install on connected device
adb install build/app/outputs/flutter-apk/app-release.apk

# Install and replace existing app
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Code Formatting
```bash
# Format all Dart files
dart format .

# Format specific file or directory
dart format lib/main.dart
dart format lib/

# Check formatting without making changes
dart format --set-exit-if-changed .
```

**Best Practice**: Run `dart format .` before committing code to ensure consistent formatting.

### Linting and Analysis
```bash
# Run static analysis (linting)
flutter analyze

# Run analysis with verbose output
flutter analyze --verbose

# Check for issues in specific directory
flutter analyze lib/
```

**What it checks**:
- Code style violations
- Potential bugs and errors
- Unused imports and variables
- Type safety issues
- Best practice violations

**Configuration**: Linting rules are defined in `analysis_options.yaml` using `flutter_lints`.

### Dependencies Management
```bash
# Get dependencies (after adding/updating pubspec.yaml)
flutter pub get

# Add a dependency
flutter pub add <package_name>

# Add a dev dependency
flutter pub add --dev <package_name>

# Remove a dependency
flutter pub remove <package_name>

# Update dependencies to latest compatible versions
flutter pub upgrade

# Update all dependencies (including breaking changes)
flutter pub upgrade --major-versions

# Check for outdated packages
flutter pub outdated

# Verify dependencies are resolved
flutter pub deps
```

**Example**:
```bash
# Add a regular dependency
flutter pub add go_router

# Add a dev dependency
flutter pub add --dev build_runner

# Remove a dependency
flutter pub remove some_package
```

### Makefile Commands (Quick Shortcuts)

The project includes a `Makefile` with convenient shortcuts for common tasks:

```bash
# Show all available commands
make help

# Build release APK
make build

# Install APK on connected device
make install

# Build and deploy to emulator
make em_deploy

# Launch emulator
make em_launch

# Run app on emulator (builds and installs automatically)
make em_run

# Run all tests
make test

# Run bootstrap test only
make test_bootstrap

# Run tests in watch mode
make test_watch

# Run tests with coverage
make test_coverage

# Run lint/analysis
make lint

# Run all security audits
make audit

# Run OSV Scanner only
make audit-osv

# Run dep_audit only
make audit-dep

# Clean build artifacts
make clean
```

**Note**: Makefile commands are wrappers around Flutter commands. You can use either `make` commands or direct Flutter commands.

### Security Auditing

The project includes security audit tools to check for vulnerabilities and outdated dependencies:

**Prerequisites**:
- **OSV Scanner**: Install with `go install github.com/google/osv-scanner/cmd/osv-scanner@latest`
  - Ensure `~/go/bin` is in your PATH
- **dep_audit**: Install with `dart pub global activate dep_audit`
  - Ensure `~/.pub-cache/bin` is in your PATH

**Setup**:
```bash
# Check if tools are installed and PATH is configured
bash scripts/check_audit_tools.sh

# Add both tools to PATH (if not already added)
echo 'export PATH="$PATH:$HOME/go/bin:$HOME/.pub-cache/bin"' >> ~/.zshrc
source ~/.zshrc
```

**Running Audits**:
```bash
# Run all security audits
make audit

# Run OSV Scanner only (checks for known vulnerabilities)
make audit-osv

# Run dep_audit only (checks for outdated/unused packages)
make audit-dep

# Or run manually:
osv-scanner --lockfile pubspec.lock
dep_audit --path .
```

**What Each Tool Does**:
- **OSV Scanner**: Scans `pubspec.lock` against Google's OSV database for known security vulnerabilities
- **dep_audit**: Analyzes dependencies for outdated packages, unused packages, and package health issues

**Note**: The `flutter` package may show as "discontinued" in dep_audit - this is a false positive since `flutter` is an SDK package, not a pub.dev package.

### Continuous Integration (CI)

The project includes a GitHub Actions CI workflow (`.github/workflows/ci.yml`) that runs on every push and pull request to the `main` branch.

**CI Pipeline Steps**:
1. ✅ Checkout code
2. ✅ Set up Flutter SDK (3.24.0 stable)
3. ✅ Verify Flutter installation
4. ✅ Get dependencies
5. ✅ Run lint (`make lint`)
6. ✅ Run tests (`make test`)
7. ✅ Run security audits (`make audit`)
8. ✅ Build APK (`make build`)

**View CI Status**:
- Check the "Actions" tab in GitHub
- CI runs automatically on push/PR to `main`
- All steps must pass for the workflow to succeed

**Local CI Verification**:
Before pushing, you can run the same checks locally:
```bash
make lint      # Equivalent to: flutter analyze
make test      # Equivalent to: flutter test
make audit     # Equivalent to: osv-scanner + dep_audit
make build     # Equivalent to: flutter build apk --release
```

## Quick Reference

### Common Commands Cheat Sheet

```bash
# Setup
flutter pub get              # Install dependencies
flutter doctor               # Check environment setup

# Development
flutter run                  # Run app in debug mode
flutter run --release        # Run app in release mode
flutter devices              # List available devices
flutter logs                 # View app logs

# Testing
flutter test                 # Run all tests
flutter test --coverage      # Run tests with coverage
make test                    # Run tests (Makefile)

# Code Quality
dart format .                # Format code
flutter analyze              # Run linting
make lint                    # Run linting (Makefile)

# Building
flutter build apk --release  # Build release APK
make build                   # Build APK (Makefile)
make install                 # Install APK on device

# Dependencies
flutter pub add <package>    # Add dependency
flutter pub remove <package> # Remove dependency
flutter pub upgrade          # Update dependencies

# Utilities
flutter clean                # Clean build artifacts
make clean                   # Clean (Makefile)
make help                    # Show all Makefile commands
```

## Bootstrap Completion Verification

To verify that all bootstrap tasks are complete, run through this checklist:

```bash
# 1. Verify Flutter environment
flutter doctor -v

# 2. Verify project structure
ls -la lib/core/theme/
ls -la lib/core/logging/
ls -la lib/features/home/

# 3. Run analysis (should pass with no errors)
flutter analyze

# 4. Run tests (should pass)
flutter test

# 5. Build APK (should succeed)
flutter build apk --release

# 6. Verify APK exists
ls -lh build/app/outputs/flutter-apk/app-release.apk

# 7. Check logs (if device connected)
adb logcat | grep -i goldfish
```

**Success Criteria** (from `prompts/01_bootstrap_project.md`):
- ✅ Flutter project initializes without errors
- ✅ Android build configured for API 33+
- ✅ App structure follows planned architecture
- ✅ Material 3 theming with light/dark mode is configured
- ✅ App launches and displays a basic home screen
- ✅ Structured logging is implemented and working
- ✅ App lifecycle events are logged (start/stop)
- ✅ Test suite exists with passing tests
- ✅ Release APK can be built successfully
- ✅ APK can be side-loaded onto Android device
- ✅ App runs on device and logs are visible in `adb logcat`
- ✅ All code follows Flutter/Dart best practices
- ✅ Analysis options configured and passing

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

