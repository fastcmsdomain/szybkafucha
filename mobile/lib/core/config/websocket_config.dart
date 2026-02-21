/// WebSocket Configuration
/// Centralized WebSocket connection settings with environment support

import '../api/api_config.dart';

abstract class WebSocketConfig {
  /// WebSocket server URL — derived from ApiConfig.serverUrl so both the HTTP
  /// client and the WebSocket always point to the same host. Using a hardcoded
  /// LAN IP while the API uses localhost (iOS simulator) or 10.0.2.2 (Android
  /// emulator) caused the socket to connect to the wrong machine.
  ///   http://  →  ws://
  ///   https:// →  wss://
  /// Override the host at build time with:
  ///   flutter run --dart-define=DEV_SERVER_URL=http://192.168.1.X:3000
  static String get webSocketUrl {
    final serverUrl = ApiConfig.serverUrl;
    if (serverUrl.startsWith('https://')) {
      return serverUrl.replaceFirst('https://', 'wss://');
    } else if (serverUrl.startsWith('http://')) {
      return serverUrl.replaceFirst('http://', 'ws://');
    }
    return serverUrl;
  }

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

  // Application/bidding events
  static const String applicationNew = 'application:new';
  static const String applicationAccepted = 'application:accepted';
  static const String applicationRejected = 'application:rejected';
  static const String applicationWithdrawn = 'application:withdrawn';
  static const String applicationCount = 'application:count';

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
