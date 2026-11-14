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

  final FlutterSecureStorage _storage;

  /// Returns the signed in user's email, or null if there is no session.
  Future<String?> restoreSession() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return null;
    return _storage.read(key: _emailKey);
  }

  Future<void> signIn({required String email, required String pin}) async {
    if (!isValidEmail(email)) {
      throw ArgumentError('Enter a valid email address');
    }
    if (!isValidPin(pin)) {
      throw ArgumentError('Your PIN must be 4 digits');
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await _storage.write(key: _tokenKey, value: _generateToken());
    await _storage.write(key: _emailKey, value: email.trim());
  }

  Future<void> signOut() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _emailKey);
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
