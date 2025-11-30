# Goldfish - Authentication and Storage Setup

## Overview

This document outlines the implementation plan for authentication and storage infrastructure that must be completed before Feature 1 (Record a New Visit). This phase establishes user authentication with Google Sign-In and Firebase integration, enabling secure user account management and cloud storage capabilities.

## Goals

- Implement Google Sign-In authentication
- Set up Firebase project and configuration
- Create authentication service layer
- Implement authentication state management
- Set up navigation guards for protected routes
- Store user account information in Firebase
- Create authentication UI (sign-in screen)
- Ensure offline-first approach with authentication state persistence

## Prerequisites

- Bootstrap project completed (see `01_bootstrap_project.md`)
- Firebase project created (see `readme.Google_Setup.md` for manual setup steps)
- Google Sign-In configured in Firebase Console
- Android app registered in Firebase Console
- `google-services.json` file downloaded and placed in `android/app/`

## Tasks

### Task 1: Add Firebase and Authentication Dependencies
**Description**: Add required packages for Firebase and Google Sign-In.

**Requirements**:
- Add `firebase_core` for Firebase initialization
- Add `firebase_auth` for authentication
- Add `cloud_firestore` for cloud storage (for user account data)
- Add `google_sign_in` for Google Sign-In
- Add `go_router` for navigation with authentication guards
- Update `pubspec.yaml` with all dependencies
- Run `flutter pub get` to resolve dependencies

**Files to Modify**:
- `pubspec.yaml`

**Dependencies to Add**:
```yaml
dependencies:
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0
  google_sign_in: ^6.2.0
  go_router: ^14.0.0
```

**Deliverables**:
- Updated `pubspec.yaml` with Firebase dependencies
- Dependencies resolved and locked

---

### Task 2: Configure Firebase for Android
**Description**: Set up Firebase configuration files and Android build configuration.

**Requirements**:
- Place `google-services.json` in `android/app/` directory
- Add Google Services plugin to `android/build.gradle`
- Apply Google Services plugin in `android/app/build.gradle`
- Verify Firebase configuration is properly loaded
- Ensure SHA-1 fingerprint is added to Firebase Console (for debug builds)

**Files to Modify**:
- `android/build.gradle` (project-level)
- `android/app/build.gradle` (app-level)

**Manual Steps** (documented in `readme.Google_Setup.md`):
- Download `google-services.json` from Firebase Console
- Add SHA-1 fingerprint to Firebase project

**Deliverables**:
- Firebase properly configured for Android
- Google Services plugin applied
- Configuration file in place

---

### Task 3: Initialize Firebase in App
**Description**: Initialize Firebase when the app starts.

**Requirements**:
- Create Firebase initialization service in `lib/core/firebase/`
- Initialize Firebase in `main()` before `runApp()`
- Handle initialization errors gracefully
- Log Firebase initialization status
- Ensure initialization completes before app UI loads

**Files to Create**:
- `lib/core/firebase/firebase_service.dart`

**Files to Modify**:
- `lib/main.dart`

**Implementation Notes**:
- Use `Firebase.initializeApp()` with error handling
- Log initialization success/failure
- Consider async initialization with loading state

**Deliverables**:
- Firebase initialization service
- Firebase initialized in app startup
- Error handling for initialization failures

---

### Task 4: Create Authentication Service
**Description**: Implement authentication service layer for Google Sign-In and user management.

**Requirements**:
- Create `AuthService` class in `lib/core/auth/`
- Implement Google Sign-In method
- Implement sign-out method
- Implement user state stream/listener
- Handle authentication errors gracefully
- Store authentication state persistently
- Log authentication events

**Files to Create**:
- `lib/core/auth/auth_service.dart`
- `lib/core/auth/auth_exceptions.dart` (custom exceptions)

**Implementation Details**:
- Use `FirebaseAuth` for authentication state
- Use `GoogleSignIn` for sign-in flow
- Expose `Stream<User?>` for authentication state changes
- Handle network errors and permission denials
- Implement token refresh handling

**Deliverables**:
- Authentication service with Google Sign-In
- Sign-out functionality
- Authentication state stream
- Error handling

---

### Task 5: Create User Model and Repository
**Description**: Define user data model and repository for storing user information in Firestore.

**Requirements**:
- Create `User` model class in `lib/core/auth/models/`
- Define user fields:
  - `uid`: String (Firebase Auth UID)
  - `email`: String
  - `displayName`: String?
  - `photoUrl`: String?
  - `createdAt`: DateTime
  - `updatedAt`: DateTime
- Create `UserRepository` for Firestore operations
- Implement create/update user methods
- Implement user data sync to Firestore
- Handle offline scenarios (queue writes)

**Files to Create**:
- `lib/core/auth/models/user_model.dart`
- `lib/core/auth/repositories/user_repository.dart`

