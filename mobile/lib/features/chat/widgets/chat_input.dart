/// Chat Input Widget
/// Message input field with send button and status indicators

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';

class ChatInput extends ConsumerStatefulWidget {
  final String taskId;
  final String currentUserId;
  final String currentUserName;
  final VoidCallback onMessageSent;
  final bool isConnected;

  const ChatInput({
    Key? key,
    required this.taskId,
    required this.currentUserId,
    required this.currentUserName,
    required this.onMessageSent,
    required this.isConnected,
  }) : super(key: key);

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

/// Detects phone number patterns in text.
/// Matches: +48 123 456 789, 0048123456789, 123-456-789, (12) 345 6789, etc.
final _phoneRegex = RegExp(
  r'(\+?(?:\d[\s\-\.\(\)]?){8,}\d)',
  caseSensitive: false,
);

bool _containsPhoneNumber(String text) => _phoneRegex.hasMatch(text);

class _ChatInputState extends ConsumerState<ChatInput> {
  late TextEditingController _messageController;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _messageController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    if (_containsPhoneNumber(content)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Udostępnianie numerów telefonu w czacie jest niedozwolone.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      await ref.read(chatProvider(widget.taskId).notifier).sendMessage(
            content: content,
            currentUserId: widget.currentUserId,
            currentUserName: widget.currentUserName,
          );

      _messageController.clear();
      widget.onMessageSent();

      // Show snackbar if offline
      if (!widget.isConnected && mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wiadomość zostanie wysłana po reconneccie'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPending = ref.watch(hasPendingMessagesProvider(widget.taskId));

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pending messages indicator
          if (hasPending)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.amber[50],
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.amber[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Masz wiadomości oczekujące na wysłanie',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Input area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      minLines: 1,
                      enabled: !_isSending && widget.isConnected,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Napisz wiadomość...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildSendButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    final isEnabled =
        _messageController.text.isNotEmpty && !_isSending && widget.isConnected;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? _sendMessage : null,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isEnabled ? const Color(0xFFE94560) : Colors.grey[300],
          ),
          child: _isSending
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.grey[600]!,
                    ),
                  ),
                )
              : const Icon(
                  Icons.send_rounded,
                  size: 20,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}
