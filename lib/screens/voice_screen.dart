import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../services/ai_service.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _available = false;
  bool _listening = false;
  String _transcript = '';
  String _status = 'Tap the circle to start';

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _available = await _speech.initialize(
        onError: (dynamic e) => debugPrint('[Voice] $e'),
        onStatus: (String s) {
          if (!mounted) return;
          setState(() {
            _listening = s == 'listening';
            _status = _listening ? 'Listening…' : 'Tap the circle to start';
          });
        },
      );
    } catch (e) {
      debugPrint('[Voice] init error: $e');
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggle() async {
    if (!_available) {
      setState(() => _status = 'Microphone not available.');
      return;
    }
    if (_listening) {
      await _speech.stop();
      final String finalText = _transcript.trim();
      if (finalText.isNotEmpty && mounted) {
        await context.read<AiService>().sendUserMessage(finalText);
        await _speakLastReply();
      }
    } else {
      setState(() => _transcript = '');
      await _speech.listen(
        onResult: (dynamic r) {
          if (!mounted) return;
          setState(() => _transcript = r.recognizedWords as String);
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _speakLastReply() async {
    final AiService ai = context.read<AiService>();
    final String last = ai.activeSession.messages.isEmpty
        ? ''
        : ai.activeSession.messages.last.text;
    if (last.isEmpty) return;
    try {
      await _tts.setSpeechRate(0.5);
      await _tts.speak(last);
    } catch (e) {
      debugPrint('[Voice] tts error: $e');
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Spacer(),
          AnimatedBuilder(
            animation: _pulse,
            builder: (BuildContext _, Widget? __) {
              final double scale = _listening ? 1.0 + _pulse.value * 0.15 : 1.0;
              return Transform.scale(
                scale: scale,
                child: GestureDetector(
                  onTap: _toggle,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: _listening ? Colors.black : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black,
                        width: _listening ? 0 : 2,
                      ),
                      boxShadow: _listening
                          ? <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 40,
                                spreadRadius: 4,
                              )
                            ]
                          : null,
                    ),
                    child: Icon(
                      _listening ? Icons.graphic_eq : Icons.mic_none_rounded,
                      color: _listening ? Colors.white : Colors.black,
                      size: 64,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            _status,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _transcript.isEmpty
                  ? 'Your words will appear here…'
                  : _transcript,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _transcript.isEmpty ? Colors.black45 : Colors.black87,
                fontStyle: _transcript.isEmpty
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