**Implementation Notes**:
- Use Firestore for user account storage
- Create user document on first sign-in
- Update user document on profile changes
- Use `uid` as document ID in Firestore
- Implement JSON serialization for Firestore

**Deliverables**:
- User model class
- User repository with Firestore integration
- User data persistence in cloud

---

### Task 6: Implement Authentication State Management
**Description**: Create state management for authentication using ChangeNotifier or ValueNotifier.

**Requirements**:
- Create `AuthNotifier` or `AuthViewModel` class
- Manage authentication state (signed in, signed out, loading)
- Expose current user information
- Listen to authentication state changes
- Provide methods for sign-in and sign-out
- Handle authentication state persistence

**Files to Create**:
- `lib/core/auth/auth_notifier.dart` or `lib/core/auth/view_models/auth_view_model.dart`

**Implementation Approach**:
- Use `ChangeNotifier` for state management (following Flutter best practices)
- Listen to `AuthService` stream
- Update state when authentication changes
- Provide reactive state to UI

**Deliverables**:
- Authentication state management class
- Reactive state updates
- User state accessible throughout app

---

### Task 7: Create Authentication UI
**Description**: Build sign-in screen and authentication UI components.

**Requirements**:
- Create sign-in screen in `lib/features/auth/presentation/screens/`
- Display Google Sign-In button
- Show loading state during authentication
- Display error messages for authentication failures
- Follow Material 3 design guidelines
- Responsive layout for all screen sizes
- Support light and dark themes

**Files to Create**:
- `lib/features/auth/presentation/screens/sign_in_screen.dart`
- `lib/features/auth/presentation/widgets/google_sign_in_button.dart` (optional, reusable component)

**UI Requirements**:
- Prominent Google Sign-In button
- App branding/logo
- Loading indicator during sign-in
- Error message display
- Clean, simple design

**Deliverables**:
- Sign-in screen UI
- Google Sign-In button component
- Error handling UI
- Loading states

---

### Task 8: Set Up Navigation with Authentication Guards
**Description**: Configure `go_router` with authentication-based routing and redirects.

**Requirements**:
- Set up `go_router` configuration in `lib/core/router/app_router.dart`
- Define routes:
  - `/sign-in` - Sign-in screen (public)
  - `/home` - Home screen (protected)
- Implement authentication redirect logic
- Redirect unauthenticated users to `/sign-in`
- Redirect authenticated users from `/sign-in` to `/home`
- Preserve intended destination after sign-in
- Handle deep links with authentication

**Files to Create**:
- `lib/core/router/app_router.dart`

**Files to Modify**:
- `lib/main.dart` (use `MaterialApp.router`)

**Implementation Details**:
- Use `redirect` callback in `GoRouter` configuration
- Check authentication state from `AuthNotifier`
- Store intended route before redirecting to sign-in
- Navigate to intended route after successful sign-in

**Deliverables**:
- Router configuration with authentication guards
- Protected routes
- Automatic redirects based on auth state

---

### Task 9: Integrate Authentication with App Lifecycle
**Description**: Ensure authentication state persists across app restarts and handles app lifecycle events.

**Requirements**:
- Persist authentication state (Firebase handles this automatically)
- Restore authentication state on app start
- Handle token refresh automatically
- Log authentication state changes
- Handle app backgrounding/foregrounding with auth state

**Files to Modify**:
- `lib/main.dart`
- `lib/core/auth/auth_service.dart`

**Implementation Notes**:
- Firebase Auth automatically persists authentication state
- Listen to auth state changes on app start
- Handle token expiration and refresh
- Log auth state transitions

**Deliverables**:
- Persistent authentication state
- Automatic token refresh
- Auth state restoration on app start

---

### Task 10: Create User Profile Service
**Description**: Implement service to manage user profile data in Firestore.

**Requirements**:
- Create user document in Firestore on first sign-in
- Update user document when profile changes
- Read user profile from Firestore
- Handle offline scenarios (cache user data locally)
- Sync user data when online
- Implement user profile update methods

**Files to Create/Modify**:
- `lib/core/auth/repositories/user_repository.dart` (extend from Task 5)

**Implementation Details**:
- Create user document with UID as document ID
- Store user data in `users/{uid}` collection
- Implement offline-first approach (local cache)
- Sync to Firestore when online
- Handle conflicts (last write wins)

**Deliverables**:
- User profile creation on sign-in
- User profile update functionality
- Offline support for user data

---

### Task 11: Add Authentication Tests
**Description**: Write tests for authentication functionality.

**Requirements**:
- Unit tests for `AuthService`
- Unit tests for `AuthNotifier`
- Unit tests for `UserRepository`
- Widget tests for sign-in screen
- Mock Firebase Auth and Google Sign-In for testing
- Test authentication flows (sign-in, sign-out)
- Test error handling

