import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../services/session_storage.dart';

class ApiService {
  // ===============================
  // 🌐 BASE URL
  // ===============================
  final String _baseUrl = ApiConstants.baseUrl;

  // ===============================
  // 🔐 HEADERS
  // ===============================
  Future<Map<String, String>> _getHeaders() async {
    final token = await SessionStorage.getToken();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // ===============================
  // 📥 GET
  // ===============================
  Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();

    final response = await http
        .get(Uri.parse('$_baseUrl$endpoint'), headers: headers)
        .timeout(const Duration(seconds: 10));

    return _handleResponse(response);
  }

  // ===============================
  // 📤 POST
  // ===============================
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();

    final response = await http
        .post(
          Uri.parse('$_baseUrl$endpoint'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));

    return _handleResponse(response);
  }

  // ===============================
  // DELETE
  // ===============================
  Future<dynamic> delete(String endpoint) async {
    final headers = await _getHeaders();

    final response = await http
        .delete(Uri.parse('$_baseUrl$endpoint'), headers: headers)
        .timeout(const Duration(seconds: 10));

    return _handleResponse(response);
  }

  // ===============================
  // 📦 RESPONSE HANDLER
  // ===============================
  Future<dynamic> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return <String, dynamic>{};
      }

      return compute(_decodeJsonBody, utf8.decode(response.bodyBytes));
    } else {
      try {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Terjadi kesalahan');
      } catch (_) {
        throw Exception(
          'Error ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    }
  }
}

dynamic _decodeJsonBody(String body) {
  return jsonDecode(body);
}
