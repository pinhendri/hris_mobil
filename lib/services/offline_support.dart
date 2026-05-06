import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../data/local/database_helper.dart';

class OfflineSupport {
  OfflineSupport._();

  static final DatabaseHelper _db = DatabaseHelper();

  static Future<void> saveJsonCache(String key, Object? value) async {
    await _db.saveCache(key, jsonEncode(value));
  }

  static Future<dynamic> getJsonCache(String key) async {
    final raw = await _db.getCache(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  static bool isLikelyOfflineError(Object error) {
    if (error is SocketException ||
        error is http.ClientException ||
        error is HandshakeException) {
      return true;
    }

    final message = error.toString().toLowerCase();
    if (RegExp(r'http\s+\d{3}').hasMatch(message)) {
      return false;
    }

    return message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('connection error') ||
        message.contains('network error') ||
        message.contains('connection closed') ||
        message.contains('software caused connection abort');
  }

  static String normalizeMessage(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  static bool isRetryableSyncError(Object error) {
    if (isLikelyOfflineError(error)) {
      return true;
    }

    final message = error.toString();
    return message.contains('HTTP 502') ||
        message.contains('HTTP 503') ||
        message.contains('HTTP 504') ||
        message.contains('HTTP 408') ||
        message.contains('HTTP 429');
  }

  static Future<int> enqueueRequest({
    required String feature,
    required String action,
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
    String? employeeUuid,
    String? date,
    String? lastError,
  }) {
    return _db.insertOfflineQueueItem({
      'feature': feature,
      'action': action,
      'endpoint': endpoint,
      'method': method,
      'payload': jsonEncode(payload),
      'employee_uuid': employeeUuid,
      'date': date,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'retry_count': 0,
      'last_error': lastError,
    });
  }

  static Future<List<Map<String, dynamic>>> getQueuedRequests({
    String? feature,
    String? employeeUuid,
  }) {
    return _db.getOfflineQueueItems(
      feature: feature,
      employeeUuid: employeeUuid,
    );
  }

  static Future<int> countQueuedRequests({
    String? feature,
    String? employeeUuid,
  }) {
    return _db.countOfflineQueueItems(
      feature: feature,
      employeeUuid: employeeUuid,
    );
  }

  static Future<void> deleteQueuedRequest(int id) {
    return _db.deleteOfflineQueueItem(id);
  }

  static Future<void> markQueuedRequestRetry(
    int id, {
    required int retryCount,
    String? lastError,
  }) {
    return _db.updateOfflineQueueItem(id, {
      'retry_count': retryCount,
      'last_error': lastError,
    });
  }

  static Future<void> updateQueuedRequest(int id, Map<String, dynamic> data) {
    return _db.updateOfflineQueueItem(id, data);
  }

  static Map<String, dynamic> decodeQueuePayload(Map<String, dynamic> item) {
    final rawPayload = item['payload']?.toString();
    if (rawPayload == null || rawPayload.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(rawPayload);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Ignore malformed payloads and return an empty map.
    }

    return <String, dynamic>{};
  }

  static String buildOfflineId(String prefix) {
    return '$prefix-${DateTime.now().millisecondsSinceEpoch}';
  }
}
