/// Test configuration for multi-device integration tests
class TestConfig {
  /// Backend API URL
  static const String apiBaseUrl = 'http://localhost:3000/api/v1';

  /// Synchronization directory for inter-device communication
  static const String syncDir = '/tmp/szybkafucha_tests';

  /// Default timeout for waiting operations
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Polling interval for sync markers
  static const Duration pollInterval = Duration(milliseconds: 500);

  /// Short delay for UI animations
  static const Duration uiDelay = Duration(milliseconds: 300);

  /// Medium delay for network operations
  static const Duration networkDelay = Duration(seconds: 2);

  /// Test user credentials (from backend seed data)
  static const String clientPhone = '+48000000002';
  static const String contractorPhone = '+48000000003';
  static const String testOtpCode = '123456';

  /// Simulator names (adjust to match your setup)
  static const String clientSimulator = 'iPhone 16 Pro';
  static const String contractorSimulator = 'iPhone 16';

  /// Task creation test data
  static const String testTaskDescription = 'Integration test task';
  static const String testTaskAddress = 'ul. Marszałkowska 100, Warszawa';
  static const double testTaskBudget = 75.0;
  static const double testLocationLat = 52.2297;
  static const double testLocationLng = 21.0122;
}

/// Device role enum for distinguishing between client and contractor tests
enum DeviceRole {
  client,
  contractor;

  /// Get device role from environment variable
  static DeviceRole fromEnvironment() {
    final role = const String.fromEnvironment('DEVICE_ROLE', defaultValue: 'client');
    return role == 'contractor' ? DeviceRole.contractor : DeviceRole.client;
  }
}
