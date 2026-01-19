/// API configuration for Szybka Fucha
abstract class ApiConfig {
  /// Enable dev mode to bypass backend and use mock data
  /// Set to true to test UI without running backend server
  static const bool devModeEnabled = true;

  /// Base URL for development
  static const String devBaseUrl = 'http://localhost:3000/api/v1';

  /// Base URL for staging
  static const String stagingBaseUrl = 'https://staging-api.szybkafucha.pl/api/v1';

  /// Base URL for production
  static const String prodBaseUrl = 'https://api.szybkafucha.pl/api/v1';

  /// Current base URL (change based on build flavor)
  static const String baseUrl = devBaseUrl;

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
