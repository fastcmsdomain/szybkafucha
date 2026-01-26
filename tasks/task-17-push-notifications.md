# Task 17: Push Notification Foundation - Implementation Plan

## Executive Summary

**Current Status:** Backend ✅ Complete (Mock Mode) | Mobile ❌ Not Implemented
**Overall Completion:** ~40% (Backend only, no mobile integration)
**Estimated Effort:** 2-3 days (1 developer)
**Priority:** **CRITICAL** - Required for MVP launch

The backend has excellent notification infrastructure with 21 notification types, Firebase Admin SDK integration, and full business logic integration. However, the mobile app has **zero Firebase SDK implementation**, making push notifications completely non-functional end-to-end.

**PRD Requirement:** Task 17.0 in tasks-prd marked as ⏳ FUTURE, but this is a **critical blocker** for core features:
- Real-time contractor alerts (MATCH-04: 45-second timeout)
- Task lifecycle notifications
- Message notifications
- Payment notifications
- KYC verification notifications

---

## Implementation Plan

### Phase 1: Firebase Project Setup (1-2 hours)

#### Step 1.1: Create Production Firebase Project

**Prerequisites:**
- Firebase account (use Google account)
- Access to Apple Developer account (for APNS)
- Access to Google Developer account (for FCM)

**Actions:**
1. Visit https://console.firebase.google.com/
2. Click "Create project"
3. Project name: "Szybka Fucha Production"
4. Enable Google Analytics (recommended for notification analytics)
5. Select analytics location: Poland
6. Create project (wait 1-2 minutes)

#### Step 1.2: Add iOS App to Firebase

**Actions:**
1. In Firebase Console, click "Add app" → iOS
2. **iOS bundle ID:** `pl.szybkafucha.mobile` (must match Xcode)
3. App nickname: "Szybka Fucha iOS"
4. Click "Register app"
5. **Download `GoogleService-Info.plist`** → Save securely
6. Skip "Add SDK" step (will do manually)
7. Click "Continue to console"

#### Step 1.3: Configure APNS for iOS

**Actions:**
1. In Firebase Console → Project Settings → Cloud Messaging tab
2. Scroll to "Apple app configuration"
3. Upload APNS Authentication Key (from Apple Developer Portal):
   - Go to https://developer.apple.com/account/resources/authkeys/list
   - Create new key with "Apple Push Notifications service (APNs)" enabled
   - Download `.p8` file (save securely - cannot re-download!)
   - Note Key ID and Team ID
4. In Firebase: Upload `.p8` file, enter Key ID and Team ID
5. Click "Upload"

#### Step 1.4: Add Android App to Firebase

**Actions:**
1. In Firebase Console, click "Add app" → Android
2. **Android package name:** `pl.szybkafucha.mobile` (must match build.gradle)
3. App nickname: "Szybka Fucha Android"
4. SHA-1 certificate fingerprint:
   ```bash
   cd mobile/android
   ./gradlew signingReport
   # Copy SHA-1 from "Variant: debug" section
   ```
5. Click "Register app"
6. **Download `google-services.json`** → Save securely
7. Skip "Add SDK" step (will do manually)
8. Click "Continue to console"

#### Step 1.5: Enable Cloud Messaging API

**Actions:**
1. In Firebase Console → Project Settings → Cloud Messaging tab
2. Verify Cloud Messaging API is enabled
3. If not: Click "Enable Cloud Messaging API" → Enable in Google Cloud Console

#### Step 1.6: Get Firebase Admin SDK Credentials (Backend)

**Actions:**
1. In Firebase Console → Project Settings → Service Accounts tab
2. Click "Generate new private key"
3. Confirm "Generate key"
4. **Download JSON file** → Save securely (contains private key!)
5. Open JSON file and extract:
   ```json
   {
     "project_id": "szybkafucha-production-xxxxx",
     "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
     "client_email": "firebase-adminsdk-xxxxx@szybkafucha-production-xxxxx.iam.gserviceaccount.com"
   }
   ```

#### Step 1.7: Update Backend Configuration

