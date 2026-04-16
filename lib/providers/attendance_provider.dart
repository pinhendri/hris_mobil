import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../core/constants/api_constants.dart';
import '../data/local/database_helper.dart';
import '../data/models/attendance_model.dart';
import '../data/models/attendance_location.dart';
import '../services/session_storage.dart';

class AttendanceProvider with ChangeNotifier {
  List<Attendance> _attendances = [];
  Attendance? _todayAttendance;
  bool _isLoading = false;
  String? _error;
  bool _isClockingIn = false;
  bool _isClockingOut = false;
  bool _isSyncingOfflineQueue = false;
  int _pendingSyncCount = 0;
  String? _syncNotice;
  String? _lastActionMessage;
  bool _lastActionQueued = false;
  Timer? _offlineSyncTimer;
  Future<void>? _bootstrapFuture;
  String _activeAttendanceContextKey = '';
  String? _resolvedCurrentEmployeeUuid;
  Set<String> _currentEmployeeIdentifiers = <String>{};
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Pagination
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  int _perPage = 50;

  // Summary
  Map<String, dynamic>? _summary;

  // ===== LOCATION MANAGEMENT =====
  List<AttendanceLocation> _allowedLocations = [];
  Setting? _settings; // Tambahkan settings

  // ===== CORRECTION MANAGEMENT =====
  List<Map<String, dynamic>> _correctionRequests = [];

  // ===== GETTERS =====
  List<Attendance> get attendances => _attendances;
  Attendance? get todayAttendance => _todayAttendance;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isClockingIn => _isClockingIn;
  bool get isClockingOut => _isClockingOut;
  Map<String, dynamic>? get summary => _summary;
  Setting? get settings => _settings;
  bool get isSyncingOfflineQueue => _isSyncingOfflineQueue;
  int get pendingSyncCount => _pendingSyncCount;
  String? get syncNotice => _syncNotice;
  String? get lastActionMessage => _lastActionMessage;
  bool get lastActionQueued => _lastActionQueued;

  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get total => _total;
  int get perPage => _perPage;

  // LOCATION GETTERS
  List<AttendanceLocation> get allowedLocations => _allowedLocations;
  AttendanceLocation? get defaultLocation =>
      _allowedLocations.isNotEmpty ? _allowedLocations.first : null;

  // CORRECTION GETTERS
  List<Map<String, dynamic>> get correctionRequests => _correctionRequests;

  AttendanceProvider() {
    _bootstrapFuture = _bootstrapOfflineSupport();
    unawaited(_bootstrapFuture!);
  }

  Future<void> ensureReady() async {
    _bootstrapFuture ??= _bootstrapOfflineSupport();
    await _bootstrapFuture;
  }

  // ===== HEADERS =====
  Future<Map<String, String>> _getHeaders({String? companyCodeOverride}) async {
    final token = await SessionStorage.getToken();
    final companyCode = companyCodeOverride?.trim().isNotEmpty == true
        ? companyCodeOverride!.trim()
        : (await SessionStorage.getCompanyCode())?.trim() ?? '';
    if (token.isNotEmpty) {
      print(
        'Token from SharedPreferences: ${token.substring(0, min(20, token.length))}...',
      );
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      if (companyCode.isNotEmpty) 'X-Company-Code': companyCode,
    };
  }

  Future<Uri> _buildApiUri(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool includeCompanyCode = false,
    String? companyCodeOverride,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final mergedQuery = <String, String>{};

    if (includeCompanyCode) {
      final companyCode = companyCodeOverride?.trim().isNotEmpty == true
          ? companyCodeOverride!.trim()
          : (await SessionStorage.getCompanyCode())?.trim() ?? '';
      if (companyCode.isNotEmpty) {
        mergedQuery['c_code'] = companyCode;
      }
    }

    queryParameters?.forEach((key, value) {
      if (value == null) {
        return;
      }

      final normalized = value.toString().trim();
      if (normalized.isNotEmpty) {
        mergedQuery[key] = normalized;
      }
    });

    if (mergedQuery.isEmpty) {
      return uri;
    }

    return uri.replace(queryParameters: mergedQuery);
  }

  Future<void> _bootstrapOfflineSupport() async {
    await _refreshPendingSyncState();
    await _restoreLocalAttendanceState();

    _offlineSyncTimer ??= Timer.periodic(const Duration(seconds: 45), (_) {
      unawaited(syncOfflineActions(silent: true));
    });
  }

  // ===== INITIALIZE =====
  Future<void> initialize() async {
    await ensureReady();
    await fetchSettings();
    await syncOfflineActions(silent: true, refreshAfterSync: false);
  }

  @override
  void dispose() {
    _offlineSyncTimer?.cancel();
    super.dispose();
  }

  // ===== FETCH SETTINGS FROM API =====
  Future<void> fetchSettings() async {
    try {
      print('🔄 Fetching settings from API...');
      final headers = await _getHeaders();

      final response = await http
          .get(
            await _buildApiUri(
              ApiConstants.settingsEndpoint,
              includeCompanyCode: true,
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      print('📥 Settings response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          final settingsData = data['data'];
          if (settingsData != null) {
            _settings = Setting.fromJson(settingsData);

            print('✅ Settings loaded successfully');
            print(
              '📍 Location: ${_settings?.latitude}, ${_settings?.longitude}',
            );
          }
        } else {
          print('⚠️ Failed to load settings: ${data['message']}');
        }
      } else {
        print('⚠️ Error loading settings');
      }
    } catch (e) {
      print('❌ Error fetching settings: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<String> _getCurrentCompanyCode() async {
    return (await SessionStorage.getCompanyCode())?.trim() ?? '';
  }

  String _normalizeIdentifier(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  String? _firstNonEmptyIdentifier(Iterable<dynamic> values) {
    for (final value in values) {
      final normalized = _normalizeIdentifier(value);
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }

    return null;
  }

  void _addEmployeeIdentifier(Set<String> identifiers, dynamic value) {
    final normalized = _normalizeIdentifier(value);
    if (normalized.isNotEmpty) {
      identifiers.add(normalized);
    }
  }

  Set<String> _extractEmployeeIdentifiersFromUserMap(
    Map<String, dynamic> userData,
  ) {
    final identifiers = <String>{};
    final employee = userData['employee'];
    final employeeMap = employee is Map
        ? Map<String, dynamic>.from(employee)
        : null;

    _addEmployeeIdentifier(identifiers, employeeMap?['uuid']);
    _addEmployeeIdentifier(identifiers, employeeMap?['employee_uuid']);
    _addEmployeeIdentifier(identifiers, userData['employee_uuid']);
    _addEmployeeIdentifier(identifiers, userData['employeeUuid']);
    _addEmployeeIdentifier(identifiers, userData['uuid']);

    return identifiers;
  }

  String? _preferredEmployeeUuidFromUserMap(Map<String, dynamic> userData) {
    final employee = userData['employee'];
    final employeeMap = employee is Map
        ? Map<String, dynamic>.from(employee)
        : null;

    return _firstNonEmptyIdentifier([
      employeeMap?['uuid'],
      employeeMap?['employee_uuid'],
      userData['employee_uuid'],
      userData['employeeUuid'],
      userData['uuid'],
    ]);
  }

  Future<Map<String, dynamic>?> _readStoredUserDataMap() async {
    final rawUserData = await SessionStorage.getUserData();
    if (rawUserData == null || rawUserData.isEmpty) {
      return null;
    }

    try {
      final decoded = json.decode(rawUserData);
      if (decoded is Map<String, dynamic>) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (e) {
      print('Error decoding stored user data for attendance: $e');
    }

    return null;
  }

  Future<Map<String, dynamic>?> _fetchCurrentUserPayload() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/api/me'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> data = await compute(
        _parseAttendanceJson,
        response.body,
      );
      final payload = data['data'];

      if (payload is Map && payload['user'] is Map) {
        return Map<String, dynamic>.from(payload['user'] as Map);
      }

      if (payload is Map) {
        return Map<String, dynamic>.from(payload);
      }
    } catch (e) {
      print('Error fetching /api/me for attendance: $e');
    }

    return null;
  }

  Future<String?> _fetchEmployeeUuidFromMeEmployee() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/api/me/employee'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> data = await compute(
        _parseAttendanceJson,
        response.body,
      );
      final payload = data['data'];

      if (payload is Map) {
        return _firstNonEmptyIdentifier([
          payload['uuid'],
          payload['employee_uuid'],
        ]);
      }
    } catch (e) {
      print('Error fetching /api/me/employee for attendance: $e');
    }

