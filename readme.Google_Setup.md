# Google Firebase Setup Guide

This document provides step-by-step instructions for manually setting up Google Firebase for the Goldfish app. These steps must be completed before implementing the authentication features outlined in `prompts/02_authentication.md`.

## Prerequisites

- Google account with access to Firebase Console
- Android app package name: `dev.goldfish.app` (as configured in `android/app/build.gradle`)
- Android device or emulator for testing
- Flutter development environment set up

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** or **"Create a project"**
3. Enter project name: `goldfish` (or your preferred name)
4. Click **"Continue"**
5. (Optional) Enable Google Analytics - you can skip this for now
6. Click **"Create project"**
7. Wait for project creation to complete
8. Click **"Continue"** when ready

## Step 2: Register Android App

1. In Firebase Console, click the **Android icon** (or **"Add app"** → **Android**)
2. Enter Android package name: `dev.goldfish.app`
   - This must match exactly with `applicationId` in `android/app/build.gradle`
3. Enter app nickname (optional): `Goldfish`
4. Enter debug signing certificate SHA-1 (see Step 3 below)
5. Click **"Register app"**

## Step 3: Get SHA-1 Fingerprint

The SHA-1 fingerprint is required for Google Sign-In to work with debug builds.

### Option A: Using Gradle (Recommended)

1. Open terminal in project root
2. Run the following command:

```bash
cd android
./gradlew signingReport
```

3. Look for the SHA-1 fingerprint in the output under `Variant: debug`
4. Copy the SHA-1 value (format: `XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX`)

### Option B: Using Keytool

If you have the debug keystore:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Look for the SHA-1 fingerprint in the output.

### Option C: Using Flutter

```bash
cd android
./gradlew signingReport | grep SHA1
```

### Add SHA-1 to Firebase

1. Go back to Firebase Console (Android app registration step)
2. Paste the SHA-1 fingerprint in the **"Debug signing certificate SHA-1"** field
3. Click **"Register app"**

**Note**: For release builds, you'll need to add the release keystore SHA-1 later. For now, the debug SHA-1 is sufficient for development.

## Step 4: Download google-services.json

1. After registering the Android app, Firebase will prompt you to download `google-services.json`
2. Click **"Download google-services.json"**
3. Save the file to: `android/app/google-services.json`
   - **Important**: The file must be in `android/app/` directory, not `android/`
4. Verify the file was downloaded correctly

## Step 5: Enable Google Sign-In Authentication

1. In Firebase Console, go to **"Authentication"** in the left sidebar
2. Click **"Get started"** (if first time)
3. Click on the **"Sign-in method"** tab
4. Click on **"Google"** provider
5. Toggle **"Enable"** to ON
6. Enter project support email (your email address)
7. Click **"Save"**

Google Sign-In is now enabled for your Firebase project.

## Step 6: Set Up Firestore Database

1. In Firebase Console, go to **"Firestore Database"** in the left sidebar
2. Click **"Create database"**
3. Select **"Start in test mode"** (for development)
   - **Note**: For production, you'll need to set up proper security rules
4. Choose a location for your database (select closest to your users)
5. Click **"Enable"**
6. Wait for database creation to complete

### Firestore Security Rules (Development)

For development, test mode allows read/write access for 30 days. For production, update the rules:

1. Go to **"Firestore Database"** → **"Rules"** tab
2. Update rules to restrict access to authenticated users:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Add more rules as you add collections (visits, etc.)
    // For now, this is sufficient for user authentication
  }
}
```

3. Click **"Publish"**

## Step 7: Verify Configuration

### Verify google-services.json

1. Open `android/app/google-services.json`
2. Verify it contains:
   - `project_id`: Should match your Firebase project ID
   - `client`: Should contain your package name `dev.goldfish.app`
   - `api_key`: Should be present

### Verify Firebase Console

1. In Firebase Console, go to **"Project settings"** (gear icon)
2. Under **"Your apps"**, verify Android app is listed
3. Verify package name matches: `dev.goldfish.app`
4. Verify SHA-1 fingerprint is listed

## Step 8: Test Firebase Connection (Optional)

You can verify Firebase is configured correctly by:

1. Building the app: `flutter build apk --debug`
2. Installing on device: `flutter install`
3. Running the app and checking logs for Firebase initialization

## Troubleshooting

### Issue: "google-services.json not found"

**Solution**:
- Ensure file is in `android/app/google-services.json` (not `android/google-services.json`)
- Verify file was downloaded correctly
- Check file permissions

### Issue: "SHA-1 fingerprint mismatch"

**Solution**:
- Verify you copied the correct SHA-1 (debug vs release)
- Ensure SHA-1 is added in Firebase Console under the correct app
- Re-download `google-services.json` after adding SHA-1

### Issue: "Google Sign-In failed"

**Solution**:
- Verify Google Sign-In is enabled in Firebase Console
- Check that SHA-1 fingerprint is correct
- Ensure `google-services.json` is in the correct location
- Verify package name matches exactly

### Issue: "Firestore permission denied"

**Solution**:
- Check Firestore security rules
- Verify user is authenticated
- Ensure rules allow access for authenticated users

## Next Steps

After completing these setup steps:

1. Proceed with implementation in `prompts/02_authentication.md`
2. Add Firebase dependencies to `pubspec.yaml`
3. Configure Android build files
4. Implement authentication service

## Additional Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Firebase Auth Documentation](https://firebase.google.com/docs/auth)
- [Google Sign-In Setup](https://firebase.google.com/docs/auth/android/google-signin)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)

## Security Notes

- **Never commit `google-services.json` with sensitive data** (though it's generally safe for client apps)
- Keep your Firebase project credentials secure
- Use proper Firestore security rules for production
- Rotate API keys if compromised
- Use different Firebase projects for development and production

## Production Considerations

Before releasing to production:

1. Create a separate Firebase project for production
2. Set up proper Firestore security rules
3. Add release keystore SHA-1 fingerprint
4. Configure OAuth consent screen in Google Cloud Console
5. Set up proper error monitoring
6. Configure app check for additional security

