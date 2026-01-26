/// Notification Router
/// Handles deep linking from push notifications to app screens

import 'package:go_router/go_router.dart';

class NotificationRouter {
  /// Route user based on notification type and data
  static void handleNotificationTap(
    GoRouter router,
    Map<String, dynamic> data,
  ) {
    final type = data['type'] as String?;

    if (type == null) {
      print('⚠️ Notification has no type field');
      return;
    }

    print('🔀 Routing notification: $type');

    switch (type) {
      // New task nearby → Contractor task list
      case 'new_task_nearby':
        router.go('/contractor/tasks');
        break;

      // Task lifecycle → Task tracking screen
      case 'task_accepted':
      case 'task_started':
      case 'task_completed':
      case 'task_confirmed':
      case 'task_cancelled':
      case 'task_rated':
        final taskId = data['taskId'] as String?;
        if (taskId != null) {
          router.go('/task/$taskId');
        } else {
          print('⚠️ Task notification missing taskId');
        }
        break;

      // New message → Chat screen
      case 'new_message':
        final taskId = data['taskId'] as String?;
        final otherUserName = data['senderName'] as String? ?? 'Użytkownik';
        if (taskId != null) {
          router.go('/chat/$taskId', extra: {
            'otherUserName': otherUserName,
          });
        } else {
          print('⚠️ Message notification missing taskId');
        }
        break;

      // Payment notifications → Earnings screen
      case 'payment_received':
      case 'payout_sent':
      case 'payment_required':
      case 'payment_held':
      case 'payment_refunded':
      case 'payment_failed':
        router.go('/contractor/earnings');
        break;

      // KYC notifications → Verification screen
      case 'kyc_document_verified':
      case 'kyc_selfie_verified':
      case 'kyc_bank_verified':
      case 'kyc_complete':
      case 'kyc_failed':
        router.go('/contractor/verification');
        break;

      // Tip received → Earnings screen
      case 'tip_received':
        router.go('/contractor/earnings');
        break;

      default:
        print('⚠️ Unknown notification type: $type');
        // Navigate to home screen as fallback
        router.go('/');
    }
  }
}
