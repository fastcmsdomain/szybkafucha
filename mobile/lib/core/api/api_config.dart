import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// API configuration for Szybka Fucha
abstract class ApiConfig {
  /// Enable dev mode to bypass backend and use mock data
  /// Set to true to test UI without running backend server
  static const bool devModeEnabled = false;

  /// Resolve host so that simulators map to the correct machine address.
  /// - Android emulator uses 10.0.2.2 to reach the host.
  /// - iOS simulator and Flutter web can reach localhost directly.
  /// - Physical devices should point to the host LAN IP (override if needed).
  static String get _localHost {
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) return '10.0.2.2';
    return '127.0.0.1';
  }

  /// Base URL for development (adjusts per platform)
  static String get devBaseUrl => 'http://$_localHost:3000/api/v1';

  /// Base URL for staging
  static const String stagingBaseUrl = 'https://staging-api.szybkafucha.pl/api/v1';

  /// Base URL for production
  static const String prodBaseUrl = 'https://api.szybkafucha.pl/api/v1';

  /// Current base URL (change based on build flavor)
  static String get baseUrl => devBaseUrl;

  /// Connection timeout in milliseconds
  static const int connectTimeout = 30000;

  /// Receive timeout in milliseconds
  static const int receiveTimeout = 30000;

  /// Send timeout in milliseconds
  static const int sendTimeout = 30000;

  /// API version header
  static const String apiVersionHeader = 'X-API-Version';
  static const String apiVersion = '1.0';
}
