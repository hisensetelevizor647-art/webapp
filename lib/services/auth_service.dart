import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';

enum AuthStatus { unknown, signedOut, signedIn }

/// Represents a signed-in end user, independent of any single provider.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.idToken,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? idToken;
}

/// Wraps `google_sign_in` with a ChangeNotifier surface so the rest of the
/// app only knows about [AppUser] + [AuthStatus].
class AuthService extends ChangeNotifier {
  AuthService()
      : _googleSignIn = GoogleSignIn(
          // The web OAuth client ID supplied by the user. Setting it as
          // serverClientId lets us request an idToken on Android without any
          // additional configuration beyond an Android OAuth client in GCP
          // (registered with the APK signing SHA-1).
          serverClientId: AppConfig.googleWebClientId,
          scopes: const <String>['email', 'profile', 'openid'],
        );

  final GoogleSignIn _googleSignIn;

  AuthStatus _status = AuthStatus.unknown;
  AuthStatus get status => _status;

  AppUser? _user;
  AppUser? get user => _user;

  String? _error;
  String? get error => _error;

  bool _busy = false;
  bool get busy => _busy;

  /// Try to pick up an existing session silently on app launch.
  Future<void> bootstrap() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      if (account != null) {
        await _finalize(account);
      } else {
        _setStatus(AuthStatus.signedOut);
      }
    } catch (e) {
      debugPrint('[Auth] bootstrap error: $e');
      _setStatus(AuthStatus.signedOut);
    }
  }

  Future<void> signInWithGoogle() async {
    if (_busy) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        // User cancelled.
        _busy = false;
        notifyListeners();
        return;
      }
      await _finalize(account);
    } catch (e) {
      debugPrint('[Auth] Google sign-in failed: $e');
      _error = _prettify(e);
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _finalize(GoogleSignInAccount account) async {
    String? idToken;
    try {
      final GoogleSignInAuthentication auth = await account.authentication;
      idToken = auth.idToken;
    } catch (e) {
      debugPrint('[Auth] fetching idToken failed: $e');
    }

    _user = AppUser(
      id: account.id,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
      idToken: idToken,
    );
    _busy = false;
    _setStatus(AuthStatus.signedIn);
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Signing out must always succeed locally even if remote fails.
    }
    _user = null;
    _setStatus(AuthStatus.signedOut);
  }

  void _setStatus(AuthStatus s) {
    _status = s;
    notifyListeners();
  }

  String _prettify(Object e) {
    final String msg = e.toString();
    if (msg.contains('network_error')) return 'Network error. Check connection.';
    if (msg.contains('sign_in_canceled')) return 'Sign in cancelled.';
    if (msg.contains('ApiException: 10')) {
      return 'Sign-in misconfigured: add your APK SHA-1 to the GCP OAuth client.';
    }
    return 'Sign in failed. Please try again.';
  }
}
