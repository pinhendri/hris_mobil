import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import '../data/models/notification_model.dart';
import '../services/session_storage.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  Future<String> _getToken() async {
    return SessionStorage.getToken();
  }

  Future<String?> _getCompanyCode() async {
    return SessionStorage.getCompanyCode();
  }

  Future<dynamic> _fetchJsonWithRetry({
    required Uri uri,
    required Map<String, String> headers,
    int attempts = 2,
  }) async {
    Object? lastError;

    for (int attempt = 1; attempt <= attempts; attempt++) {
      final response = await http.get(uri, headers: headers);
      print('GET notifications attempt $attempt -> ${response.statusCode}');

      if (response.statusCode != 200) {
        lastError = Exception('HTTP ${response.statusCode}: ${response.body}');
        if (attempt < attempts) {
          await Future.delayed(const Duration(milliseconds: 250));
          continue;
        }
        throw lastError;
      }

      final rawBody = utf8.decode(response.bodyBytes);

      try {
        return await compute(_decodeNotificationJson, rawBody);
      } on FormatException catch (e) {
        lastError = e;
        print('Invalid notifications JSON on attempt $attempt: $e');
        if (attempt < attempts) {
          await Future.delayed(const Duration(milliseconds: 250));
          continue;
        }
        rethrow;
      }
    }

    throw lastError ?? Exception('Failed to load notifications');
  }

  Future<void> fetchNotifications() async {
    if (_isLoading) {
      print('Notifications fetch already running, skip duplicate call.');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      final companyCode = await _getCompanyCode();

      if (token.isEmpty) {
        print('No token found for notifications');
        return;
      }

      final body = await _fetchJsonWithRetry(
        uri: Uri.parse('${ApiConstants.baseUrl}/api/notifications'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Company-Code': companyCode ?? '',
        },
      );

      if (body is Map<String, dynamic> &&
          body['success'] == true &&
          body['data'] is List) {
        _notifications =
            (body['data'] as List)
                .whereType<Map<String, dynamic>>()
                .map(NotificationItem.fromJson)
                .toList(growable: true)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        _unreadCount = _notifications.where((item) => !item.isRead).length;
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final token = await _getToken();
      final companyCode = await _getCompanyCode();

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/notifications/$id/read'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Company-Code': companyCode ?? '',
        },
      );

      if (response.statusCode == 200) {
        final index = _notifications.indexWhere((item) => item.id == id);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          _unreadCount = _notifications.where((item) => !item.isRead).length;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final unreadNotifications = _notifications
        .where((notification) => !notification.isRead)
        .toList(growable: false);
    if (unreadNotifications.isEmpty) {
      return;
    }

    try {
      final token = await _getToken();
      final companyCode = await _getCompanyCode();

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/notifications/mark-all-read'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Company-Code': companyCode ?? '',
        },
      );

      if (response.statusCode == 200) {
        for (int index = 0; index < _notifications.length; index++) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
        }
        _unreadCount = 0;
        notifyListeners();
        return;
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }

    for (final notification in unreadNotifications) {
      await markAsRead(notification.id);
    }
  }

  Future<void> refreshNotifications() async {
    await fetchNotifications();
  }
}

dynamic _decodeNotificationJson(String rawBody) {
  return json.decode(rawBody);
}
