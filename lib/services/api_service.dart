import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import 'session_storage.dart';

class ApiService {
  static const String baseUrl = ApiConstants.baseUrl;

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

  // GET METHOD
  Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();
    final url = '$baseUrl/api$endpoint';

    print('📡 GET: $url');

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      print('📥 Response (${response.statusCode}): ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Network error: $e');
      throw Exception('Network error: $e');
    }
  }

  // POST METHOD
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final url = '$baseUrl/api$endpoint';

    print('📡 POST: $url');
    print('📤 Data: $data');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(data),
      );

      print('📥 Response (${response.statusCode}): ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Network error: $e');
      throw Exception('Network error: $e');
    }
  }

  // PUT METHOD
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final url = '$baseUrl/api$endpoint';

    print('📡 PUT: $url');
    print('📤 Data: $data');

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(data),
      );

      print('📥 Response (${response.statusCode}): ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Network error: $e');
      throw Exception('Network error: $e');
    }
  }

  // DELETE METHOD
  Future<dynamic> delete(String endpoint) async {
    final headers = await _getHeaders();
    final url = '$baseUrl/api$endpoint';

    print('📡 DELETE: $url');

    try {
      final response = await http.delete(Uri.parse(url), headers: headers);

      print('📥 Response (${response.statusCode}): ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Network error: $e');
      throw Exception('Network error: $e');
    }
  }
}
