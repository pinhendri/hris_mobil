import 'package:flutter/material.dart';

import '../models/broadcast_models.dart';
import '../services/api_service.dart';

class BroadcastProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<BroadcastDepartmentOption> _departments = const [];
  List<BroadcastEmployeeOption> _employees = const [];
  List<BroadcastHistoryItem> _history = const [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _companyRequired = false;
  String? _error;

  List<BroadcastDepartmentOption> get departments => _departments;
  List<BroadcastEmployeeOption> get employees => _employees;
  List<BroadcastHistoryItem> get history => _history;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get companyRequired => _companyRequired;
  String? get error => _error;

  Future<void> initialize({bool showLoading = true}) async {
    _error = null;
    _companyRequired = false;

    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    String? firstError;

    await Future.wait<void>([
      _loadDepartments().catchError((Object error) {
        firstError ??= _normalizeError(error);
      }),
      _loadEmployees().catchError((Object error) {
        final message = _normalizeError(error);
        if (_looksLikeCompanyRequired(message)) {
          _companyRequired = true;
        } else {
          firstError ??= message;
        }
      }),
      _loadHistory().catchError((Object error) {
        firstError ??= _normalizeError(error);
      }),
    ]);

    if (!_companyRequired) {
      _error = firstError;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshHistory() async {
    try {
      await _loadHistory();
      _error = null;
    } catch (error) {
      _error = _normalizeError(error);
    }

    notifyListeners();
  }

  Future<bool> sendBroadcast({
    required String title,
    required String message,
    required String type,
    required List<int> departmentIds,
    required List<int> employeeIds,
    required String priority,
    required int recipientCount,
  }) async {
    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/broadcast/send', {
        'title': title.trim(),
        'message': message.trim(),
        'type': type,
        'department_ids': departmentIds,
        'employee_ids': employeeIds,
        'priority': priority,
        'recipient_count': recipientCount,
      });

      if (response is Map<String, dynamic> && response['success'] == false) {
        throw Exception(
          response['message']?.toString() ?? 'Failed to send broadcast',
        );
      }

      try {
        await _loadHistory();
      } catch (_) {
        // Keep the successful submit flow responsive even if history refresh
        // cannot be loaded immediately.
      }

      return true;
    } catch (error) {
      _error = _normalizeError(error);
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> _loadDepartments() async {
    final response = await _apiService.get('/departments');
    final items = _extractList(
      response,
      preferredKeys: const ['departments', 'data'],
    );

    _departments = items
        .whereType<Map>()
        .map(
          (item) => BroadcastDepartmentOption.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((department) => department.id > 0 && department.name.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _loadEmployees() async {
    final response = await _apiService.get('/employees');
    final items = _extractList(
      response,
      preferredKeys: const ['employees', 'data'],
    );

    _employees = items
        .whereType<Map>()
        .map(
          (item) =>
              BroadcastEmployeeOption.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((employee) => employee.id > 0 && employee.name.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _loadHistory() async {
    final response = await _apiService.get('/broadcast/history');
    final items = _extractList(
      response,
      preferredKeys: const ['history', 'broadcasts', 'data'],
    );

    final parsed = items
        .whereType<Map>()
        .map(
          (item) =>
              BroadcastHistoryItem.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((entry) => entry.title.isNotEmpty || entry.message.isNotEmpty)
        .toList(growable: false);

    parsed.sort((left, right) {
      final rightDate = right.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final leftDate = left.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return rightDate.compareTo(leftDate);
    });

    _history = parsed;
  }

  bool _looksLikeCompanyRequired(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('select a company') ||
        normalized.contains('company first') ||
        normalized.contains('company required');
  }

  String _normalizeError(Object error) {
    final raw = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
    final normalized = raw
        .replaceFirst(RegExp(r'^Network error:\s*'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return normalized.isEmpty
        ? 'Terjadi kesalahan saat memuat broadcast.'
        : normalized;
  }

  List<dynamic> _extractList(
    dynamic value, {
    List<String> preferredKeys = const [],
  }) {
    if (value is List) {
      return List<dynamic>.from(value);
    }

    if (value is Map<String, dynamic>) {
      for (final key in preferredKeys) {
        final extracted = _extractList(
          value[key],
          preferredKeys: preferredKeys,
        );
        if (extracted.isNotEmpty) {
          return extracted;
        }
      }

      for (final key in const [
        'data',
        'items',
        'results',
        'history',
        'broadcasts',
        'employees',
        'departments',
      ]) {
        final extracted = _extractList(
          value[key],
          preferredKeys: preferredKeys,
        );
        if (extracted.isNotEmpty) {
          return extracted;
        }
      }
    }

    return const [];
  }
}
