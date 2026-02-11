import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// API configuration for Szybka Fucha
abstract class ApiConfig {
  /// Enable dev mode to bypass backend and use mock data
  /// Set to true to test UI without running backend server
  static const bool devModeEnabled = true;

  /// Server base URL for development (without /api/v1)
  static const String devServerUrl = 'http://localhost:3000';

  /// Server base URL for staging (without /api/v1)
  static const String stagingServerUrl = 'https://staging-api.szybkafucha.pl';

  /// Server base URL for production (without /api/v1)
  static const String prodServerUrl = 'https://api.szybkafucha.pl';

  /// Current server base URL (change based on build flavor)
  static const String serverUrl = devServerUrl;

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
  static const String stagingBaseUrl = '$stagingServerUrl/api/v1';

  /// Base URL for production
  static const String prodBaseUrl = '$prodServerUrl/api/v1';

  /// Current base URL (change based on build flavor)
  static String get baseUrl => devBaseUrl;

  /// Get full URL for avatar/media paths
  /// Converts relative paths like /uploads/avatars/file.jpg to full URLs
  static String? getFullMediaUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      return null;
    }
    // If already a full URL, return as-is
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }
    // Prepend server URL to relative path
    return '$serverUrl$relativePath';
  }

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
