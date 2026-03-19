import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  SessionStorage._();

  static const String tokenKey = 'token';
  static const String companyCodeKey = 'company_code';
  static const String userDataKey = 'user_data';
  static const String companyAssignmentsKey = 'company_assignments';
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

  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: _androidOptions,
  );

  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: tokenKey, value: token);
  }

  static Future<String> getToken() async {
    final secureToken = await _secureStorage.read(key: tokenKey);
    if (secureToken != null && secureToken.isNotEmpty) {
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(companyCodeKey, companyCode);
  }

  static Future<String?> getCompanyCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(companyCodeKey);
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

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.delete(key: tokenKey);
    await prefs.remove(tokenKey);
    await prefs.remove(companyCodeKey);
    await prefs.remove(userDataKey);
    await prefs.remove(companyAssignmentsKey);

    for (final key in _legacyTokenKeys) {
      if (key != tokenKey) {
        await prefs.remove(key);
      }
    }
  }
}
