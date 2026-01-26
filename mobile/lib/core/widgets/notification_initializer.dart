/// Notification Initializer Widget
/// Initializes push notifications when user is authenticated
/// Wraps the app to handle notification setup automatically

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';

/// Widget that initializes notifications when user becomes authenticated
/// Place this widget high in the widget tree, wrapping your main app content
class NotificationInitializer extends ConsumerStatefulWidget {
  final Widget child;

  const NotificationInitializer({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<NotificationInitializer> createState() =>
      _NotificationInitializerState();
}

class _NotificationInitializerState
    extends ConsumerState<NotificationInitializer> {
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Check initial auth state after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndInitialize();
    });
  }

  Future<void> _checkAndInitialize() async {
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated && !_hasInitialized) {
      await _initializeNotifications();
    }
  }

  Future<void> _initializeNotifications() async {
    if (_hasInitialized) return;

    try {
      print('NotificationInitializer: Starting initialization...');
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.initialize();

      _hasInitialized = true;
      ref.read(notificationInitializedProvider.notifier).state = true;
      print('NotificationInitializer: Initialization complete');
    } catch (e) {
      print('NotificationInitializer: Error during initialization: $e');
      // Don't crash the app if notifications fail
    }
  }

  void _clearNotificationState() {
    _hasInitialized = false;
    ref.read(notificationInitializedProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes
    ref.listen<AuthState>(authProvider, (previous, next) async {
      final wasAuthenticated = previous?.isAuthenticated ?? false;
      final isAuthenticated = next.isAuthenticated;

      if (!wasAuthenticated && isAuthenticated) {
        // User just logged in - initialize notifications
        print('NotificationInitializer: User authenticated, initializing...');
        await _initializeNotifications();
      } else if (wasAuthenticated && !isAuthenticated) {
        // User logged out - clear notification state
        print('NotificationInitializer: User logged out, clearing state...');
        _clearNotificationState();
      }
    });

    return widget.child;
  }
}

/// Extension method to easily wrap any widget with notification initialization
extension NotificationInitializerExtension on Widget {
  Widget withNotificationInitializer() {
    return NotificationInitializer(child: this);
  }
}
