import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/constants/api_constants.dart';
import '../models/employee_model.dart';
import '../models/performance_model.dart';
import '../services/api_service.dart';
import '../services/offline_support.dart';
import '../services/session_storage.dart';
import 'auth_provider.dart';

class PerformanceProvider with ChangeNotifier {
  PerformanceProvider(this._authProvider) {
    Future.microtask(loadPerformance);
  }

  final AuthProvider _authProvider;
  final ApiService _apiService = ApiService();

  List<KpiModel> _kpis = [];
  List<KpiEvaluationModel> _evaluations = [];
  List<PerformanceHistoryModel> _history = [];
  List<String> _availablePeriods = _defaultPeriods();
  String _selectedPeriod = DateFormat('yyyy-MM').format(DateTime.now());
  bool _isLoading = false;
  bool _isUsingCachedData = false;
  String? _error;

  List<KpiModel> get kpis => _kpis;
  List<KpiEvaluationModel> get evaluations => _evaluations;
  List<PerformanceHistoryModel> get history => _history;
  List<String> get availablePeriods => _availablePeriods;
  String get selectedPeriod => _selectedPeriod;
  bool get isLoading => _isLoading;
  bool get isUsingCachedData => _isUsingCachedData;
  String? get error => _error;
  bool get hasData => _kpis.isNotEmpty;

  PerformanceHistoryModel? get currentPeriodHistory =>
      _findHistoryForPeriod(_selectedPeriod);

  Future<void> setPeriod(String period) async {
    if (_selectedPeriod == period) {
      return;
    }

    _selectedPeriod = period;
    await loadPerformance();
  }

  Future<void> refresh() => loadPerformance();