**File:** `backend/.env`

**Actions:**
```bash
# Replace existing Firebase credentials with production values
FIREBASE_PROJECT_ID=szybkafucha-production-xxxxx
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@szybkafucha-production-xxxxx.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_ACTUAL_PRIVATE_KEY_HERE_WITH_\n_NEWLINES_ESCAPED\n-----END PRIVATE KEY-----\n"
```

**Important:** Escape newlines in private key as `\n`

#### Step 1.8: Verify Backend Exits Mock Mode

**Actions:**
1. Start backend: `cd backend && npm run start:dev`
2. Check logs for: ✅ **"Firebase Admin initialized successfully"** (or similar)
3. Should NOT see: ❌ "Firebase not configured - running in MOCK MODE"
4. Test notification sending:
   ```bash
   # Use Postman or curl
   POST http://localhost:3000/api/v1/notifications/test
   # Should attempt real FCM send (will fail without device token - expected)
   ```

**Verification Criteria:**
- Backend logs show Firebase initialization success
- No mock mode warnings in logs
- Firebase Admin SDK methods return real responses (not mocked)

---

### Phase 2: Mobile SDK Installation (30 minutes)

#### Step 2.1: Add Firebase Configuration Files

**iOS:**
1. Copy `GoogleService-Info.plist` to: `mobile/ios/Runner/`
2. Open Xcode: `open mobile/ios/Runner.xcworkspace`
3. Drag `GoogleService-Info.plist` into Xcode project navigator (Runner folder)
4. **Check:** "Copy items if needed"
5. **Target:** Select "Runner"
6. Verify file appears in Xcode under Runner group

**Android:**
1. Copy `google-services.json` to: `mobile/android/app/`
2. Verify file exists: `ls mobile/android/app/google-services.json`

#### Step 2.2: Add Firebase Packages to pubspec.yaml

**File:** `mobile/pubspec.yaml`

**Add these dependencies:**
```yaml
dependencies:
  # Existing dependencies...

  # Firebase Core (required for all Firebase features)
  firebase_core: ^3.1.1

  # Firebase Cloud Messaging for push notifications
  firebase_messaging: ^15.1.1

  # Optional: Local notifications for foreground alerts
  flutter_local_notifications: ^17.2.2
```

**Actions:**
```bash
cd mobile
flutter pub get
```

#### Step 2.3: Configure Android Build Files

**File:** `mobile/android/build.gradle`

**Add Google Services plugin to buildscript:**
```gradle
buildscript {
    dependencies {
        // Existing dependencies...
        classpath 'com.google.gms:google-services:4.4.0'  // Add this line
    }
}
```

**File:** `mobile/android/app/build.gradle`

**Add plugin at the BOTTOM of the file:**
```gradle
// ... existing configuration ...

// Add at the very bottom (after android block)
apply plugin: 'com.google.gms.google-services'
```

#### Step 2.4: Configure iOS Capabilities

**Actions:**
1. Open Xcode: `open mobile/ios/Runner.xcworkspace`
2. Select Runner project in navigator
3. Select Runner target
4. Go to "Signing & Capabilities" tab
5. Click "+ Capability"
6. Add **"Push Notifications"**
7. Add **"Background Modes"**
8. Under Background Modes, check: **"Remote notifications"**

**File:** `mobile/ios/Runner/Info.plist`

**Verify this key exists (should already be there):**
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

#### Step 2.5: Verify Build

**iOS:**
```bash
cd mobile
flutter build ios --debug
# Should build successfully without errors
```

**Android:**
```bash
cd mobile
flutter build apk --debug
# Should build successfully without errors
```

**Common Errors & Fixes:**
- **"google-services.json not found"**: Verify file in `mobile/android/app/`
- **"GoogleService-Info.plist not found"**: Verify file added to Xcode target
- **Gradle sync failed**: Check `build.gradle` plugin syntax

---

### Phase 3: Mobile Notification Service (4-6 hours)

#### Step 3.1: Create Notification Service

**File:** `mobile/lib/core/services/notification_service.dart` (NEW)

