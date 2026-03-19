import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/leave_model.dart';
import '../services/api_service.dart';
import '../services/offline_support.dart';
import 'auth_provider.dart';

class LeaveProvider with ChangeNotifier {
  LeaveProvider(this._authProvider) {
    unawaited(_bootstrapOfflineSupport());
  }

  final AuthProvider _authProvider;
  final ApiService _apiService = ApiService();

  List<LeaveRequest> _leaveRequests = [];
  LeaveBalance? _leaveBalance;
  bool _isLoading = false;
  String? _error;
  String? _selectedCCode;
  int? _correctEmployeeId;
  bool _isUsingCachedData = false;
  int _pendingSyncCount = 0;
  String? _syncNotice;
  String? _lastActionMessage;
  bool _lastActionQueued = false;
  Timer? _offlineSyncTimer;

  List<LeaveRequest> get leaveRequests => _leaveRequests;
  LeaveBalance? get leaveBalance => _leaveBalance;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get correctEmployeeId => _correctEmployeeId;
  bool get isUsingCachedData => _isUsingCachedData;
  int get pendingSyncCount => _pendingSyncCount;
  String? get syncNotice => _syncNotice;
  String? get lastActionMessage => _lastActionMessage;
  bool get lastActionQueued => _lastActionQueued;

  Future<void> _bootstrapOfflineSupport() async {
    await _refreshPendingSyncState(notify: false);
    _offlineSyncTimer ??= Timer.periodic(const Duration(seconds: 45), (_) {
      unawaited(syncOfflineActions(silent: true));
    });
  }

  @override
  void dispose() {
    _offlineSyncTimer?.cancel();
    super.dispose();
  }