  Future<void> loadPerformance() async {
    final employeeUuid = await _resolveEmployeeUuid();
    final cacheKey = _cacheKey(employeeUuid, _selectedPeriod);

    _isLoading = true;
    _error = null;
    _isUsingCachedData = false;
    notifyListeners();

    try {
      final employeeContext = await _resolveEmployeeContext(employeeUuid);
      if (employeeContext == null || employeeContext.id <= 0) {
        throw Exception('Employee performance context not found.');
      }

      final responses = await Future.wait<dynamic>([
        _loadAssignedKpis(employeeContext.id),
        _safeCheckExisting(employeeContext.id, _selectedPeriod),
        _safeLoadHistory(employeeContext.id),
      ]);

      _kpis = _extractAssignedKpis(responses[0]);
      _evaluations = _extractEvaluations(
        responses[1],
        fallbackPeriod: _selectedPeriod,
        fallbackEmployeeId: employeeContext.id.toString(),
      );
      _history = _extractHistory(responses[2]);
      _availablePeriods = _mergePeriods(_history.map((item) => item.period));
      _error = null;

      await OfflineSupport.saveJsonCache(cacheKey, {
        'kpis': _kpis.map((item) => item.toJson()).toList(),
        'evaluations': _evaluations.map((item) => item.toJson()).toList(),
        'history': _history.map((item) => item.toJson()).toList(),
        'available_periods': _availablePeriods,
      });
    } catch (error) {
      final loadedFromCache = await _loadFromCache(cacheKey);
      if (!loadedFromCache) {
        _kpis = [];
        _evaluations = [];
        _history = [];
        _availablePeriods = _mergePeriods(const <String>[]);
        _error = _normalizePerformanceError(error);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double getEvaluationValue(KpiModel kpi) {
    final evaluation = _findEvaluationForKpi(kpi);
    return evaluation?.actual ?? 0.0;
  }

  bool hasEvaluation(KpiModel kpi) {
    return _findEvaluationForKpi(kpi) != null;
  }

  PerformanceSummary get summary {
    var calculatedScore = 0.0;
    var completedKpis = 0;

    for (final kpi in _kpis) {
      final evaluation = _findEvaluationForKpi(kpi);
      if (evaluation == null) {
        continue;
      }

      completedKpis++;

      if (kpi.target <= 0) {
        continue;
      }

      var achievement = evaluation.actual / kpi.target;
      if (achievement > 1.2) {
        achievement = 1.2;
      }

      calculatedScore += achievement * kpi.weight;
    }

    final historyEntry = currentPeriodHistory;
    final overallScore = historyEntry?.finalScore ?? calculatedScore;
    final grade =
        historyEntry?.grade ?? _gradeForScore(overallScore, completedKpis);

    return PerformanceSummary(
      period: _selectedPeriod,
      overallScore: overallScore,
      grade: grade,
      totalKpis: _kpis.length,
      completedKpis: completedKpis,
    );
  }

  Future<dynamic> _safeCheckExisting(int employeeId, String period) async {
    final payload = <String, dynamic>{
      'employee_id': employeeId,
      'period': period,
    };

    try {
      final detailResponse = await _postFirstAvailable(
        _performanceDetailPaths,
        payload,
      );
      final detailItems = _extractEvaluationItems(detailResponse);
      if (detailItems.isNotEmpty) {
        return detailResponse;
      }
    } catch (_) {
      // Fall through to the lighter endpoint below.
    }

    try {
      return await _postFirstAvailable(_performanceCheckPaths, payload);
    } catch (_) {
      return const <String, dynamic>{
        'success': false,
        'evaluations': <dynamic>[],
      };
    }
  }

  Future<dynamic> _safeLoadHistory(int employeeId) async {
    try {
      return await _getFirstAvailable(_performanceHistoryPaths(employeeId));
    } catch (_) {
      return const <dynamic>[];
    }
  }

  Future<dynamic> _loadAssignedKpis(int employeeId) async {
    return _getFirstAvailable(
      _performanceKpiPaths(employeeId),
      canContinue: _shouldTryNextKpiPath,
    );
  }

  Future<String> _resolveEmployeeUuid() async {
    final authEmployeeUuid = _authProvider.getEmployeeUuid().trim();
    if (authEmployeeUuid.isNotEmpty) {
      return authEmployeeUuid;
    }

    final rawUserData = await SessionStorage.getUserData();
    if (rawUserData == null || rawUserData.isEmpty) {
      return '';
    }

    try {
      final decoded = jsonDecode(rawUserData);
      if (decoded is! Map<String, dynamic>) {
        return '';
      }

      final employee = decoded['employee'];
      if (employee is Map) {
        final employeeMap = Map<String, dynamic>.from(employee);
        final employeeUuid =
            employeeMap['uuid']?.toString().trim() ??
            employeeMap['employee_uuid']?.toString().trim() ??
            '';
        if (employeeUuid.isNotEmpty) {
          return employeeUuid;
        }
      }

      return decoded['employee_uuid']?.toString().trim() ??
          decoded['uuid']?.toString().trim() ??
          '';
    } catch (_) {
      return '';
    }
  }

  Future<_PerformanceEmployeeContext?> _resolveEmployeeContext(
    String employeeUuid,
  ) async {
    if (employeeUuid.isNotEmpty) {
      try {
        final response = await _apiService.get('/employees/$employeeUuid');
        final employeePayload = _extractEmployeePayload(response);
        final context = _employeeContextFromMap(
          employeePayload,
          fallbackUuid: employeeUuid,
        );
        if (context != null) {
          return context;
        }
      } catch (_) {
        final cached = await OfflineSupport.getJsonCache(
          'employees::detail::$employeeUuid',
        );
        if (cached is Map<String, dynamic>) {
          final context = _employeeContextFromMap(
            cached,
            fallbackUuid: employeeUuid,
          );
          if (context != null) {
            return context;
          }
        }
      }
    }

    final rawUserData = await SessionStorage.getUserData();
    if (rawUserData == null || rawUserData.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawUserData);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final employee = decoded['employee'];
      if (employee is Map) {
        final context = _employeeContextFromMap(
          Map<String, dynamic>.from(employee),
          fallbackUuid: employeeUuid,
        );
        if (context != null) {
          return context;
        }
      }

      final fallbackId = _asInt(decoded['employee_id']);
      if (fallbackId > 0) {
        return _PerformanceEmployeeContext(id: fallbackId, uuid: employeeUuid);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  _PerformanceEmployeeContext? _employeeContextFromMap(
    Map<String, dynamic>? payload, {
    required String fallbackUuid,
  }) {
    if (payload == null) {
      return null;
    }

    final employee = Employee.fromJson(payload);
    final employeeId = _asInt(payload['id'] ?? payload['employee_id']);
    if (employeeId <= 0) {
      return null;
    }

    final resolvedUuid = employee.uuid.trim().isNotEmpty
        ? employee.uuid.trim()
        : fallbackUuid;

    return _PerformanceEmployeeContext(id: employeeId, uuid: resolvedUuid);
  }

  Map<String, dynamic>? _extractEmployeePayload(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }

      if (data is List && data.isNotEmpty && data.first is Map) {
        return Map<String, dynamic>.from(data.first as Map);
      }

      final employee = response['employee'];
      if (employee is Map<String, dynamic>) {
        return employee;
      }

      if (response.containsKey('id') || response.containsKey('uuid')) {
        return response;
      }
    }

    return null;
  }

  List<KpiModel> _extractAssignedKpis(dynamic response) {
    final items = _extractList(
      response,
      candidateKeys: const ['data', 'items', 'kpis'],
    );

    final normalizedItems = <Map<String, dynamic>>[];
    for (final rawItem in items.whereType<Map>()) {
      final item = Map<String, dynamic>.from(rawItem);
      final details = item['details'];
      if (details is List && details.isNotEmpty) {
        for (var index = 0; index < details.length; index++) {
          final rawDetail = details[index];
          if (rawDetail is! Map) {
            continue;
          }

          normalizedItems.add(
            _expandAssignmentItem(
              assignment: item,
              detail: Map<String, dynamic>.from(rawDetail),
              detailIndex: index,
            ),
          );
        }
        continue;
      }

      final fallbackId = _stringValue(
        item['master_kpi_detail_id'] ?? item['employee_kpi_id'] ?? item['id'],
      );
      normalizedItems.add({
        ...item,
        'id': fallbackId,
        'composite_id': fallbackId,
        'target': item['target'] ?? item['target_value'],
      });
    }

    final unique = <String, KpiModel>{};
    for (final item in normalizedItems) {
      final model = KpiModel.fromAssignment(item);
      if (model.id.isEmpty) {
        continue;
      }

      unique[model.id] = model;
    }

    final mapped = unique.values.toList(growable: false);
    mapped.sort((left, right) => left.title.compareTo(right.title));
    return mapped;
  }

  List<KpiEvaluationModel> _extractEvaluations(
    dynamic response, {
    required String fallbackPeriod,
    required String fallbackEmployeeId,
  }) {
    final items = _extractEvaluationItems(response);

    return items
        .whereType<Map>()
        .map(
          (item) => KpiEvaluationModel.fromEvaluation(
            Map<String, dynamic>.from(item),
            fallbackPeriod: fallbackPeriod,
            fallbackEmployeeId: fallbackEmployeeId,
          ),
        )
        .where((item) => item.kpiId.isNotEmpty)
        .toList(growable: false);
  }

  List<dynamic> _extractEvaluationItems(dynamic response) {
    final directItems = _extractList(
      response,
      candidateKeys: const ['evaluations', 'details', 'data', 'items'],
    );
    if (directItems.isNotEmpty) {
      return directItems;
    }

    if (response is Map<String, dynamic>) {
      final evaluation = response['evaluation'];
      if (evaluation is Map<String, dynamic>) {
        final detailItems = _extractList(
          evaluation,
          candidateKeys: const ['details', 'evaluations', 'data', 'items'],
        );
        if (detailItems.isNotEmpty) {
          return detailItems;
        }

        return <dynamic>[evaluation];
      }
    }

    return const <dynamic>[];
  }

  List<PerformanceHistoryModel> _extractHistory(dynamic response) {
    final items = _extractList(
      response,
      candidateKeys: const ['history', 'data', 'evaluations', 'items'],
    );

    final history = items
        .whereType<Map>()
        .map(
          (item) =>
              PerformanceHistoryModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.period.isNotEmpty)
        .toList(growable: false);

    history.sort((left, right) => right.period.compareTo(left.period));
    return history;
  }

  List<dynamic> _extractList(
    dynamic response, {
    required List<String> candidateKeys,
  }) {
    if (response is List) {
      return response;
    }

    if (response is! Map<String, dynamic>) {
      return const <dynamic>[];
    }

    for (final key in candidateKeys) {
      final value = response[key];
      if (value is List) {
        return value;
      }

      if (value is Map<String, dynamic>) {
        final nestedData = value['data'];
        if (nestedData is List) {
          return nestedData;
        }
      }
    }

    return const <dynamic>[];
  }

  Future<bool> _loadFromCache(String cacheKey) async {
    final cached = await OfflineSupport.getJsonCache(cacheKey);
    if (cached is! Map<String, dynamic>) {
      return false;
    }

    final cachedKpis = cached['kpis'];
    final cachedEvaluations = cached['evaluations'];
    final cachedHistory = cached['history'];

    if (cachedKpis is! List ||
        cachedEvaluations is! List ||
        cachedHistory is! List) {
      return false;
    }

    _kpis = cachedKpis
        .whereType<Map>()
        .map((item) => KpiModel.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    _evaluations = cachedEvaluations
        .whereType<Map>()
        .map(
          (item) =>
              KpiEvaluationModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
    _history = cachedHistory
        .whereType<Map>()
        .map(
          (item) =>
              PerformanceHistoryModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);

    final cachedPeriods = cached['available_periods'];
    _availablePeriods = cachedPeriods is List
        ? cachedPeriods
              .map((item) => item.toString())
              .where((item) => item.isNotEmpty)
              .toList(growable: false)
        : _mergePeriods(_history.map((item) => item.period));

    _isUsingCachedData = true;
    _error = null;
    return true;
  }

  KpiEvaluationModel? _findEvaluationForKpi(KpiModel kpi) {
    final matches = _evaluations
        .where((evaluation) => _evaluationMatchesKpi(evaluation, kpi))
        .toList(growable: false);

    if (matches.isEmpty) {
      return null;
    }

    matches.sort(_compareEvaluationPriority);
    return matches.first;
  }

  PerformanceHistoryModel? _findHistoryForPeriod(String period) {
    for (final item in _history) {
      if (item.period == period) {
        return item;
      }
    }

    return null;
  }

  List<String> _mergePeriods(Iterable<String> incomingPeriods) {
    final periods = <String>{..._defaultPeriods(), ...incomingPeriods};
    final merged = periods.toList(growable: false);
    merged.sort((left, right) => right.compareTo(left));
    return merged;
  }

  String _gradeForScore(double score, int completedKpis) {
    if (completedKpis == 0) {
      return '-';
    }

    if (score >= 90) {
      return 'A';
    }

    if (score >= 75) {
      return 'B';
    }

    return 'C';
  }

  String _cacheKey(String employeeUuid, String period) {
    final cacheSubject = employeeUuid.trim().isNotEmpty
        ? employeeUuid.trim()
        : 'self';
    return 'performance::$cacheSubject::$period';
  }

  String _performanceKpiPath(int employeeId) {
    final base = ApiConstants.performanceKpiAssignmentsEndpoint.replaceFirst(
      '/api',
      '',
    );
    return '$base/$employeeId/kpi';
  }

  List<String> _performanceKpiPaths(int employeeId) {
    return <String>[
      _performanceKpiPath(employeeId),
      _assignedEmployeeKpiPath(employeeId),
    ];
  }

  String _assignedEmployeeKpiPath(int employeeId) {
    final base = ApiConstants.performanceEmployeeAssignmentsEndpoint
        .replaceFirst('/api', '');
    return '$base/$employeeId';
  }

  List<String> get _performanceCheckPaths => <String>[
    ApiConstants.performanceEvaluationCheckEndpoint.replaceFirst('/api', ''),
    ApiConstants.legacyPerformanceEvaluationCheckEndpoint.replaceFirst(
      '/api',
      '',
    ),
  ];

  List<String> get _performanceDetailPaths => <String>[
    ApiConstants.performanceEvaluationDetailEndpoint.replaceFirst('/api', ''),
    ApiConstants.legacyPerformanceEvaluationDetailEndpoint.replaceFirst(
      '/api',
      '',
    ),
  ];

  List<String> _performanceHistoryPaths(int employeeId) {
    final currentBase = ApiConstants.performanceEvaluationHistoryEndpoint
        .replaceFirst('/api', '');
    final legacyBase = ApiConstants.legacyPerformanceEvaluationHistoryEndpoint
        .replaceFirst('/api', '');

    return <String>[
      '$currentBase/$employeeId/history',
      '$legacyBase/$employeeId',
    ];
  }

  static List<String> _defaultPeriods() {
    return List<String>.generate(6, (index) {
      return DateFormat(
        'yyyy-MM',
      ).format(DateTime.now().subtract(Duration(days: 30 * index)));
    });
  }

  int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _isRouteNotFound(Object error) {
    final message = OfflineSupport.normalizeMessage(error).toLowerCase();
    return message.contains('http 404') ||
        message.contains('http 405') ||
        message.contains('method not allowed') ||
        message.contains('method is not supported for route') ||
        message.contains('supported methods: get') ||
        message.contains('notfoundhttpexception') ||
        message.contains('route') && message.contains('could not be found');
  }

  bool _shouldTryNextKpiPath(Object error) {
    return _isRouteNotFound(error) || _isKnownBrokenPerformanceRoute(error);
  }

  bool _isKnownBrokenPerformanceRoute(Object error) {
    final message = OfflineSupport.normalizeMessage(error).toLowerCase();
    return message.contains('sqlstate[') ||
        message.contains('operator does not exist') ||
        message.contains('undefined function') ||
        message.contains('terjadi kesalahan saat mengambil detail evaluasi');
  }

  Future<dynamic> _getFirstAvailable(
    List<String> endpoints, {
    bool Function(Object error)? canContinue,
  }) async {
    Object? lastError;

    for (final endpoint in endpoints) {
      try {
        return await _apiService.get(endpoint);
      } catch (error) {
        lastError = error;
        final shouldContinue =
            canContinue?.call(error) ?? _isRouteNotFound(error);
        if (!shouldContinue) {
          rethrow;
        }
      }
    }

    throw lastError ?? Exception('No performance endpoint available.');
  }

  Future<dynamic> _postFirstAvailable(
    List<String> endpoints,
    Map<String, dynamic> payload,
  ) async {
    Object? lastError;

    for (final endpoint in endpoints) {
      try {
        return await _apiService.post(endpoint, payload);
      } catch (error) {
        lastError = error;
        if (!_isRouteNotFound(error)) {
          rethrow;
        }
      }
    }

    throw lastError ?? Exception('No performance endpoint available.');
  }

  Map<String, dynamic> _expandAssignmentItem({
    required Map<String, dynamic> assignment,
    required Map<String, dynamic> detail,
    required int detailIndex,
  }) {
    final employeeKpiId = assignment['employee_kpi_id'] ?? assignment['id'];
    final detailId = _stringValue(detail['id']);
    final compositeId = detailId.isNotEmpty
        ? detailId
        : '${_stringValue(employeeKpiId)}::$detailIndex';

    return <String, dynamic>{
      ...assignment,
      ...detail,
      'employee_kpi_id': employeeKpiId,
      'master_kpi_detail_id':
          detail['id'] ?? assignment['master_kpi_detail_id'],
      'id': compositeId,
      'composite_id': compositeId,
      'goal_name': detail['goal_name'] ?? assignment['goal_name'],
      'category': detail['category'] ?? assignment['category'],
      'target':
          detail['target'] ?? detail['target_value'] ?? assignment['target'],
      'weight': detail['weight'] ?? assignment['weight'],
    };
  }

  String _stringValue(dynamic value) {
    final normalized = value?.toString().trim() ?? '';
    if (normalized.toLowerCase() == 'null') {
      return '';
    }

    return normalized;
  }

  String _normalizePerformanceError(Object error) {
    final normalized = OfflineSupport.normalizeMessage(error);
    final jsonStart = normalized.indexOf('{');

    if (jsonStart >= 0) {
      final maybeJson = normalized.substring(jsonStart);
      try {
        final decoded = jsonDecode(maybeJson);
        if (decoded is Map<String, dynamic>) {
          final message = decoded['message']?.toString().trim();
          if (message != null && message.isNotEmpty) {
            return message;
          }
        }
      } catch (_) {
        // Keep the normalized message when the payload is not valid JSON.
      }
    }

    return normalized;
  }

  bool _evaluationMatchesKpi(KpiEvaluationModel evaluation, KpiModel kpi) {
    final evaluationIds = _normalizedIds([
      evaluation.kpiId,
      evaluation.masterKpiDetailId,
      evaluation.employeeKpiId,
      evaluation.id,
    ]);
    final kpiIds = _normalizedIds([
      kpi.id,
      kpi.masterKpiDetailId,
      kpi.employeeKpiId,
    ]);

    if (evaluationIds.isEmpty || kpiIds.isEmpty) {
      return false;
    }

    return evaluationIds.any(kpiIds.contains);
  }

  Set<String> _normalizedIds(Iterable<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty && value.toLowerCase() != 'null')
        .toSet();
  }

  int _compareEvaluationPriority(
    KpiEvaluationModel left,
    KpiEvaluationModel right,
  ) {
    final leftPriority = _evaluationPriority(left);
    final rightPriority = _evaluationPriority(right);

    if (leftPriority != rightPriority) {
      return rightPriority.compareTo(leftPriority);
    }

    final timestampComparison = right.evaluatedAt.compareTo(left.evaluatedAt);
    if (timestampComparison != 0) {
      return timestampComparison;
    }

    final leftId = _asInt(left.id);
    final rightId = _asInt(right.id);
    if (leftId != rightId) {
      return rightId.compareTo(leftId);
    }

    return 0;
  }

  int _evaluationPriority(KpiEvaluationModel evaluation) {
    var score = 0;

    if (evaluation.actual != 0) {
      score += 8;
    }

    if (evaluation.score != 0) {
      score += 4;
    }

    if (evaluation.finalScore != 0) {
      score += 3;
    }

    if (evaluation.isLocked) {
      score += 2;
    }

    if ((evaluation.comment ?? '').trim().isNotEmpty) {
      score += 1;
    }

    return score;
  }
}

class _PerformanceEmployeeContext {
  const _PerformanceEmployeeContext({required this.id, required this.uuid});

  final int id;
  final String uuid;
}
