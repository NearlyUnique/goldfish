# Goldfish - Emulator and APK Installation Guide

## Overview

This guide covers building, installing, and running the Goldfish app. The app and emulator are configured to match a **Google Pixel 4a with Android 13 (API 33)**:

- **APK**: Built with `minSdk = 33` (Android 13)
- **Emulator**: Configured as Google Pixel 4a with Android 13 (API 33)
- **Target SDK**: Android 14 (API 34)

The emulator AVD is named `goldfish_emulator` and uses the Pixel 4a device profile to accurately mimic the target device.

## APK Location

After running `flutter build apk --release`, the APK is located at:

```
build/app/outputs/flutter-apk/app-release.apk
```

The APK is typically around 40-50MB in size.

## Installing APK on Your Phone

**Note**: The APK requires Android 13 (API 33) or higher. Your physical device must be running Android 13+ to install and run the app. This matches the Pixel 4a emulator configuration.

### Option A: Using ADB (Recommended)

1. **Connect your phone via USB** and enable USB debugging:
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times to enable Developer Options
   - Go to Settings → Developer Options
   - Enable "USB Debugging"

2. **Verify your device is connected:**
   ```bash
   adb devices
   ```
   You should see your device listed.

3. **Install the APK:**
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

4. **If the app is already installed**, use `-r` to reinstall:
   ```bash
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```

### Option B: Manual Transfer

1. **Copy the APK to your phone:**
   - Transfer `build/app/outputs/flutter-apk/app-release.apk` to your phone via:
     - USB file transfer
     - Email attachment
     - Cloud storage (Google Drive, Dropbox, etc.)
     - Any other file transfer method

2. **On your phone:**
   - Open your file manager and navigate to where you saved the APK
   - Tap the APK file to install
   - Allow installation from unknown sources if prompted
   - Follow the installation prompts
   - Launch "Goldfish" from your app drawer

## Running in the Emulator

### Prerequisites: Setting Up an Emulator

The emulator is configured to mimic a **Google Pixel 4a with Android 13**. If you see the error "Unable to find any emulator sources", you need to install a system image and create an AVD.

#### Step 1: Install System Image

Install Android 13 (API 33) system image to match the app's `minSdk` and Pixel 4a requirement:

```bash
/home/adams/dev/Android/Sdk/cmdline-tools/latest/bin/sdkmanager "system-images;android-33;google_apis;x86_64"
```

#### Step 2: Create AVD

Create an Android Virtual Device with Pixel 4a profile:

```bash
echo "no" | /home/adams/dev/Android/Sdk/cmdline-tools/latest/bin/avdmanager create avd \
  -n goldfish_emulator \
  -k "system-images;android-33;google_apis;x86_64" \
  -d "pixel_4a"
```

**Note**: If an AVD named `goldfish_emulator` already exists (e.g., with a different device profile), delete it first:

```bash
/home/adams/dev/Android/Sdk/cmdline-tools/latest/bin/avdmanager delete avd -n goldfish_emulator
```

Then create the new one with the Pixel 4a profile as shown above.

#### Step 3: Verify AVD Created

```bash
/home/adams/dev/Android/Sdk/cmdline-tools/latest/bin/avdmanager list avd
```

You should see `goldfish_emulator` in the list with:
- **Device**: pixel_4a (Google)
- **Target**: Android 13.0 ("Tiramisu") / API 33
- **ABI**: google_apis/x86_64

### Option A: Using Flutter Run (Recommended)

1. **List available emulators:**
   ```bash
   flutter emulators
   ```

2. **Launch an emulator** (if not already running):
   ```bash
   flutter emulators --launch goldfish_emulator
   ```
   Or start from Android Studio's AVD Manager.

3. **Run the app directly:**
   ```bash
   flutter run
   ```
   This builds and installs the app on the emulator automatically.

### Option B: Install APK on Emulator

1. **Start an emulator** (via Android Studio or command line):
   ```bash
   /home/adams/dev/Android/Sdk/emulator/emulator -avd goldfish_emulator &
   ```

2. **Wait for emulator to fully boot** (you'll see the Android home screen).

3. **Install the APK using ADB:**
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

4. **Launch the app:**
   ```bash
   adb shell am start -n dev.goldfish.app/.MainActivity
   ```
   Or find "Goldfish" in the app drawer and tap it.

### Option C: Using Android Studio (Recommended for WSL2)

If you're on WSL2, the emulator may not run directly due to hardware acceleration requirements. Use Android Studio instead:

1. **Open Android Studio**
2. **Go to Tools → Device Manager**
3. **You should see `goldfish_emulator` in the list**
4. **Click the Play button** to start it
5. **Once running**, use `flutter run` or install the APK as shown above

## Quick Reference Commands

```bash
# Build APK
flutter build apk --release

# List connected devices/emulators
adb devices

# Install on connected device/emulator
adb install build/app/outputs/flutter-apk/app-release.apk

# Reinstall (if already installed)
adb install -r build/app/outputs/flutter-apk/app-release.apk

# View logs
adb logcat | grep -i goldfish

# Launch app on device/emulator
adb shell am start -n dev.goldfish.app/.MainActivity

# List available emulators
flutter emulators

# Launch emulator
flutter emulators --launch goldfish_emulator

# Run app on connected device/emulator
flutter run
```

## Troubleshooting

### Emulator Won't Start on WSL2

WSL2 doesn't support hardware acceleration required by the Android emulator. Solutions:

1. **Use Android Studio** (runs on Windows host, connects to WSL2)
2. **Use a physical device** via USB debugging
3. **Use remote emulator** or cloud-based Android emulator

### ADB Device Not Found

1. Ensure USB debugging is enabled on your device
2. Check USB connection and try different USB ports
3. On Linux/WSL2, you may need to configure udev rules for your device
4. Try `adb kill-server && adb start-server`

### APK Installation Fails

1. **"INSTALL_FAILED_OLDER_SDK"** or **"Requires newer sdk version"**:
   - Your device is running an older Android version than the app's minimum requirement
   - Check your device's Android version: `adb shell getprop ro.build.version.sdk`
   - The app requires Android 13 (API 33) or higher
   - **Solutions:**
     - Use a device/emulator with Android 13+ (API 33+)
     - Use the `goldfish_emulator` we set up (Pixel 4a with Android 13 / API 33)

2. **"INSTALL_FAILED_UPDATE_INCOMPATIBLE"**: Uninstall the existing app first:
   ```bash
   adb uninstall dev.goldfish.app
   ```

3. **"INSTALL_FAILED_INSUFFICIENT_STORAGE"**: Free up space on device/emulator

4. **"INSTALL_PARSE_FAILED_NO_CERTIFICATES"**: Rebuild the APK:
   ```bash
   flutter clean
   flutter build apk --release
   ```

## Configuration Summary

- **Package Name**: `dev.goldfish.app`
- **Minimum Android Version**: Android 13 (API 33) - Required for both APK and emulator
- **Target Android Version**: Android 14 (API 34)
- **Emulator AVD Name**: `goldfish_emulator`
- **Emulator Device Profile**: **Google Pixel 4a**
- **Emulator Android Version**: Android 13 (API 33)
- **System Image**: Google APIs x86_64

The APK and emulator are configured to match a Google Pixel 4a with Android 13, ensuring consistent testing and deployment.

