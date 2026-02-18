import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage keys
abstract class StorageKeys {
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userType = 'user_type';
  static const String userData = 'user_data';
  static const String onboardingComplete = 'onboarding_complete';
  static const String fcmToken = 'fcm_token';
}

/// Secure storage service for sensitive data
class SecureStorageService {
  late final FlutterSecureStorage _storage;

  SecureStorageService() {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
  }

  // ============ Auth Token ============

  /// Save authentication token
  Future<void> saveToken(String token) async {
    await _storage.write(key: StorageKeys.authToken, value: token);
  }

  /// Get authentication token
  Future<String?> getToken() async {
    return await _storage.read(key: StorageKeys.authToken);
  }

  /// Delete authentication token
  Future<void> deleteToken() async {
    await _storage.delete(key: StorageKeys.authToken);
  }

  // ============ Refresh Token ============

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: StorageKeys.refreshToken, value: token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: StorageKeys.refreshToken);
  }

  /// Delete refresh token
  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: StorageKeys.refreshToken);
  }

  // ============ User Info ============

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: StorageKeys.userId, value: userId);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    return await _storage.read(key: StorageKeys.userId);
  }

  /// Save user type (client/contractor)
  Future<void> saveUserType(String userType) async {
    await _storage.write(key: StorageKeys.userType, value: userType);
  }

  /// Get user type
  Future<String?> getUserType() async {
    return await _storage.read(key: StorageKeys.userType);
  }

  /// Delete user ID
  Future<void> deleteUserId() async {
    await _storage.delete(key: StorageKeys.userId);
  }

  /// Delete user type
  Future<void> deleteUserType() async {
    await _storage.delete(key: StorageKeys.userType);
  }

  // ============ User Data (cached) ============

  /// Save cached user data (JSON string)
  Future<void> saveUserData(String userData) async {
    await _storage.write(key: StorageKeys.userData, value: userData);
  }

  /// Get cached user data (JSON string)
  Future<String?> getUserData() async {
    return await _storage.read(key: StorageKeys.userData);
  }

  /// Delete cached user data
  Future<void> deleteUserData() async {
    await _storage.delete(key: StorageKeys.userData);
  }

  // ============ Onboarding ============

  /// Mark onboarding as complete
  Future<void> setOnboardingComplete() async {
    await _storage.write(key: StorageKeys.onboardingComplete, value: 'true');
  }

  /// Check if onboarding is complete
  Future<bool> isOnboardingComplete() async {
    final value = await _storage.read(key: StorageKeys.onboardingComplete);
    return value == 'true';
  }

  /// Delete onboarding complete flag (for testing)
  Future<void> deleteOnboardingComplete() async {
    await _storage.delete(key: StorageKeys.onboardingComplete);
  }

  // ============ FCM Token ============

  /// Save FCM token for push notifications
  Future<void> saveFcmToken(String token) async {
    await _storage.write(key: StorageKeys.fcmToken, value: token);
  }

  /// Get FCM token
  Future<String?> getFcmToken() async {
    return await _storage.read(key: StorageKeys.fcmToken);
  }

  // ============ Utilities ============

  /// Clear all stored data (for logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Check if user has saved credentials
  Future<bool> hasCredentials() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
