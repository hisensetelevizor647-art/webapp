import 'package:uuid/uuid.dart';

/// An image the user has generated via the Image model.
/// Either [url] or [base64] is set.
class GeneratedImage {
  GeneratedImage({
    String? id,
    required this.prompt,
    this.url,
    this.base64,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final String prompt;
  final String? url;
  final String? base64;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'prompt': prompt,
        'url': url,
        'base64': base64,
        'createdAt': createdAt.toIso8601String(),
      };

  factory GeneratedImage.fromJson(Map<String, dynamic> json) {
    return GeneratedImage(
      id: json['id'] as String?,
      prompt: (json['prompt'] as String?) ?? '',
      url: json['url'] as String?,
      base64: json['base64'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}
