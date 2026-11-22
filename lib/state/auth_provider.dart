import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service);

  final AuthService _service;

  AuthStatus status = AuthStatus.unknown;
  String? email;
  String? error;
  bool busy = false;

  /// App lock: when on, the app asks for the PIN after it was hidden.
  bool appLockEnabled = true;
  bool locked = false;
  String? lockError;

  void lock() {
    if (status != AuthStatus.signedIn || !appLockEnabled || locked) return;
    locked = true;
    lockError = null;
    notifyListeners();
  }

  Future<bool> unlock(String pin) async {
    final ok = await _service.verifyPin(pin);
    if (ok) {
      locked = false;
      lockError = null;
    } else {
      lockError = 'Wrong PIN. Try again.';
    }
    notifyListeners();
    return ok;
  }

  void setAppLock(bool value) {
    appLockEnabled = value;
    notifyListeners();
  }

  Future<void> restore() async {
    email = await _service.restoreSession();
    status = email == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    notifyListeners();
  }

  Future<void> signIn(String email, String pin) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await _service.signIn(email: email, pin: pin);
      this.email = email.trim();
      status = AuthStatus.signedIn;
    } on ArgumentError catch (e) {
      error = e.message.toString();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    email = null;
    locked = false;
    status = AuthStatus.signedOut;
    notifyListeners();
  }
}
