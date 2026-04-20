import 'package:uuid/uuid.dart';

import 'chat_message.dart';

/// A named conversation with its own message history.
class ChatSession {
  ChatSession({
    String? id,
    required this.title,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.pinned = false,
  })  : id = id ?? const Uuid().v4(),
        messages = messages ?? <ChatMessage>[],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  DateTime updatedAt;
  bool pinned;

  String get preview {
    for (final ChatMessage m in messages.reversed) {
      if (m.text.trim().isNotEmpty) return m.text.trim();
    }
    return '';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'messages': messages.map((ChatMessage m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'pinned': pinned,
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawMsgs =
        (json['messages'] as List<dynamic>?) ?? <dynamic>[];
    return ChatSession(
      id: json['id'] as String?,
      title: (json['title'] as String?) ?? 'New chat',
      messages: rawMsgs
          .whereType<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      pinned: (json['pinned'] as bool?) ?? false,
    );
  }
}