**Implementation:**
```dart
/// Firebase Cloud Messaging Service
/// Handles push notification setup, token management, and message handling

import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import '../api/api_client.dart';

/// Top-level function for background message handling
/// Must be top-level or static to be called by isolate
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.messageId}');
  print('Notification: ${message.notification?.title}');
  print('Data: ${message.data}');

  // Handle data-only messages in background
  // Can update local database, trigger sync, etc.
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final SecureStorage _storage;
  final Dio _apiClient;

  // Notification channel for Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'szybkafucha_notifications',
    'Szybka Fucha',
    description: 'Powiadomienia o zleceniach, wiadomościach i płatnościach',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  NotificationService({
    required SecureStorage storage,
    required Dio apiClient,
  })  : _storage = storage,
        _apiClient = apiClient;

  /// Initialize Firebase Messaging and local notifications
  Future<void> initialize() async {
    print('NotificationService: Initializing...');

    // 1. Request permissions (iOS only, Android auto-grants)
    await _requestPermissions();

    // 2. Create Android notification channel
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    // 3. Initialize local notifications plugin
    await _initializeLocalNotifications();

    // 4. Get FCM token and register with backend
    await _getAndRegisterToken();

    // 5. Set up foreground notification handler
    _setupForegroundHandler();

    // 6. Set up notification tap handler
    _setupNotificationTapHandler();

    // 7. Listen for token refresh
    _listenForTokenRefresh();

    print('NotificationService: Initialization complete');
  }

  /// Request notification permissions (iOS)
  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('iOS notification permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('⚠️ User denied notification permissions');
        // Could show dialog explaining importance of notifications
      }
    } else {
      // Android auto-grants notification permissions
      print('Android: Notification permissions auto-granted');
    }
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false, // Already requested above
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  /// Get FCM token and register with backend
  Future<void> _getAndRegisterToken() async {
    try {
      // Get FCM token from Firebase
      final token = await _messaging.getToken();

      if (token == null) {
        print('❌ Failed to get FCM token');
        return;
      }

      print('✅ FCM Token obtained: ${token.substring(0, 20)}...');

      // Save token locally
      await _storage.saveFcmToken(token);

      // Register token with backend
      await _registerTokenWithBackend(token);
    } catch (e) {
      print('❌ Error getting/registering FCM token: $e');
    }
  }

  /// Register FCM token with backend API
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      final response = await _apiClient.put(
        '/users/me/fcm-token',
        data: {'fcmToken': token},
      );

      if (response.statusCode == 200) {
        print('✅ FCM token registered with backend');
      } else {
        print('⚠️ Backend returned status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Failed to register token with backend: $e');
      // Token will be retried on next app launch
    }
  }

  /// Listen for token refresh and re-register
  void _listenForTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) async {
      print('🔄 FCM token refreshed');
      await _storage.saveFcmToken(newToken);
      await _registerTokenWithBackend(newToken);
    });
  }

  /// Handle foreground notifications (app is open)
  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Foreground message received: ${message.notification?.title}');

      // Extract notification data
      final notification = message.notification;
      final data = message.data;

      if (notification != null) {
        // Show local notification when app is in foreground
        _showLocalNotification(
          title: notification.title ?? 'Szybka Fucha',
          body: notification.body ?? '',
          payload: data,
        );
      }
    });
  }

  /// Show local notification (foreground alerts)
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      title,
      body,
      notificationDetails,
      payload: _encodePayload(payload),
    );
  }

  /// Set up handler for notification taps
  void _setupNotificationTapHandler() {
    // Handle notification tap when app was in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📲 Notification tapped (background): ${message.data}');
      _handleNotificationTap(message.data);
    });

    // Check if app was opened from terminated state via notification
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('📲 Notification tapped (terminated): ${message.data}');
        _handleNotificationTap(message.data);
      }
    });
  }

  /// Handle notification tap (routing)
  void _onNotificationTap(NotificationResponse response) {
    final payload = _decodePayload(response.payload);
    if (payload != null) {
      _handleNotificationTap(payload);
    }
  }

  /// Route user based on notification type
  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    print('🔀 Routing notification: $type');

    // Notification routing will be implemented in Phase 4
    // For now, just log the notification type
    switch (type) {
      case 'new_task_nearby':
        print('→ Navigate to contractor task list');
        break;
      case 'task_accepted':
      case 'task_started':
      case 'task_completed':
      case 'task_confirmed':
        final taskId = data['taskId'];
        print('→ Navigate to task tracking screen: $taskId');
        break;
      case 'new_message':
        final taskId = data['taskId'];
        print('→ Navigate to chat screen: $taskId');
        break;
      case 'payment_received':
      case 'payout_sent':
        print('→ Navigate to earnings screen');
        break;
      case 'kyc_document_verified':
      case 'kyc_selfie_verified':
      case 'kyc_bank_verified':
      case 'kyc_complete':
      case 'kyc_failed':
        print('→ Navigate to KYC verification screen');
        break;
      default:
        print('→ Unknown notification type: $type');
    }
  }

  /// Clear FCM token on logout
  Future<void> clearToken() async {
    try {
      // Delete token from backend
      await _apiClient.delete('/users/me/fcm-token');

      // Delete token from Firebase
      await _messaging.deleteToken();

      // Clear from local storage
      await _storage.saveFcmToken(null);

      print('✅ FCM token cleared');
    } catch (e) {
      print('❌ Failed to clear FCM token: $e');
    }
  }

  /// Helper: Encode payload for local notifications
  String _encodePayload(Map<String, dynamic> payload) {
    // Simple encoding - for production, use json.encode
    return payload.toString();
  }

  /// Helper: Decode payload from local notifications
  Map<String, dynamic>? _decodePayload(String? payload) {
    if (payload == null) return null;
    // Simple decoding - for production, use json.decode
    // For now, return empty map
    return {};
  }
}
```

