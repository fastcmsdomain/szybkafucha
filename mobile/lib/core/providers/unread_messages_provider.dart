import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/websocket_config.dart';
import '../providers/auth_provider.dart';
import '../providers/websocket_provider.dart';
import '../services/websocket_service.dart';
import '../../features/chat/providers/chat_provider.dart';

/// Tracks which 1-to-1 chat is currently open, or null if none.
final activeChatKeyProvider = StateProvider<ChatKey?>((ref) => null);

class UnreadMessagesNotifier extends StateNotifier<Map<String, int>> {
  UnreadMessagesNotifier() : super({});

  /// Increment unread count for a conversation (keyed by "taskId:otherUserId")
  void increment(String conversationKey) {
    final current = state[conversationKey] ?? 0;
    state = {...state, conversationKey: current + 1};
  }

  /// Clear unread count for a conversation
  void clearUnread(String conversationKey) {
    if (!state.containsKey(conversationKey)) return;
    state = Map<String, int>.from(state)..remove(conversationKey);
  }
}

final unreadMessagesProvider =
    StateNotifierProvider<UnreadMessagesNotifier, Map<String, int>>(
  (ref) {
    final notifier = UnreadMessagesNotifier();
    final webSocketService = ref.read(webSocketServiceProvider);

    void onNewMessage(dynamic data) {
      if (data is! ChatMessageEvent) return;
      final currentUserId = ref.read(currentUserProvider)?.id ?? '';
      if (data.senderId == currentUserId) return;

      // Build conversation key from taskId + sender (the other user)
      final conversationKey = '${data.taskId}:${data.senderId}';

      // Don't count if this exact conversation is currently open
      final activeKey = ref.read(activeChatKeyProvider);
      if (activeKey != null &&
          activeKey.taskId == data.taskId &&
          activeKey.otherUserId == data.senderId) {
        return;
      }

      notifier.increment(conversationKey);
    }

    void registerListener() {
      // Remove first to avoid duplicates, then re-add
      webSocketService.off(WebSocketConfig.messageNew, onNewMessage);
      webSocketService.on(WebSocketConfig.messageNew, onNewMessage);
    }

    // Register immediately
    registerListener();

    // Re-register when user logs back in (disconnect() clears all listeners on logout)
    ref.listen<AuthState>(authProvider, (previous, next) {
      final wasAuthenticated = previous?.isAuthenticated ?? false;
      if (!wasAuthenticated && next.isAuthenticated) {
        registerListener();
      }
    });

    ref.onDispose(() {
      webSocketService.off(WebSocketConfig.messageNew, onNewMessage);
    });

    return notifier;
  },
);

/// Unread count for a specific conversation.
final chatUnreadCountProvider = Provider.family<int, ChatKey>((ref, key) {
  return ref.watch(unreadMessagesProvider)[key.toString()] ?? 0;
});

/// Unread count for a specific task (sum of all conversations in that task).
final taskUnreadCountProvider = Provider.family<int, String>((ref, taskId) {
  final allUnread = ref.watch(unreadMessagesProvider);
  int total = 0;
  for (final entry in allUnread.entries) {
    if (entry.key.startsWith('$taskId:')) {
      total += entry.value;
    }
  }
  return total;
});
