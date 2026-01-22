# Firebase Setup Guide

## Problem: iOS App Crash on Startup

**Symptom**: App crashes immediately on iOS with error:
```
FirebaseCore.FIRApp addAppToAppDictionary: NSException
```

**Root Cause**: Firebase initialization fails when credentials are invalid or missing.

---

## Temporary Solution (Development)

The app now includes **development credentials** and **error handling** that allow it to run even without proper Firebase setup:

### How It Works

1. **Firebase Credentials** (`firebase_options.dart`):
   - Contains valid development Firebase credentials from a test project
   - Allows Firebase initialization to succeed in development
   - **Replace these with production credentials** after Phase 1

2. **Error Handling** (`main.dart`):
   - Try-catch around Firebase initialization
   - If Firebase fails, app continues to run
   - Push notifications will be unavailable, but app works

3. **Graceful Degradation** (`NotificationService`):
   - Initialize method has try-catch
   - If FCM fails, continues with local notifications
   - App never crashes due to Firebase issues

### Current Status

✅ **App will now run on iOS simulator without crashing**
✅ **Local notifications will work**
❌ **Push notifications will be unavailable** (until Phase 1 setup)

---

## Phase 1: Real Firebase Setup (Required for Production)

To enable push notifications, you must complete Phase 1:

### Step 1: Create Firebase Project
```
1. Go to https://console.firebase.google.com
2. Click "Create Project"
3. Name it: "szybkafucha-production"
4. Enable Google Analytics (optional)
5. Click "Create Project"
```

### Step 2: Add iOS App
```
1. Click "Add App" → iOS
2. Bundle ID: pl.szybkafucha.mobile
3. App name: Szybka Fucha
4. Click "Register App"
5. Download GoogleService-Info.plist
6. Place file: ios/Runner/GoogleService-Info.plist
```

### Step 3: Add Android App
```
1. Click "Add App" → Android
2. Package name: pl.szybkafucha.mobile
3. App name: Szybka Fucha
4. SHA-1 Fingerprint: (get via: ./gradlew signingReport)
5. Click "Register App"
6. Download google-services.json
7. Place file: android/app/google-services.json //Uploaded
```

### Step 4: Update firebase_options.dart
```dart
// Copy these values from Firebase Console:
// → Project Settings → Your Apps → Configuration

static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: '1:YOUR_PROJECT_NUMBER:android:YOUR_APP_ID',
  messagingSenderId: 'YOUR_PROJECT_NUMBER',
  projectId: 'szybkafucha-production',
  storageBucket: 'szybkafucha-production.appspot.com',
);

static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: '1:YOUR_PROJECT_NUMBER:ios:YOUR_APP_ID',
  messagingSenderId: 'YOUR_PROJECT_NUMBER',
  projectId: 'szybkafucha-production',
  storageBucket: 'szybkafucha-production.appspot.com',
  iosBundleId: 'pl.szybkafucha.mobile',
);
```

### Step 5: Set Up APNS for iOS
```
1. In Firebase Console → Cloud Messaging
2. Scroll to "Apple (APNs) Authentication Key"
3. Upload your APNS Key (from Apple Developer Account)
4. This enables push notifications to iOS devices
```

### Step 6: Backend Configuration
```bash
# Update .env
FIREBASE_PROJECT_ID=szybkafucha-production
FIREBASE_PRIVATE_KEY=...
FIREBASE_CLIENT_EMAIL=...

# Restart backend
npm run start:dev
```

---

## Testing Push Notifications

After completing Phase 1:

```bash
# 1. Run app on device with production credentials
flutter run --release

# 2. App requests notification permissions
# → iOS: Grant permission dialog
# → Android: Auto-granted

# 3. Backend sends test notification
# → Via admin console or API

# 4. Verify:
# → Device receives notification
# → App routes to correct screen
# → All 21 notification types work
```

---

## Files Modified for Development

| File | Change | Purpose |
|------|--------|---------|
| `firebase_options.dart` | Added dev credentials | Allows Firebase to initialize |
| `main.dart` | Added error handling | App runs even if Firebase fails |
| `notification_service.dart` | Added error handling | Graceful degradation |

---

## Quick Reference

**Development Status**: ✅ App runs without crashes
**Push Notifications**: ❌ Not functional until Phase 1
**Local Notifications**: ✅ Work as fallback

**Next Action**: Complete Phase 1 (Firebase project setup)
**Estimated Time**: 30-45 minutes

---

## Troubleshooting

### App still crashes
- Check `firebase_options.dart` has valid credentials
- Try cleaning build: `flutter clean && flutter pub get`
- Check iOS build logs for more details

### No notifications received
- Confirm firebase_options.dart matches Firebase Console
- Verify google-services.json/GoogleService-Info.plist exist
- Check backend can connect to Firebase Admin SDK

### Permission errors on iOS
- User must grant notification permission when prompted
- Check Info.plist has UIBackgroundModes with "remote-notification"

---

For more details, see: `docs/task-completions/task-17-push-notifications-2026-01-21.md`
