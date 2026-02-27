/// Chat Provider
/// Real-time 1-to-1 chat with offline message queuing and API integration

import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/config/websocket_config.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/websocket_provider.dart';
import '../../../core/services/websocket_service.dart';
import '../models/message.dart';

/// Composite key for identifying a 1-to-1 conversation
class ChatKey extends Equatable {
  final String taskId;
  final String otherUserId;

  const ChatKey({required this.taskId, required this.otherUserId});

  @override
  List<Object?> get props => [taskId, otherUserId];

  @override
  String toString() => '$taskId:$otherUserId';
}

/// Chat state for a specific 1-to-1 conversation
class ChatState {
  final String taskId;
  final String otherUserId;
  final List<Message> messages;
  final List<Message> pendingMessages;
  final bool isLoading;
  final bool isConnected;
  final String? error;
  final DateTime? lastFetched;

  ChatState({
    required this.taskId,
    required this.otherUserId,
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
    String? otherUserId,
    List<Message>? messages,
    List<Message>? pendingMessages,
    bool? isLoading,
    bool? isConnected,
    String? error,
    DateTime? lastFetched,
  }) {
    return ChatState(
      taskId: taskId ?? this.taskId,
      otherUserId: otherUserId ?? this.otherUserId,
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

/// Chat notifier for real-time 1-to-1 messaging
class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(
    this._webSocketService,
    this._apiClient,
    ChatKey key,
    this._currentUserId,
  ) : super(ChatState(taskId: key.taskId, otherUserId: key.otherUserId)) {
    _initializeChat();
  }

  final WebSocketService _webSocketService;
  final ApiClient _apiClient;
  final String _currentUserId;
  StreamSubscription<ChatMessageEvent>? _messageSubscription;
  StreamSubscription<WebSocketState>? _connectionSubscription;

  /// Initialize chat for a 1-to-1 conversation
  void _initializeChat() {
    // Listen for incoming messages
    _webSocketService.on(
      WebSocketConfig.messageNew,
      _handleIncomingMessage,
    );

    // Listen for message send errors (moderation blocks)
    _webSocketService.on(
      'message:error',
      _handleMessageError,
    );

    // Join 1-to-1 chat room (not task room — that's for status events)
    _webSocketService.joinChat(state.taskId, state.otherUserId);

    // Reflect real WebSocket connection state
    state = state.copyWith(isConnected: _webSocketService.isConnected);

    // Track connection changes dynamically
    _connectionSubscription = _webSocketService.stateStream.listen((wsState) {
      if (!mounted) return;
      final connected = wsState == WebSocketState.connected;
      state = state.copyWith(isConnected: connected);
      if (connected) {
        // Re-join the chat room on every (re)connect
        _webSocketService.joinChat(state.taskId, state.otherUserId);
        if (state.hasPendingMessages) {
          retrySendingPending(currentUserId: _currentUserId);
        }
      }
    });
  }

  /// Handle message send error from WebSocket (moderation block)
  void _handleMessageError(dynamic data) {
    if (data is Map) {
      final taskId = data['taskId'] as String?;
      if (taskId == state.taskId) {
        final error = data['error'] as String? ?? 'Błąd wysyłania wiadomości';
        state = state.copyWith(error: error);
        // Remove the last pending message since it was rejected
        if (state.pendingMessages.isNotEmpty) {
          final pending = List<Message>.from(state.pendingMessages);
          pending.removeLast();
          state = state.copyWith(pendingMessages: pending);
        }
      }
    }
  }

  /// Handle incoming message from WebSocket (only from the other user in this conversation)
  void _handleIncomingMessage(dynamic data) {
    if (data is ChatMessageEvent &&
        data.taskId == state.taskId &&
        data.senderId == state.otherUserId) {
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

  /// Send message to the other user in this conversation
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
      // Send via WebSocket with recipientId
      if (state.isConnected) {
        _webSocketService.sendMessage(
          taskId: state.taskId,
          recipientId: state.otherUserId,
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
          recipientId: state.otherUserId,
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

  /// Mark all messages in this conversation as read
  void markAllAsRead() {
    _webSocketService.markMessagesRead(state.taskId);
  }

  /// Load initial messages from API (scoped to this conversation)
  Future<void> loadInitialMessages() async {
    state = state.copyWith(isLoading: true);
    try {
      // Fetch messages for this specific 1-to-1 conversation
      final response = await _apiClient.get<List<dynamic>>(
        '/tasks/${state.taskId}/messages/${state.otherUserId}',
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

  /// Leave chat
  void leaveChat() {
    _webSocketService.off(WebSocketConfig.messageNew, _handleIncomingMessage);
    _webSocketService.off('message:error', _handleMessageError);
    // NOTE: Do NOT leave the chat room here. The room must remain joined
    // so that the unread badge continues to work after the chat screen closes.
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
  }

  @override
  void dispose() {
    leaveChat();
    super.dispose();
  }
}

/// Chat provider for a specific 1-to-1 conversation (keyed by ChatKey)
final chatProvider = StateNotifierProvider.autoDispose.family<ChatNotifier, ChatState, ChatKey>(
  (ref, key) {
    final webSocketService = ref.read(webSocketServiceProvider);
    final apiClient = ref.read(apiClientProvider);
    final currentUserId = ref.read(currentUserProvider)?.id ?? '';
    return ChatNotifier(webSocketService, apiClient, key, currentUserId);
  },
);

/// Get all messages for a conversation (sorted)
final taskMessagesProvider = Provider.autoDispose.family<List<Message>, ChatKey>(
  (ref, key) {
    final chat = ref.watch(chatProvider(key));
    return chat.getAllMessagesSorted();
  },
);

/// Get pending messages count
final pendingMessagesCountProvider = Provider.autoDispose.family<int, ChatKey>(
  (ref, key) {
    final chat = ref.watch(chatProvider(key));
    return chat.pendingMessages.length;
  },
);

/// Check if chat has pending messages
final hasPendingMessagesProvider = Provider.autoDispose.family<bool, ChatKey>(
  (ref, key) {
    final chat = ref.watch(chatProvider(key));
    return chat.hasPendingMessages;
  },
);