    return null;
  }

  Future<void> _cacheResolvedEmployeeIdentity(
    String? employeeUuid, {
    Map<String, dynamic>? userData,
    Set<String>? identifiers,
  }) async {
    final normalizedEmployeeUuid = _normalizeIdentifier(employeeUuid);
    _resolvedCurrentEmployeeUuid = normalizedEmployeeUuid.isEmpty
        ? null
        : normalizedEmployeeUuid;
    _currentEmployeeIdentifiers = Set<String>.from(
      (identifiers ?? const <String>{})
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty),
    );

    if (_resolvedCurrentEmployeeUuid != null) {
      _currentEmployeeIdentifiers.add(_resolvedCurrentEmployeeUuid!);
    }

    if (userData == null || _resolvedCurrentEmployeeUuid == null) {
      return;
    }

    final storedEmployeeUuid = _normalizeIdentifier(userData['employee_uuid']);
    if (storedEmployeeUuid == _resolvedCurrentEmployeeUuid) {
      return;
    }

    final mergedUserData = Map<String, dynamic>.from(userData);
    mergedUserData['employee_uuid'] = _resolvedCurrentEmployeeUuid;
    await SessionStorage.saveUserData(jsonEncode(mergedUserData));
  }

  Future<String?> resolveCurrentEmployeeUuid({bool refresh = false}) async {
    Map<String, dynamic>? mergedUserData = await _readStoredUserDataMap();
    final storedIdentifiers = mergedUserData != null
        ? _extractEmployeeIdentifiersFromUserMap(mergedUserData)
        : <String>{};

    if (!refresh) {
      if (mergedUserData == null) {
        _resolvedCurrentEmployeeUuid = null;
        _currentEmployeeIdentifiers = <String>{};
        return null;
      }

      if (_resolvedCurrentEmployeeUuid?.isNotEmpty == true &&
          storedIdentifiers.contains(_resolvedCurrentEmployeeUuid)) {
        _currentEmployeeIdentifiers = <String>{
          ...storedIdentifiers,
          ..._currentEmployeeIdentifiers,
          _resolvedCurrentEmployeeUuid!,
        };
        return _resolvedCurrentEmployeeUuid;
      }
    }

    final identifiers = <String>{...storedIdentifiers};

    if (mergedUserData != null) {
      identifiers.addAll(
        _extractEmployeeIdentifiersFromUserMap(mergedUserData),
      );
    }

    var resolvedEmployeeUuid = mergedUserData != null
        ? _preferredEmployeeUuidFromUserMap(mergedUserData)
        : null;

    final serverEmployeeUuid = await _fetchEmployeeUuidFromMeEmployee();
    if (serverEmployeeUuid != null && serverEmployeeUuid.isNotEmpty) {
      resolvedEmployeeUuid = serverEmployeeUuid;
      identifiers.add(serverEmployeeUuid);
    }

    final meUserData = await _fetchCurrentUserPayload();
    if (meUserData != null) {
      mergedUserData = <String, dynamic>{
        if (mergedUserData != null) ...mergedUserData,
        ...meUserData,
      };
      identifiers.addAll(_extractEmployeeIdentifiersFromUserMap(meUserData));
      resolvedEmployeeUuid ??= _preferredEmployeeUuidFromUserMap(meUserData);
    }

    resolvedEmployeeUuid ??= identifiers.isNotEmpty ? identifiers.first : null;

    await _cacheResolvedEmployeeIdentity(
      resolvedEmployeeUuid,
      userData: mergedUserData,
      identifiers: identifiers,
    );

    return _resolvedCurrentEmployeeUuid;
  }

  Future<Set<String>> _getCurrentEmployeeIdentifiers({
    bool refresh = false,
  }) async {
    await resolveCurrentEmployeeUuid(refresh: refresh);

    if (_currentEmployeeIdentifiers.isNotEmpty) {
      return Set<String>.from(_currentEmployeeIdentifiers);
    }

    final employeeUuid = _resolvedCurrentEmployeeUuid;
    return employeeUuid != null && employeeUuid.isNotEmpty
        ? <String>{employeeUuid}
        : <String>{};
  }

  bool _matchesEmployeeIdentifier(
    String? candidate, {
    String? employeeUuid,
    Set<String>? employeeIdentifiers,
  }) {
    final normalizedCandidate = _normalizeIdentifier(candidate);
    if (normalizedCandidate.isEmpty) {
      return true;
    }

    final normalizedPrimary = _normalizeIdentifier(employeeUuid);
    if (normalizedPrimary.isNotEmpty &&
        normalizedCandidate == normalizedPrimary) {
      return true;
    }

    final identifiers = employeeIdentifiers ?? _currentEmployeeIdentifiers;
    return identifiers.contains(normalizedCandidate);
  }

  String _buildAttendanceContextKey(String? employeeUuid, String companyCode) {
    return '${employeeUuid?.trim() ?? ''}::$companyCode';
  }

  Future<String> _ensureAttendanceContext({String? employeeUuid}) async {
    final companyCode = await _getCurrentCompanyCode();
    final contextKey = _buildAttendanceContextKey(employeeUuid, companyCode);

    if (_activeAttendanceContextKey != contextKey) {
      _activeAttendanceContextKey = contextKey;
      _attendances = [];
      _todayAttendance = null;
      _summary = null;
      _error = null;
    }

    return companyCode;
  }

  Future<void> fetchTodayAttendance({String? date}) async {
    final employeeUuid = await resolveCurrentEmployeeUuid();
    final employeeIdentifiers = await _getCurrentEmployeeIdentifiers();
    final companyCode = await _ensureAttendanceContext(
      employeeUuid: employeeUuid,
    );
    final dateParam = date ?? DateTime.now().toIso8601String().split('T')[0];
    final localDrafts = await _loadLocalAttendances(
      employeeUuid: employeeUuid,
      companyCode: companyCode,
    );
    final fallbackToday = _fallbackAttendanceForDate(
      date: dateParam,
      employeeUuid: employeeUuid,
      companyCode: companyCode,
      localDrafts: localDrafts,
    );

    if (employeeUuid == null || employeeUuid.isEmpty) {
      _todayAttendance = fallbackToday;
      notifyListeners();
      return;
    }

    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            await _buildApiUri(
              ApiConstants.attendanceEndpoint,
              includeCompanyCode: true,
              queryParameters: {
                'page': 1,
                'per_page': 100,
                if (dateParam.trim().isNotEmpty) 'date': dateParam,
              },
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = await compute(
          _parseAttendanceJson,
          response.body,
        );

        if (data['success'] == true) {
          final attendancesData = _extractAttendanceItems(data);

          Attendance? serverToday;
          for (final rawItem in attendancesData.whereType<Map>()) {
            final item = Map<String, dynamic>.from(rawItem);
            final itemDate = _normalizeAttendanceDateValue(
              item['date'] ?? item['attendance_date'],
            );
            final itemEmployeeUuid = _extractEmployeeUuidFromAttendanceItem(
              item,
            );

            final matchesEmployee = _matchesEmployeeIdentifier(
              itemEmployeeUuid,
              employeeUuid: employeeUuid,
              employeeIdentifiers: employeeIdentifiers,
            );

            if (matchesEmployee && itemDate == dateParam) {
              final resolvedItemEmployeeUuid = itemEmployeeUuid.isNotEmpty
                  ? itemEmployeeUuid
                  : employeeUuid;
              if (resolvedItemEmployeeUuid.isNotEmpty) {
                item['employee_uuid'] = resolvedItemEmployeeUuid;
              }
              item['c_code'] ??= companyCode;
              item['uuid'] ??= item['id']?.toString();
              serverToday = _preferAttendance(
                serverToday,
                Attendance.fromJson(item),
              );
            }
          }

          _todayAttendance = _preferAttendance(serverToday, fallbackToday);
        } else {
          _todayAttendance = fallbackToday;
        }
      } else {
        _todayAttendance = fallbackToday;
      }
    } catch (e) {
      print('Error fetching today attendance: $e');
      _todayAttendance = fallbackToday;
    }

    notifyListeners();
  }

  // ===== FETCH ATTENDANCES =====
  Future<void> fetchAttendances({String? date, int page = 1}) async {
    if (_isLoading) return;

    _isLoading = true;
    if (page == 1) {
      _error = null;
    }
    notifyListeners();

    final employeeUuid = await resolveCurrentEmployeeUuid();
    final employeeIdentifiers = await _getCurrentEmployeeIdentifiers();
    final companyCode = await _ensureAttendanceContext(
      employeeUuid: employeeUuid,
    );
    final todayDate = DateTime.now().toIso8601String().split('T')[0];
    final normalizedRequestedDate = _normalizeAttendanceDateValue(date);
    final shouldPreserveTodayInHistory =
        normalizedRequestedDate.isEmpty || normalizedRequestedDate == todayDate;
    var localDrafts = <Attendance>[];
    Attendance? optimisticToday;

    try {
      await syncOfflineActions(silent: true, refreshAfterSync: false);
      localDrafts = await _loadLocalAttendances(
        employeeUuid: employeeUuid,
        companyCode: companyCode,
      );
      if (shouldPreserveTodayInHistory) {
        optimisticToday = _fallbackAttendanceForDate(
          date: todayDate,
          employeeUuid: employeeUuid,
          companyCode: companyCode,
          localDrafts: localDrafts,
        );
      }

      if (employeeUuid == null || employeeUuid.isEmpty) {
        _attendances = _sortAttendances(localDrafts);
        _findTodayAttendance(
          employeeUuid: employeeUuid,
          companyCode: companyCode,
        );
        return;
      }

      final headers = await _getHeaders();

      final response = await http
          .get(
            await _buildApiUri(
              ApiConstants.attendanceEndpoint,
              includeCompanyCode: true,
              queryParameters: {
                'page': page,
                'per_page': _perPage,
                if (date != null && date.trim().isNotEmpty) 'date': date,
              },
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Parse JSON di background
        final Map<String, dynamic> data = await compute(
          _parseAttendanceJson,
          response.body,
        );

        if (data['success'] == true) {
          final attendancesData = _extractAttendanceItems(data)
              .whereType<Map>()
              .map((raw) => Map<String, dynamic>.from(raw))
              .where((item) {
                final itemEmployeeUuid = _extractEmployeeUuidFromAttendanceItem(
                  item,
                );
                return _matchesEmployeeIdentifier(
                  itemEmployeeUuid,
                  employeeUuid: employeeUuid,
                  employeeIdentifiers: employeeIdentifiers,
                );
              })
              .toList(growable: false);

          // Parse attendances di background jika datanya banyak
          if (attendancesData.length > 50) {
            final List<Attendance> parsedAttendances =
                await compute(_parseAttendanceHistoryList, {
                  'items': attendancesData,
                  'employee_uuid': employeeUuid,
                  'employee_identifiers': employeeIdentifiers.toList(),
                  'c_code': companyCode,
                });
            _attendances = _mergeFetchedAttendances(
              fetchedAttendances: parsedAttendances,
              page: page,
              localDrafts: localDrafts,
              optimisticToday: optimisticToday,
            );
          } else {
            final newAttendances = attendancesData.whereType<Map>().map((raw) {
              final json = Map<String, dynamic>.from(raw);
              final extractedEmployeeUuid =
                  _extractEmployeeUuidFromAttendanceItem(json);
              final resolvedItemEmployeeUuid = extractedEmployeeUuid.isNotEmpty
                  ? extractedEmployeeUuid
                  : employeeUuid;
              if (resolvedItemEmployeeUuid.isNotEmpty) {
                json['employee_uuid'] = resolvedItemEmployeeUuid;
              }
              json['c_code'] ??= companyCode;
              json['uuid'] ??= json['id']?.toString();
              return Attendance.fromJson(json);
            }).toList();
            _attendances = _mergeFetchedAttendances(
              fetchedAttendances: newAttendances,
              page: page,
              localDrafts: localDrafts,
              optimisticToday: optimisticToday,
            );
          }

          // Meta data
          final meta = _extractAttendanceMeta(data);
          _currentPage = meta['current_page'] ?? page;
          _lastPage =
              meta['last_page'] ??
              ((attendancesData.length >= _perPage) ? page + 1 : page);
          _total = meta['total'] ?? _attendances.length;
          _perPage = meta['per_page'] ?? _perPage;

          print('Loaded ${_attendances.length} attendances, total: $_total');

          _mergeOfflineAttendances(localDrafts);
          _syncNotice = localDrafts.isNotEmpty
              ? 'Ada ${localDrafts.length} data absensi offline menunggu sinkronisasi.'
              : null;
          _findTodayAttendance(
            employeeUuid: employeeUuid,
            companyCode: companyCode,
            preserveExisting: true,
          );
        } else {
          _applyOfflineFallback(
            localDrafts,
            fallbackMessage:
                'Server sedang offline. Data absensi lokal tetap tersedia.',
            employeeUuid: employeeUuid,
            companyCode: companyCode,
          );
          _error = null;
        }
      } else {
        _applyOfflineFallback(
          localDrafts,
          fallbackMessage:
              'Server belum bisa diakses. Data absensi lokal tetap tersedia.',
          employeeUuid: employeeUuid,
          companyCode: companyCode,
        );
        _error = null;
      }
    } on TimeoutException catch (e) {
      print('Timeout fetching attendances: $e');
      _applyOfflineFallback(
        localDrafts,
        fallbackMessage:
            'Koneksi ke server timeout. Data absensi lokal tetap ditampilkan.',
        employeeUuid: employeeUuid,
        companyCode: companyCode,
      );
      _error = null;
    } on SocketException catch (e) {
      print('Socket exception fetching attendances: $e');
      _applyOfflineFallback(
        localDrafts,
        fallbackMessage:
            'Anda sedang offline. Data absensi lokal tetap ditampilkan.',
        employeeUuid: employeeUuid,
        companyCode: companyCode,
      );
      _error = null;
    } catch (e) {
      print('Exception fetching attendances: $e');
      if (_isOfflineException(e)) {
        _applyOfflineFallback(
          localDrafts,
          fallbackMessage:
              'Jaringan tidak tersedia. Data absensi lokal tetap ditampilkan.',
          employeeUuid: employeeUuid,
          companyCode: companyCode,
        );
        _error = null;
      } else {
        _error = 'Error: $e';
        if (localDrafts.isNotEmpty) {
          _mergeOfflineAttendances(localDrafts);
          _findTodayAttendance(
            employeeUuid: employeeUuid,
            companyCode: companyCode,
            preserveExisting: true,
          );
        }
      }
    } finally {
      await _refreshPendingSyncState(notify: false);
      _isLoading = false;
      notifyListeners();
    }
  }

  // Background parsing functions
  static Map<String, dynamic> _parseAttendanceJson(String body) {
    return json.decode(body);
  }

  static List<dynamic> _extractAttendanceItems(Map<String, dynamic> payload) {
    final data = payload['data'];

    if (data is List) {
      return data;
    }

    if (payload['attendances'] is List) {
      return List<dynamic>.from(payload['attendances'] as List);
    }

    if (data is Map<String, dynamic>) {
      if (data['attendances'] is List) {
        return List<dynamic>.from(data['attendances'] as List);
      }

      if (data['data'] is List) {
        return List<dynamic>.from(data['data'] as List);
      }

      if (_looksLikeAttendanceMap(data)) {
        return [data];
      }
    } else if (data is Map) {
      final normalized = Map<String, dynamic>.from(data);
      if (_looksLikeAttendanceMap(normalized)) {
        return [normalized];
      }
    }

    if (_looksLikeAttendanceMap(payload)) {
      return [payload];
    }

    return const <dynamic>[];
  }

  static Map<String, dynamic> _extractAttendanceMeta(
    Map<String, dynamic> payload,
  ) {
    if (payload['meta'] is Map) {
      return Map<String, dynamic>.from(payload['meta'] as Map);
    }

    final data = payload['data'];
    if (data is Map<String, dynamic> && data['meta'] is Map) {
      return Map<String, dynamic>.from(data['meta'] as Map);
    }

    if (data is Map && data['meta'] is Map) {
      return Map<String, dynamic>.from(data['meta'] as Map);
    }

    return const <String, dynamic>{};
  }

  static bool _looksLikeAttendanceMap(Map<String, dynamic> data) {
    return data.containsKey('date') ||
        data.containsKey('attendance_date') ||
        data.containsKey('clock_in') ||
        data.containsKey('clock_out') ||
        data.containsKey('clock_in_time') ||
        data.containsKey('clock_out_time');
  }

  static String _normalizeAttendanceDateValue(dynamic rawValue) {
    final normalized = rawValue?.toString().trim() ?? '';
    if (normalized.isEmpty) {
      return '';
    }

    final parsed = DateTime.tryParse(normalized);
    if (parsed != null) {
      return parsed.toIso8601String().split('T')[0];
    }

    final match = RegExp(r'^(\d{4}-\d{2}-\d{2})').firstMatch(normalized);
    if (match != null) {
      return match.group(1) ?? normalized;
    }

    return normalized;
  }

  static String _extractEmployeeUuidFromAttendanceItem(
    Map<String, dynamic> item,
  ) {
    final employee = item['employee'];
    if (employee is Map) {
      final employeeMap = Map<String, dynamic>.from(employee);
      final nestedUuid =
          employeeMap['uuid']?.toString().trim() ??
          employeeMap['employee_uuid']?.toString().trim() ??
          '';
      if (nestedUuid.isNotEmpty) {
        return nestedUuid;
      }
    }

    return item['employee_uuid']?.toString().trim() ??
        item['employeeUuid']?.toString().trim() ??
        '';
  }

  static List<Attendance> _parseAttendanceHistoryList(
    Map<String, dynamic> payload,
  ) {
    final employeeUuid = payload['employee_uuid']?.toString() ?? '';
    final companyCode = payload['c_code']?.toString() ?? '';
    final employeeIdentifiers =
        (payload['employee_identifiers'] as List? ?? const <dynamic>[])
            .map((value) => value?.toString().trim() ?? '')
            .where((value) => value.isNotEmpty)
            .toList(growable: false);
    final items = (payload['items'] as List? ?? const <dynamic>[]);

    return items.whereType<Map>().map((raw) {
      final json = Map<String, dynamic>.from(raw);
      final extractedEmployeeUuid = _extractEmployeeUuidFromAttendanceItem(
        json,
      );
      final resolvedEmployeeUuid = extractedEmployeeUuid.isNotEmpty
          ? extractedEmployeeUuid
          : (employeeUuid.isNotEmpty
                ? employeeUuid
                : (employeeIdentifiers.isNotEmpty
                      ? employeeIdentifiers.first
                      : ''));
      if (resolvedEmployeeUuid.isNotEmpty) {
        json['employee_uuid'] = resolvedEmployeeUuid;
      }
      json['c_code'] ??= companyCode;
      json['uuid'] ??= json['id']?.toString();
      return Attendance.fromJson(json);
    }).toList();
  }

  // ===== FIND TODAY'S ATTENDANCE =====
  void _findTodayAttendance({
    String? employeeUuid,
    String? companyCode,
    bool preserveExisting = false,
  }) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    Attendance? matched;

    for (final attendance in _attendances) {
      if (_matchesAttendanceContext(
        attendance,
        date: today,
        employeeUuid: employeeUuid,
        companyCode: companyCode,
      )) {
        matched = _preferAttendance(matched, attendance);
      }
    }

    if (preserveExisting) {
      _todayAttendance = _preferAttendance(_todayAttendance, matched);
    } else {
      _todayAttendance = matched;
    }
  }

  bool _matchesAttendanceContext(
    Attendance attendance, {
    required String date,
    String? employeeUuid,
    String? companyCode,
  }) {
    if (attendance.date != date) {
      return false;
    }

    if (!_matchesEmployeeIdentifier(
      attendance.employeeUuid,
      employeeUuid: employeeUuid,
    )) {
      return false;
    }

    final normalizedCompanyCode = companyCode?.trim() ?? '';
    final attendanceCompanyCode = attendance.cCode?.trim() ?? '';
    return normalizedCompanyCode.isEmpty ||
        attendanceCompanyCode.isEmpty ||
        attendanceCompanyCode == normalizedCompanyCode;
  }

  Attendance? _fallbackAttendanceForDate({
    required String date,
    String? employeeUuid,
    required String companyCode,
    Iterable<Attendance> localDrafts = const <Attendance>[],
  }) {
    if (employeeUuid == null || employeeUuid.isEmpty) {
      return null;
    }

    final localAttendance = _findAttendanceByDate(
      employeeUuid,
      date,
      companyCode: companyCode,
      items: localDrafts,
    );
    final inMemoryAttendance = _findAttendanceByDate(
      employeeUuid,
      date,
      companyCode: companyCode,
    );
    final currentTodayAttendance = _todayAttendance;
    final matchingCurrentAttendance =
        currentTodayAttendance != null &&
            _matchesAttendanceContext(
              currentTodayAttendance,
              date: date,
              employeeUuid: employeeUuid,
              companyCode: companyCode,
            )
        ? currentTodayAttendance
        : null;

    return _preferAttendance(
      _preferAttendance(localAttendance, inMemoryAttendance),
      matchingCurrentAttendance,
    );
  }

  // ===== CLOCK IN =====
  Future<bool> clockIn({
    required String employeeUuid,
    String? photo,
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    if (_isClockingIn) return false;
    final normalizedEmployeeUuid = employeeUuid.trim();

    _isClockingIn = true;
    _error = null;
    _lastActionQueued = false;
    _lastActionMessage = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'employee_uuid': normalizedEmployeeUuid,
        if (photo != null) 'photo': photo,
        if (location != null) 'location': location,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

      return _submitAttendanceAction(
        action: 'clock_in',
        endpoint: ApiConstants.clockInEndpoint,
        successStatusCodes: const {200, 201},
        employeeUuid: normalizedEmployeeUuid,
        body: body,
      );
    } finally {
      _isClockingIn = false;
      notifyListeners();
    }
  }

  // ===== CLOCK OUT =====
  Future<bool> clockOut({
    required String employeeUuid,
    String? photo,
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    if (_isClockingOut) return false;
    final normalizedEmployeeUuid = employeeUuid.trim();

    _isClockingOut = true;
    _error = null;
    _lastActionQueued = false;
    _lastActionMessage = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'employee_uuid': normalizedEmployeeUuid,
        if (photo != null) 'photo': photo,
        if (location != null) 'location': location,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

      return _submitAttendanceAction(
        action: 'clock_out',
        endpoint: ApiConstants.clockOutEndpoint,
        successStatusCodes: const {200, 201},
        employeeUuid: normalizedEmployeeUuid,
        body: body,
      );
    } finally {
      _isClockingOut = false;
      notifyListeners();
    }
  }

  Future<bool> _submitAttendanceAction({
    required String action,
    required String endpoint,
    required Set<int> successStatusCodes,
    required String employeeUuid,
    required Map<String, dynamic> body,
  }) async {
    final actionTime = DateTime.now();
    final normalizedEmployeeUuid = employeeUuid.trim();
    final companyCode = await _getCurrentCompanyCode();

    if (normalizedEmployeeUuid.isEmpty) {
      _error = 'Employee ID tidak ditemukan.';
      return false;
    }

    if (companyCode.isEmpty) {
      _error = 'C_CODE aktif tidak ditemukan.';
      return false;
    }

    try {
      final headers = await _getHeaders(companyCodeOverride: companyCode);

      print('$action request: $body');

      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}$endpoint'),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 15));

      print('$action response status: ${response.statusCode}');
      print('$action response body: ${response.body}');

      final data = _decodeResponseBody(response.body);

      if (successStatusCodes.contains(response.statusCode) &&
          data['success'] == true) {
        _applyImmediateAttendanceAction(
          action: action,
          employeeUuid: normalizedEmployeeUuid,
          companyCode: companyCode,
          body: body,
          actionTime: actionTime,
          serverResponse: data,
        );
        _lastActionQueued = false;
        _lastActionMessage = action == 'clock_in'
            ? 'Clock in berhasil disimpan ke server.'
            : 'Clock out berhasil disimpan ke server.';
        _syncNotice = _pendingSyncCount > 0
            ? 'Ada $_pendingSyncCount data absensi offline menunggu sinkronisasi.'
            : null;
        await _refreshDataAfterAction();
        return true;
      }

      if (_shouldQueueResponse(response.statusCode)) {
        await _queueOfflineAttendanceAction(
          action: action,
          endpoint: endpoint,
          employeeUuid: normalizedEmployeeUuid,
          companyCode: companyCode,
          body: body,
          actionTime: actionTime,
          failureReason: 'HTTP ${response.statusCode}',
        );
        return true;
      }

      _error =
          data['message']?.toString() ??
          (action == 'clock_in' ? 'Clock in gagal' : 'Clock out gagal');
      return false;
    } on TimeoutException catch (e) {
      print('Timeout $action: $e');
      await _queueOfflineAttendanceAction(
        action: action,
        endpoint: endpoint,
        employeeUuid: normalizedEmployeeUuid,
        companyCode: companyCode,
        body: body,
        actionTime: actionTime,
        failureReason: e.toString(),
      );
      return true;
    } on SocketException catch (e) {
      print('Socket exception $action: $e');
      await _queueOfflineAttendanceAction(
        action: action,
        endpoint: endpoint,
        employeeUuid: normalizedEmployeeUuid,
        companyCode: companyCode,
        body: body,
        actionTime: actionTime,
        failureReason: e.toString(),
      );
      return true;
    } on http.ClientException catch (e) {
      print('Client exception $action: $e');
      await _queueOfflineAttendanceAction(
        action: action,
        endpoint: endpoint,
        employeeUuid: normalizedEmployeeUuid,
        companyCode: companyCode,
        body: body,
        actionTime: actionTime,
        failureReason: e.toString(),
      );
      return true;
    } catch (e) {
      print('Exception $action: $e');
      if (_isOfflineException(e)) {
        await _queueOfflineAttendanceAction(
          action: action,
          endpoint: endpoint,
          employeeUuid: normalizedEmployeeUuid,
          companyCode: companyCode,
          body: body,
          actionTime: actionTime,
          failureReason: e.toString(),
        );
        return true;
      }

      _error = 'Error: $e';
      return false;
    }
  }

  void _applyImmediateAttendanceAction({
    required String action,
    required String employeeUuid,
    required String companyCode,
    required Map<String, dynamic> body,
    required DateTime actionTime,
    required Map<String, dynamic> serverResponse,
  }) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(actionTime);
    final formattedTime = DateFormat('HH:mm:ss').format(actionTime);
    final currentAttendance = _findAttendanceByDate(
      employeeUuid,
      formattedDate,
      companyCode: companyCode,
    );
    final serverAttendance = _attendanceFromResponseData(
      serverResponse,
      employeeUuid: employeeUuid,
      companyCode: companyCode,
      targetDate: formattedDate,
    );

    final mergedAttendance = Attendance(
      uuid: serverAttendance?.uuid ?? currentAttendance?.uuid,
      employeeUuid: employeeUuid,
      employeeName:
          serverAttendance?.employeeName ?? currentAttendance?.employeeName,
      employeePosition:
          serverAttendance?.employeePosition ??
          currentAttendance?.employeePosition,
      employeeNik:
          serverAttendance?.employeeNik ?? currentAttendance?.employeeNik,
      date: formattedDate,
      clockIn: action == 'clock_in'
          ? serverAttendance?.clockIn ?? formattedTime
          : serverAttendance?.clockIn ?? currentAttendance?.clockIn,
      clockOut: action == 'clock_out'
          ? serverAttendance?.clockOut ?? formattedTime
          : serverAttendance?.clockOut ?? currentAttendance?.clockOut,
      clockInPhoto: action == 'clock_in'
          ? body['photo']?.toString() ??
                serverAttendance?.clockInPhoto ??
                currentAttendance?.clockInPhoto
          : serverAttendance?.clockInPhoto ?? currentAttendance?.clockInPhoto,
      clockInLocation: action == 'clock_in'
          ? body['location']?.toString() ??
                serverAttendance?.clockInLocation ??
                currentAttendance?.clockInLocation
          : serverAttendance?.clockInLocation ??
                currentAttendance?.clockInLocation,
      clockOutPhoto: action == 'clock_out'
          ? body['photo']?.toString() ??
                serverAttendance?.clockOutPhoto ??
                currentAttendance?.clockOutPhoto
          : serverAttendance?.clockOutPhoto ?? currentAttendance?.clockOutPhoto,
      clockOutLocation: action == 'clock_out'
          ? body['location']?.toString() ??
                serverAttendance?.clockOutLocation ??
                currentAttendance?.clockOutLocation
          : serverAttendance?.clockOutLocation ??
                currentAttendance?.clockOutLocation,
      cCode: companyCode,
      employee: serverAttendance?.employee ?? currentAttendance?.employee,
      isPendingSync: false,
    );

    _mergeOfflineAttendances([mergedAttendance]);
    _todayAttendance = mergedAttendance;
    notifyListeners();
  }

  Attendance? _attendanceFromResponseData(
    Map<String, dynamic> response, {
    required String employeeUuid,
    required String companyCode,
    required String targetDate,
  }) {
    final employeeIdentifiers = _currentEmployeeIdentifiers.isNotEmpty
        ? Set<String>.from(_currentEmployeeIdentifiers)
        : <String>{if (employeeUuid.trim().isNotEmpty) employeeUuid.trim()};
    final items = _extractAttendanceItems(response);
    for (final raw in items.whereType<Map>()) {
      final json = Map<String, dynamic>.from(raw);
      final itemDate = _normalizeAttendanceDateValue(
        json['date'] ?? json['attendance_date'],
      );
      final itemEmployeeUuid = _extractEmployeeUuidFromAttendanceItem(json);

      if (itemDate != targetDate) {
        continue;
      }

      if (!_matchesEmployeeIdentifier(
        itemEmployeeUuid,
        employeeUuid: employeeUuid,
        employeeIdentifiers: employeeIdentifiers,
      )) {
        continue;
      }

      final resolvedItemEmployeeUuid = itemEmployeeUuid.isNotEmpty
          ? itemEmployeeUuid
          : employeeUuid;
      if (resolvedItemEmployeeUuid.isNotEmpty) {
        json['employee_uuid'] = resolvedItemEmployeeUuid;
      }
      json['c_code'] ??= companyCode;
      json['uuid'] ??= json['id']?.toString();
      return Attendance.fromJson(json);
    }

    return null;
  }

  Future<void> _queueOfflineAttendanceAction({
    required String action,
    required String endpoint,
    required String employeeUuid,
    required String companyCode,
    required Map<String, dynamic> body,
    required DateTime actionTime,
    String? failureReason,
  }) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(actionTime);

    await _databaseHelper.insertOfflineQueueItem({
      'feature': 'attendance',
      'action': action,
      'endpoint': endpoint,
      'method': 'POST',
      'payload': json.encode(body),
      'employee_uuid': employeeUuid,
      'c_code': companyCode,
      'date': formattedDate,
      'created_at': actionTime.millisecondsSinceEpoch,
      'retry_count': 0,
      'last_error': failureReason,
    });

    await _upsertAttendanceDraft(
      action: action,
      employeeUuid: employeeUuid,
      companyCode: companyCode,
      body: body,
      actionTime: actionTime,
    );

    await _refreshPendingSyncState(notify: false);

    _lastActionQueued = true;
    _lastActionMessage = action == 'clock_in'
        ? 'Clock in tersimpan offline dan akan dikirim otomatis saat server online.'
        : 'Clock out tersimpan offline dan akan dikirim otomatis saat server online.';
    _syncNotice =
        'Ada $_pendingSyncCount data absensi offline menunggu sinkronisasi.';
  }

  Future<void> _upsertAttendanceDraft({
    required String action,
    required String employeeUuid,
    required String companyCode,
    required Map<String, dynamic> body,
    required DateTime actionTime,
  }) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(actionTime);
    final formattedTime = DateFormat('HH:mm:ss').format(actionTime);
    final existingDraft = await _databaseHelper.getAttendanceDraft(
      employeeUuid,
      formattedDate,
      companyCode,
    );
    final currentAttendance = _findAttendanceByDate(
      employeeUuid,
      formattedDate,
      companyCode: companyCode,
    );

    final draftData = <String, dynamic>{
      'employee_uuid': employeeUuid,
      'date': formattedDate,
      'c_code': companyCode,
      'clock_in': existingDraft?['clock_in'] ?? currentAttendance?.clockIn,
      'clock_out': existingDraft?['clock_out'] ?? currentAttendance?.clockOut,
      'clock_in_photo':
          existingDraft?['clock_in_photo'] ?? currentAttendance?.clockInPhoto,
      'clock_out_photo':
          existingDraft?['clock_out_photo'] ?? currentAttendance?.clockOutPhoto,
      'clock_in_location':
          existingDraft?['clock_in_location'] ??
          currentAttendance?.clockInLocation,
      'clock_out_location':
          existingDraft?['clock_out_location'] ??
          currentAttendance?.clockOutLocation,
      'sync_status': 'pending',
      'updated_at': actionTime.millisecondsSinceEpoch,
    };

    if (action == 'clock_in') {
      draftData['clock_in'] = formattedTime;
      draftData['clock_in_photo'] = body['photo'];
      draftData['clock_in_location'] = body['location'];
    } else {
      draftData['clock_out'] = formattedTime;
      draftData['clock_out_photo'] = body['photo'];
      draftData['clock_out_location'] = body['location'];
    }

    await _databaseHelper.upsertAttendanceDraft(draftData);

    _mergeOfflineAttendances([
      Attendance(
        employeeUuid: employeeUuid,
        date: formattedDate,
        cCode: companyCode,
        clockIn: draftData['clock_in']?.toString(),
        clockOut: draftData['clock_out']?.toString(),
        clockInPhoto: draftData['clock_in_photo']?.toString(),
        clockOutPhoto: draftData['clock_out_photo']?.toString(),
        clockInLocation: draftData['clock_in_location']?.toString(),
        clockOutLocation: draftData['clock_out_location']?.toString(),
        isPendingSync: true,
      ),
    ]);
    _findTodayAttendance(employeeUuid: employeeUuid, companyCode: companyCode);
  }

  Attendance? _findAttendanceByDate(
    String employeeUuid,
    String date, {
    String? companyCode,
    Iterable<Attendance>? items,
  }) {
    try {
      final normalizedCompanyCode = companyCode?.trim() ?? '';
      return (items ?? _attendances).firstWhere(
        (attendance) =>
            attendance.date == date &&
            _matchesEmployeeIdentifier(
              attendance.employeeUuid,
              employeeUuid: employeeUuid,
            ) &&
            (normalizedCompanyCode.isEmpty ||
                (attendance.cCode?.trim().isEmpty ?? true) ||
                attendance.cCode?.trim() == normalizedCompanyCode),
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> syncOfflineActions({
    bool silent = false,
    bool refreshAfterSync = true,
  }) async {
    final employeeUuid = await _getCurrentEmployeeUuid();
    final companyCode = await _getCurrentCompanyCode();
    if (_isSyncingOfflineQueue) {
      return false;
    }

    final pendingItems = await _databaseHelper.getOfflineQueueItems(
      feature: 'attendance',
      employeeUuid: employeeUuid,
      companyCode: companyCode,
    );
    if (pendingItems.isEmpty) {
      await _refreshPendingSyncState(notify: !silent);
      return true;
    }

    final token = await SessionStorage.getToken();
    if (token.isEmpty) {
      return false;
    }

    _isSyncingOfflineQueue = true;
    if (!silent) {
      notifyListeners();
    }

    var syncedAny = false;

    try {
      for (final item in pendingItems) {
        final id = item['id'] as int?;
        final endpoint = item['endpoint']?.toString() ?? '';
        final method = item['method']?.toString().toUpperCase() ?? 'POST';
        final payload = _decodeResponseBody(
          item['payload']?.toString() ?? '{}',
        );

        try {
          final itemCompanyCode =
              item['c_code']?.toString().trim().isNotEmpty == true
              ? item['c_code']?.toString().trim()
              : companyCode;
          final headers = await _getHeaders(
            companyCodeOverride: itemCompanyCode,
          );
          late http.Response response;

          switch (method) {
            case 'POST':
              response = await http
                  .post(
                    Uri.parse('${ApiConstants.baseUrl}$endpoint'),
                    headers: headers,
                    body: json.encode(payload),
                  )
                  .timeout(const Duration(seconds: 15));
              break;
            case 'PUT':
              response = await http
                  .put(
                    Uri.parse('${ApiConstants.baseUrl}$endpoint'),
                    headers: headers,
                    body: json.encode(payload),
                  )
                  .timeout(const Duration(seconds: 15));
              break;
            default:
              continue;
          }

          final data = _decodeResponseBody(response.body);

          if ((response.statusCode == 200 || response.statusCode == 201) &&
              data['success'] == true) {
            syncedAny = true;
            if (id != null) {
              await _databaseHelper.deleteOfflineQueueItem(id);
            }
          } else {
            if (id != null) {
              await _databaseHelper.updateOfflineQueueItem(id, {
                'retry_count': ((item['retry_count'] as int?) ?? 0) + 1,
                'last_error':
                    data['message']?.toString() ??
                    'HTTP ${response.statusCode}',
              });
            }

            if (_shouldQueueResponse(response.statusCode)) {
              break;
            }
          }
        } on TimeoutException catch (e) {
          if (id != null) {
            await _databaseHelper.updateOfflineQueueItem(id, {
              'retry_count': ((item['retry_count'] as int?) ?? 0) + 1,
              'last_error': e.toString(),
            });
          }
          break;
        } on SocketException catch (e) {
          if (id != null) {
            await _databaseHelper.updateOfflineQueueItem(id, {
              'retry_count': ((item['retry_count'] as int?) ?? 0) + 1,
              'last_error': e.toString(),
            });
          }
          break;
        } on http.ClientException catch (e) {
          if (id != null) {
            await _databaseHelper.updateOfflineQueueItem(id, {
              'retry_count': ((item['retry_count'] as int?) ?? 0) + 1,
              'last_error': e.toString(),
            });
          }
          break;
        }
      }

      await _cleanupSyncedAttendanceDrafts(employeeUuid: employeeUuid);
      await _refreshPendingSyncState(notify: false);

      if (syncedAny && refreshAfterSync) {
        _lastActionQueued = false;
        _lastActionMessage = 'Data absensi offline berhasil disinkronkan.';
        await _refreshDataAfterAction();
      }

      return syncedAny;
    } finally {
      _isSyncingOfflineQueue = false;
      if (!silent) {
        notifyListeners();
      }
    }
  }

  Future<void> _cleanupSyncedAttendanceDrafts({String? employeeUuid}) async {
    final companyCode = await _getCurrentCompanyCode();
    final pendingItems = await _databaseHelper.getOfflineQueueItems(
      feature: 'attendance',
      employeeUuid: employeeUuid,
      companyCode: companyCode,
    );
    final pendingKeys = pendingItems
        .map(
          (item) =>
              '${item['employee_uuid']?.toString() ?? ''}::${item['date']?.toString() ?? ''}::${item['c_code']?.toString() ?? ''}',
        )
        .toSet();
    final drafts = await _databaseHelper.getAttendanceDrafts(
      employeeUuid: employeeUuid,
      companyCode: companyCode,
    );

    for (final draft in drafts) {
      final key =
          '${draft['employee_uuid']?.toString() ?? ''}::${draft['date']?.toString() ?? ''}::${draft['c_code']?.toString() ?? ''}';
      if (!pendingKeys.contains(key)) {
        final employeeUuid = draft['employee_uuid']?.toString() ?? '';
        final date = draft['date']?.toString() ?? '';
        final draftCompanyCode = draft['c_code']?.toString() ?? '';
        if (employeeUuid.isNotEmpty &&
            date.isNotEmpty &&
            draftCompanyCode.isNotEmpty) {
          await _databaseHelper.deleteAttendanceDraft(
            employeeUuid,
            date,
            draftCompanyCode,
          );
        }
      }
    }
  }

  Future<void> _restoreLocalAttendanceState() async {
    final employeeUuid = await _getCurrentEmployeeUuid();
    final companyCode = await _ensureAttendanceContext(
      employeeUuid: employeeUuid,
    );
    final localAttendances = await _loadLocalAttendances(
      employeeUuid: employeeUuid,
      companyCode: companyCode,
    );

    if (localAttendances.isEmpty) {
      return;
    }

    _mergeOfflineAttendances(localAttendances);
    _findTodayAttendance(employeeUuid: employeeUuid, companyCode: companyCode);
    await _refreshPendingSyncState(notify: false);
    notifyListeners();
  }

  Future<List<Attendance>> _loadLocalAttendances({
    String? employeeUuid,
    String? companyCode,
  }) async {
    final drafts = await _databaseHelper.getAttendanceDrafts(
      employeeUuid: employeeUuid,
      companyCode: companyCode,
    );

    return drafts
        .map((draft) {
          return Attendance.fromJson({
            'employee_uuid': draft['employee_uuid'],
            'date': draft['date'],
            'c_code': draft['c_code'],
            'clock_in': draft['clock_in'],
            'clock_out': draft['clock_out'],
            'clock_in_photo': draft['clock_in_photo'],
            'clock_out_photo': draft['clock_out_photo'],
            'clock_in_location': draft['clock_in_location'],
            'clock_out_location': draft['clock_out_location'],
            'sync_status': draft['sync_status'],
            'is_pending_sync': draft['sync_status'] == 'pending',
          });
        })
        .toList(growable: false);
  }

  void _mergeOfflineAttendances(List<Attendance> offlineAttendances) {
    if (offlineAttendances.isEmpty) {
      return;
    }

    final merged = <String, Attendance>{};
    for (final attendance in _attendances) {
      merged[_attendanceKey(attendance)] = attendance;
    }
    for (final attendance in offlineAttendances) {
      merged[_attendanceKey(attendance)] = attendance;
    }

    _attendances = _sortAttendances(merged.values);
  }

  void _applyOfflineFallback(
    List<Attendance> localDrafts, {
    required String fallbackMessage,
    String? employeeUuid,
    String? companyCode,
  }) {
    if (localDrafts.isNotEmpty) {
      _attendances = _sortAttendances(localDrafts);
    } else {
      _attendances = const <Attendance>[];
    }
    _findTodayAttendance(
      employeeUuid: employeeUuid,
      companyCode: companyCode,
      preserveExisting: true,
    );
    _syncNotice = fallbackMessage;
  }

  List<Attendance> _mergeFetchedAttendances({
    required List<Attendance> fetchedAttendances,
    required int page,
    List<Attendance> localDrafts = const <Attendance>[],
    Attendance? optimisticToday,
  }) {
    if (page == 1) {
      return _sortAttendances([
        ...fetchedAttendances,
        ...localDrafts,
        if (optimisticToday != null) optimisticToday,
      ]);
    }

    return _sortAttendances([..._attendances, ...fetchedAttendances]);
  }

  List<Attendance> _sortAttendances(Iterable<Attendance> items) {
    final uniqueAttendances = <String, Attendance>{};
    for (final attendance in items) {
      final key = _attendanceKey(attendance);
      uniqueAttendances[key] = _preferAttendance(
        uniqueAttendances[key],
        attendance,
      )!;
    }

    final sorted = List<Attendance>.from(uniqueAttendances.values);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  String _attendanceKey(Attendance attendance) {
    return '${attendance.employeeUuid ?? 'self'}::${attendance.date}::${attendance.cCode?.trim() ?? ''}';
  }

  Attendance? _preferAttendance(Attendance? current, Attendance? candidate) {
    if (current == null) {
      return candidate;
    }
    if (candidate == null) {
      return current;
    }

    final currentScore = _attendanceCompletenessScore(current);
    final candidateScore = _attendanceCompletenessScore(candidate);

    if (candidateScore > currentScore) {
      return candidate;
    }

    return current;
  }

  int _attendanceCompletenessScore(Attendance attendance) {
    var score = 0;

    if (attendance.hasClockIn) {
      score += 2;
    }
    if (attendance.hasClockOut) {
      score += 3;
    }
    if (attendance.clockInLocation?.trim().isNotEmpty ?? false) {
      score += 1;
    }
    if (attendance.clockOutLocation?.trim().isNotEmpty ?? false) {
      score += 1;
    }
    if (attendance.uuid?.trim().isNotEmpty ?? false) {
      score += 1;
    }
    if (attendance.isPendingSync) {
      score += 4;
    }

    return score;
  }

  Future<String?> _getCurrentEmployeeUuid() async {
    return resolveCurrentEmployeeUuid();
  }

  Future<void> _refreshPendingSyncState({bool notify = true}) async {
    final employeeUuid = await _getCurrentEmployeeUuid();
    final companyCode = await _getCurrentCompanyCode();
    _pendingSyncCount = await _databaseHelper.countOfflineQueueItems(
      feature: 'attendance',
      employeeUuid: employeeUuid,
      companyCode: companyCode,
    );

    if (_pendingSyncCount > 0) {
      _syncNotice =
          'Ada $_pendingSyncCount data absensi offline menunggu sinkronisasi.';
    } else if (_syncNotice != null &&
        (_syncNotice!.contains('menunggu sinkronisasi') ||
            _syncNotice!.contains('offline berhasil disinkronkan'))) {
      _syncNotice = null;
    }

    if (notify) {
      notifyListeners();
    }
  }

  bool _shouldQueueResponse(int statusCode) {
    return statusCode >= 500 || statusCode == 408;
  }

  bool _isOfflineException(Object error) {
    return error is SocketException ||
        error is TimeoutException ||
        error is http.ClientException;
  }

  Map<String, dynamic> _decodeResponseBody(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return <String, dynamic>{'data': decoded};
    } catch (_) {
      return <String, dynamic>{'message': body};
    }
  }

  // ===== REFRESH DATA AFTER ACTION =====
  Future<void> _refreshDataAfterAction() async {
    try {
      await Future.wait([
        fetchTodayAttendance(),
        fetchAttendances(),
        getAttendanceSummary(),
      ]);
    } catch (e) {
      print('Error refreshing data: $e');
    }
  }

  // ===== GET DAILY REPORT =====
  Future<Map<String, dynamic>?> getDailyReport({String? date}) async {
    try {
      final headers = await _getHeaders();
      final dateParam = date ?? DateTime.now().toIso8601String().split('T')[0];

      final url =
          '${ApiConstants.baseUrl}${ApiConstants.dailyReportEndpoint}?date=$dateParam';
      print('Fetching daily report from: $url');

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting daily report: $e');
      return null;
    }
  }

  // ===== GET ATTENDANCE SUMMARY =====
  Future<void> getAttendanceSummary({String? date}) async {
    try {
      final headers = await _getHeaders();
      final dateParam = date ?? DateTime.now().toIso8601String().split('T')[0];

      final url =
          '${ApiConstants.baseUrl}${ApiConstants.attendanceSummaryEndpoint}?date=$dateParam';
      print('Fetching attendance summary from: $url');

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          _summary = data['data'];
          print('Summary loaded: $_summary');
          notifyListeners();
        }
      }
    } on TimeoutException catch (e) {
      print('Timeout getting attendance summary: $e');
      _summary = _buildLocalSummary();
      notifyListeners();
    } on SocketException catch (e) {
      print('Socket exception getting attendance summary: $e');
      _summary = _buildLocalSummary();
      notifyListeners();
    } catch (e) {
      print('Error getting attendance summary: $e');
      if (_isOfflineException(e)) {
        _summary = _buildLocalSummary();
        notifyListeners();
      }
    }
  }

  Map<String, dynamic> _buildLocalSummary() {
    return {
      'present': _todayAttendance?.hasClockIn == true ? 1 : 0,
      'completed': _todayAttendance?.hasClockOut == true ? 1 : 0,
      'pending_sync': _pendingSyncCount,
    };
  }

  // ===== LOAD NEXT PAGE =====
  Future<void> loadNextPage({String? date}) async {
    if (_currentPage < _lastPage && !_isLoading) {
      await fetchAttendances(date: date, page: _currentPage + 1);
    }
  }

  // ===== REFRESH DATA =====
  Future<void> refreshData() async {
    await syncOfflineActions(silent: true, refreshAfterSync: false);
    await fetchTodayAttendance();
    await fetchAttendances();
    await getAttendanceSummary();
    await fetchSettings(); // Refresh settings juga
  }

  // ===== CLEAR ERROR =====
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ===== RESET =====
  void reset() {
    _attendances = [];
    _todayAttendance = null;
    _isLoading = false;
    _error = null;
    _isClockingIn = false;
    _isClockingOut = false;
    _isSyncingOfflineQueue = false;
    _pendingSyncCount = 0;
    _syncNotice = null;
    _lastActionMessage = null;
    _lastActionQueued = false;
    _activeAttendanceContextKey = '';
    _resolvedCurrentEmployeeUuid = null;
    _currentEmployeeIdentifiers = <String>{};
    _currentPage = 1;
    _lastPage = 1;
    _total = 0;
    _summary = null;
    _settings = null;
    _allowedLocations = [];
    _correctionRequests = [];
    notifyListeners();
  }

  // ===== LOCATION MANAGEMENT =====
  Future<void> loadLocations({bool forceRefresh = false}) async {
    if (_allowedLocations.isNotEmpty && !forceRefresh) {
      return;
    }

    final employeeUuid = await _getCurrentEmployeeUuid();
    final resolvedLocation = await _loadResolvedEmployeeLocation(employeeUuid);
    if (resolvedLocation != null) {
      _allowedLocations = [resolvedLocation];
      notifyListeners();
      return;
    }

    final vendorLocation = await _loadAssignedVendorLocation(employeeUuid);
    if (vendorLocation != null) {
      _allowedLocations = [vendorLocation];
      notifyListeners();
      return;
    }

    final entityLookup = await _loadPrimaryEntityLocation();
    if (entityLookup.location != null) {
      _allowedLocations = [entityLookup.location!];
      notifyListeners();
      return;
    }

    if (entityLookup.shouldFallbackToSettings) {
      final settingsLocation = await _loadSettingsLocation();
      if (settingsLocation != null) {
        _allowedLocations = [settingsLocation];
        notifyListeners();
        return;
      }
    }

    _allowedLocations = [];
    notifyListeners();
  }

  Future<AttendanceLocation?> _loadAssignedVendorLocation(
    String? employeeUuid,
  ) async {
    final assignedLocations = await _loadAssignedClientLocations(employeeUuid);
    if (assignedLocations.isNotEmpty) {
      return assignedLocations.first;
    }

    final resolvedLocation = await _loadResolvedEmployeeLocation(
      employeeUuid,
      vendorOnly: true,
    );
    if (resolvedLocation != null) {
      return resolvedLocation;
    }

    return null;
  }

  Future<_EntityLocationLookupResult> _loadPrimaryEntityLocation() async {
    var shouldFallbackToSettings = false;

    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            await _buildApiUri(ApiConstants.activeDefaultEntityEndpoint),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      print('Active default entity response status: ${response.statusCode}');

      if (response.statusCode == 404) {
        shouldFallbackToSettings = true;
      } else if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['data'] is Map) {
          final entity = Map<String, dynamic>.from(data['data'] as Map);
          final location = _parseEntityLocation(entity);
          if (location != null) {
            return _EntityLocationLookupResult(location: location);
          }
        }
      }
    } catch (e) {
      print('Error loading active default entity location: $e');
    }

    final entityListLookup = await _loadEntityLocationFromList();
    if (entityListLookup.location != null) {
      return entityListLookup;
    }

    return _EntityLocationLookupResult(
      shouldFallbackToSettings:
          shouldFallbackToSettings || entityListLookup.shouldFallbackToSettings,
    );
  }

  Future<_EntityLocationLookupResult> _loadEntityLocationFromList() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            await _buildApiUri(ApiConstants.entitiesEndpoint),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      print('Entity list response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        return const _EntityLocationLookupResult(
          shouldFallbackToSettings: true,
        );
      }

      final Map<String, dynamic> data = json.decode(response.body);
      final entities = _extractEntityItems(data);

      if (entities.isEmpty) {
        print('Entity list fallback returned no rows');
        return const _EntityLocationLookupResult(
          shouldFallbackToSettings: true,
        );
      }

      for (final entity in entities) {
        if (!_isEntityActive(entity)) {
          continue;
        }

        final location = _parseEntityLocation(entity);
        if (location != null) {
          print('Using active entity from list fallback: ${location.name}');
          return _EntityLocationLookupResult(location: location);
        }
      }

      print('Entity list fallback found rows, but no active entity location');
      return const _EntityLocationLookupResult(shouldFallbackToSettings: true);
    } catch (e) {
      print('Error loading entity list fallback: $e');
      return const _EntityLocationLookupResult(shouldFallbackToSettings: true);
    }
  }

  List<Map<String, dynamic>> _extractEntityItems(
    Map<String, dynamic> response,
  ) {
    if (response['success'] != true) {
      return const <Map<String, dynamic>>[];
    }

    final data = response['data'];

    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }

    if (data is Map) {
      for (final key in const ['data', 'items', 'rows', 'entities']) {
        final nested = data[key];
        if (nested is List) {
          return nested
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false);
        }
      }

      final singleItem = Map<String, dynamic>.from(data);
      if (_parseEntityLocation(singleItem) != null) {
        return <Map<String, dynamic>>[singleItem];
      }
    }

    return const <Map<String, dynamic>>[];
  }

  bool _isEntityActive(Map<String, dynamic> entity) {
    return _isTruthy(entity['is_active']) ||
        _isTruthy(entity['active']) ||
        _isTruthy(entity['status']) ||
        _isTruthy(entity['status_active']) ||
        _isTruthy(entity['is_default']) ||
        _isTruthy(entity['default']) ||
        _isTruthy(entity['selected']);
  }

  bool _isTruthy(dynamic value) {
    if (value == null) {
      return false;
    }

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final normalized = value.toString().trim().toLowerCase();
    return normalized == '1' ||
        normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'active' ||
        normalized == 'enabled' ||
        normalized == 'aktif' ||
        normalized == 'on' ||
        normalized == 'default' ||
        normalized == 'selected';
  }

  Future<AttendanceLocation?> _loadResolvedEmployeeLocation(
    String? employeeUuid, {
    bool vendorOnly = false,
    Set<String>? allowedSources,
  }) async {
    if (employeeUuid == null || employeeUuid.isEmpty) {
      return null;
    }

    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            await _buildApiUri('/api/employees/$employeeUuid/client-location'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      print(
        'Resolved employee location response status: ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> data = json.decode(response.body);
      if (data['success'] != true || data['data'] is! Map) {
        return null;
      }

      final locationData = Map<String, dynamic>.from(data['data'] as Map);
      final source = _normalizeResolvedLocationSource(locationData);
      if (allowedSources != null && !allowedSources.contains(source)) {
        return null;
      }
      if (vendorOnly && !_isVendorLocationSource(source, locationData)) {
        return null;
      }

      final sourcePayload = _pickResolvedLocationPayload(locationData, source);
      final coordinates =
          _extractCoordinatePair(sourcePayload) ??
          _extractCoordinatePair(locationData);

      if (coordinates == null) {
        return null;
      }

      final resolvedName = _firstNonEmptyString([
        sourcePayload['name'],
        sourcePayload['company_name'],
        sourcePayload['vendor_name'],
        sourcePayload['client_name'],
        locationData['name'],
        locationData['company_name'],
        locationData['vendor_name'],
        locationData['client_name'],
      ]);
      final resolvedId = _firstNonEmptyString([
        sourcePayload['uuid'],
        sourcePayload['id'],
        locationData['uuid'],
        locationData['id'],
      ]);
      final resolvedAddress = _firstNonEmptyString([
        sourcePayload['address'],
        locationData['address'],
      ]);
      final resolvedRadius =
          _asDouble(sourcePayload['radius']) ??
          _asDouble(locationData['radius']) ??
          100;

      return AttendanceLocation(
        id: resolvedId ?? 'resolved_$source',
        name: resolvedName ?? _resolvedLocationName(source),
        latitude: coordinates.key,
        longitude: coordinates.value,
        radius: resolvedRadius,
        address: resolvedAddress,
      );
    } catch (e) {
      print('Error loading resolved employee location: $e');
      return null;
    }
  }

  String _normalizeResolvedLocationSource(Map<String, dynamic> locationData) {
    final rawSource = locationData['source']?.toString().trim().toLowerCase();
    if (rawSource != null && rawSource.isNotEmpty) {
      if (rawSource.contains('vendor') || rawSource.contains('client')) {
        return 'vendor';
      }
      if (rawSource.contains('setting')) {
        return 'system_settings';
      }
      if (rawSource.contains('default') && rawSource.contains('entity')) {
        return 'default_entity';
      }
      if (rawSource.contains('entity')) {
        return 'entity';
      }
      return rawSource;
    }

    if (locationData['vendor'] is Map ||
        locationData['client'] is Map ||
        locationData['vendor_uuid'] != null ||
        locationData['client_uuid'] != null) {
      return 'vendor';
    }

    if (locationData['entity'] is Map || locationData['entity_uuid'] != null) {
      return 'entity';
    }

    if (locationData['settings'] is Map || locationData['setting'] is Map) {
      return 'system_settings';
    }

    return 'attendance';
  }

  bool _isVendorLocationSource(
    String source,
    Map<String, dynamic> locationData,
  ) {
    return source == 'vendor' ||
        source == 'client' ||
        locationData['vendor'] is Map ||
        locationData['client'] is Map ||
        locationData['vendor_uuid'] != null ||
        locationData['client_uuid'] != null;
  }

  Map<String, dynamic> _pickResolvedLocationPayload(
    Map<String, dynamic> locationData,
    String source,
  ) {
    final candidates = <dynamic>[
      if (source == 'vendor') locationData['vendor'],
      if (source == 'vendor') locationData['client'],
      if (source == 'entity' || source == 'default_entity')
        locationData['entity'],
      if (source == 'system_settings') locationData['settings'],
      if (source == 'system_settings') locationData['setting'],
      locationData['location'],
      locationData['coordinates'],
      locationData,
    ];

    for (final candidate in candidates) {
      if (candidate is! Map) {
        continue;
      }

      final payload = Map<String, dynamic>.from(candidate);
      if (_extractCoordinatePair(payload) != null) {
        return payload;
      }
    }

    return locationData;
  }

  String _resolvedLocationName(String source) {
    switch (source) {
      case 'vendor':
      case 'client':
        return 'Lokasi Vendor';
      case 'entity':
        return 'Lokasi Default Entity';
      case 'default_entity':
        return 'Lokasi Entity Aktif';
      case 'system_settings':
        return 'Lokasi General Setting';
      default:
        return 'Lokasi Absensi';
    }
  }

  Future<List<AttendanceLocation>> _loadAssignedClientLocations(
    String? employeeUuid,
  ) async {
    if (employeeUuid == null || employeeUuid.isEmpty) {
      return const <AttendanceLocation>[];
    }

    try {
      final headers = await _getHeaders();
      final clients = await _fetchClients(headers);

      if (clients.isEmpty) {
        return const <AttendanceLocation>[];
      }

      final matchedLocations = <AttendanceLocation>[];
      for (final client in clients) {
        final location = _parseClientLocation(client);
        if (location == null) {
          continue;
        }

        final isAssignedInline = _clientPayloadHasEmployee(
          client,
          employeeUuid,
        );
        final clientUuid =
            client['uuid']?.toString() ?? client['id']?.toString() ?? '';

        final isAssigned =
            isAssignedInline ||
            (clientUuid.isNotEmpty &&
                await _clientHasAssignedEmployee(
                  clientUuid,
                  employeeUuid,
                  headers,
                ));

        if (isAssigned) {
          matchedLocations.add(location);
        }
      }

      if (matchedLocations.isNotEmpty) {
        print(
          'Assigned client attendance locations found: ${matchedLocations.length}',
        );
      }

      return matchedLocations;
    } catch (e) {
      print('Error loading assigned client locations: $e');
    }

    return const <AttendanceLocation>[];
  }

  Future<AttendanceLocation?> _loadSettingsLocation() async {
    if (_settings == null) {
      await fetchSettings();
    }

    final settings = _settings;
    final coordinates = _extractCoordinatePairFromValues(
      settings?.latitude,
      settings?.longitude,
    );

    if (coordinates == null) {
      return null;
    }

    return AttendanceLocation(
      id: 'system_settings',
      name: settings?.companyName?.trim().isNotEmpty == true
          ? settings!.companyName!.trim()
          : 'Default Setting',
      latitude: coordinates.key,
      longitude: coordinates.value,
      radius: 100,
      address: null,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchClients(
    Map<String, String> headers,
  ) async {
    final clients = <Map<String, dynamic>>[];
    var page = 1;

    while (true) {
      final response = await http
          .get(
            await _buildApiUri(
              '/api/clients',
              queryParameters: {'page': page, 'per_page': 200},
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      print('Client list response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        break;
      }

      final Map<String, dynamic> data = json.decode(response.body);
      final payload = _extractClientListPayload(data);

      if (payload.items.isEmpty) {
        break;
      }

      clients.addAll(payload.items);
      if (page >= payload.lastPage) {
        break;
      }

      page += 1;
    }

    return clients;
  }

  _ClientListPayload _extractClientListPayload(Map<String, dynamic> response) {
    if (response['success'] != true) {
      return const _ClientListPayload();
    }

    final data = response['data'];
    final pagination = response['pagination'];
    var lastPage = 1;
    final items = <Map<String, dynamic>>[];

    if (data is List) {
      items.addAll(
        data.whereType<Map>().map((item) => Map<String, dynamic>.from(item)),
      );
    } else if (data is Map) {
      if (data['data'] is List) {
        items.addAll(
          (data['data'] as List).whereType<Map>().map(
            (item) => Map<String, dynamic>.from(item),
          ),
        );
      }
      lastPage = _asInt(data['last_page']) ?? lastPage;
    }

    if (pagination is Map) {
      lastPage = _asInt(pagination['last_page']) ?? lastPage;
    }

    return _ClientListPayload(
      items: items,
      lastPage: lastPage < 1 ? 1 : lastPage,
    );
  }

  AttendanceLocation? _parseClientLocation(Map<String, dynamic> client) {
    final coordinates = _extractCoordinatePair(client['location_map']);
    if (coordinates == null) {
      return null;
    }

    final latitude = coordinates.key;
    final longitude = coordinates.value;

    return AttendanceLocation(
      id: client['uuid']?.toString() ?? client['id']?.toString() ?? 'client',
      name:
          client['name']?.toString() ??
          client['company_name']?.toString() ??
          'Lokasi Vendor',
      latitude: latitude,
      longitude: longitude,
      radius: _asDouble(client['radius']) ?? 100,
      address: client['address']?.toString(),
    );
  }

  bool _clientPayloadHasEmployee(
    Map<String, dynamic> client,
    String employeeUuid,
  ) {
    if (client['employee_uuid']?.toString() == employeeUuid) {
      return true;
    }

    const employeeCollectionKeys = <String>[
      'employees',
      'employee_uuids',
      'assigned_employees',
      'client_employees',
      'assignments',
    ];

    for (final key in employeeCollectionKeys) {
      if (_employeeCollectionContains(client[key], employeeUuid)) {
        return true;
      }
    }

    return false;
  }

  bool _employeeCollectionContains(dynamic collection, String employeeUuid) {
    if (collection == null) {
      return false;
    }

    if (collection is String) {
      return collection.trim() == employeeUuid;
    }

    if (collection is Map) {
      return _employeeCollectionContains([collection], employeeUuid);
    }

    if (collection is! List) {
      return false;
    }

    for (final item in collection) {
      if (item is String && item.trim() == employeeUuid) {
        return true;
      }

      if (item is! Map) {
        continue;
      }

      final employee = Map<String, dynamic>.from(item);
      if (employee['employee_uuid']?.toString() == employeeUuid ||
          employee['uuid']?.toString() == employeeUuid) {
        return true;
      }

      if (_employeeCollectionContains(employee['employee'], employeeUuid)) {
        return true;
      }
    }

    return false;
  }

  Future<bool> _clientHasAssignedEmployee(
    String clientUuid,
    String employeeUuid,
    Map<String, String> headers,
  ) async {
    try {
      final response = await http
          .get(
            await _buildApiUri(
              '/api/clients/$clientUuid/employees',
              queryParameters: const {'per_page': '200'},
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      print('Client employee response for $clientUuid: ${response.statusCode}');

      if (response.statusCode != 200) {
        return false;
      }

      final Map<String, dynamic> data = json.decode(response.body);
      final employees = _extractClientEmployees(data);

      return employees.any(
        (employee) =>
            employee['employee_uuid']?.toString() == employeeUuid ||
            employee['uuid']?.toString() == employeeUuid,
      );
    } catch (e) {
      print('Error loading employees for client $clientUuid: $e');
      return false;
    }
  }

  List<Map<String, dynamic>> _extractClientEmployees(
    Map<String, dynamic> response,
  ) {
    if (response['success'] != true) {
      return const <Map<String, dynamic>>[];
    }

    final data = response['data'];

    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }

    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }

    return const <Map<String, dynamic>>[];
  }

  AttendanceLocation? _parseEntityLocation(Map<String, dynamic> entity) {
    final coordinates =
        _extractCoordinatePair(entity['default_location']) ??
        _extractCoordinatePair(entity['location_map']) ??
        _extractCoordinatePair(entity['location']) ??
        _extractCoordinatePair(entity['coordinates']) ??
        _extractCoordinatePairFromValues(
          entity['latitude'],
          entity['longitude'],
        ) ??
        _extractCoordinatePairFromValues(entity['lat'], entity['lng']) ??
        _extractCoordinatePairFromValues(entity['lat'], entity['lon']) ??
        _extractCoordinatePairFromValues(entity['lat'], entity['long']);

    if (coordinates == null) {
      return null;
    }

    final latitude = coordinates.key;
    final longitude = coordinates.value;

    return AttendanceLocation(
      id: entity['id']?.toString() ?? 'entity_$latitude$longitude',
      name:
          entity['name']?.toString() ??
          entity['entity_name']?.toString() ??
          entity['company_name']?.toString() ??
          'Lokasi Absensi',
      latitude: latitude,
      longitude: longitude,
      radius:
          _asDouble(entity['radius']) ??
          _asDouble(entity['location_radius']) ??
          100,
      address: entity['address']?.toString(),
    );
  }

  double? _asDouble(dynamic value) {
    return _coerceDouble(value);
  }

  int? _asInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }

  String? _firstNonEmptyString(Iterable<dynamic> values) {
    for (final value in values) {
      final normalized = value?.toString().trim();
      if (normalized != null && normalized.isNotEmpty) {
        return normalized;
      }
    }

    return null;
  }

  bool isLocationAllowed(double latitude, double longitude) {
    if (_allowedLocations.isEmpty) return true;

    for (var loc in _allowedLocations) {
      final distance = _calculateDistance(
        loc.latitude,
        loc.longitude,
        latitude,
        longitude,
      );
      print(
        'Distance to ${loc.name}: ${distance.toStringAsFixed(2)} meters (radius: ${loc.radius})',
      );
      if (distance <= loc.radius) {
        return true;
      }
    }
    return false;
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000;

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double sinDLat = sin(dLat / 2);
    double sinDLon = sin(dLon / 2);
    double cosLat1 = cos(_toRadians(lat1));
    double cosLat2 = cos(_toRadians(lat2));

    double a = sinDLat * sinDLat + cosLat1 * cosLat2 * sinDLon * sinDLon;

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  // ===== CORRECTION MANAGEMENT =====
  Future<bool> applyCorrectionForDate({
    required String employeeUuid,
    required DateTime date,
    required String clockIn,
    required String clockOut,
    String? reason,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

      final body = {
        'employee_uuid': employeeUuid,
        'date': formattedDate,
        'clock_in': clockIn,
        'clock_out': clockOut,
        if (reason != null) 'reason': reason,
      };

      print('Apply correction request: $body');

      final response = await http
          .post(
            Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.attendanceCorrectionEndpoint}',
            ),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 15));

      print('Apply correction response: ${response.statusCode}');

      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          print('Correction applied successfully');
          await refreshData();
          return true;
        } else {
          _error = data['message'] ?? 'Gagal mengajukan koreksi';
          return false;
        }
      } else {
        _error =
            data['message'] ??
            'Gagal mengajukan koreksi (${response.statusCode})';
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      print('Exception applying correction: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getCorrectionRequests() async {
    try {
      final headers = await _getHeaders();

      final response = await http
          .get(
            Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.attendanceCorrectionEndpoint}/requests',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> requests = data['data'] ?? [];
          _correctionRequests = requests.cast<Map<String, dynamic>>();
          notifyListeners();
          return _correctionRequests;
        }
      }
      return [];
    } catch (e) {
      print('Error getting correction requests: $e');
      return [];
    }
  }

  Future<bool> approveCorrection(String requestId) async {
    try {
      final headers = await _getHeaders();

      final response = await http
          .post(
            Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.attendanceCorrectionEndpoint}/$requestId/approve',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          await getCorrectionRequests();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error approving correction: $e');
      return false;
    }
  }

  Future<bool> rejectCorrection(String requestId, {String? reason}) async {
    try {
      final headers = await _getHeaders();

      final body = reason != null ? {'reason': reason} : {};

      final response = await http
          .post(
            Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.attendanceCorrectionEndpoint}/$requestId/reject',
            ),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          await getCorrectionRequests();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error rejecting correction: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getAttendanceForCorrection({
    required String employeeUuid,
    required DateTime date,
  }) async {
    try {
      final headers = await _getHeaders();
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

      final response = await http
          .get(
            Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.attendanceCorrectionEndpoint}?employee_uuid=$employeeUuid&date=$formattedDate',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting attendance for correction: $e');
      return null;
    }
  }

  Future<bool> requestCorrection({
    required String attendanceId,
    required String clockIn,
    required String clockOut,
    String? reason,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _getHeaders();

      final body = {
        'attendance_id': attendanceId,
        'clock_in': clockIn,
        'clock_out': clockOut,
        if (reason != null) 'reason': reason,
      };

      final response = await http
          .post(
            Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.attendanceCorrectionEndpoint}/request',
            ),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 10));

      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          return true;
        } else {
          _error = data['message'] ?? 'Gagal mengajukan koreksi';
          return false;
        }
      } else {
        _error =
            data['message'] ??
            'Gagal mengajukan koreksi (${response.statusCode})';
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      print('Exception requesting correction: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getCorrectionHistory(
    String employeeUuid,
  ) async {
    try {
      final headers = await _getHeaders();

      final response = await http
          .get(
            Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.attendanceCorrectionEndpoint}/history?employee_uuid=$employeeUuid',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> history = data['data'] ?? [];
          return history.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      print('Error getting correction history: $e');
      return [];
    }
  }

  Future<bool> cancelCorrectionRequest(String requestId) async {
    try {
      final headers = await _getHeaders();

      final response = await http
          .delete(
            Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.attendanceCorrectionEndpoint}/$requestId',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          await getCorrectionRequests();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error cancelling correction request: $e');
      return false;
    }
  }
}

