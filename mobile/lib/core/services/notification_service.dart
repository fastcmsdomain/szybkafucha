/// Firebase Cloud Messaging Service
/// Handles push notification setup, token management, and message handling

import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

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
  final SecureStorageService _storage;
  final Dio _apiClient;
  final GoRouter? _router;

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
    required SecureStorageService storage,
    required Dio apiClient,
    GoRouter? router,
  })  : _storage = storage,
        _apiClient = apiClient,
        _router = router;

  /// Initialize Firebase Messaging and local notifications
  Future<void> initialize() async {
    print('NotificationService: Initializing...');

    try {
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

      print('✅ NotificationService: Initialization complete');
    } catch (e, stackTrace) {
      print('⚠️ NotificationService: Initialization error (continuing in degraded mode)');
      print('Error: $e');
      print('Stack trace: $stackTrace');

      // Continue in degraded mode - local notifications will still work
      // FCM token registration will fail but app won't crash
      try {
        await _initializeLocalNotifications();
        _setupNotificationTapHandler();
        print('✅ NotificationService: Local notifications initialized (FCM disabled)');
      } catch (e2) {
        print('❌ NotificationService: Local notifications also failed: $e2');
      }
    }
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
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  /// Get FCM token and register with backend
  Future<void> _getAndRegisterToken() async {
    try {
      // On iOS Simulator, APNS is not available - skip FCM registration
      if (Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          print('⚠️ APNS token not available (iOS Simulator or APNS not configured)');
          print('   Push notifications will not work, but app continues normally');
          return;
        }
      }

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
      // Handle specific APNS token error gracefully
      final errorStr = e.toString();
      if (errorStr.contains('apns-token-not-set') ||
          errorStr.contains('APNS token')) {
        print('⚠️ APNS token not available - running on iOS Simulator?');
        print('   Push notifications disabled, app continues normally');
        return;
      }
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
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      title: title,
      body: body,
      notificationDetails: notificationDetails,
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

    // If router is available, delegate to NotificationRouter
    if (_router != null) {
      // Import NotificationRouter at the top of the file
      // NotificationRouter.handleNotificationTap(_router!, data);
      // For now, implement routing here to avoid circular dependencies
      _routeNotification(data);
    } else {
      print('⚠️ Router not available - notification routing deferred');
      print('Notification data: $data');
    }
  }

  /// Route notification to appropriate screen
  /// This is a simplified version; use NotificationRouter for full implementation
  void _routeNotification(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    switch (type) {
      case 'new_task_nearby':
        _router?.go('/contractor/tasks');
        break;
      case 'task_accepted':
      case 'task_started':
      case 'task_completed':
      case 'task_confirmed':
      case 'task_cancelled':
      case 'task_rated':
        final taskId = data['taskId'] as String?;
        if (taskId != null) {
          _router?.go('/task/$taskId');
        }
        break;
      case 'new_message':
        final taskId = data['taskId'] as String?;
        if (taskId != null) {
          final senderName = data['senderName'] as String? ?? 'Użytkownik';
          _router?.go('/chat/$taskId', extra: {'otherUserName': senderName});
        }
        break;
      case 'payment_received':
      case 'payout_sent':
      case 'payment_required':
      case 'payment_held':
      case 'payment_refunded':
      case 'payment_failed':
        _router?.go('/contractor/earnings');
        break;
      case 'kyc_document_verified':
      case 'kyc_selfie_verified':
      case 'kyc_bank_verified':
      case 'kyc_complete':
      case 'kyc_failed':
        _router?.go('/contractor/verification');
        break;
      case 'tip_received':
        _router?.go('/contractor/earnings');
        break;
      default:
        print('⚠️ Unknown notification type: $type');
        _router?.go('/');
    }
  }

  /// Clear FCM token on logout
  Future<void> clearToken() async {
    try {
      // Delete token from backend
      await _apiClient.delete('/users/me/fcm-token');

      // Delete token from Firebase
      await _messaging.deleteToken();

      // Note: Token remains in secure storage but is invalidated on backend
      // Local storage is not cleared intentionally for re-login optimization

      print('✅ FCM token cleared on backend');
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

  /// Get current FCM token (for debugging/testing)
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Request permission again (for manual permission request UI)
  Future<NotificationSettings> requestPermissionAgain() async {
    return await _messaging.requestPermission();
  }
}
