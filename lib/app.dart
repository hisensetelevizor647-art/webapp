import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:provider/provider.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/ai_service.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

class OleksandrAiApp extends StatefulWidget {
  const OleksandrAiApp({super.key});

  @override
  State<OleksandrAiApp> createState() => _OleksandrAiAppState();
}

class _OleksandrAiAppState extends State<OleksandrAiApp> {
  StreamSubscription<dynamic>? _overlayDataSub;

  @override
  void initState() {
    super.initState();
    _listenForOverlayData();
  }

  /// Subscribes to data pushed from the floating overlay. When the user types
  /// something into the overlay prompt bar and taps "Analyze", we forward it
  /// into the active chat session in the main engine.
  void _listenForOverlayData() {
    try {
      _overlayDataSub =
          FlutterOverlayWindow.overlayListener.listen((dynamic event) {
        if (event is Map) {
          final String action = (event['action'] ?? '').toString();
          final String prompt = (event['prompt'] ?? '').toString().trim();
          if (prompt.isEmpty) return;
          final AiService ai = context.read<AiService>();
          if (action == 'analyze' || action == 'openFullscreen') {
            unawaited(ai.sendUserMessage(prompt));
          }
        }
      });
    } catch (e) {
      debugPrint('[OleksandrAi] overlay listener unavailable: $e');
    }
  }

  @override
  void dispose() {
    _overlayDataSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OleksandrAi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final AuthService auth = context.watch<AuthService>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const SplashScreen();
      case AuthStatus.signedOut:
        return const LoginScreen();
      case AuthStatus.signedIn:
        return const HomeShell();
    }
  }
}
