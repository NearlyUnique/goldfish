# Goldfish - Visit Tracking App

A mobile app (Android 13+) designed to make it easy to record visits to pubs, bars, restaurants, and places of interest.

## Project Status

🚧 **Bootstrap Phase** - Project foundation is being established. See `prompts/01_bootstrap_project.md` for bootstrap tasks.

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

