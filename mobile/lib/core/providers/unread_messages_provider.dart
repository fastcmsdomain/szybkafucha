import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/websocket_config.dart';
import '../providers/auth_provider.dart';
import '../providers/websocket_provider.dart';
import '../services/websocket_service.dart';

/// Tracks which chat screen is currently open (taskId), or null if none.
final activeChatTaskIdProvider = StateProvider<String?>((ref) => null);

class UnreadMessagesNotifier extends StateNotifier<Map<String, int>> {
  UnreadMessagesNotifier() : super({});

  void increment(String taskId) {
    final current = state[taskId] ?? 0;
    state = {...state, taskId: current + 1};
  }

  void clearUnread(String taskId) {
    if (!state.containsKey(taskId)) return;
    state = Map<String, int>.from(state)..remove(taskId);
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
      if (data.taskId == ref.read(activeChatTaskIdProvider)) return;
      notifier.increment(data.taskId);
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

/// Unread count for a specific task.
final taskUnreadCountProvider = Provider.family<int, String>((ref, taskId) {
  return ref.watch(unreadMessagesProvider)[taskId] ?? 0;
});
