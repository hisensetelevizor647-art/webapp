import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_session.dart';
import '../models/generated_image.dart';
import '../models/pinned_widget.dart';

/// Lightweight persistence backed by SharedPreferences.
///
/// Keeps the APK lean (no sqflite dependency) while still offering durable
/// storage for chat sessions, generated images, pinned widgets, and the
/// usage counter.
class StorageService {
  static const String _kSessionsKey = 'oa_sessions_v1';
  static const String _kImagesKey = 'oa_images_v1';
  static const String _kPinnedKey = 'oa_pinned_widgets_v1';
  static const String _kUsageKey = 'oa_usage_counter';
  static const String _kLangKey = 'oa_language';

  late SharedPreferences _prefs;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    _prefs = await SharedPreferences.getInstance();
    _ready = true;
  }

  // ---- Sessions ----------------------------------------------------------

  List<ChatSession> loadSessions() {
    final String? raw = _prefs.getString(_kSessionsKey);
    if (raw == null || raw.isEmpty) return <ChatSession>[];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ChatSession.fromJson)
          .toList();
    } catch (_) {
      return <ChatSession>[];
    }
  }

  Future<void> saveSessions(List<ChatSession> sessions) async {
    final String raw = jsonEncode(
      sessions.map((ChatSession s) => s.toJson()).toList(),
    );
    await _prefs.setString(_kSessionsKey, raw);
  }

  // ---- Images ------------------------------------------------------------

  List<GeneratedImage> loadImages() {
    final String? raw = _prefs.getString(_kImagesKey);
    if (raw == null || raw.isEmpty) return <GeneratedImage>[];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(GeneratedImage.fromJson)
          .toList();
    } catch (_) {
      return <GeneratedImage>[];
    }
  }

  Future<void> saveImages(List<GeneratedImage> images) async {
    final String raw = jsonEncode(
      images.map((GeneratedImage i) => i.toJson()).toList(),
    );
    await _prefs.setString(_kImagesKey, raw);
  }

  // ---- Pinned widgets ----------------------------------------------------

  List<PinnedWidget> loadPinnedWidgets() {
    final String? raw = _prefs.getString(_kPinnedKey);
    if (raw == null || raw.isEmpty) return <PinnedWidget>[];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PinnedWidget.fromJson)
          .toList();
    } catch (_) {
      return <PinnedWidget>[];
    }
  }

  Future<void> savePinnedWidgets(List<PinnedWidget> widgets) async {
    final String raw = jsonEncode(
      widgets.map((PinnedWidget w) => w.toJson()).toList(),
    );
    await _prefs.setString(_kPinnedKey, raw);
  }

  // ---- Usage counter -----------------------------------------------------

  int get usageCount => _prefs.getInt(_kUsageKey) ?? 0;

  Future<void> setUsageCount(int value) =>
      _prefs.setInt(_kUsageKey, value);

  // ---- Language ----------------------------------------------------------

  String get language => _prefs.getString(_kLangKey) ?? 'uk';

  Future<void> setLanguage(String code) =>
      _prefs.setString(_kLangKey, code);
}
