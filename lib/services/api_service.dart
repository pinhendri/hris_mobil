import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import 'session_storage.dart';

class ApiService {
  static const String baseUrl = ApiConstants.baseUrl;
  static const Duration _requestTimeout = Duration(seconds: 12);
  static const int _maxLoggedBodyLength = 240;

  Future<Map<String, String>> _getHeaders() async {
    final token = await SessionStorage.getToken();
    final companyCode = (await SessionStorage.getCompanyCode())?.trim() ?? '';

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (companyCode.isNotEmpty) {
      headers['X-Company-Code'] = companyCode;
    }

    return headers;
  }

  Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();
    final url = '$baseUrl/api$endpoint';

    _debugLog('GET: $url');

    try {
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(_requestTimeout);

      _debugLog(
        'GET Response (${response.statusCode}): ${_previewBody(response.body)}',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _decodeResponse(response);
      }

      throw Exception(
        'HTTP ${response.statusCode}: ${_previewBody(response.body)}',
      );
    } catch (error) {
      _debugLog('GET error: $error');
      throw Exception('Network error: $error');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final url = '$baseUrl/api$endpoint';

    _debugLog('POST: $url');
    _debugLog('POST Payload: ${_previewBody(jsonEncode(data))}');

    try {
      final response = await http
          .post(Uri.parse(url), headers: headers, body: jsonEncode(data))
          .timeout(_requestTimeout);

      _debugLog(
        'POST Response (${response.statusCode}): ${_previewBody(response.body)}',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _decodeResponse(response);
      }

      throw Exception(
        'HTTP ${response.statusCode}: ${_previewBody(response.body)}',
      );
    } catch (error) {
      _debugLog('POST error: $error');
      throw Exception('Network error: $error');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final url = '$baseUrl/api$endpoint';

    _debugLog('PUT: $url');
    _debugLog('PUT Payload: ${_previewBody(jsonEncode(data))}');

    try {
      final response = await http
          .put(Uri.parse(url), headers: headers, body: jsonEncode(data))
          .timeout(_requestTimeout);

      _debugLog(
        'PUT Response (${response.statusCode}): ${_previewBody(response.body)}',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _decodeResponse(response);
      }

      throw Exception(
        'HTTP ${response.statusCode}: ${_previewBody(response.body)}',
      );
    } catch (error) {
      _debugLog('PUT error: $error');
      throw Exception('Network error: $error');
    }
  }

  Future<dynamic> patch(String endpoint, [Map<String, dynamic>? data]) async {
    final headers = await _getHeaders();
    final url = '$baseUrl/api$endpoint';

    _debugLog('PATCH: $url');
    if (data != null) {
      _debugLog('PATCH Payload: ${_previewBody(jsonEncode(data))}');
    }

    try {
      final response = await http
          .patch(
            Uri.parse(url),
            headers: headers,
            body: data == null ? null : jsonEncode(data),
          )
          .timeout(_requestTimeout);

      _debugLog(
        'PATCH Response (${response.statusCode}): ${_previewBody(response.body)}',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _decodeResponse(response);
      }

      throw Exception(
        'HTTP ${response.statusCode}: ${_previewBody(response.body)}',
      );
    } catch (error) {
      _debugLog('PATCH error: $error');
      throw Exception('Network error: $error');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final headers = await _getHeaders();
    final url = '$baseUrl/api$endpoint';

    _debugLog('DELETE: $url');

    try {
      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(_requestTimeout);

      _debugLog(
        'DELETE Response (${response.statusCode}): ${_previewBody(response.body)}',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _decodeResponse(response);
      }

      throw Exception(
        'HTTP ${response.statusCode}: ${_previewBody(response.body)}',
      );
    } catch (error) {
      _debugLog('DELETE error: $error');
      throw Exception('Network error: $error');
    }
  }

  Future<dynamic> _decodeResponse(http.Response response) async {
    if (response.bodyBytes.isEmpty) {
      return <String, dynamic>{};
    }

    return compute(_decodeJsonBody, utf8.decode(response.bodyBytes));
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  String _previewBody(String body) {
    final normalized = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= _maxLoggedBodyLength) {
      return normalized;
    }

    return '${normalized.substring(0, _maxLoggedBodyLength)}...';
  }
}

dynamic _decodeJsonBody(String body) => jsonDecode(body);
