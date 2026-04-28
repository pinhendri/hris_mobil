import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/claim_model.dart';
import '../services/api_service.dart';
import '../services/offline_support.dart';
import '../services/session_storage.dart';

class ClaimProvider with ChangeNotifier {
  ClaimProvider() {
    Future<void>.microtask(() {
      unawaited(ensureInitialized());
    });
  }

  final ApiService _apiService = ApiService();

  List<ClaimModel> _claims = [];
  List<ClaimEmployeeOption> _employees = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  int? _currentEmployeeId;
  String? _currentEmployeeUuid;
  bool _isUsingCachedData = false;
  int _pendingSyncCount = 0;
  String? _syncNotice;
  String? _lastActionMessage;
  bool _lastActionQueued = false;
  Timer? _offlineSyncTimer;
  bool _isInitialized = false;
  Future<void>? _initializationFuture;

  List<ClaimModel> get claims => _claims;
  List<ClaimEmployeeOption> get employees => _employees;
  List<ClaimModel> get myClaims {
    if (_currentEmployeeId == null) {
      return const [];
    }

    return _claims
        .where((claim) => claim.employeeId == _currentEmployeeId)
        .toList(growable: false);
  }

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  int? get currentEmployeeId => _currentEmployeeId;
  bool get isUsingCachedData => _isUsingCachedData;
  int get pendingSyncCount => _pendingSyncCount;
  String? get syncNotice => _syncNotice;
  String? get lastActionMessage => _lastActionMessage;
  bool get lastActionQueued => _lastActionQueued;
  bool get isInitialized => _isInitialized;

  Future<void> ensureInitialized() {
    return _initializationFuture ??= _bootstrapOfflineSupport();
  }

  Future<void> _bootstrapOfflineSupport() async {
    final loadedFromCache = await _loadCache();
    await _refreshPendingSyncState(notify: false);
    _offlineSyncTimer ??= Timer.periodic(const Duration(seconds: 45), (_) {
      unawaited(syncOfflineActions(silent: true));
    });
    _isInitialized = true;

    if (loadedFromCache || _pendingSyncCount > 0) {
      notifyListeners();
    }

    await refresh(showLoading: !loadedFromCache && _claims.isEmpty);
  }

  @override
  void dispose() {
    _offlineSyncTimer?.cancel();
    super.dispose();
  }