  void setCompanyCode(String cCode) {
    _selectedCCode = cCode;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> fetchLeaveData() async {
    _isLoading = true;
    _error = null;
    _isUsingCachedData = false;
    notifyListeners();

    try {
      await syncOfflineActions(silent: true, refreshAfterSync: false);

      final requestsResponse = await _apiService.get('/leave-requests');
      if (requestsResponse is! Map<String, dynamic> ||
          requestsResponse['success'] != true) {
        throw Exception(
          requestsResponse is Map<String, dynamic>
              ? requestsResponse['message'] ?? 'Failed to load leave requests'
              : 'Failed to load leave requests',
        );
      }

      final balanceResponse = await _apiService.get('/leave-balance');
      if (balanceResponse is! Map<String, dynamic> ||
          balanceResponse['success'] != true ||
          balanceResponse['data'] == null) {
        throw Exception(
          balanceResponse is Map<String, dynamic>
              ? balanceResponse['message'] ?? 'Failed to load leave balance'
              : 'Failed to load leave balance',
        );
      }

      final requestItems = (requestsResponse['data'] as List? ?? const [])
          .whereType<Map>()
          .map((json) => LeaveRequest.fromJson(Map<String, dynamic>.from(json)))
          .toList(growable: true);

      _leaveRequests = requestItems;
      _leaveBalance = LeaveBalance.fromJson(
        Map<String, dynamic>.from(balanceResponse['data']),
      );
      _correctEmployeeId = _parseInt(balanceResponse['data']['employee_id']);

      await _mergePendingOfflineRequests();
      await _saveCache();
      await _refreshPendingSyncState(notify: false);
    } catch (error) {
      final loadedFromCache = await _loadCache();
      await _mergePendingOfflineRequests();
      await _refreshPendingSyncState(notify: false);

      if (!loadedFromCache && _leaveRequests.isEmpty) {
        _error = 'Connection error: ${OfflineSupport.normalizeMessage(error)}';
      } else {
        _error = null;
        _isUsingCachedData = true;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitLeaveRequestWithUser({
    required String employeeUuid,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required int days,
    required String reason,
    required String cCode,
  }) async {
    if (_correctEmployeeId == null) {
      await fetchLeaveData();
    }

    if (_correctEmployeeId == null) {
      _error =
          'Employee ID belum tersedia. Buka halaman leave saat online minimal sekali.';
      notifyListeners();
      return false;
    }

    return submitLeaveRequest(
      type: type,
      startDate: startDate,
      endDate: endDate,
      days: days,
      reason: reason,
      cCode: cCode,
    );
  }

  Future<bool> submitLeaveRequest({
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required int days,
    required String reason,
    required String cCode,
  }) async {
    _isLoading = true;
    _error = null;
    _lastActionQueued = false;
    _lastActionMessage = null;
    notifyListeners();

    try {
      if (_authProvider.user == null) {
        throw Exception('User not logged in');
      }

      if (_correctEmployeeId == null) {
        await fetchLeaveData();
      }

      if (_correctEmployeeId == null) {
        throw Exception(
          'Employee ID belum tersedia. Buka halaman leave saat online minimal sekali.',
        );
      }

      final effectiveCompanyCode = cCode.isNotEmpty
          ? cCode
          : (_selectedCCode ?? _authProvider.getCompanyCode());

      final requestData = _buildSubmitPayload(
        employeeId: _correctEmployeeId!,
        type: type,
        startDate: startDate,
        endDate: endDate,
        days: days,
        reason: reason,
        cCode: effectiveCompanyCode,
      );

      try {
        final response = await _apiService.post('/leave-requests', requestData);
        if (response is Map<String, dynamic> && response['success'] == true) {
          _lastActionQueued = false;
          _lastActionMessage =
              response['message']?.toString() ?? 'Leave request submitted.';
          await fetchLeaveData();
          return true;
        }

        _error = response is Map<String, dynamic>
            ? response['message']?.toString() ?? 'Failed to submit request'
            : 'Failed to submit request';
        return false;
      } catch (error) {
        if (!OfflineSupport.isRetryableSyncError(error)) {
          rethrow;
        }

        await _queueOfflineLeaveRequest(requestData);
        return true;
      }
    } catch (error) {
      _error = 'Error: ${OfflineSupport.normalizeMessage(error)}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveRequest(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.put('/leave-requests/$id', {
        'status': 'Approved',
      });

      if (response is Map<String, dynamic> && response['success'] == true) {
        await fetchLeaveData();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> rejectRequest(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.put('/leave-requests/$id', {
        'status': 'Rejected',
      });

      if (response is Map<String, dynamic> && response['success'] == true) {
        await fetchLeaveData();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int getRemainingDays(String type) {
    if (_leaveBalance == null) {
      return 0;
    }

    switch (type) {
      case 'Annual Leave':
        return _leaveBalance!.annualTotal - _leaveBalance!.annualUsed;
      case 'Sick Leave':
        return _leaveBalance!.sickTotal - _leaveBalance!.sickUsed;
      case 'Personal Leave':
        return _leaveBalance!.personalTotal - _leaveBalance!.personalUsed;
      default:
        return 0;
    }
  }

  Future<void> syncOfflineActions({
    bool silent = false,
    bool refreshAfterSync = true,
  }) async {
    final employeeUuid = _currentEmployeeUuid;
    if (employeeUuid.isEmpty) {
      return;
    }

    final queuedItems = await OfflineSupport.getQueuedRequests(
      feature: 'leave',
      employeeUuid: employeeUuid,
    );

    if (queuedItems.isEmpty) {
      await _refreshPendingSyncState(notify: !silent);
      return;
    }

    for (final item in queuedItems) {
      final queueId = item['id'] as int?;
      if (queueId == null) {
        continue;
      }

      final payload = OfflineSupport.decodeQueuePayload(item);
      try {
        final response = await _apiService.post('/leave-requests', payload);
        if (response is Map<String, dynamic> && response['success'] == true) {
          await OfflineSupport.deleteQueuedRequest(queueId);
          _lastActionQueued = false;
          _lastActionMessage = 'Leave offline berhasil disinkronkan.';
        } else {
          await OfflineSupport.deleteQueuedRequest(queueId);
        }
      } catch (error) {
        if (OfflineSupport.isRetryableSyncError(error)) {
          final retryCount =
              int.tryParse(item['retry_count']?.toString() ?? '0') ?? 0;
          await OfflineSupport.markQueuedRequestRetry(
            queueId,
            retryCount: retryCount + 1,
            lastError: OfflineSupport.normalizeMessage(error),
          );
          break;
        }

        await OfflineSupport.deleteQueuedRequest(queueId);
      }
    }

    if (refreshAfterSync) {
      await fetchLeaveData();
      return;
    }

    await _mergePendingOfflineRequests();
    await _refreshPendingSyncState(notify: !silent);
    if (!silent) {
      notifyListeners();
    }
  }

  Future<void> _queueOfflineLeaveRequest(Map<String, dynamic> payload) async {
    await OfflineSupport.enqueueRequest(
      feature: 'leave',
      action: 'submit_leave_request',
      endpoint: '/leave-requests',
      method: 'POST',
      payload: payload,
      employeeUuid: _currentEmployeeUuid,
      date: payload['start_date']?.toString(),
      lastError: 'queued_offline',
    );

    _lastActionQueued = true;
    _lastActionMessage =
        'Leave request disimpan offline dan akan dikirim saat server online.';
    await _mergePendingOfflineRequests();
    await _saveCache();
    await _refreshPendingSyncState(notify: false);
  }

  Map<String, dynamic> _buildSubmitPayload({
    required int employeeId,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required int days,
    required String reason,
    required String cCode,
  }) {
    return {
      'employee_id': employeeId,
      'type': type,
      'start_date': DateFormat('yyyy-MM-dd').format(startDate),
      'end_date': DateFormat('yyyy-MM-dd').format(endDate),
      'days': days,
      'reason': reason,
      'c_code': cCode,
    };
  }

  Future<void> _mergePendingOfflineRequests() async {
    final employeeUuid = _currentEmployeeUuid;
    if (employeeUuid.isEmpty) {
      return;
    }

    final queuedItems = await OfflineSupport.getQueuedRequests(
      feature: 'leave',
      employeeUuid: employeeUuid,
    );

    final merged = <String, LeaveRequest>{
      for (final request in _leaveRequests) request.id: request,
    };

    for (final item in queuedItems) {
      final payload = OfflineSupport.decodeQueuePayload(item);
      final queueId =
          item['id']?.toString() ?? OfflineSupport.buildOfflineId('leave');
      final createdAtMillis =
          int.tryParse(item['created_at']?.toString() ?? '0') ?? 0;
      final createdAt = createdAtMillis > 0
          ? DateTime.fromMillisecondsSinceEpoch(
              createdAtMillis,
            ).toIso8601String()
          : DateTime.now().toIso8601String();
      final currentUser = _authProvider.user;

      merged['offline-$queueId'] = LeaveRequest(
        id: 'offline-$queueId',
        uuid: currentUser?.employeeUuid ?? currentUser?.uuid ?? '',
        employeeName: currentUser?.name ?? 'My Request',
        employeeAvatar: '',
        immediateSupervisor: null,
        type: payload['type']?.toString() ?? 'Annual Leave',
        startDate: payload['start_date']?.toString() ?? '',
        endDate: payload['end_date']?.toString() ?? '',
        days: _parseInt(payload['days']) ?? 0,
        status: 'Pending Sync',
        reason: payload['reason']?.toString() ?? '',
        createdAt: createdAt,
        isPendingSync: true,
      );
    }

    _leaveRequests = merged.values.toList(growable: true)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _saveCache() {
    return OfflineSupport.saveJsonCache(_cacheKey, {
      'leaveRequests': _leaveRequests
          .where((request) => !request.isPendingSync)
          .map((request) => request.toJson())
          .toList(),
      'leaveBalance': _leaveBalance?.toJson(),
      'correctEmployeeId': _correctEmployeeId,
    });
  }

  Future<bool> _loadCache() async {
    final cached = await OfflineSupport.getJsonCache(_cacheKey);
    if (cached is! Map<String, dynamic>) {
      return false;
    }

    final leaveRequests = cached['leaveRequests'];
    if (leaveRequests is List) {
      _leaveRequests = leaveRequests
          .whereType<Map>()
          .map((json) => LeaveRequest.fromJson(Map<String, dynamic>.from(json)))
          .toList(growable: true);
    }

    final leaveBalance = cached['leaveBalance'];
    if (leaveBalance is Map<String, dynamic>) {
      _leaveBalance = LeaveBalance.fromJson(leaveBalance);
    }

    _correctEmployeeId = _parseInt(cached['correctEmployeeId']);
    _isUsingCachedData =
        _leaveRequests.isNotEmpty ||
        _leaveBalance != null ||
        _correctEmployeeId != null;
    return _isUsingCachedData;
  }

  Future<void> _refreshPendingSyncState({bool notify = true}) async {
    final employeeUuid = _currentEmployeeUuid;
    if (employeeUuid.isEmpty) {
      _pendingSyncCount = 0;
      _syncNotice = null;
      if (notify) {
        notifyListeners();
      }
      return;
    }

    _pendingSyncCount = await OfflineSupport.countQueuedRequests(
      feature: 'leave',
      employeeUuid: employeeUuid,
    );

    _syncNotice = _pendingSyncCount > 0
        ? 'Ada $_pendingSyncCount leave request offline menunggu sinkronisasi.'
        : null;

    if (notify) {
      notifyListeners();
    }
  }

  int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '');
  }

  String get _currentEmployeeUuid {
    return _authProvider.user?.employeeUuid ?? _authProvider.user?.uuid ?? '';
  }

  String get _cacheKey =>
      'leave::${_currentEmployeeUuid.isEmpty ? 'self' : _currentEmployeeUuid}';
}
