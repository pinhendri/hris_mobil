import 'dart:async';

import 'package:flutter/material.dart';

import '../services/session_storage.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider({bool loadOnInit = true}) {
    if (loadOnInit) {
      unawaited(loadSavedTheme());
    }
  }

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> loadSavedTheme() async {
    final savedTheme = await SessionStorage.getThemeMode();
    if (savedTheme == null || savedTheme == _themeMode) {
      return;
    }

    _themeMode = savedTheme;
    notifyListeners();
  }

  void toggleTheme(bool isDark) {
    setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) {
      return;
    }

    _themeMode = mode;
    notifyListeners();
    unawaited(SessionStorage.saveThemeMode(mode));
  }
}
