import 'package:uuid/uuid.dart';

/// Role of a message author.
enum MessageRole { user, assistant, system }

/// A single chat message. Can be plain text, an image, or a combination
/// (text + optional image URL attachment, mirroring the web app's
/// multi-modal prompt flow).
class ChatMessage {
  ChatMessage({
    String? id,
    required this.role,
    required this.text,
    this.imageUrl,
    this.imageBase64,
    DateTime? createdAt,
    this.isStreaming = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final MessageRole role;
  final String text;
  final String? imageUrl;
  final String? imageBase64;
  final DateTime createdAt;
  final bool isStreaming;

  ChatMessage copyWith({
    String? text,
    String? imageUrl,
    String? imageBase64,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBase64: imageBase64 ?? this.imageBase64,
      createdAt: createdAt,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'role': role.name,
        'text': text,
        'imageUrl': imageUrl,
        'imageBase64': imageBase64,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String?,
      role: MessageRole.values.firstWhere(
        (MessageRole r) => r.name == json['role'],
        orElse: () => MessageRole.assistant,
      ),
      text: (json['text'] as String?) ?? '',
      imageUrl: json['imageUrl'] as String?,
      imageBase64: json['imageBase64'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
