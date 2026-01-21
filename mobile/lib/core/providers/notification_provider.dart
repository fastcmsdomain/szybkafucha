/// Notification Provider
/// Provides NotificationService to the app via Riverpod

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../api/api_config.dart';
import '../router/router.dart';
import 'storage_provider.dart';

/// Creates a Dio instance with auth token interceptor
Dio _createAuthenticatedDio(SecureStorageService storage) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConfig.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConfig.receiveTimeout),
      sendTimeout: const Duration(milliseconds: ApiConfig.sendTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ApiConfig.apiVersionHeader: ApiConfig.apiVersion,
      },
    ),
  );

  // Add auth interceptor that reads token from storage
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ),
  );

  return dio;
}

/// Notification service provider (singleton)
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final router = ref.watch(routerProvider);

  // Create authenticated Dio instance
  final dio = _createAuthenticatedDio(storage);

  return NotificationService(
    storage: storage,
    apiClient: dio,
    router: router,
  );
});

/// Provider to track if notifications have been initialized
final notificationInitializedProvider = StateProvider<bool>((ref) => false);
