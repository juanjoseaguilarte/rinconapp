import 'dart:async';
import 'package:flutter/material.dart';

class AppState with ChangeNotifier {
  Timer? _logoutTimer;
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  void login() {
    _isLoggedIn = true;
    _startLogoutTimer();
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _logoutTimer?.cancel();
    notifyListeners();
  }

  void _startLogoutTimer() {
    _logoutTimer?.cancel();
    _logoutTimer = Timer(const Duration(minutes: 15), () {
      logout();
    });
  }

  void resetLogoutTimer() {
    if (_isLoggedIn) {
      _startLogoutTimer();
    }
  }
}
