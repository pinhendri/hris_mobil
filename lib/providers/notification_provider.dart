import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../data/models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<String?> _getCompanyCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('company_code');
  }

  // Fetch notifications from API
  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      final companyCode = await _getCompanyCode();
      
      if (token.isEmpty) {
        print('❌ No token found');
        _isLoading = false;
        notifyListeners();
        return;
      }

      print('📡 Fetching notifications from API...');
      
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/notifications'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Company-Code': companyCode ?? '',
        },
      );

      print('📡 Notifications response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        
        if (body['success'] == true && body['data'] != null) {
          _notifications = (body['data'] as List)
              .map((item) => NotificationItem.fromJson(item))
              .toList();
          
          // Sort by date (newest first)
          _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          _unreadCount = _notifications.where((n) => !n.isRead).length;
          
          print('✅ Notifications fetched: ${_notifications.length}');
          print('📊 Unread count: $_unreadCount');
        }
      } else {
        print('❌ Failed to fetch notifications: ${response.statusCode}');
        print('📦 Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark single notification as read
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
        // Update local state
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          _unreadCount = _notifications.where((n) => !n.isRead).length;
          notifyListeners();
        }
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
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
        // Update local state
        for (int i = 0; i < _notifications.length; i++) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
  }

  // Refresh notifications (pull to refresh)
  Future<void> refreshNotifications() async {
    await fetchNotifications();
  }
}