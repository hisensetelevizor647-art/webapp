import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
// The overlay entry point `overlayMain()` is declared as a top-level,
// `@pragma('vm:entry-point')` function inside overlay_entry.dart. Importing
// the file here ensures it is included in the build output.
import 'screens/overlay_entry.dart' show overlayMain;
import 'services/ai_service.dart';
import 'services/assistant_service.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/widget_registry_service.dart';

// Keep `overlayMain` reachable from the tree-shaker. A no-op call is fine
// because we never invoke this helper at runtime — the reference alone is
// enough for AOT to retain the entry point.
// ignore: unused_element
void _keepOverlayMain() => overlayMain;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait for a phone-first experience. Remove to allow landscape.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Soft status bar theming that matches the minimalist web design.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // Eagerly bootstrap storage so downstream services can read prefs sync.
  final StorageService storage = StorageService();
  await storage.init();

  // Global error guard: any uncaught Flutter error is logged and shown, never a crash loop.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[OleksandrAi] ${details.exceptionAsString()}');
  };

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService()..bootstrap(),
        ),
        ChangeNotifierProvider<AiService>(
          create: (_) => AiService(storage: storage),
        ),
        ChangeNotifierProvider<WidgetRegistryService>(
          create: (_) => WidgetRegistryService(storage: storage),
        ),
        ChangeNotifierProvider<AssistantService>(
          create: (_) => AssistantService(),
        ),
      ],
      child: const OleksandrAiApp(),
    ),
  );
}
