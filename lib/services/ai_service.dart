import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/generated_image.dart';
import 'storage_service.dart';

/// Thin orchestration layer for both the text chat model and the image
/// generation model.
///
/// When [AppConfig.aiEndpoint] is a non-empty URL, requests are sent to
/// that backend. When it is empty, an offline stub generates believable
/// responses so the APK is fully functional without any server. This keeps
/// the build self-contained and crash-free out of the box.
class AiService extends ChangeNotifier {
  AiService({required StorageService storage}) : _storage = storage {
    _sessions = _storage.loadSessions();
    _images = _storage.loadImages();
    if (_sessions.isEmpty) {
      _sessions.add(ChatSession(title: 'New chat'));
    }
    _activeSessionId = _sessions.first.id;
  }

  final StorageService _storage;

  List<ChatSession> _sessions = <ChatSession>[];
  List<GeneratedImage> _images = <GeneratedImage>[];
  String? _activeSessionId;
  bool _generating = false;

  List<ChatSession> get sessions => List<ChatSession>.unmodifiable(_sessions);
  List<GeneratedImage> get images =>
      List<GeneratedImage>.unmodifiable(_images);
  bool get isGenerating => _generating;

  ChatSession get activeSession =>
      _sessions.firstWhere((ChatSession s) => s.id == _activeSessionId,
          orElse: () => _sessions.first);

  // ---- Session management ------------------------------------------------

  void selectSession(String id) {
    if (_sessions.any((ChatSession s) => s.id == id)) {
      _activeSessionId = id;
      notifyListeners();
    }
  }

  ChatSession newSession({String title = 'New chat'}) {
    final ChatSession session = ChatSession(title: title);
    _sessions.insert(0, session);
    _activeSessionId = session.id;
    _persistSessions();
    notifyListeners();
    return session;
  }

  void deleteSession(String id) {
    _sessions.removeWhere((ChatSession s) => s.id == id);
    if (_sessions.isEmpty) {
      _sessions.add(ChatSession(title: 'New chat'));
    }
    if (_activeSessionId == id) {
      _activeSessionId = _sessions.first.id;
    }
    _persistSessions();
    notifyListeners();
  }

  void togglePin(String id) {
    for (final ChatSession s in _sessions) {
      if (s.id == id) {
        s.pinned = !s.pinned;
        break;
      }
    }
    _sessions.sort((ChatSession a, ChatSession b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    _persistSessions();
    notifyListeners();
  }

  // ---- Text generation ---------------------------------------------------

  Future<void> sendUserMessage(String text, {String? imageUrl}) async {
    if (_generating) return;
    final String trimmed = text.trim();
    if (trimmed.isEmpty && imageUrl == null) return;

    final ChatSession session = activeSession;
    final ChatMessage userMsg = ChatMessage(
      role: MessageRole.user,
      text: trimmed,
      imageUrl: imageUrl,
    );
    session.messages.add(userMsg);
    session.updatedAt = DateTime.now();

    // Auto-title the session from the first user prompt.
    if (session.title == 'New chat' && trimmed.isNotEmpty) {
      session.title = trimmed.length > 40 ? '${trimmed.substring(0, 40)}…' : trimmed;
    }

    _generating = true;
    notifyListeners();

    // Bump usage counter (mirrors web `oa_usage_counter`).
    await _storage.setUsageCount(_storage.usageCount + 1);

    try {
      final String reply = await _requestTextReply(session.messages);
      session.messages.add(ChatMessage(
        role: MessageRole.assistant,
        text: reply,
      ));
      session.updatedAt = DateTime.now();
    } catch (e) {
      session.messages.add(ChatMessage(
        role: MessageRole.assistant,
        text: 'Sorry, something went wrong: ${e.toString()}',
      ));
    } finally {
      _generating = false;
      await _persistSessions();
      notifyListeners();
    }
  }

  Future<String> _requestTextReply(List<ChatMessage> history) async {
    if (AppConfig.aiEndpoint.isEmpty) {
      return _stubTextReply(history);
    }
    final Uri url = Uri.parse('${AppConfig.aiEndpoint}/chat');
    final http.Response res = await http
        .post(
          url,
          headers: <String, String>{'content-type': 'application/json'},
          body: jsonEncode(<String, dynamic>{
            'messages': history
                .map((ChatMessage m) => <String, String>{
                      'role': m.role.name,
                      'content': m.text,
                    })
                .toList(),
          }),
        )
        .timeout(const Duration(seconds: 45));
    if (res.statusCode >= 400) {
      throw Exception('Server ${res.statusCode}');
    }
    final Map<String, dynamic> data =
        jsonDecode(res.body) as Map<String, dynamic>;
    return (data['text'] as String?) ?? '';
  }

  String _stubTextReply(List<ChatMessage> history) {
    final ChatMessage lastUser =
        history.lastWhere((ChatMessage m) => m.role == MessageRole.user,
            orElse: () => ChatMessage(role: MessageRole.user, text: ''));
    final String q = lastUser.text.trim();
    if (q.isEmpty) {
      return 'Hi! I am OleksandrAi. Ask me anything — text, code, or ideas.';
    }
    return "You said: \"$q\".\n\n"
        'This build is running the offline response stub. Configure '
        '`AppConfig.aiEndpoint` in `lib/config/app_config.dart` to connect '
        'to your real model backend. The UI, auth, storage, and message '
        'pipeline are all live.';
  }

  // ---- Image generation --------------------------------------------------

  Future<GeneratedImage?> generateImage(String prompt,
      {String size = '1024x1024'}) async {
    if (_generating) return null;
    if (prompt.trim().isEmpty) return null;

    _generating = true;
    notifyListeners();

    GeneratedImage? img;
    try {
      if (AppConfig.aiEndpoint.isEmpty) {
        img = GeneratedImage(
          prompt: prompt,
          url: _placeholderImageUrl(prompt),
        );
      } else {
        final Uri url = Uri.parse('${AppConfig.aiEndpoint}/image');
        final http.Response res = await http
            .post(
              url,
              headers: <String, String>{'content-type': 'application/json'},
              body: jsonEncode(<String, String>{'prompt': prompt, 'size': size}),
            )
            .timeout(const Duration(seconds: 60));
        if (res.statusCode >= 400) {
          throw Exception('Server ${res.statusCode}');
        }
        final Map<String, dynamic> data =
            jsonDecode(res.body) as Map<String, dynamic>;
        img = GeneratedImage(
          prompt: prompt,
          url: data['url'] as String?,
          base64: data['base64'] as String?,
        );
      }
      _images.insert(0, img);
      await _storage.saveImages(_images);
    } catch (e) {
      debugPrint('[Ai] image gen failed: $e');
    } finally {
      _generating = false;
      notifyListeners();
    }
    return img;
  }

  String _placeholderImageUrl(String prompt) {
    final int seed = prompt.hashCode.abs() % 1000;
    const int w = 768;
    const int h = 768;
    // Public Picsum stand-in keeps the stub offline-safe on real devices with
    // a network connection. Returns a deterministic image per prompt.
    return 'https://picsum.photos/seed/$seed/${math.min(w, 1024)}/${math.min(h, 1024)}';
  }

  void deleteImage(String id) {
    _images.removeWhere((GeneratedImage i) => i.id == id);
    _storage.saveImages(_images);
    notifyListeners();
  }

  Future<void> _persistSessions() => _storage.saveSessions(_sessions);
}
