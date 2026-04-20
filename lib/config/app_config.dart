/// Central place for keys and endpoints.
///
/// Values mirror what was present in the original web `index.html` /
/// `auth.js`. Non-secret identifiers (OAuth client ID, Firebase project ID,
/// public Firebase web API key, Turnstile site key) are safe to ship in a
/// client binary. Any truly secret key MUST be routed through a backend —
/// never embedded in the APK.
class AppConfig {
  AppConfig._();

  /// Google OAuth web client ID — provided by the user.
  /// Used as `serverClientId` to obtain an ID token on Android.
  static const String googleWebClientId =
      '1034187669203-7ssee2rn0ldvhv1c6q7pmrkckj9evvd6.apps.googleusercontent.com';

  // ---- Firebase web config (from auth.js) ---------------------------------
  // These are public identifiers, not secrets. They are kept here in case a
  // future build integrates `firebase_core` + `firebase_auth`.
  static const String firebaseApiKey =
      'AIzaSyC9LEhBI--8tzwRy61XZbafupcP0NcnIi4';
  static const String firebaseAuthDomain = 'oleksandrai-f5565.firebaseapp.com';
  static const String firebaseProjectId = 'oleksandrai-f5565';
  static const String firebaseStorageBucket =
      'oleksandrai-f5565.firebasestorage.app';
  static const String firebaseMessagingSenderId = '1034187669203';
  static const String firebaseAppIdWeb =
      '1:1034187669203:web:dfff76fe755ccf9cb15e26';
  static const String firebaseMeasurementId = 'G-1F5YQDYNK5';

  /// Cloudflare Turnstile site key (public).
  static const String turnstileSiteKey = '0x4AAAAAACaReZTJLCrvUSWB';

  // ---- AI backend ---------------------------------------------------------
  /// Text/image model gateway. Leave empty to use the offline stub that ships
  /// with the app. When you host a real endpoint, drop the URL here (e.g. a
  /// Vercel route that proxies Gemini / OpenAI / etc. using server-side keys).
  ///
  /// Expected contract:
  ///   POST {aiEndpoint}/chat      { model, messages } -> { text }
  ///   POST {aiEndpoint}/image     { prompt, size }    -> { url }  (base64 or https)
  static const String aiEndpoint = '';

  /// Default daily free usage limit (mirrors FREE_LIMIT in auth.js).
  static const int freeDailyLimit = 10;

  /// Primary brand colors pulled from styles.css (accent = --accent-color).
  static const int brandBlack = 0xFF000000;
  static const int brandAccentBlue = 0xFF2B55E5;
  static const int brandAccentOrange = 0xFFF5A623;
}
