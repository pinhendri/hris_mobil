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
  List<CompanyLeaveBatch> _companyLeaveBatches = [];
  bool _isLoading = false;
  bool _isSubmittingCompanyLeaveBatch = false;
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
  List<CompanyLeaveBatch> get companyLeaveBatches => _companyLeaveBatches;
  bool get isLoading => _isLoading;
  bool get isSubmittingCompanyLeaveBatch => _isSubmittingCompanyLeaveBatch;
  String? get error => _error;
  int? get correctEmployeeId => _correctEmployeeId;
  bool get isUsingCachedData => _isUsingCachedData;
  int get pendingSyncCount => _pendingSyncCount;
  String? get syncNotice => _syncNotice;
  String? get lastActionMessage => _lastActionMessage;
  bool get lastActionQueued => _lastActionQueued;
  bool get canManageCompanyLeave {
    final normalizedRoles = <String>{
      _normalizeRole(_authProvider.user?.role ?? ''),
      ..._authProvider.roles.map(_normalizeRole),
    }..removeWhere((role) => role.isEmpty);

    for (final role in normalizedRoles) {
      if (const {
        'administrator',
        'admin',
        'superadmin',
        'super-admin',
        'platform-admin',
      }.contains(role)) {
        return true;
      }

      if (role.contains('hrd') || role.contains('hr-') || role == 'hr') {
        return true;
      }
    }

    return false;
  }

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

      final requestsResponse = await _apiService.get(
        '/leave-requests$_companyQuerySuffix',
      );
      if (requestsResponse is! Map<String, dynamic> ||
          requestsResponse['success'] != true) {
        throw Exception(
          requestsResponse is Map<String, dynamic>
              ? requestsResponse['message'] ?? 'Failed to load leave requests'
              : 'Failed to load leave requests',
        );
      }

      final requestItems = (requestsResponse['data'] as List? ?? const [])
          .whereType<Map>()
          .map((json) => LeaveRequest.fromJson(Map<String, dynamic>.from(json)))
          .toList(growable: true);

      _leaveRequests = requestItems;
      _leaveBalance = null;
      _correctEmployeeId = null;

      try {
        final balanceResponse = await _apiService.get(
          '/leave-balance$_companyQuerySuffix',
        );
        if (balanceResponse is Map<String, dynamic> &&
            balanceResponse['success'] == true &&
            balanceResponse['data'] is Map<String, dynamic>) {
          final balanceData = Map<String, dynamic>.from(
            balanceResponse['data'],
          );
          _leaveBalance = LeaveBalance.fromJson(balanceData);
          _correctEmployeeId = _parseInt(balanceData['employee_id']);
        }
      } catch (_) {
        _leaveBalance = null;
        _correctEmployeeId = null;
      }

      if (canManageCompanyLeave) {
        try {
          final batchesResponse = await _apiService.get(
            '/leave-requests/company-batches$_companyQuerySuffix',
          );
          if (batchesResponse is Map<String, dynamic> &&
              batchesResponse['success'] == true &&
              batchesResponse['data'] is List) {
            _companyLeaveBatches = (batchesResponse['data'] as List)
                .whereType<Map>()
                .map(
                  (json) => CompanyLeaveBatch.fromJson(
                    Map<String, dynamic>.from(json),
                  ),
                )
                .toList(growable: false);
          } else {
            _companyLeaveBatches = [];
          }
        } catch (_) {
          _companyLeaveBatches = [];
        }
      } else {
        _companyLeaveBatches = [];
      }

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
          : _effectiveCompanyCode;

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
        if (_effectiveCompanyCode.isNotEmpty) 'c_code': _effectiveCompanyCode,
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
        if (_effectiveCompanyCode.isNotEmpty) 'c_code': _effectiveCompanyCode,
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

  Future<bool> createCompanyLeaveBatch({
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required String cCode,
  }) async {
    _isSubmittingCompanyLeaveBatch = true;
    _error = null;
    _lastActionQueued = false;
    notifyListeners();

    try {
      final effectiveCompanyCode = cCode.isNotEmpty
          ? cCode
          : _effectiveCompanyCode;
      if (effectiveCompanyCode.isEmpty) {
        throw Exception('Company code not found');
      }

      final normalizedStartDate = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );
      final normalizedEndDate = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
      );

      final payload = {
        'title': title.trim(),
        'description': description.trim(),
        'leave_type': 'Company Leave',
        'start_date': DateFormat('yyyy-MM-dd').format(normalizedStartDate),
        'end_date': DateFormat('yyyy-MM-dd').format(normalizedEndDate),
        'days': normalizedEndDate.difference(normalizedStartDate).inDays + 1,
        'c_code': effectiveCompanyCode,
      };

      final response = await _apiService.post(
        '/leave-requests/company-batches',
        payload,
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        _lastActionMessage =
            response['message']?.toString() ??
            'Company leave batch created successfully.';
        await fetchLeaveData();
        return true;
      }

      _error = response is Map<String, dynamic>
          ? response['message']?.toString() ??
                'Failed to create company leave batch'
          : 'Failed to create company leave batch';
      return false;
    } catch (error) {
      _error = 'Error: ${OfflineSupport.normalizeMessage(error)}';
      return false;
    } finally {
      _isSubmittingCompanyLeaveBatch = false;
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

  String _normalizeRole(String value) {
    return value.trim().toLowerCase().replaceAll('_', '-').replaceAll(' ', '-');
  }

  String get _effectiveCompanyCode =>
      _selectedCCode ?? _authProvider.getCompanyCode();

  String get _companyQuerySuffix {
    final companyCode = _effectiveCompanyCode.trim();
    if (companyCode.isEmpty) {
      return '';
    }

    return '?c_code=${Uri.encodeComponent(companyCode)}';
  }

  String get _currentEmployeeUuid {
    return _authProvider.user?.employeeUuid ?? _authProvider.user?.uuid ?? '';
  }

  String get _cacheKey =>
      'leave::${_currentEmployeeUuid.isEmpty ? 'self' : _currentEmployeeUuid}';
}
