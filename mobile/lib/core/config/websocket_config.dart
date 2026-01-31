import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// WebSocket Configuration
/// Centralized WebSocket connection settings with environment support

abstract class WebSocketConfig {
  /// Resolve host so that simulators map to the correct machine address.
  /// - Android emulator uses 10.0.2.2 to reach the host.
  /// - iOS simulator and Flutter web can reach localhost directly.
  /// - Physical devices should point to the host LAN IP (override if needed).
  static String get _localHost {
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) return '10.0.2.2';
    return '127.0.0.1';
  }

  /// WebSocket server URL
  /// - Dev: ws://<resolved-host>:3000/realtime
  /// - Staging: wss://staging-api.szybkafucha.pl/realtime
  /// - Production: wss://api.szybkafucha.pl/realtime
  static String get webSocketUrl => 'ws://$_localHost:3000';

  /// WebSocket namespace
  static const String namespace = '/realtime';

  /// Full connection URL with namespace
  static String get fullUrl => '$webSocketUrl$namespace';

  /// Connection timeout in seconds
  static const int connectionTimeout = 10;

  /// Reconnection configuration
  static const Map<String, dynamic> reconnectConfig = {
    'reconnection': true,
    'reconnectionDelay': 1000, // Start with 1 second
    'reconnectionDelayMax': 8000, // Max 8 seconds
    'reconnectionAttempts': 10,
    'randomizationFactor': 0.1,
  };

  /// Query parameters for connection (JWT token added at runtime)
  static const Map<String, dynamic> connectionParams = {
    'transport': ['websocket', 'polling'],
  };

  /// Event names for server → client
  static const String locationUpdate = 'location:update';
  static const String messageNew = 'message:new';
  static const String messageRead = 'message:read';
  static const String taskStatus = 'task:status';
  static const String taskNewAvailable = 'task:new_available';
  static const String userOnline = 'user:online';
  static const String userOffline = 'user:offline';
  static const String error = 'error';

  /// Event names for client → server
  static const String sendLocation = 'location:update';
  static const String taskJoin = 'task:join';
  static const String taskLeave = 'task:leave';
  static const String sendMessage = 'message:send';
  static const String markRead = 'message:read';

  /// Dev mode mock implementation toggle
  /// Set to false to use real WebSocket connection with backend
  static const bool devModeEnabled = false;

  /// Mock data configuration for dev mode
  static const Map<String, dynamic> devModeConfig = {
    'simulateNetworkDelay': true,
    'networkDelayMs': 100,
    'simulateLocationUpdates': true,
    'locationUpdateIntervalSeconds': 15,
    'simulateIncomingMessages': true,
    'messageDelaySeconds': 5,
  };
}
