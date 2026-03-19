import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  LanguageProvider({bool loadOnInit = true}) {
    if (loadOnInit) {
      unawaited(loadSavedLanguage());
    }
  }

  static const String _languageCodeKey = 'app_language_code';
  static const List<Locale> supportedLocales = [
    Locale('id', 'ID'),
    Locale('en', 'US'),
  ];

  Locale _locale = const Locale('id', 'ID');
  bool _hasLoadedSavedLanguage = false;

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  Future<void> loadSavedLanguage() async {
    if (_hasLoadedSavedLanguage) {
      return;
    }

    _hasLoadedSavedLanguage = true;
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_languageCodeKey);

    if (savedCode == null || savedCode.isEmpty) {
      return;
    }

    await setLanguageCode(savedCode, persist: false);
  }

  Future<void> setLanguageCode(
    String languageCode, {
    bool persist = true,
  }) async {
    final normalizedCode = languageCode.trim().toLowerCase();
    final matchedLocale = supportedLocales.firstWhere(
      (locale) => locale.languageCode == normalizedCode,
      orElse: () => const Locale('id', 'ID'),
    );

    if (_locale == matchedLocale) {
      return;
    }

    _locale = matchedLocale;

    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageCodeKey, matchedLocale.languageCode);
    }

    notifyListeners();
  }

  Future<void> setLocale(Locale locale) {
    return setLanguageCode(locale.languageCode);
  }
}
