/// Chat Input Widget
/// Message input field with send button and status indicators

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';

class ChatInput extends ConsumerStatefulWidget {
  final ChatKey chatKey;
  final String currentUserId;
  final String currentUserName;
  final VoidCallback onMessageSent;
  final bool isConnected;

  const ChatInput({
    Key? key,
    required this.chatKey,
    required this.currentUserId,
    required this.currentUserName,
    required this.onMessageSent,
    required this.isConnected,
  }) : super(key: key);

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

// --- Chat moderation patterns (client-side, mirrors backend) ---

/// Detects phone number patterns in text.
/// Matches: +48 123 456 789, 0048123456789, 123-456-789, (12) 345 6789, etc.
final _phoneRegex = RegExp(
  r'(\+?(?:\d[\s\-\.\(\)]?){8,}\d)',
  caseSensitive: false,
);

/// Detects digits spread across the message (e.g. "5 1 2 3 4 5 6 7 8").
bool _containsHiddenPhone(String text) {
  final digitsOnly = text.replaceAll(RegExp(r'\D'), '');
  return digitsOnly.length >= 7;
}

/// Detects email addresses.
final _emailRegex = RegExp(
  r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  caseSensitive: false,
);

/// Detects URLs and links.
final _urlRegex = RegExp(
  r'(https?://|www\.)\S+',
  caseSensitive: false,
);

/// Detects @username handles (min 3 chars after @).
final _atHandleRegex = RegExp(
  r'(?<!\w)@[a-zA-Z0-9._]{3,}',
  caseSensitive: false,
);

/// Detects social media / messaging platform names.
final _socialMediaRegex = RegExp(
  r'\b(instagram|facebook|tiktok|linkedin|whatsapp|telegram|signal|snapchat|viber|discord|twitter|youtube|skype|messenger|gg|x\.com)\b',
  caseSensitive: false,
);

/// Detects Polish contact-sharing phrases.
final _contactPhraseRegex = RegExp(
  r'\b(napisz (do mnie )?na|mój profil|znajdź mnie|dodaj mnie|zadzwoń (do mnie )?na|mój numer|mój mail|mój email|kontakt do mnie|prywatna wiadomość)\b',
  caseSensitive: false,
);

/// Returns a Polish error message if content violates moderation rules, or null if OK.
String? _checkModeration(String text) {
  if (_phoneRegex.hasMatch(text) || _containsHiddenPhone(text)) {
    return 'Udostępnianie numerów telefonu w czacie jest niedozwolone.';
  }
  if (_emailRegex.hasMatch(text)) {
    return 'Udostępnianie adresów email w czacie jest niedozwolone.';
  }
  if (_urlRegex.hasMatch(text)) {
    return 'Udostępnianie linków w czacie jest niedozwolone.';
  }
  if (_atHandleRegex.hasMatch(text)) {
    return 'Udostępnianie nazw użytkowników (@handle) w czacie jest niedozwolone.';
  }
  if (_socialMediaRegex.hasMatch(text)) {
    return 'Wspominanie platform społecznościowych w czacie jest niedozwolone.';
  }
  if (_contactPhraseRegex.hasMatch(text)) {
    return 'Udostępnianie danych kontaktowych w czacie jest niedozwolone.';
  }
  return null;
}

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

    final moderationError = _checkModeration(content);
    if (moderationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(moderationError),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      await ref.read(chatProvider(widget.chatKey).notifier).sendMessage(
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
    final hasPending = ref.watch(hasPendingMessagesProvider(widget.chatKey));

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
