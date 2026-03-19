import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/models/correction_model.dart';
import '../services/api_service.dart';
import '../services/offline_support.dart';
import '../services/session_storage.dart';

class CorrectionProvider with ChangeNotifier {
  CorrectionProvider() {
    unawaited(_bootstrapOfflineSupport());
  }

  final ApiService _apiService = ApiService();

  List<CorrectionRequest> _requests = [];
  bool _isLoading = false;
  String? _error;
  AttendanceData? _attendanceData;
  bool _isUsingCachedData = false;
  int _pendingSyncCount = 0;
  String? _syncNotice;
  String? _lastActionMessage;
  bool _lastActionQueued = false;
  Timer? _offlineSyncTimer;

  List<CorrectionRequest> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AttendanceData? get attendanceData => _attendanceData;
  bool get isUsingCachedData => _isUsingCachedData;
  int get pendingSyncCount => _pendingSyncCount;
  String? get syncNotice => _syncNotice;
  String? get lastActionMessage => _lastActionMessage;
  bool get lastActionQueued => _lastActionQueued;

  Future<void> _bootstrapOfflineSupport() async {
    await _refreshPendingSyncState(notify: false);
    await fetchRequests();
    _offlineSyncTimer ??= Timer.periodic(const Duration(seconds: 45), (_) {
      unawaited(syncOfflineActions(silent: true));
    });
  }