// ===== SETTING MODEL =====
class Setting {
  final String? companyName;
  final String? timezone;
  final String? dateFormat;
  final String? currency;
  final double? latitude;
  final double? longitude;

  Setting({
    this.companyName,
    this.timezone,
    this.dateFormat,
    this.currency,
    this.latitude,
    this.longitude,
  });

  factory Setting.fromJson(Map<String, dynamic> json) {
    final coordinates =
        _extractCoordinatePairFromValues(json['latitude'], json['longitude']) ??
        _extractCoordinatePair(json['default_location']);

    return Setting(
      companyName: json['company_name']?.toString(),
      timezone: json['timezone']?.toString(),
      dateFormat: json['date_format']?.toString(),
      currency: json['currency']?.toString(),
      latitude: coordinates?.key,
      longitude: coordinates?.value,
    );
  }
}

class _ClientListPayload {
  final List<Map<String, dynamic>> items;
  final int lastPage;

  const _ClientListPayload({
    this.items = const <Map<String, dynamic>>[],
    this.lastPage = 1,
  });
}

class _EntityLocationLookupResult {
  final AttendanceLocation? location;
  final bool shouldFallbackToSettings;

  const _EntityLocationLookupResult({
    this.location,
    this.shouldFallbackToSettings = false,
  });
}