  Future<void> refresh({bool showLoading = true}) async {
    _isLoading = showLoading;
    _error = null;
    _isUsingCachedData = false;
    if (showLoading) {
      notifyListeners();
    }

    try {
      await _ensureCurrentEmployeeIdentity();
      await syncOfflineActions(silent: true, refreshAfterSync: false);

      final response = await _apiService.get('/claims');
      _claims = _extractClaims(response);
      _employees = _extractEmployees(response);
      _sortClaims();
      await _mergePendingOfflineClaims();
      await _saveCache();
      await _refreshPendingSyncState(notify: false);
    } catch (error) {
      final loadedFromCache = await _loadCache();
      await _mergePendingOfflineClaims();
      await _refreshPendingSyncState(notify: false);

      if (!loadedFromCache && _claims.isEmpty) {
        _error = _normalizeError(error);
      } else {
        _error = null;
        _isUsingCachedData = true;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitClaim(ClaimModel claim) async {
    _isSubmitting = true;
    _error = null;
    _lastActionQueued = false;
    _lastActionMessage = null;
    notifyListeners();

    try {
      final employeeId = claim.employeeId ?? await _ensureCurrentEmployeeId();
      if (employeeId == null) {
        throw Exception(
          'Profil karyawan belum tersedia. Buka menu claim saat online minimal sekali.',
        );
      }

      final payload = claim.toRequestPayload(employeeId: employeeId);

      try {
        final response = await _apiService.post('/claims', payload);
        final createdClaim = _extractClaim(response);
        if (createdClaim != null) {
          _upsertClaim(createdClaim);
          await _saveCache();
        } else {
          await refresh();
        }

        _lastActionQueued = false;
        _lastActionMessage = 'Claim submitted.';
        return true;
      } catch (error) {
        if (!OfflineSupport.isRetryableSyncError(error)) {
          rethrow;
        }

        await _queueOfflineClaimSubmission(
          claim,
          payload,
          employeeId: employeeId,
        );
        return true;
      }
    } catch (error) {
      _error = _normalizeError(error);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> updateClaim(ClaimModel updated) async {
    _isSubmitting = true;
    _error = null;
    _lastActionQueued = false;
    _lastActionMessage = null;
    notifyListeners();

    try {
      final employeeId = updated.employeeId ?? await _ensureCurrentEmployeeId();
      if (employeeId == null) {
        throw Exception(
          'Profil karyawan belum tersedia. Buka menu claim saat online minimal sekali.',
        );
      }

      final payload = updated.toRequestPayload(employeeId: employeeId);

      if (updated.id.startsWith('offline-')) {
        final queueId = int.tryParse(updated.id.replaceFirst('offline-', ''));
        if (queueId == null) {
          throw Exception('Offline claim queue tidak valid.');
        }

        await OfflineSupport.markQueuedRequestRetry(
          queueId,
          retryCount: 0,
          lastError: null,
        );
        await _replaceQueuedPayload(queueId, payload);
        await _mergePendingOfflineClaims();
        await _saveCache();
        _lastActionQueued = true;
        _lastActionMessage =
            'Perubahan claim offline diperbarui dan menunggu sinkronisasi.';
        await _refreshPendingSyncState(notify: false);
        return true;
      }

      try {
        final response = await _apiService.put(
          '/claims/${updated.id}',
          payload,
        );
        final refreshedClaim = _extractClaim(response);
        if (refreshedClaim != null) {
          _upsertClaim(refreshedClaim);
          await _saveCache();
        } else {
          await refresh();
        }

        _lastActionQueued = false;
        _lastActionMessage = 'Claim updated.';
        return true;
      } catch (error) {
        if (!OfflineSupport.isRetryableSyncError(error)) {
          rethrow;
        }

        await _queueOfflineClaimUpdate(
          updated,
          payload,
          employeeId: employeeId,
        );
        return true;
      }
    } catch (error) {
      _error = _normalizeError(error);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> approveClaim(String id) async {
    return _performStatusAction(
      request: () => _apiService.post('/claims/$id/approve', {}),
    );
  }

  Future<bool> rejectClaim(String id, {String? notes}) async {
    return _performStatusAction(
      request: () => _apiService.post('/claims/$id/reject', {
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      }),
    );
  }

  Future<bool> markClaimPaid(String id) async {
    return _performStatusAction(
      request: () => _apiService.post('/claims/$id/mark-paid', {}),
    );
  }

  Future<bool> deleteClaim(String id) async {
    _isSubmitting = true;
    _error = null;
    _lastActionQueued = false;
    _lastActionMessage = null;
    notifyListeners();

    try {
      await _apiService.delete('/claims/$id');
      _claims.removeWhere((claim) => claim.id == id);
      await _saveCache();
      _lastActionMessage = 'Claim deleted.';
      return true;
    } catch (error) {
      _error = _normalizeError(error);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus(String id, String status, {String? notes}) async {
    switch (status) {
      case 'approved':
        return approveClaim(id);
      case 'rejected':
        return rejectClaim(id, notes: notes);
      case 'paid':
        return markClaimPaid(id);
      default:
        _error = 'Status claim tidak didukung.';
        notifyListeners();
        return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> syncOfflineActions({
    bool silent = false,
    bool refreshAfterSync = true,
  }) async {
    final employeeUuid = await _ensureCurrentEmployeeUuid();
    if (employeeUuid == null || employeeUuid.isEmpty) {
      return;
    }

    final queuedItems = await OfflineSupport.getQueuedRequests(
      feature: 'claim',
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
      final action = item['action']?.toString() ?? '';
      try {
        dynamic response;
        if (action == 'update_claim') {
          final claimId = payload.remove('id')?.toString() ?? '';
          response = await _apiService.put('/claims/$claimId', payload);
        } else {
          response = await _apiService.post('/claims', payload);
        }

        if (response is Map<String, dynamic> && response['success'] == true) {
          await OfflineSupport.deleteQueuedRequest(queueId);
          _lastActionQueued = false;
          _lastActionMessage = 'Claim offline berhasil disinkronkan.';
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
      await refresh();
      return;
    }

    await _mergePendingOfflineClaims();
    await _refreshPendingSyncState(notify: !silent);
    if (!silent) {
      notifyListeners();
    }
  }

  Future<bool> _performStatusAction({
    required Future<dynamic> Function() request,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final response = await request();
      final updatedClaim = _extractClaim(response);

      if (updatedClaim != null) {
        _upsertClaim(updatedClaim);
        await _saveCache();
      } else {
        await refresh();
      }

      return true;
    } catch (error) {
      _error = _normalizeError(error);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<int?> _ensureCurrentEmployeeId() async {
    if (_currentEmployeeId != null) {
      return _currentEmployeeId;
    }

    await _ensureCurrentEmployeeIdentity();
    return _currentEmployeeId;
  }

  Future<String?> _ensureCurrentEmployeeUuid() async {
    if (_currentEmployeeUuid != null && _currentEmployeeUuid!.isNotEmpty) {
      return _currentEmployeeUuid;
    }

    await _ensureCurrentEmployeeIdentity();
    return _currentEmployeeUuid;
  }

  Future<void> _ensureCurrentEmployeeIdentity() async {
    if (_currentEmployeeId != null &&
        _currentEmployeeUuid != null &&
        _currentEmployeeUuid!.isNotEmpty) {
      return;
    }

    try {
      final response = await _apiService.get('/me/employee');
      final data = response is Map<String, dynamic> ? response['data'] : null;

      if (data is Map<String, dynamic>) {
        _currentEmployeeId = _parseInt(data['id']);
        _currentEmployeeUuid = data['uuid']?.toString();
        await _saveCache();
        return;
      }
    } catch (_) {
      // Fall back to cache/session.
    }

    await _loadCache();
    _currentEmployeeUuid ??= await _getStoredEmployeeUuid();
  }

  Future<void> _queueOfflineClaimSubmission(
    ClaimModel claim,
    Map<String, dynamic> payload, {
    required int employeeId,
  }) async {
    final employeeUuid = await _ensureCurrentEmployeeUuid() ?? '';
    final queueId = await OfflineSupport.enqueueRequest(
      feature: 'claim',
      action: 'submit_claim',
      endpoint: '/claims',
      method: 'POST',
      payload: payload,
      employeeUuid: employeeUuid,
      date: payload['expense_date']?.toString(),
      lastError: 'queued_offline',
    );

    _upsertClaim(
      claim.copyWith(
        id: 'offline-$queueId',
        employeeId: employeeId,
        employeeUuid: employeeUuid,
        status: 'submitted',
        isPendingSync: true,
      ),
    );
    await _saveCache();
    await _refreshPendingSyncState(notify: false);
    _lastActionQueued = true;
    _lastActionMessage =
        'Claim disimpan offline dan akan dikirim saat server online.';
  }

  Future<void> _queueOfflineClaimUpdate(
    ClaimModel claim,
    Map<String, dynamic> payload, {
    required int employeeId,
  }) async {
    final employeeUuid = await _ensureCurrentEmployeeUuid() ?? '';
    await OfflineSupport.enqueueRequest(
      feature: 'claim',
      action: 'update_claim',
      endpoint: '/claims/${claim.id}',
      method: 'PUT',
      payload: {'id': claim.id, ...payload},
      employeeUuid: employeeUuid,
      date: payload['expense_date']?.toString(),
      lastError: 'queued_offline',
    );

    _upsertClaim(
      claim.copyWith(
        employeeId: employeeId,
        employeeUuid: employeeUuid,
        isPendingSync: true,
      ),
    );
    await _saveCache();
    await _refreshPendingSyncState(notify: false);
    _lastActionQueued = true;
    _lastActionMessage =
        'Perubahan claim disimpan offline dan akan dikirim saat server online.';
  }

  Future<void> _replaceQueuedPayload(
    int queueId,
    Map<String, dynamic> payload,
  ) async {
    await OfflineSupport.updateQueuedRequest(queueId, {
      'payload': jsonEncode(payload),
      'date': payload['expense_date']?.toString(),
      'last_error': 'updated_offline',
      'retry_count': 0,
    });
  }

  Future<void> _mergePendingOfflineClaims() async {
    final employeeUuid = await _ensureCurrentEmployeeUuid() ?? '';
    if (employeeUuid.isEmpty) {
      return;
    }

    final queuedItems = await OfflineSupport.getQueuedRequests(
      feature: 'claim',
      employeeUuid: employeeUuid,
    );
    final merged = <String, ClaimModel>{
      for (final claim in _claims) claim.id: claim,
    };

    for (final item in queuedItems) {
      final queueId = item['id']?.toString() ?? '';
      final payload = OfflineSupport.decodeQueuePayload(item);
      final action = item['action']?.toString() ?? '';
      _currentEmployeeId ??= _parseInt(payload['employee_id']);
      final claimId = action == 'update_claim'
          ? payload['id']?.toString() ?? ''
          : 'offline-$queueId';

      final existing = merged[claimId];
      final parsedClaim = ClaimModel(
        id: claimId,
        employeeId: _currentEmployeeId,
        employeeUuid: employeeUuid,
        employeeName: existing?.employeeName,
        claimNumber: existing?.claimNumber,
        title: payload['title']?.toString() ?? existing?.title ?? '',
        amount: _parseDouble(payload['amount']) ?? existing?.amount ?? 0,
        date:
            DateTime.tryParse(payload['expense_date']?.toString() ?? '') ??
            existing?.date ??
            DateTime.now(),
        status: 'submitted',
        type: payload['category']?.toString() ?? existing?.type ?? 'other',
        claimType:
            payload['claim_type']?.toString() ??
            existing?.claimType ??
            'expense',
        description:
            payload['notes']?.toString() ?? existing?.description ?? '',
        currency:
            payload['currency']?.toString() ?? existing?.currency ?? 'IDR',
        attachmentUrl: existing?.attachmentUrl,
        approverName: existing?.approverName,
        isPendingSync: true,
      );

      merged[claimId] = parsedClaim;
    }

    _claims = merged.values.toList(growable: true);
    _sortClaims();
  }

  Future<void> _saveCache() {
    return OfflineSupport.saveJsonCache(_cacheKey, {
      'claims': _claims
          .where((claim) => !claim.isPendingSync)
          .map((claim) => claim.toJson())
          .toList(),
      'employees': _employees.map((employee) => employee.toJson()).toList(),
      'currentEmployeeId': _currentEmployeeId,
      'currentEmployeeUuid': _currentEmployeeUuid,
    });
  }

  Future<bool> _loadCache() async {
    final cacheKeys = <String>{_cacheKey, 'claims::self'};
    final storedEmployeeUuid = await _getStoredEmployeeUuid();
    if (storedEmployeeUuid != null && storedEmployeeUuid.isNotEmpty) {
      cacheKeys.add('claims::$storedEmployeeUuid');
    }

    Map<String, dynamic>? cached;
    for (final key in cacheKeys) {
      final candidate = await OfflineSupport.getJsonCache(key);
      if (candidate is Map<String, dynamic>) {
        cached = candidate;
        break;
      }
    }

    if (cached == null) {
      return false;
    }

    final rawClaims = cached['claims'];
    if (rawClaims is List) {
      _claims = rawClaims
          .whereType<Map>()
          .map((json) => ClaimModel.fromJson(Map<String, dynamic>.from(json)))
          .toList(growable: true);
      _sortClaims();
    }

    final rawEmployees = cached['employees'];
    if (rawEmployees is List) {
      _employees = rawEmployees
          .whereType<Map>()
          .map(
            (json) =>
                ClaimEmployeeOption.fromJson(Map<String, dynamic>.from(json)),
          )
          .where((employee) => employee.id > 0)
          .toList(growable: true);
    }

    _currentEmployeeId = _parseInt(cached['currentEmployeeId']);
    _currentEmployeeUuid = cached['currentEmployeeUuid']?.toString();
    _isUsingCachedData = _claims.isNotEmpty || _currentEmployeeId != null;
    return _isUsingCachedData;
  }

  Future<void> _refreshPendingSyncState({bool notify = true}) async {
    final employeeUuid = _currentEmployeeUuid ?? await _getStoredEmployeeUuid();
    if (employeeUuid == null || employeeUuid.isEmpty) {
      _pendingSyncCount = 0;
      _syncNotice = null;
      if (notify) {
        notifyListeners();
      }
      return;
    }

    _pendingSyncCount = await OfflineSupport.countQueuedRequests(
      feature: 'claim',
      employeeUuid: employeeUuid,
    );
    _syncNotice = _pendingSyncCount > 0
        ? 'Ada $_pendingSyncCount claim offline menunggu sinkronisasi.'
        : null;

    if (notify) {
      notifyListeners();
    }
  }

  String get _cacheKey => 'claims::${_currentEmployeeUuid ?? 'self'}';

  Future<String?> _getStoredEmployeeUuid() async {
    final rawUserData = await SessionStorage.getUserData();
    if (rawUserData == null || rawUserData.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawUserData);
      if (decoded is Map<String, dynamic>) {
        final employeeUuid = decoded['employee_uuid']?.toString();
        final uuid = decoded['uuid']?.toString();
        return (employeeUuid != null && employeeUuid.isNotEmpty)
            ? employeeUuid
            : uuid;
      }
    } catch (_) {
      // Ignore malformed cache.
    }

    return null;
  }

  List<ClaimModel> _extractClaims(dynamic response) {
    if (response is! Map<String, dynamic>) {
      return const [];
    }

    final data = response['data'];
    final rawClaims = data is Map<String, dynamic> ? data['claims'] : null;

    if (rawClaims is! List) {
      return const [];
    }

    return rawClaims
        .whereType<Map<String, dynamic>>()
        .map(ClaimModel.fromJson)
        .toList(growable: true);
  }

  List<ClaimEmployeeOption> _extractEmployees(dynamic response) {
    if (response is! Map<String, dynamic>) {
      return const [];
    }

    final data = response['data'];
    final rawEmployees = data is Map<String, dynamic>
        ? data['employees']
        : null;

    if (rawEmployees is! List) {
      return const [];
    }

    return rawEmployees
        .whereType<Map>()
        .map(
          (json) =>
              ClaimEmployeeOption.fromJson(Map<String, dynamic>.from(json)),
        )
        .where((employee) => employee.id > 0)
        .toList(growable: true);
  }

  ClaimModel? _extractClaim(dynamic response) {
    if (response is! Map<String, dynamic>) {
      return null;
    }

    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      return null;
    }

    return ClaimModel.fromJson(data);
  }

  void _upsertClaim(ClaimModel claim) {
    final index = _claims.indexWhere((item) => item.id == claim.id);

    if (index == -1) {
      _claims.insert(0, claim);
    } else {
      _claims[index] = claim;
    }

    _sortClaims();
  }

  void _sortClaims() {
    _claims.sort((a, b) => b.date.compareTo(a.date));
  }

  String _normalizeError(Object error) {
    return OfflineSupport.normalizeMessage(error);
  }

  int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '');
  }

  double? _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }
}