**Files to Create**:
- `test/core/auth/auth_service_test.dart`
- `test/core/auth/auth_notifier_test.dart`
- `test/core/auth/repositories/user_repository_test.dart`
- `test/features/auth/presentation/screens/sign_in_screen_test.dart`

**Testing Approach**:
- Use `mockito` or `mocktail` for mocking Firebase services
- Test successful authentication flows
- Test error scenarios
- Test state management

**Deliverables**:
- Unit tests for authentication services
- Widget tests for authentication UI
- Test coverage for authentication flows

---

### Task 12: Update App Structure for Authentication
**Description**: Integrate authentication into main app structure and update home screen.

**Requirements**:
- Update `main.dart` to initialize Firebase and set up router
- Update home screen to show user information (if needed)
- Add sign-out option (in settings or app bar)
- Display user profile information
- Handle authentication state changes in UI

**Files to Modify**:
- `lib/main.dart`
- `lib/features/home/presentation/screens/home_screen.dart` (if exists)

**Implementation Notes**:
- Initialize Firebase before `runApp()`
- Set up router with authentication guards
- Update home screen to reflect authenticated state
- Add user profile display (optional for this phase)

**Deliverables**:
- App structure updated for authentication
- Home screen shows authenticated state
- Sign-out functionality accessible

---

## Success Criteria

The authentication and storage phase is complete when:

1. ✅ Firebase project is created and configured
2. ✅ `google-services.json` is properly placed and configured
3. ✅ Firebase dependencies are added and resolved
4. ✅ Firebase initializes successfully on app start
5. ✅ Google Sign-In button is displayed on sign-in screen
6. ✅ User can sign in with Google account
7. ✅ User account is created/stored in Firebase
8. ✅ User data is stored in Firestore
9. ✅ Authentication state persists across app restarts
10. ✅ Unauthenticated users are redirected to sign-in
11. ✅ Authenticated users can access protected routes
12. ✅ User can sign out successfully
13. ✅ Navigation guards work correctly
14. ✅ Error handling works for authentication failures
15. ✅ Tests pass for authentication functionality
16. ✅ App follows offline-first principles (auth state cached)

## Verification Checklist

Before considering authentication complete, verify:

- [ ] `flutter pub get` completes without errors
- [ ] `flutter analyze` passes with no errors
- [ ] Firebase initializes on app start (check logs)
- [ ] Google Sign-In button appears on sign-in screen
- [ ] User can successfully sign in with Google
- [ ] User document is created in Firestore after sign-in
- [ ] User data appears in Firebase Console
- [ ] App redirects to home after successful sign-in
- [ ] App redirects to sign-in when user is not authenticated
- [ ] Sign-out works and redirects to sign-in
- [ ] Authentication state persists after app restart
- [ ] Error messages display for authentication failures
- [ ] Tests pass: `flutter test`
- [ ] App builds successfully: `flutter build apk --release`

## Manual Setup Steps

All manual Google/Firebase setup steps are documented in `readme.Google_Setup.md`. This includes:

- Creating Firebase project
- Enabling Google Sign-In
- Registering Android app
- Downloading `google-services.json`
- Adding SHA-1 fingerprint
- Configuring Firestore database

## Implementation Notes

### Authentication Flow

1. App starts → Check authentication state
2. If not authenticated → Show sign-in screen
3. User taps Google Sign-In → Initiate Google Sign-In flow
4. Google Sign-In succeeds → Get Google credentials
5. Sign in to Firebase with Google credentials
6. Create/update user document in Firestore
7. Update authentication state
8. Navigate to home screen

### Offline-First Considerations

- Firebase Auth automatically caches authentication state
- User data should be cached locally (SQLite) for offline access
- Firestore writes are queued when offline
- Sync occurs when connection is restored

### Security Considerations

- Never store sensitive credentials in code
- Use Firebase Security Rules for Firestore
- Validate user data on server side
- Handle token expiration gracefully
- Implement proper error handling

### Future Enhancements

- Additional sign-in providers (email/password, Apple, etc.)
- User profile editing
- Account deletion
- Multi-device sync
- Biometric authentication

## Next Steps

After authentication and storage completion:

1. Begin Feature 1 implementation (Record a New Visit)
2. Set up local SQLite database for visits
3. Implement data models for visits
4. Create visit recording UI
5. Integrate with authenticated user context

## Dependencies Summary

Required packages:
- `firebase_core`: Firebase initialization
- `firebase_auth`: Authentication
- `cloud_firestore`: Cloud database
- `google_sign_in`: Google Sign-In
- `go_router`: Navigation with guards

Optional packages (for testing):
- `mockito` or `mocktail`: Mocking for tests

