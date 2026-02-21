import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:szybka_fucha/core/api/api_client.dart';
import 'package:szybka_fucha/core/api/api_exceptions.dart';
import 'package:szybka_fucha/core/providers/api_provider.dart';
import 'package:szybka_fucha/core/providers/notification_provider.dart';
import 'package:szybka_fucha/core/providers/storage_provider.dart';
import 'package:szybka_fucha/core/services/notification_service.dart';
import 'package:szybka_fucha/core/storage/secure_storage.dart';
import 'package:szybka_fucha/features/profile/screens/notifications_preferences_screen.dart';

class _InMemorySecureStorage implements SecureStorageService {
  final Map<String, String> _store = {};

  @override
  Future<void> clearAll() async => _store.clear();

  @override
  Future<void> deleteOnboardingComplete() async =>
      _store.remove(StorageKeys.onboardingComplete);

  @override
  Future<void> deleteRefreshToken() async =>
      _store.remove(StorageKeys.refreshToken);

  @override
  Future<void> deleteSelectedRole() async =>
      _store.remove(StorageKeys.selectedRole);

  @override
  Future<void> deleteToken() async => _store.remove(StorageKeys.authToken);

  @override
  Future<void> deleteUserData() async => _store.remove(StorageKeys.userData);

  @override
  Future<void> deleteUserId() async => _store.remove(StorageKeys.userId);

  @override
  Future<void> deleteUserType() async => _store.remove(StorageKeys.userType);

  @override
  Future<String?> getFcmToken() async => _store[StorageKeys.fcmToken];

  @override
  Future<String?> getRefreshToken() async => _store[StorageKeys.refreshToken];

  @override
  Future<String?> getSelectedRole() async => _store[StorageKeys.selectedRole];

  @override
  Future<String?> getToken() async => _store[StorageKeys.authToken];

  @override
  Future<String?> getUserData() async => _store[StorageKeys.userData];

  @override
  Future<String?> getUserId() async => _store[StorageKeys.userId];

  @override
  Future<String?> getUserType() async => _store[StorageKeys.userType];

  @override
  Future<bool> hasCredentials() async {
    final token = _store[StorageKeys.authToken];
    return token != null && token.isNotEmpty;
  }

  @override
  Future<bool> isOnboardingComplete() async =>
      _store[StorageKeys.onboardingComplete] == 'true';

  @override
  Future<void> saveFcmToken(String token) async =>
      _store[StorageKeys.fcmToken] = token;

  @override
  Future<void> saveRefreshToken(String token) async =>
      _store[StorageKeys.refreshToken] = token;

  @override
  Future<void> saveSelectedRole(String role) async =>
      _store[StorageKeys.selectedRole] = role;

  @override
  Future<void> saveToken(String token) async =>
      _store[StorageKeys.authToken] = token;

  @override
  Future<void> saveUserData(String userData) async =>
      _store[StorageKeys.userData] = userData;

  @override
  Future<void> saveUserId(String userId) async =>
      _store[StorageKeys.userId] = userId;

  @override
  Future<void> saveUserType(String userType) async =>
      _store[StorageKeys.userType] = userType;

  @override
  Future<void> setOnboardingComplete() async =>
      _store[StorageKeys.onboardingComplete] = 'true';
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({
    required Map<String, bool> initialPreferences,
    this.failOnPut = false,
    this.putError = const ServerException(message: 'Błąd testowy zapisu'),
  }) : _preferences = Map<String, bool>.from(initialPreferences);

  final Map<String, bool> _preferences;
  bool failOnPut;
  final ApiException putError;
  int putCalls = 0;

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    if (path == '/users/me/notification-preferences') {
      return Map<String, dynamic>.from(_preferences) as T;
    }
    throw UnsupportedError('Unexpected GET path in test: $path');
  }

  @override
  Future<T> put<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    if (path != '/users/me/notification-preferences') {
      throw UnsupportedError('Unexpected PUT path in test: $path');
    }

    putCalls += 1;
    if (failOnPut) {
      throw putError;
    }

    if (data is Map) {
      data.forEach((key, value) {
        if (key is String && value is bool) {
          _preferences[key] = value;
        }
      });
    }

    return Map<String, dynamic>.from(_preferences) as T;
  }
}

class _FakeNotificationService extends Fake implements NotificationService {
  @override
  Future<NotificationSettings> getPermissionSettings() async {
    throw Exception('Permission check is not available in widget tests');
  }

  @override
  Future<NotificationSettings> requestPermissionAgain() async {
    throw Exception('Permission request is not available in widget tests');
  }
}

void main() {
  testWidgets(
    'rolls back preference toggle and shows API error when save fails',
    (tester) async {
      final storage = _InMemorySecureStorage();
      final api = _FakeApiClient(
        initialPreferences: const {
          'messages': true,
          'taskUpdates': true,
          'payments': true,
          'ratingsAndTips': true,
          'newNearbyTasks': true,
          'kycUpdates': true,
        },
        failOnPut: true,
      );
      final notificationService = _FakeNotificationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageProvider.overrideWithValue(storage),
            apiClientProvider.overrideWithValue(api),
            notificationServiceProvider.overrideWithValue(notificationService),
          ],
          child: const MaterialApp(home: NotificationsPreferencesScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nowe wiadomości'), findsOneWidget);
      expect(find.text('Nowe zlecenia w pobliżu'), findsNothing);

      final messagesTileFinder = find.widgetWithText(
        SwitchListTile,
        'Nowe wiadomości',
      );
      expect(messagesTileFinder, findsOneWidget);
      expect(tester.widget<SwitchListTile>(messagesTileFinder).value, isTrue);

      await tester.tap(messagesTileFinder);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(messagesTileFinder).value, isTrue);
      expect(api.putCalls, 1);
      expect(find.text('Błąd testowy zapisu'), findsOneWidget);
    },
  );
}
