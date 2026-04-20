# OleksandrAi — Flutter (Android)

A Flutter port of the OleksandrAi web app. Ships as a single installable
Android APK in the ~60–100 MB range when built as a fat APK.

> v0 does not have the Flutter toolchain. This repo contains **source
> code only**. You compile the APK locally with the standard Flutter
> build commands below.

---

## Features

- Google Sign-In (uses the provided OAuth web client ID as `serverClientId`)
- Chat with the **text model** (pluggable HTTP backend, offline stub included)
- **Image model** generation screen with grid history + delete
- **Learn** mode (NotebookLM-style summarize & ask)
- **Voice** mode with on-device speech-to-text + TTS playback
- **Code Studio** (explain / refactor / review via the chat pipeline)
- **Widgets** — quick-action prompt recipes that can be pinned; any pinned
  widget appears simultaneously on the Chat home rail, in **Settings**, and
  as an Android home-screen **AppWidget** (via `home_widget`)
- **Settings** screen with one-tap actions for: overlay permission, default
  digital-assistant role, pinned-widget management, push-to-launcher
- **Floating prompt overlay** — launches over other apps via
  `flutter_overlay_window`; fullscreen dimmed background with only the
  prompt bar and three buttons (Screenshot, Analyze, Fullscreen)
- **Default assistant intent** — app handles `android.intent.action.ASSIST`
  and `VOICE_COMMAND`, so the user can pick OleksandrAi under
  Settings → Apps → Default apps → Digital assistant app
- **MediaProjection screenshot** — the overlay's Screenshot button captures
  the current screen to the app cache via a one-shot `ScreenshotActivity`
- Persistent chat history + pinned conversations (SharedPreferences)
- Material 3 theme mirroring the web app's minimalist black/white + blue accent

## Project layout

```
flutter_app/
├── pubspec.yaml
├── lib/
│   ├── main.dart             # app bootstrap + providers
│   ├── app.dart              # MaterialApp + auth gate
│   ├── config/app_config.dart
│   ├── theme/app_theme.dart
│   ├── models/
│   │   ├── chat_message.dart
│   │   ├── chat_session.dart
│   │   └── generated_image.dart
│   ├── services/
│   │   ├── auth_service.dart  # Google sign-in
│   │   ├── ai_service.dart    # text + image model orchestration
│   │   └── storage_service.dart
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   ├── home_shell.dart
│   │   ├── chat_screen.dart
│   │   ├── image_screen.dart
│   │   ├── learn_screen.dart
│   │   ├── voice_screen.dart
│   │   ├── code_screen.dart
│   │   └── widgets_screen.dart
│   └── widgets/
│       ├── app_drawer.dart
│       ├── message_bubble.dart
│       ├── prompt_bar.dart
│       └── welcome_chips.dart
├── android/                   # gradle config, manifest, launcher icon
└── assets/images/logo.jpg
```

## Prerequisites

- Flutter SDK **3.22+**, Dart **3.3+**
- Android SDK **34**, build-tools 34.x
- JDK **17**
- Android NDK **26.1.10909125** (installed automatically by Gradle on first build)
- A real device or emulator with Google Play Services (required for Google
  Sign-In)

Verify:

```bash
flutter doctor
```

## 1. Configure the OAuth client

The web client ID is already wired in
`lib/config/app_config.dart`:

```
1034187669203-7ssee2rn0ldvhv1c6q7pmrkckj9evvd6.apps.googleusercontent.com
```

For Android sign-in to actually succeed you **must** register an **Android**
OAuth 2.0 client in the same Google Cloud project:

1. Open Google Cloud Console → APIs & Services → Credentials
2. *Create Credentials → OAuth client ID → Android*
3. Package name: `com.oleksandrai.app`
4. SHA-1: paste the fingerprint of the keystore you will use to sign the APK

Get your debug fingerprint:

```bash
keytool -list -v -alias androiddebugkey \
  -keystore ~/.android/debug.keystore \
  -storepass android -keypass android
```

For a release keystore, run `keytool` against your own `.jks`.

> You don't need `google-services.json` because this build uses the
> `google_sign_in` plugin directly rather than `firebase_auth`.

## 2. Install dependencies

```bash
cd flutter_app
flutter pub get
```

## 3. Run in debug

```bash
flutter run
```

## 4. Build a release APK

### Fat APK (target: ~60–100 MB single installable)

```bash
flutter build apk --release
```

Artifact: `build/app/outputs/flutter-apk/app-release.apk`

### Per-ABI split (smaller per install, ~20–30 MB each)

```bash
flutter build apk --release --split-per-abi
```

### Signing your release APK

1. Generate a keystore:

   ```bash
   keytool -genkey -v -keystore ~/oleksandrai-release.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias oleksandrai
   ```

2. Create `android/key.properties` (ignored by git):

   ```
   storePassword=YOUR_STORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=oleksandrai
   storeFile=/absolute/path/to/oleksandrai-release.jks
   ```

3. Rebuild — `android/app/build.gradle.kts` automatically picks up
   `key.properties` when present.

4. Take the SHA-1 of this keystore and add it to your **Android OAuth
   client** in Google Cloud Console (see step 1).

## 5. Point the app at your AI backend (optional)

Out of the box the app runs against a local **offline stub** so nothing
crashes, even without a backend. To plug in a real model:

1. Stand up an HTTP endpoint that accepts:

   - `POST /chat`  →  `{ "messages": [{role, content}, …] }`  → `{ "text": "…" }`
   - `POST /image` →  `{ "prompt": "…", "size": "1024x1024" }` → `{ "url": "…" }` or `{ "base64": "…" }`

2. Set its base URL in `lib/config/app_config.dart`:

   ```dart
   static const String aiEndpoint = 'https://your-api.example.com';
   ```

3. Rebuild.

**Never embed a real model-provider API key in `AppConfig`** — route all
calls through your own backend and keep secrets on the server.

## 6. APK size tuning

| Build command                                      | Approx size |
| -------------------------------------------------- | ----------- |
| `flutter build apk --release` (this repo default)  | **60–100 MB** (fat APK, all 4 ABIs) |
| `flutter build apk --release --split-per-abi`      | 20–30 MB per ABI |
| `flutter build appbundle --release`                | ~30 MB AAB (Play Store delivery) |

The fat APK hits the 60–100 MB target because it bundles the Flutter
engine for `armeabi-v7a`, `arm64-v8a`, `x86_64`, plus Google Play
Services client bits and the Google/Inter font sets fetched by
`google_fonts` at first launch.

## Keys & settings summary (from `index.html` / `auth.js`)

All non-secret public identifiers are kept in `lib/config/app_config.dart`:

- Google OAuth web client ID
- Firebase project ID / messaging sender ID / web API key / auth domain
- Cloudflare Turnstile site key
- Free daily usage limit (`FREE_LIMIT = 10`)

None of these are secrets — they're safe to ship inside the APK.

## Troubleshooting

- **Sign-in error `ApiException: 10`** → your APK's SHA-1 is not
  registered for the Android OAuth client. Add it in GCP Console.
- **`PlatformException(sign_in_failed)`** → usually a Play Services /
  emulator problem. Test on a device with Google Play.
- **No voice input** → the device didn't grant the mic permission, or
  the OS has no speech recognizer. Grant mic in Android Settings.
- **App installs but shows stub answers** → `AppConfig.aiEndpoint` is
  empty. Set it to your backend URL and rebuild.
