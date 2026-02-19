/// Chat Provider
/// Real-time chat with offline message queuing and API integration

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/config/websocket_config.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/websocket_provider.dart';
import '../../../core/services/websocket_service.dart';
import '../models/message.dart';

/// Chat state for a specific task
class ChatState {
  final String taskId;
  final List<Message> messages;
  final List<Message> pendingMessages;
  final bool isLoading;
  final bool isConnected;
  final String? error;
  final DateTime? lastFetched;

  ChatState({
    required this.taskId,
    this.messages = const [],
    this.pendingMessages = const [],
    this.isLoading = false,
    this.isConnected = false,
    this.error,
    this.lastFetched,
  });

  /// Total message count (including pending)
  int get totalMessageCount => messages.length + pendingMessages.length;

  /// Has unsent pending messages
  bool get hasPendingMessages => pendingMessages.isNotEmpty;

  /// All messages sorted by time
  List<Message> getAllMessagesSorted() {
    final all = [...messages, ...pendingMessages];
    all.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return all;
  }

  ChatState copyWith({
    String? taskId,
    List<Message>? messages,
    List<Message>? pendingMessages,
    bool? isLoading,
    bool? isConnected,
    String? error,
    DateTime? lastFetched,
  }) {
    return ChatState(
      taskId: taskId ?? this.taskId,
      messages: messages ?? this.messages,
      pendingMessages: pendingMessages ?? this.pendingMessages,
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      error: error ?? this.error,
      lastFetched: lastFetched ?? this.lastFetched,
    );
  }

  ChatState addMessage(Message message) {
    return copyWith(
      messages: [...messages, message],
      error: null,
    );
  }

  ChatState addPendingMessage(Message message) {
    return copyWith(
      pendingMessages: [...pendingMessages, message],
      error: null,
    );
  }

  ChatState removePendingMessage(String messageId) {
    return copyWith(
      pendingMessages: pendingMessages
          .where((msg) => msg.id != messageId)
          .toList(),
    );
  }

  ChatState clearMessages() {
    return copyWith(messages: [], pendingMessages: []);
  }
}

/// Chat notifier for real-time messaging
class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(
    this._webSocketService,
    this._apiClient,
    String taskId,
    this._currentUserId,
  ) : super(ChatState(taskId: taskId)) {
    _initializeChat();
  }

  final WebSocketService _webSocketService;
  final ApiClient _apiClient;
  final String _currentUserId;
  StreamSubscription<ChatMessageEvent>? _messageSubscription;

  /// Initialize chat for a task
  void _initializeChat() {
    // Listen for incoming messages
    _webSocketService.on(
      WebSocketConfig.messageNew,
      _handleIncomingMessage,
    );

    // Join task room to receive updates
    _webSocketService.joinTask(state.taskId);
    state = state.copyWith(isConnected: true);
  }

  /// Handle incoming message from WebSocket
  void _handleIncomingMessage(dynamic data) {
    if (data is ChatMessageEvent &&
        data.taskId == state.taskId &&
        data.senderId != _currentUserId) {
      final message = Message(
        id: data.id,
        taskId: data.taskId,
        senderId: data.senderId,
        senderName: 'Unknown User',
        content: data.content,
        createdAt: data.createdAt,
        status: MessageStatus.sent,
      );
      state = state.addMessage(message);
    }
  }

  /// Send message to task chat
  Future<void> sendMessage({
    required String content,
    required String currentUserId,
    required String currentUserName,
  }) async {
    // Create message with pending status
    final message = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      taskId: state.taskId,
      senderId: currentUserId,
      senderName: currentUserName,
      content: content,
      createdAt: DateTime.now(),
      status: MessageStatus.pending,
    );

    // Add to pending messages
    state = state.addPendingMessage(message);

    try {
      // Send via WebSocket
      if (state.isConnected) {
        _webSocketService.sendMessage(
          taskId: state.taskId,
          content: content,
        );

        // Move from pending to sent
        state = state
            .removePendingMessage(message.id)
            .addMessage(message.copyWith(status: MessageStatus.sent));
      } else {
        // Keep in pending queue if not connected
        state = state.copyWith(
          error: 'Wiadomość zostanie wysłana po reconneccie',
        );
      }
    } catch (e) {
      // Mark as failed but keep in pending for retry
      state = state.copyWith(
        error: 'Błąd wysyłania: $e',
      );
    }
  }

  /// Retry sending pending messages (when connection restored)
  Future<void> retrySendingPending({
    required String currentUserId,
  }) async {
    for (final message in state.pendingMessages) {
      try {
        _webSocketService.sendMessage(
          taskId: state.taskId,
          content: message.content,
        );

        state = state
            .removePendingMessage(message.id)
            .addMessage(message.copyWith(status: MessageStatus.sent));
      } catch (e) {
        state = state.copyWith(error: 'Błąd podczas ponawiania: $e');
      }
    }
  }

  /// Mark all messages in task as read
  void markAllAsRead() {
    _webSocketService.markMessagesRead(state.taskId);
  }

  /// Load initial messages from API
  Future<void> loadInitialMessages() async {
    state = state.copyWith(isLoading: true);
    try {
      // Fetch messages from backend API
      final response = await _apiClient.get<List<dynamic>>(
        '/tasks/${state.taskId}/messages',
      );

      final messages = response.map((json) {
        return Message.fromJson(json as Map<String, dynamic>);
      }).toList();

      state = state.copyWith(
        messages: messages,
        isLoading: false,
        lastFetched: DateTime.now(),
        error: null,
      );
    } catch (e) {
      // If API fails, start with empty messages (chat still works via WebSocket)
      state = state.copyWith(
        messages: [],
        isLoading: false,
        lastFetched: DateTime.now(),
        error: null, // Don't show error - chat can still work
      );
    }
  }

  /// Leave task chat
  void leaveChat() {
    _webSocketService.off(WebSocketConfig.messageNew, _handleIncomingMessage);
    _webSocketService.leaveTask(state.taskId);
    _messageSubscription?.cancel();
    state = state.copyWith(isConnected: false);
  }

  @override
  void dispose() {
    leaveChat();
    super.dispose();
  }
}

/// Chat provider for specific task
final chatProvider = StateNotifierProvider.family<ChatNotifier, ChatState, String>(
  (ref, taskId) {
    final webSocketService = ref.read(webSocketServiceProvider);
    final apiClient = ref.read(apiClientProvider);
    final currentUserId = ref.read(currentUserProvider)?.id ?? '';
    return ChatNotifier(webSocketService, apiClient, taskId, currentUserId);
  },
);

/// Get all messages for a task (sorted)
final taskMessagesProvider = Provider.family<List<Message>, String>(
  (ref, taskId) {
    final chat = ref.watch(chatProvider(taskId));
    return chat.getAllMessagesSorted();
  },
);

/// Get pending messages count
final pendingMessagesCountProvider = Provider.family<int, String>(
  (ref, taskId) {
    final chat = ref.watch(chatProvider(taskId));
    return chat.pendingMessages.length;
  },
);

/// Check if chat has pending messages
final hasPendingMessagesProvider = Provider.family<bool, String>(
  (ref, taskId) {
    final chat = ref.watch(chatProvider(taskId));
    return chat.hasPendingMessages;
  },
);
