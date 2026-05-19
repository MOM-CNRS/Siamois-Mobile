import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kSecureEmail = 'siamois_secure_email';
const _kSecurePassword = 'siamois_secure_password';
const _kPrefEmailFallback = 'siamois_cred_email_fallback';
const _kPrefPasswordFallback = 'siamois_cred_password_fallback';

/// Sur macOS (sans certificat dev Apple), le Keychain exige des entitlements signés :
/// on utilise uniquement SharedPreferences. iOS/Android gardent le stockage sécurisé.
bool get _useLocalCredentialCacheOnly =>
    kIsWeb || defaultTargetPlatform == TargetPlatform.macOS;

/// Stocke e-mail / mot de passe pour le renouvellement silencieux du JWT.
class CredentialStore {
  CredentialStore({FlutterSecureStorage? secureStorage})
      : _secure = _useLocalCredentialCacheOnly
            ? null
            : (secureStorage ?? const FlutterSecureStorage());

  final FlutterSecureStorage? _secure;

  Future<void> save(String email, String password) async {
    if (_useLocalCredentialCacheOnly) {
      await _saveToPrefs(email, password);
      return;
    }
    final secure = _secure!;
    try {
      await secure.write(key: _kSecureEmail, value: email);
      await secure.write(key: _kSecurePassword, value: password);
      final p = await SharedPreferences.getInstance();
      await p.remove(_kPrefEmailFallback);
      await p.remove(_kPrefPasswordFallback);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[Siamois] Keychain indisponible ($e) — identifiants en cache local.',
        );
      }
      await _saveToPrefs(email, password);
    }
  }

  Future<({String? email, String? password})> read() async {
    if (_useLocalCredentialCacheOnly) {
      return _readFromPrefs();
    }
    final secure = _secure!;
    try {
      final email = await secure.read(key: _kSecureEmail);
      final password = await secure.read(key: _kSecurePassword);
      if (email != null &&
          email.isNotEmpty &&
          password != null &&
          password.isNotEmpty) {
        return (email: email, password: password);
      }
    } catch (_) {
      /* fallback */
    }
    return _readFromPrefs();
  }

  Future<void> clear() async {
    final secure = _secure;
    if (secure != null) {
      try {
        await secure.delete(key: _kSecureEmail);
        await secure.delete(key: _kSecurePassword);
      } catch (_) {}
    }
    final p = await SharedPreferences.getInstance();
    await p.remove(_kPrefEmailFallback);
    await p.remove(_kPrefPasswordFallback);
  }

  Future<void> _saveToPrefs(String email, String password) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPrefEmailFallback, email);
    await p.setString(_kPrefPasswordFallback, password);
  }

  Future<({String? email, String? password})> _readFromPrefs() async {
    final p = await SharedPreferences.getInstance();
    return (
      email: p.getString(_kPrefEmailFallback),
      password: p.getString(_kPrefPasswordFallback),
    );
  }
}
