import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Ganti dengan URL backend Anda
  static const String baseUrl = 'http://10.0.2.2:8000'; // Untuk Android Emulator
  // static const String baseUrl = 'http://localhost:8000'; // Untuk iOS Simulator
  // static const String baseUrl = 'https://api.modernland.co.id'; // Untuk Production

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); // Sesuaikan dengan key token Anda

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
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
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
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
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
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
}