  @override
  void dispose() {
    _offlineSyncTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queuedByCurrentUser = await _loadQueuedCorrectionRequests();
      _requests = queuedByCurrentUser;
    } catch (error) {
      _error = OfflineSupport.normalizeMessage(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AttendanceData> getAttendanceForCorrection({
    required String employeeUuid,
    required String date,
  }) async {
    _isLoading = true;
    _error = null;
    _isUsingCachedData = false;
    notifyListeners();

    final cacheKey = _attendanceCacheKey(employeeUuid, date);

    try {
      final response = await _apiService.get(
        '/attendances/getAttendanceForCorrection?employee_uuid=$employeeUuid&date=$date',
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        final data = AttendanceData.fromJson(
          Map<String, dynamic>.from(response['data']),
        );
        _attendanceData = await _mergePendingCorrectionIntoAttendance(data);
        await OfflineSupport.saveJsonCache(cacheKey, _attendanceData!.toJson());
        return _attendanceData!;
      }

      throw Exception(
        response is Map<String, dynamic>
            ? response['message'] ?? 'Failed to get attendance'
            : 'Failed to get attendance',
      );
    } catch (error) {
      final cached = await OfflineSupport.getJsonCache(cacheKey);
      if (cached is Map<String, dynamic>) {
        _attendanceData = await _mergePendingCorrectionIntoAttendance(
          AttendanceData.fromJson(cached),
        );
        _isUsingCachedData = true;
        return _attendanceData!;
      }

      final fallback = await _buildPendingAttendanceFallback(
        employeeUuid: employeeUuid,
        date: date,
      );
      if (fallback != null) {
        _attendanceData = fallback;
        _isUsingCachedData = true;
        return fallback;
      }

      _error = OfflineSupport.normalizeMessage(error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAttendanceCorrection({
    required String identifier,
    required Map<String, dynamic> data,
  }) async {
    _isLoading = true;
    _error = null;
    _lastActionQueued = false;
    _lastActionMessage = null;
    notifyListeners();

    try {
      try {
        final response = await _apiService.put(
          '/attendances/attendance-correction/$identifier',
          data,
        );

        if (response is Map<String, dynamic> && response['success'] == true) {
          _lastActionQueued = false;
          _lastActionMessage =
              response['message']?.toString() ?? 'Koreksi tersimpan.';

          final responseData = response['data'];
          if (responseData is Map<String, dynamic>) {
            _attendanceData = AttendanceData.fromJson(responseData);
            await OfflineSupport.saveJsonCache(
              _attendanceCacheKey(
                _attendanceData!.employeeUuid,
                _attendanceData!.date,
              ),
              _attendanceData!.toJson(),
            );
          }

          await fetchRequests();
          return true;
        }

        _error = response is Map<String, dynamic>
            ? response['message']?.toString() ?? 'Failed to update attendance'
            : 'Failed to update attendance';
        return false;
      } catch (error) {
        if (!OfflineSupport.isRetryableSyncError(error)) {
          rethrow;
        }

        await _queueOfflineCorrection(identifier: identifier, data: data);
        return true;
      }
    } catch (error) {
      _error = OfflineSupport.normalizeMessage(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveRequest(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final index = _requests.indexWhere((request) => request.id == id);
      if (index == -1) {
        return false;
      }

      _requests[index] = CorrectionRequest(
        id: _requests[index].id,
        type: _requests[index].type,
        description: _requests[index].description,
        status: 'Approved',
        targetDate: _requests[index].targetDate,
        employeeId: _requests[index].employeeId,
        details: _requests[index].details,
      );
      return true;
    } catch (error) {
      _error = OfflineSupport.normalizeMessage(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> rejectRequest(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final index = _requests.indexWhere((request) => request.id == id);
      if (index == -1) {
        return false;
      }

      _requests[index] = CorrectionRequest(
        id: _requests[index].id,
        type: _requests[index].type,
        description: _requests[index].description,
        status: 'Rejected',
        targetDate: _requests[index].targetDate,
        employeeId: _requests[index].employeeId,
        details: _requests[index].details,
      );
      return true;
    } catch (error) {
      _error = OfflineSupport.normalizeMessage(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addRequest(CorrectionRequest request) {
    _requests.add(request);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> syncOfflineActions({
    bool silent = false,
    bool refreshAfterSync = true,
  }) async {
    final currentUserUuid = await _getCurrentUserUuid();
    if (currentUserUuid == null || currentUserUuid.isEmpty) {
      return;
    }

    final queuedItems = await OfflineSupport.getQueuedRequests(
      feature: 'correction',
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
      if (payload['_queued_by_uuid']?.toString() != currentUserUuid) {
        continue;
      }

      final identifier = payload.remove('_identifier')?.toString() ?? '';
      payload.remove('_queued_by_uuid');

      try {
        final response = await _apiService.put(
          '/attendances/attendance-correction/$identifier',
          payload,
        );

        if (response is Map<String, dynamic> && response['success'] == true) {
          await OfflineSupport.deleteQueuedRequest(queueId);
          _lastActionQueued = false;
          _lastActionMessage = 'Koreksi offline berhasil disinkronkan.';

          final data = response['data'];
          if (data is Map<String, dynamic>) {
            final attendance = AttendanceData.fromJson(data);
            await OfflineSupport.saveJsonCache(
              _attendanceCacheKey(attendance.employeeUuid, attendance.date),
              attendance.toJson(),
            );
          }
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
      await fetchRequests();
    }

    await _refreshPendingSyncState(notify: !silent);
    if (!silent) {
      notifyListeners();
    }
  }

  Future<void> _queueOfflineCorrection({
    required String identifier,
    required Map<String, dynamic> data,
  }) async {
    final currentUserUuid = await _getCurrentUserUuid() ?? '';
    final employeeUuid =
        data['employee_uuid']?.toString() ??
        _attendanceData?.employeeUuid ??
        '';
    final date = data['date']?.toString() ?? _attendanceData?.date ?? '';

    await OfflineSupport.enqueueRequest(
      feature: 'correction',
      action: 'update_attendance_correction',
      endpoint: '/attendances/attendance-correction/$identifier',
      method: 'PUT',
      payload: {
        ...data,
        '_identifier': identifier,
        '_queued_by_uuid': currentUserUuid,
      },
      employeeUuid: employeeUuid,
      date: date,
      lastError: 'queued_offline',
    );

    final mergedAttendance = AttendanceData(
      id: _attendanceData?.id,
      employeeUuid: employeeUuid,
      clockIn: data['clock_in']?.toString() ?? _attendanceData?.clockIn,
      clockOut: data['clock_out']?.toString() ?? _attendanceData?.clockOut,
      status: data['status']?.toString() ?? _attendanceData?.status,
      date: date,
      exists: _attendanceData?.exists ?? false,
      employee: _attendanceData?.employee,
      isPendingSync: true,
    );

    _attendanceData = mergedAttendance;
    await OfflineSupport.saveJsonCache(
      _attendanceCacheKey(employeeUuid, date),
      mergedAttendance.toJson(),
    );
    _lastActionQueued = true;
    _lastActionMessage =
        'Koreksi absensi disimpan offline dan akan dikirim saat server online.';
    await _refreshPendingSyncState(notify: false);
    await fetchRequests();
  }

  Future<List<CorrectionRequest>> _loadQueuedCorrectionRequests() async {
    final currentUserUuid = await _getCurrentUserUuid() ?? '';
    final queuedItems = await OfflineSupport.getQueuedRequests(
      feature: 'correction',
    );

    return queuedItems
        .where((item) {
          final payload = OfflineSupport.decodeQueuePayload(item);
          return payload['_queued_by_uuid']?.toString() == currentUserUuid;
        })
        .map((item) {
          final payload = OfflineSupport.decodeQueuePayload(item);
          final date = DateTime.tryParse(payload['date']?.toString() ?? '');
          return CorrectionRequest(
            id: 'offline-${item['id']}',
            type: 'Attendance Correction',
            description:
                'Koreksi absensi untuk ${payload['date']?.toString() ?? '-'}',
            status: 'Pending Sync',
            targetDate: date,
            employeeId: payload['employee_uuid']?.toString() ?? '',
            details: payload,
          );
        })
        .toList(growable: false);
  }

  Future<AttendanceData> _mergePendingCorrectionIntoAttendance(
    AttendanceData base,
  ) async {
    final queuedItems = await OfflineSupport.getQueuedRequests(
      feature: 'correction',
      employeeUuid: base.employeeUuid,
    );

    for (final item in queuedItems) {
      final payload = OfflineSupport.decodeQueuePayload(item);
      if (payload['date']?.toString() != base.date) {
        continue;
      }

      return base.copyWith(
        clockIn: payload['clock_in']?.toString() ?? base.clockIn,
        clockOut: payload['clock_out']?.toString() ?? base.clockOut,
        status: payload['status']?.toString() ?? base.status,
        isPendingSync: true,
      );
    }

    return base;
  }

  Future<AttendanceData?> _buildPendingAttendanceFallback({
    required String employeeUuid,
    required String date,
  }) async {
    final queuedItems = await OfflineSupport.getQueuedRequests(
      feature: 'correction',
      employeeUuid: employeeUuid,
    );

    for (final item in queuedItems) {
      final payload = OfflineSupport.decodeQueuePayload(item);
      if (payload['date']?.toString() != date) {
        continue;
      }

      return AttendanceData(
        id: null,
        employeeUuid: employeeUuid,
        clockIn: payload['clock_in']?.toString(),
        clockOut: payload['clock_out']?.toString(),
        status: payload['status']?.toString(),
        date: date,
        exists: false,
        isPendingSync: true,
      );
    }

    return null;
  }

  Future<void> _refreshPendingSyncState({bool notify = true}) async {
    final currentUserUuid = await _getCurrentUserUuid() ?? '';
    final queuedItems = await OfflineSupport.getQueuedRequests(
      feature: 'correction',
    );
    _pendingSyncCount = queuedItems.where((item) {
      final payload = OfflineSupport.decodeQueuePayload(item);
      return payload['_queued_by_uuid']?.toString() == currentUserUuid;
    }).length;

    _syncNotice = _pendingSyncCount > 0
        ? 'Ada $_pendingSyncCount koreksi offline menunggu sinkronisasi.'
        : null;

    if (notify) {
      notifyListeners();
    }
  }

  String _attendanceCacheKey(String employeeUuid, String date) {
    return 'correction::attendance::$employeeUuid::$date';
  }

  Future<String?> _getCurrentUserUuid() async {
    final rawUserData = await SessionStorage.getUserData();
    if (rawUserData == null || rawUserData.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawUserData);
      if (decoded is Map<String, dynamic>) {
        final employeeUuid = decoded['employee_uuid']?.toString();
        final uuid = decoded['uuid']?.toString();
        if (employeeUuid != null && employeeUuid.isNotEmpty) {
          return employeeUuid;
        }
        return uuid;
      }
    } catch (_) {
      // Ignore malformed session data.
    }

    return null;
  }
}
