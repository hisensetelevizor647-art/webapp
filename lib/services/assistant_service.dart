import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// Bridge to native Android bits needed for the "assistant over other apps"
/// experience: overlay permission, default-assistant role, screenshot capture
/// via MediaProjection, and opening the prompt overlay.
class AssistantService extends ChangeNotifier {
  static const MethodChannel _ch =
      MethodChannel('com.oleksandrai.app/assistant');

  bool _overlayShown = false;
  bool get overlayShown => _overlayShown;

  /// Ensures SYSTEM_ALERT_WINDOW is granted. Sends the user to the system
  /// page if it isn't — no automatic grant is possible on Android 6+.
  Future<bool> ensureOverlayPermission() async {
    try {
      final bool granted = await FlutterOverlayWindow.isPermissionGranted();
      if (granted) return true;
      await FlutterOverlayWindow.requestPermission();
      // requestPermission does not await the system dialog result; the caller
      // should re-check on return. We return the current value.
      return FlutterOverlayWindow.isPermissionGranted();
    } catch (e) {
      debugPrint('[Assistant] overlay permission error: $e');
      return false;
    }
  }

  /// Opens the "Assist & voice input" system page where the user can pick
  /// OleksandrAi as the default assistant.
  Future<void> openDefaultAssistantSettings() async {
    try {
      await _ch.invokeMethod<void>('openAssistSettings');
    } on PlatformException catch (e) {
      debugPrint('[Assistant] openAssistSettings: ${e.message}');
    }
  }

  /// Show the floating prompt bar. The overlay entry point lives in
  /// `overlayMain()` inside main.dart.
  Future<void> showPromptOverlay() async {
    final bool ok = await ensureOverlayPermission();
    if (!ok) return;
    try {
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: 'OleksandrAi',
        overlayContent: 'Assistant active',
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        height: WindowSize.matchParent,
        width: WindowSize.matchParent,
      );
      _overlayShown = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[Assistant] showOverlay failed: $e');
    }
  }

  Future<void> hidePromptOverlay() async {
    try {
      await FlutterOverlayWindow.closeOverlay();
    } catch (_) {}
    _overlayShown = false;
    notifyListeners();
  }

  /// Ask the native side to perform a one-shot screen capture via
  /// MediaProjection. Returns the saved file path, or null on failure.
  Future<String?> captureScreenshot() async {
    try {
      final String? path =
          await _ch.invokeMethod<String>('captureScreenshot');
      return path;
    } on PlatformException catch (e) {
      debugPrint('[Assistant] captureScreenshot: ${e.message}');
      return null;
    }
  }
}
