import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  SessionStorage._();

  static const String tokenKey = 'token';
  static const String companyCodeKey = 'company_code';
  static const String userDataKey = 'user_data';
  static const String companyAssignmentsKey = 'company_assignments';
  static const String rememberMeKey = 'remember_me';
  static const String rememberedEmailKey = 'remembered_email';
  static const String rememberedPasswordKey = 'remembered_password';
  static const String themeModeKey = 'theme_mode';
  static const List<String> _sessionPreferenceKeys = <String>[
    tokenKey,
    companyCodeKey,
    userDataKey,
    companyAssignmentsKey,
    'user',
    'userData',
    'selectedCompany',
    'selectedCompanyId',
    'selectedCcode',
    'selected_c_code',
    'c_code',
    'company_assignments_json',
    'company_assignments_data',
    'permissions',
    'roles',
    'role',
    'login_time',
    'trialStatusSnapshot',
  ];
  static const List<String> _legacyTokenKeys = <String>[
    'auth_token',
    'token',
    'access_token',
    'user_token',
    'api_token',
    'bearer_token',
    'jwt_token',
    'login_token',
    'session_token',
  ];

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static String? _cachedToken;
  static String? _cachedCompanyCode;

  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    await _secureStorage.write(key: tokenKey, value: token);
  }

  static Future<String> getToken() async {
    final cachedToken = _cachedToken;
    if (cachedToken != null && cachedToken.isNotEmpty) {
      return cachedToken;
    }

    final secureToken = await _secureStorage.read(key: tokenKey);
    if (secureToken != null && secureToken.isNotEmpty) {
      _cachedToken = secureToken;
      return secureToken;
    }

    final prefs = await SharedPreferences.getInstance();
    for (final key in _legacyTokenKeys) {
      final legacyToken = prefs.getString(key);
      if (legacyToken != null && legacyToken.isNotEmpty) {
        await saveToken(legacyToken);
        if (key != tokenKey) {
          await prefs.remove(key);
        }
        await prefs.remove(tokenKey);
        return legacyToken;
      }
    }

    return '';
  }

  static Future<void> saveCompanyCode(String companyCode) async {
    _cachedCompanyCode = companyCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(companyCodeKey, companyCode);
  }

  static Future<String?> getCompanyCode() async {
    final cachedCompanyCode = _cachedCompanyCode;
    if (cachedCompanyCode != null && cachedCompanyCode.isNotEmpty) {
      return cachedCompanyCode;
    }

    final prefs = await SharedPreferences.getInstance();
    final companyCode = prefs.getString(companyCodeKey);
    if (companyCode != null && companyCode.isNotEmpty) {
      _cachedCompanyCode = companyCode;
    }

    return companyCode;
  }

  static Future<void> saveUserData(String rawJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userDataKey, rawJson);
  }

  static Future<String?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userDataKey);
  }

  static Future<void> saveCompanyAssignments(String rawJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(companyAssignmentsKey, rawJson);
  }

  static Future<void> saveRememberedEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(rememberMeKey, true);
    await prefs.setString(rememberedEmailKey, email);
    await _secureStorage.delete(key: rememberedPasswordKey);
  }

  static Future<Map<String, String?>> getRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(rememberMeKey) ?? false;

    if (!rememberMe) {
      return {'email': null, 'password': null};
    }

    final email = prefs.getString(rememberedEmailKey);
    await _secureStorage.delete(key: rememberedPasswordKey);

    return {'email': email, 'password': null};
  }

  static Future<bool> isRememberMeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(rememberMeKey) ?? false;
  }

  static Future<void> clearRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(rememberMeKey);
    await prefs.remove(rememberedEmailKey);
    await _secureStorage.delete(key: rememberedPasswordKey);
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themeModeKey, mode.name);
  }

  static Future<ThemeMode?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(themeModeKey)?.trim();

    switch (savedTheme) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
        return ThemeMode.light;
      default:
        return null;
    }
  }

  static Future<void> clearSession() async {
    _cachedToken = null;
    _cachedCompanyCode = null;
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.delete(key: tokenKey);
    await _secureStorage.delete(key: rememberedPasswordKey);

    for (final key in _sessionPreferenceKeys) {
      await prefs.remove(key);
    }

    for (final key in _legacyTokenKeys) {
      await prefs.remove(key);
    }
  }
}
