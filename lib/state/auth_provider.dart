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
    status = AuthStatus.signedOut;
    notifyListeners();
  }
}
