/// Chat Screen
/// Real-time task chat interface with message input and status indicators

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import '../../../core/providers/unread_messages_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String taskId;
  final String taskTitle;
  final String otherUserName;
  final String? otherUserAvatarUrl;
  final String currentUserId;
  final String currentUserName;

  const ChatScreen({
    Key? key,
    required this.taskId,
    required this.taskTitle,
    required this.otherUserName,
    this.otherUserAvatarUrl,
    required this.currentUserId,
    required this.currentUserName,
  }) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    // Defer provider modifications until after widget tree is built
    Future.microtask(() {
      if (!mounted) return;
      // Mark this chat as active — stops unread counter from incrementing
      ref.read(activeChatTaskIdProvider.notifier).state = widget.taskId;
      ref.read(unreadMessagesProvider.notifier).clearUnread(widget.taskId);
      ref.read(chatProvider(widget.taskId).notifier).loadInitialMessages();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_autoScroll && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.taskId));
    final messages = chatState.getAllMessagesSorted();
    final isConnected = chatState.isConnected;

    // Auto-scroll to new messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) {
          // Clear active chat — resume counting unread for other screens
          ref.read(activeChatTaskIdProvider.notifier).state = null;
          ref.read(chatProvider(widget.taskId).notifier).leaveChat();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.taskTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.otherUserName,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: _buildConnectionIndicator(isConnected),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Error message banner
            if (chatState.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.orange.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        chatState.error!,
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            // Messages list
            Expanded(
              child: chatState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.mail_outline,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Brak wiadomości',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Zacznij rozmowę!',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            return MessageBubble(
                              message: message,
                              isCurrentUser:
                                  message.senderId == widget.currentUserId,
                            );
                          },
                        ),
            ),
            // Chat input
            ChatInput(
              taskId: widget.taskId,
              currentUserId: widget.currentUserId,
              currentUserName: widget.currentUserName,
              onMessageSent: _scrollToBottom,
              isConnected: isConnected,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionIndicator(bool isConnected) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isConnected ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isConnected ? 'Połączony' : 'Offline',
          style: TextStyle(
            fontSize: 12,
            color: isConnected ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }
}