#### Step 3.2: Create Notification Provider

**File:** `mobile/lib/core/providers/notification_provider.dart` (NEW)

**Implementation:**
```dart
/// Notification Provider
/// Provides NotificationService to the app via Riverpod

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../storage/secure_storage.dart';
import '../api/api_client.dart';

/// Notification service provider (singleton)
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    storage: ref.watch(secureStorageProvider),
    apiClient: ref.watch(apiClientProvider),
  );
});
```

#### Step 3.3: Initialize Firebase in main()

**File:** `mobile/lib/main.dart`

**Modify:**
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/notification_service.dart'; // Import background handler

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();
  print('✅ Firebase initialized');

  // Set up background message handler (must be top-level function)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Run app
  runApp(const ProviderScope(child: SzybkaFuchaApp()));
}

// Rest of the app remains the same...
```

#### Step 3.4: Initialize Notification Service on App Start

**File:** `mobile/lib/app.dart` (or wherever app initialization happens)

**Add to app initialization:**
```dart
class SzybkaFuchaApp extends ConsumerStatefulWidget {
  const SzybkaFuchaApp({Key? key}) : super(key: key);

  @override
  ConsumerState<SzybkaFuchaApp> createState() => _SzybkaFuchaAppState();
}

class _SzybkaFuchaAppState extends ConsumerState<SzybkaFuchaApp> {
  @override
  void initState() {
    super.initState();

    // Initialize notifications after successful login
    // For now, initialize on app start (will move to post-login later)
    Future.microtask(() async {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Existing app build code...
  }
}
```

**Better approach (initialize after login):**
```dart
// In your login success handler
final notificationService = ref.read(notificationServiceProvider);
await notificationService.initialize();
```

**On logout:**
```dart
// In your logout handler
final notificationService = ref.read(notificationServiceProvider);
await notificationService.clearToken();
```

---

### Phase 4: Notification Routing & Deep Links (2-3 hours)

#### Step 4.1: Create Notification Router

**File:** `mobile/lib/core/router/notification_router.dart` (NEW)

**Implementation:**
```dart
/// Notification Router
/// Handles deep linking from push notifications to app screens

import 'package:go_router/go_router.dart';
import '../../features/tasks/screens/task_tracking_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/contractor/screens/task_list_screen.dart';
import '../../features/contractor/screens/earnings_screen.dart';
import '../../features/contractor/screens/kyc_verification_screen.dart';

class NotificationRouter {
  /// Route user based on notification type and data
  static void handleNotificationTap(
    GoRouter router,
    Map<String, dynamic> data,
  ) {
    final type = data['type'] as String?;

    if (type == null) {
      print('⚠️ Notification has no type field');
      return;
    }

    print('🔀 Routing notification: $type');

    switch (type) {
      // New task nearby → Contractor task list
      case 'new_task_nearby':
        router.go('/contractor/tasks');
        break;

      // Task lifecycle → Task tracking screen
      case 'task_accepted':
      case 'task_started':
      case 'task_completed':
      case 'task_confirmed':
      case 'task_cancelled':
      case 'task_rated':
        final taskId = data['taskId'] as String?;
        if (taskId != null) {
          router.go('/task/$taskId');
        } else {
          print('⚠️ Task notification missing taskId');
        }
        break;

      // New message → Chat screen
      case 'new_message':
        final taskId = data['taskId'] as String?;
        final otherUserName = data['senderName'] as String? ?? 'Użytkownik';
        if (taskId != null) {
          router.go('/chat/$taskId', extra: {
            'otherUserName': otherUserName,
          });
        } else {
          print('⚠️ Message notification missing taskId');
        }
        break;

      // Payment notifications → Earnings screen
      case 'payment_received':
      case 'payout_sent':
      case 'payment_required':
      case 'payment_held':
      case 'payment_refunded':
      case 'payment_failed':
        router.go('/contractor/earnings');
        break;

      // KYC notifications → Verification screen
      case 'kyc_document_verified':
      case 'kyc_selfie_verified':
      case 'kyc_bank_verified':
      case 'kyc_complete':
      case 'kyc_failed':
        router.go('/contractor/verification');
        break;

      // Tip received → Earnings screen
      case 'tip_received':
        router.go('/contractor/earnings');
        break;

      default:
        print('⚠️ Unknown notification type: $type');
        // Navigate to home screen as fallback
        router.go('/');
    }
  }
}
```

#### Step 4.2: Integrate Router with Notification Service

**File:** `mobile/lib/core/services/notification_service.dart`

**Modify `_handleNotificationTap` method:**
```dart
// Add import at top
import '../router/app_router.dart'; // Your GoRouter instance
import '../router/notification_router.dart';

// In NotificationService class, modify _handleNotificationTap:
void _handleNotificationTap(Map<String, dynamic> data) {
  // Get router instance (adjust based on your app architecture)
  final router = AppRouter.instance; // Or however you access GoRouter

  // Delegate to notification router
  NotificationRouter.handleNotificationTap(router, data);
}
```

#### Step 4.3: Add Deep Link Routes to GoRouter

**File:** `mobile/lib/core/router/app_router.dart` (your existing router)

**Ensure these routes exist:**
```dart
GoRouter(
  routes: [
    // ... existing routes ...

    // Task tracking (from task notifications)
    GoRoute(
      path: '/task/:taskId',
      builder: (context, state) {
        final taskId = state.pathParameters['taskId']!;
        return TaskTrackingScreen(taskId: taskId);
      },
    ),

    // Chat screen (from message notifications)
    GoRoute(
      path: '/chat/:taskId',
      builder: (context, state) {
        final taskId = state.pathParameters['taskId']!;
        final extra = state.extra as Map<String, dynamic>?;
        final otherUserName = extra?['otherUserName'] as String? ?? 'Użytkownik';

        return ChatScreen(
          taskId: taskId,
          otherUserName: otherUserName,
        );
      },
    ),

    // Contractor task list (from new task nearby)
    GoRoute(
      path: '/contractor/tasks',
      builder: (context, state) => ContractorTaskListScreen(),
    ),

    // Earnings screen (from payment notifications)
    GoRoute(
      path: '/contractor/earnings',
      builder: (context, state) => EarningsScreen(),
    ),

    // KYC verification (from KYC notifications)
    GoRoute(
      path: '/contractor/verification',
      builder: (context, state) => KycVerificationScreen(),
    ),
  ],
);
```

---

### Phase 5: Testing & Validation (2-3 hours)

#### Test 5.1: iOS Permission Request

**Actions:**
1. Delete app from device/simulator
2. Rebuild and install: `flutter run`
3. On first launch, should see iOS permission dialog:
   - "Szybka Fucha Would Like to Send You Notifications"
   - Buttons: "Don't Allow" / "Allow"
4. Tap "Allow"
5. Check logs for: `iOS notification permission: AuthorizationStatus.authorized`

**Expected:** Permission granted, no errors

#### Test 5.2: FCM Token Registration

**Actions:**
1. Continue from Test 5.1 (app running)
2. Check console logs for:
   ```
   ✅ FCM Token obtained: ExampleTokenHere...
   ✅ FCM token registered with backend
   ```
3. Verify token in backend database:
   ```sql
   SELECT id, email, fcm_token FROM users WHERE fcm_token IS NOT NULL;
   ```
4. Should see token for logged-in user

**Expected:** Token obtained and saved to backend

#### Test 5.3: Backend Notification Sending

**Actions:**
1. Use backend API to send test notification:
   ```bash
   # Get user ID and token from database
   # Use Postman or curl:

   POST http://localhost:3000/api/v1/notifications/send-to-user
   Authorization: Bearer <admin-jwt-token>
   Content-Type: application/json

   {
     "userId": "user-uuid-here",
     "type": "new_task_nearby",
     "data": {
       "category": "Sprzątanie",
       "budget": "150",
       "distance": "2.5"
     }
   }
   ```

2. Check mobile device - should receive notification:
   - Title: "Nowe zlecenie w pobliżu!"
   - Body: "Sprzątanie - 150 PLN (2.5km od Ciebie)"

**Expected:** Notification appears on device

#### Test 5.4: Foreground Notification Display

**Actions:**
1. Keep app open in foreground
2. Send notification from backend (Test 5.3)
3. Should see local notification appear in-app
4. Check logs for: `📨 Foreground message received: Nowe zlecenie w pobliżu!`

**Expected:** Local notification shown while app is open

#### Test 5.5: Background Notification

**Actions:**
1. Press home button (app to background)
2. Send notification from backend
3. Should see notification in system tray
4. Tap notification
5. App should open to relevant screen (contractor task list)

**Expected:** Notification appears, tap opens app to correct screen

#### Test 5.6: Notification from Terminated State

**Actions:**
1. Force quit app (swipe up on iOS, close from recent apps on Android)
2. Send notification from backend
3. Should receive notification
4. Tap notification
5. App should launch and navigate to relevant screen

**Expected:** App launches and routes correctly

#### Test 5.7: Token Refresh

**Actions:**
1. Firebase tokens can expire/refresh
2. Simulate token refresh: Re-install app without clearing backend token
3. New token should be generated
4. Should see log: `🔄 FCM token refreshed`
5. New token sent to backend

**Expected:** Token automatically refreshed and re-registered

#### Test 5.8: Logout Token Clearing

**Actions:**
1. While logged in with notifications working
2. Logout from app
3. Check logs for: `✅ FCM token cleared`
4. Verify backend database - fcm_token should be NULL for user
5. Send notification to user - should NOT receive (expected)

**Expected:** Token cleared on logout

#### Test 5.9: All Notification Types

**Create test script:** `backend/test-notifications.sh`

```bash
#!/bin/bash
# Test all 21 notification types

USER_ID="user-uuid-here"
BACKEND_URL="http://localhost:3000/api/v1"
JWT_TOKEN="admin-jwt-token-here"

# Array of all notification types with sample data
declare -A notifications=(
  ["new_task_nearby"]='{"category":"Sprzątanie","budget":"150","distance":"2.5"}'
  ["task_accepted"]='{"taskId":"task-123","contractorName":"Jan Kowalski"}'
  ["task_started"]='{"taskId":"task-123","contractorName":"Jan Kowalski"}'
  ["task_completed"]='{"taskId":"task-123"}'
  ["task_confirmed"]='{"taskId":"task-123","amount":"150"}'
  ["task_cancelled"]='{"taskId":"task-123","reason":"Klient anulował"}'
  ["task_rated"]='{"taskId":"task-123","rating":"5"}'
  ["new_message"]='{"taskId":"task-123","senderName":"Jan Kowalski","preview":"Jestem już w drodze!"}'
  ["payment_received"]='{"amount":"150","taskId":"task-123"}'
  ["payout_sent"]='{"amount":"125","bankAccount":"****1234"}'
  ["kyc_document_verified"]='{"documentType":"ID Card"}'
  ["kyc_selfie_verified"]='{}'
  ["kyc_bank_verified"]='{}'
  ["kyc_complete"]='{}'
  ["kyc_failed"]='{"reason":"Dokument nieczytelny"}'
)

# Send each notification type
for type in "${!notifications[@]}"; do
  echo "Sending: $type"
  curl -X POST "$BACKEND_URL/notifications/send-to-user" \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"userId\":\"$USER_ID\",\"type\":\"$type\",\"data\":${notifications[$type]}}"

  echo ""
  sleep 2 # Wait 2 seconds between notifications
done

echo "All notifications sent!"
```

**Actions:**
1. Update script with real user ID and JWT token
2. Run script: `bash backend/test-notifications.sh`
3. Verify each notification received on mobile device
4. Check notification text matches templates
5. Verify Polish text displays correctly
6. Test tapping each notification routes correctly

**Expected:** All 21 notification types work correctly

---

## Critical Files Reference

### Backend Files (Already Implemented ✅)
- `backend/src/notifications/notifications.module.ts` - Module definition
- `backend/src/notifications/notifications.service.ts` - Service with Firebase Admin SDK (313 lines)
- `backend/src/notifications/constants/notification-templates.ts` - All 21 notification types (156 lines)
- `backend/src/notifications/dto/send-notification.dto.ts` - DTOs
- `backend/src/users/users.controller.ts` - PUT /users/me/fcm-token endpoint (line 65-73)
- `backend/src/users/users.service.ts` - updateFcmToken() method (line 89-90)
- `backend/src/tasks/tasks.service.ts` - Task notification triggers
- `backend/src/messages/messages.service.ts` - Message notification trigger
- `backend/src/payments/payments.service.ts` - Payment notification triggers
- `backend/src/kyc/kyc.service.ts` - KYC notification triggers

### Mobile Files (To Be Created ❌)
- `mobile/lib/core/services/notification_service.dart` - NEW (notification handling)
- `mobile/lib/core/providers/notification_provider.dart` - NEW (Riverpod provider)
- `mobile/lib/core/router/notification_router.dart` - NEW (deep linking)
- `mobile/lib/main.dart` - MODIFY (Firebase initialization)
- `mobile/pubspec.yaml` - MODIFY (add firebase packages)
- `mobile/android/app/build.gradle` - MODIFY (add Google Services plugin)
- `mobile/android/build.gradle` - MODIFY (add plugin dependency)
- `mobile/ios/Runner.xcworkspace` - MODIFY (add capabilities in Xcode)

### Configuration Files (To Be Added ❌)
- `mobile/android/app/google-services.json` - Firebase Android config
- `mobile/ios/Runner/GoogleService-Info.plist` - Firebase iOS config
- `backend/.env` - UPDATE (production Firebase credentials)

---

## Success Criteria

### Must Pass Before Completion:
1. ✅ Firebase project created with iOS and Android apps
2. ✅ APNS configured for iOS notifications
3. ✅ Backend exits mock mode (real Firebase Admin SDK)
4. ✅ Mobile app builds successfully on both platforms
5. ✅ iOS permission dialog appears and can be granted
6. ✅ FCM token obtained and registered with backend
7. ✅ Backend can send notifications to mobile device
8. ✅ Foreground notifications display correctly
9. ✅ Background notifications appear in system tray
10. ✅ Notification taps route to correct screens
11. ✅ All 21 notification types work end-to-end
12. ✅ Token refresh handles correctly
13. ✅ Logout clears token from backend

---

## Dependencies

### External Services:
- Firebase account (free)
- Apple Developer account ($99/year) - for APNS
- Google Developer account (free for Firebase)

### Team Access Required:
- Firebase Console access (for project setup)
- Apple Developer Portal access (for APNS key)
- Backend .env update permissions (for Firebase credentials)

### Mobile Development:
- Xcode (for iOS capabilities configuration)
- Physical iOS device (simulator has limited notification support)
- Physical Android device (recommended for testing)

---

## Risk Mitigation

### Risk 1: APNS Certificate Issues
**Mitigation:** Use APNS Authentication Key (.p8 file) instead of certificates - easier to set up and doesn't expire

### Risk 2: Firebase Token Not Obtained
**Mitigation:**
- Check Firebase SDK initialization logs
- Verify google-services.json and GoogleService-Info.plist are correct
- Test on physical devices (simulators can have issues)

### Risk 3: Notifications Not Appearing
**Mitigation:**
- Test on physical devices first
- Check iOS settings: Settings > Notifications > Szybka Fucha (ensure allowed)
- Check Android settings: Settings > Apps > Szybka Fucha > Notifications (ensure allowed)
- Verify backend sends notifications (check Firebase Console → Cloud Messaging logs)

### Risk 4: Backend Still in Mock Mode
**Mitigation:**
- Triple-check Firebase credentials in .env
- Verify private key has proper newline escaping (`\n`)
- Restart backend after .env changes
- Check backend logs for initialization success

---

## Post-Implementation Tasks

### Documentation:
1. Update `mobile/docs/PUSH_NOTIFICATIONS.md` with mobile setup steps
2. Add notification testing guide to `mobile/docs/TESTING_GUIDE.md`
3. Document deep link routes in router documentation

### Code Quality:
1. Add unit tests for NotificationService
2. Add widget tests for notification UI
3. Add integration tests for notification flow

### Monitoring:
1. Set up Firebase Analytics to track notification delivery rates
2. Monitor notification engagement in Firebase Console
3. Track notification-driven user actions in analytics

### Future Enhancements:
1. Rich notifications with images (requires backend support)
2. Notification categories for granular user control (iOS)
3. Notification action buttons (e.g., "Accept Task" directly from notification)
4. Scheduled local notifications for reminders
5. Badge count management (iOS app icon badge)

---

## Timeline Estimate

**Phase 1: Firebase Setup** - 1-2 hours
**Phase 2: SDK Installation** - 30 minutes
**Phase 3: Notification Service** - 4-6 hours
**Phase 4: Routing & Deep Links** - 2-3 hours
**Phase 5: Testing & Validation** - 2-3 hours

**Total: 10-14.5 hours (~2 working days for 1 developer)**

**Buffer for issues:** +0.5-1 day

**Realistic Completion: 2-3 days**

---

## Verification Steps

After completing all phases, verify:

```bash
# 1. Backend mock mode disabled
cd backend
npm run start:dev
# Check logs: Should NOT see "MOCK MODE"

# 2. Mobile builds successfully
cd mobile
flutter clean
flutter pub get
flutter build ios --debug    # Should succeed
flutter build apk --debug    # Should succeed

# 3. Run on device and test all notification types
flutter run --release
# Follow Test 5.1 through 5.9

# 4. Verify backend database has FCM tokens
psql -d szybkafucha
SELECT COUNT(*) FROM users WHERE fcm_token IS NOT NULL;
# Should show logged-in users with tokens

# 5. Check Firebase Console
# Go to: Firebase Console → Cloud Messaging → Send test message
# Should be able to send test notification to device
```

---

**Document Version:** 1.0
**Date:** 2026-01-20
**Status:** Ready for Implementation
**Estimated Effort:** 2-3 days (1 developer)
**Priority:** CRITICAL (blocking MVP launch)
