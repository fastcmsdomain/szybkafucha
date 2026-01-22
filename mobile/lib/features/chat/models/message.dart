/// Message Model
/// Real-time chat message with local storage serialization

import 'package:equatable/equatable.dart';

/// Chat message in a task conversation
class Message extends Equatable {
  final String id;
  final String taskId;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String content;
  final DateTime createdAt;
  final DateTime? readAt;
  final MessageStatus status;

  const Message({
    required this.id,
    required this.taskId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.content,
    required this.createdAt,
    this.readAt,
    this.status = MessageStatus.sent,
  });

  /// Is message from current user
  bool isFromCurrentUser(String currentUserId) => senderId == currentUserId;

  /// Is message read
  bool get isRead => readAt != null;

  /// Copy with modifications
  Message copyWith({
    String? id,
    String? taskId,
    String? senderId,
    String? senderName,
    String? senderAvatarUrl,
    String? content,
    DateTime? createdAt,
    DateTime? readAt,
    MessageStatus? status,
  }) {
    return Message(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      status: status ?? this.status,
    );
  }

  /// Convert to JSON for local storage (Hive)
  Map<String, dynamic> toJson() => {
    'id': id,
    'taskId': taskId,
    'senderId': senderId,
    'senderName': senderName,
    'senderAvatarUrl': senderAvatarUrl,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'readAt': readAt?.toIso8601String(),
    'status': status.name,
  };

  /// Create from JSON (local storage retrieval or API response)
  /// Handles both camelCase (backend) and local storage formats
  factory Message.fromJson(Map<String, dynamic> json) {
    // Handle sender info - may be nested object from backend or flat fields
    final sender = json['sender'] as Map<String, dynamic>?;
    final senderName = sender?['fullName'] as String? ??
                       sender?['full_name'] as String? ??
                       sender?['name'] as String? ??
                       json['senderName'] as String? ??
                       json['sender_name'] as String? ??
                       'Użytkownik';
    final senderAvatarUrl = sender?['avatarUrl'] as String? ??
                            sender?['avatar_url'] as String? ??
                            json['senderAvatarUrl'] as String? ??
                            json['sender_avatar_url'] as String?;
    final senderId = sender?['id'] as String? ??
                     json['senderId'] as String? ??
                     json['sender_id'] as String? ??
                     '';

    return Message(
      id: json['id'] as String,
      taskId: json['taskId'] as String? ?? json['task_id'] as String? ?? '',
      senderId: senderId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      content: json['content'] as String? ?? json['text'] as String? ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] as String? ??
        json['created_at'] as String? ??
        DateTime.now().toIso8601String()
      ),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : (json['read_at'] != null
              ? DateTime.parse(json['read_at'] as String)
              : null),
      status: _mapStatus(json['status'] as String?),
    );
  }

  /// Map backend status string to MessageStatus enum
  static MessageStatus _mapStatus(String? status) {
    if (status == null) return MessageStatus.sent;
    switch (status.toLowerCase()) {
      case 'pending':
        return MessageStatus.pending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }

  /// Mock message for development
  static Message mock({
    String? id,
    String taskId = 'task_123',
    String senderId = 'contractor_1',
    String senderName = 'Jan Kowalski',
    String content = 'Już jestem na miejscu!',
    MessageStatus status = MessageStatus.sent,
  }) {
    return Message(
      id: id ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
      taskId: taskId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      createdAt: DateTime.now(),
      status: status,
    );
  }

  /// Generate mock conversation for development
  static List<Message> mockConversation(String taskId) {
    final now = DateTime.now();
    return [
      Message(
        id: 'msg_1',
        taskId: taskId,
        senderId: 'client_1',
        senderName: 'Anna Nowak',
        content: 'Cześć! Kiedy możesz przyjechać?',
        createdAt: now.subtract(const Duration(minutes: 5)),
        readAt: now.subtract(const Duration(minutes: 4)),
        status: MessageStatus.sent,
      ),
      Message(
        id: 'msg_2',
        taskId: taskId,
        senderId: 'contractor_1',
        senderName: 'Jan Kowalski',
        content: 'Cześć! Jestem już w drodze, za około 10 minut będę.',
        createdAt: now.subtract(const Duration(minutes: 4)),
        readAt: now.subtract(const Duration(minutes: 3)),
        status: MessageStatus.sent,
      ),
      Message(
        id: 'msg_3',
        taskId: taskId,
        senderId: 'client_1',
        senderName: 'Anna Nowak',
        content: 'Super! Czekam :)',
        createdAt: now.subtract(const Duration(minutes: 3)),
        status: MessageStatus.sent,
      ),
      Message(
        id: 'msg_4',
        taskId: taskId,
        senderId: 'contractor_1',
        senderName: 'Jan Kowalski',
        content: 'Już jestem na miejscu, dzwonię do Ciebie!',
        createdAt: now.subtract(const Duration(minutes: 1)),
        status: MessageStatus.sent,
      ),
    ];
  }

  @override
  List<Object?> get props => [
    id,
    taskId,
    senderId,
    senderName,
    senderAvatarUrl,
    content,
    createdAt,
    readAt,
    status,
  ];
}

/// Message sending status
enum MessageStatus {
  pending, // Waiting to send
  sent, // Successfully sent to server
  delivered, // Server received and broadcasted
  read, // Recipient has read
  failed, // Failed to send
}

extension MessageStatusExtension on MessageStatus {
  /// Display name for UI
  String get displayName {
    switch (this) {
      case MessageStatus.pending:
        return 'Wysyłanie...';
      case MessageStatus.sent:
        return 'Wysłane';
      case MessageStatus.delivered:
        return 'Dostarczone';
      case MessageStatus.read:
        return 'Przeczytane';
      case MessageStatus.failed:
        return 'Błąd wysyłania';
    }
  }

  /// Icon name for status indicator
  String get iconName {
    switch (this) {
      case MessageStatus.pending:
        return 'schedule';
      case MessageStatus.sent:
        return 'check';
      case MessageStatus.delivered:
        return 'done_all';
      case MessageStatus.read:
        return 'done_all'; // double check
      case MessageStatus.failed:
        return 'error';
    }
  }
}
