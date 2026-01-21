/// Notification Provider
/// Provides NotificationService to the app via Riverpod

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../api/api_config.dart';
import '../router/router.dart';
import 'storage_provider.dart';

/// Notification service provider (singleton)
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final router = ref.watch(routerProvider);

  // Create a Dio instance for notification API calls
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

  return NotificationService(
    storage: storage,
    apiClient: dio,
    router: router,
  );
});
