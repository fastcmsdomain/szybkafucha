import 'package:flutter/foundation.dart';

/// API configuration for Szybka Fucha
abstract class ApiConfig {
  /// Enable dev mode to bypass backend and use mock data
  /// Set to true to test UI without running backend server
  static const bool devModeEnabled = true;

  /// Server base URL for development (without `/api/v1`).
  /// Override at run time with:
  ///   `--dart-define=DEV_SERVER_URL=http://...`
  ///
  /// Defaults:
  /// - iOS Simulator: `http://localhost:3000`
  /// - Android Emulator: `http://10.0.2.2:3000` (host machine)
  ///
  /// Physical device (iOS/Android): use your Mac's LAN IP, e.g.:
  ///   `--dart-define=DEV_SERVER_URL=http://192.168.1.114:3000`
  static String get devServerUrl {
    const defined = String.fromEnvironment('DEV_SERVER_URL', defaultValue: '');
    if (defined.isNotEmpty) return defined;

    if (kIsWeb) return 'http://localhost:3000';

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:3000',
      _ => 'http://localhost:3000',
    };
  }

  /// Server base URL for staging (without /api/v1)
  static const String stagingServerUrl = 'https://staging-api.szybkafucha.pl';

  /// Server base URL for production (without /api/v1)
  static const String prodServerUrl = 'https://api.szybkafucha.pl';

  /// Current server base URL (change based on build flavor)
  static String get serverUrl => devServerUrl;

  /// Base URL for development
  static String get devBaseUrl => '$devServerUrl/api/v1';

  /// Base URL for staging
  static String get stagingBaseUrl => '$stagingServerUrl/api/v1';

  /// Base URL for production
  static String get prodBaseUrl => '$prodServerUrl/api/v1';

  /// Current base URL (change based on build flavor)
  static String get baseUrl => devBaseUrl;

  /// Get full URL for avatar/media paths
  /// Converts relative paths like /uploads/avatars/file.jpg to full URLs
  static String? getFullMediaUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      return null;
    }
    // If already a full URL, return as-is
    if (relativePath.startsWith('http://') ||
        relativePath.startsWith('https://')) {
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
