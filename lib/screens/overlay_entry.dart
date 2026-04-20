import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// Separate Flutter engine entry point used by flutter_overlay_window.
///
/// This widget renders fullscreen on top of other apps as a pure prompt
/// surface — only the input bar and three action buttons are visible.
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _OverlayApp());
}

class _OverlayApp extends StatelessWidget {
  const _OverlayApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _OverlayRoot(),
    );
  }
}

class _OverlayRoot extends StatefulWidget {
  const _OverlayRoot();

  @override
  State<_OverlayRoot> createState() => _OverlayRootState();
}

class _OverlayRootState extends State<_OverlayRoot> {
  static const MethodChannel _nativeCh =
      MethodChannel('com.oleksandrai.app/assistant');

  final TextEditingController _c = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _busy = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    try {
      await FlutterOverlayWindow.closeOverlay();
    } catch (_) {}
  }

  Future<void> _screenshot() async {
    setState(() {
      _busy = true;
      _status = 'Capturing screen…';
    });
    try {
      final String? path =
          await _nativeCh.invokeMethod<String>('captureScreenshot');
      setState(() {
        _status = path != null ? 'Saved: $path' : 'Capture cancelled';
      });
    } catch (e) {
      setState(() => _status = 'Capture failed');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _analyze() async {
    final String text = _c.text.trim();
    if (text.isEmpty) {
      setState(() => _status = 'Type a prompt first.');
      return;
    }
    setState(() {
      _busy = true;
      _status = 'Analyzing…';
    });
    try {
      // Forward the prompt to the main engine so the chat screen picks it up.
      await FlutterOverlayWindow.shareData(<String, String>{
        'action': 'analyze',
        'prompt': text,
      });
      _c.clear();
      setState(() => _status = 'Sent to OleksandrAi.');
    } catch (e) {
      setState(() => _status = 'Failed to send.');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _openFullscreen() async {
    try {
      await FlutterOverlayWindow.shareData(<String, String>{
        'action': 'openFullscreen',
        'prompt': _c.text.trim(),
      });
      await _nativeCh.invokeMethod<void>('launchApp');
    } catch (_) {}
    await _close();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    return Material(
      color: Colors.black.withOpacity(0.55),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + mq.viewInsets.bottom,
          ),
          child: Column(
            children: <Widget>[
              // Top row: close button.
              Row(
                children: <Widget>[
                  const _Brand(),
                  const Spacer(),
                  _IconChip(
                    icon: Icons.close_rounded,
                    onTap: _close,
                    label: 'Close',
                  ),
                ],
              ),
              const Spacer(),
              // Status bar.
              if (_status != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _status!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              // Prompt bar + actions.
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextField(
                      controller: _c,
                      focusNode: _focus,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Ask OleksandrAi anything…',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        _ActionButton(
                          icon: Icons.screenshot_rounded,
                          label: 'Screenshot',
                          enabled: !_busy,
                          onTap: _screenshot,
                        ),
                        const SizedBox(width: 8),
                        _ActionButton(
                          icon: Icons.auto_awesome_rounded,
                          label: 'Analyze',
                          enabled: !_busy,
                          primary: true,
                          onTap: _analyze,
                        ),
                        const SizedBox(width: 8),
                        _ActionButton(
                          icon: Icons.open_in_full_rounded,
                          label: 'Fullscreen',
                          enabled: !_busy,
                          onTap: _openFullscreen,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'OleksandrAi',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({
    required this.icon,
    required this.onTap,
    required this.label,
  });
  final IconData icon;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: Material(
        color: Colors.white.withOpacity(0.12),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.primary = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final Color bg = primary ? Colors.black : const Color(0xFFF3F4F6);
    final Color fg = primary ? Colors.white : Colors.black87;
    return Expanded(
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(icon, size: 18, color: fg),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
