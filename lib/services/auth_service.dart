import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Handles sign in and keeps the session token in secure storage
/// (Keychain on iOS, EncryptedSharedPreferences on Android),
/// never in plain shared preferences.
///
/// This demo signs in locally. In production, [signIn] would call the
/// backend and store the access token it returns.
class AuthService {
  AuthService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const _tokenKey = 'ecopay_session_token';
  static const _emailKey = 'ecopay_user_email';
  static const _pinKey = 'ecopay_lock_pin';

  final FlutterSecureStorage _storage;

  /// Used only when the platform blocks secure storage, for example a
  /// browser in private mode or a sandboxed web preview. The session then
  /// lasts until the app or tab is closed.
  final Map<String, String> _memory = {};

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key) ?? _memory[key];
    } catch (_) {
      return _memory[key];
    }
  }

  Future<void> _write(String key, String value) async {
    _memory[key] = value;
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      // Storage blocked: the in memory copy above is used instead.
    }
  }

  Future<void> _delete(String key) async {
    _memory.remove(key);
    try {
      await _storage.delete(key: key);
    } catch (_) {
      // Nothing stored to clear.
    }
  }

  /// Returns the signed in user's email, or null if there is no session.
  Future<String?> restoreSession() async {
    final token = await _read(_tokenKey);
    if (token == null) return null;
    return _read(_emailKey);
  }

  Future<void> signIn({required String email, required String pin}) async {
    if (!isValidEmail(email)) {
      throw ArgumentError('Enter a valid email address');
    }
    if (!isValidPin(pin)) {
      throw ArgumentError('Your PIN must be 4 digits');
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await _write(_tokenKey, _generateToken());
    await _write(_emailKey, email.trim());
    // Kept in encrypted secure storage so the app lock can check it.
    await _write(_pinKey, pin);
  }

  /// Checks the PIN for the app lock screen.
  Future<bool> verifyPin(String pin) async {
    final saved = await _read(_pinKey);
    if (saved == null) {
      // Sessions from before the app lock existed: adopt the first PIN.
      if (!isValidPin(pin)) return false;
      await _write(_pinKey, pin);
      return true;
    }
    return saved == pin;
  }

  Future<void> signOut() async {
    await _delete(_tokenKey);
    await _delete(_emailKey);
    await _delete(_pinKey);
  }

  static bool isValidEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());

  static bool isValidPin(String pin) => RegExp(r'^\d{4}$').hasMatch(pin);

  String _generateToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