double? _coerceDouble(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}

MapEntry<double, double>? _extractCoordinatePairFromValues(
  dynamic latitudeValue,
  dynamic longitudeValue,
) {
  final latitude = _coerceDouble(latitudeValue);
  final longitude = _coerceDouble(longitudeValue);

  if (_isValidCoordinatePair(latitude, longitude)) {
    return MapEntry(latitude!, longitude!);
  }

  return null;
}

MapEntry<double, double>? _extractCoordinatePair(dynamic source) {
  if (source == null) {
    return null;
  }

  if (source is Map) {
    final value = Map<String, dynamic>.from(source);
    final direct = _extractCoordinatePairFromValues(
      value['latitude'] ?? value['lat'],
      value['longitude'] ?? value['lng'] ?? value['lon'] ?? value['long'],
    );
    if (direct != null) {
      return direct;
    }

    for (final key in const [
      'default_location',
      'location_map',
      'location',
      'coordinates',
    ]) {
      final nested = _extractCoordinatePair(value[key]);
      if (nested != null) {
        return nested;
      }
    }

    return null;
  }

  if (source is List && source.length >= 2) {
    return _extractCoordinatePairFromValues(source[0], source[1]);
  }

  if (source is! String) {
    return null;
  }

  final raw = source.trim();
  if (raw.isEmpty) {
    return null;
  }

  try {
    final decoded = json.decode(raw);
    final parsed = _extractCoordinatePair(decoded);
    if (parsed != null) {
      return parsed;
    }
  } catch (_) {
    // Keep parsing as plain text if the value is not valid JSON.
  }

  final pattern = RegExp(
    r'(-?\d{1,3}(?:\.\d+)?)\s*[,;/ ]\s*(-?\d{1,3}(?:\.\d+)?)',
  );

  for (final match in pattern.allMatches(raw)) {
    final latitude = double.tryParse(match.group(1) ?? '');
    final longitude = double.tryParse(match.group(2) ?? '');

    if (_isValidCoordinatePair(latitude, longitude)) {
      return MapEntry(latitude!, longitude!);
    }
  }

  return null;
}

bool _isValidCoordinatePair(double? latitude, double? longitude) {
  if (latitude == null || longitude == null) {
    return false;
  }

  return latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}
