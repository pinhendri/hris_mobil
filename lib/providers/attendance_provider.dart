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
    unawaited(_bootstrapOfflineSupport());
  }

  // ===== HEADERS =====
  Future<Map<String, String>> _getHeaders() async {
    final token = await SessionStorage.getToken();
    if (token.isNotEmpty) {
      print(
        'Token from SharedPreferences: ${token.substring(0, min(20, token.length))}...',
      );
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
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
    await _bootstrapOfflineSupport();
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
            Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.settingsEndpoint}',
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

            // Konversi settings ke AttendanceLocation
            _convertSettingsToLocation();

            print('✅ Settings loaded successfully');
            print(
              '📍 Location: ${_settings?.latitude}, ${_settings?.longitude}',
            );
          }
        } else {
          print('⚠️ Failed to load settings: ${data['message']}');
          _loadDefaultLocation();
        }
      } else {
        print('⚠️ Error loading settings, using default location');
        _loadDefaultLocation();
      }
    } catch (e) {
      print('❌ Error fetching settings: $e');
      _loadDefaultLocation();
    } finally {
      notifyListeners();
    }
  }

  // ===== CONVERT SETTINGS TO LOCATION =====
  // Di method _convertSettingsToLocation, perbaiki menjadi:
  void _convertSettingsToLocation() {
    if (_settings != null &&
        _settings!.latitude != null &&
        _settings!.longitude != null) {
      _allowedLocations = [
        AttendanceLocation(
          id: 'office_1',
          name: _settings?.companyName ?? 'Kantor Pusat',
          latitude: _settings!.latitude!,
          longitude: _settings!.longitude!,
          radius: 100, // Default radius 100 meter
          // Hapus parameter 'address' jika tidak ada di model
          // atau tambahkan jika model mendukung
        ),
      ];
      print('✅ Location from settings: ${_allowedLocations.first.name}');
    } else {
      _loadDefaultLocation();
    }
  }

  // ===== LOAD DEFAULT LOCATION =====
  void _loadDefaultLocation() {
    _allowedLocations = [
      AttendanceLocation(
        id: 'default_1',
        name: 'Default Location',
        latitude: -6.200000,
        longitude: 106.816666,
        radius: 100,
      ),
    ];
    print('⚠️ Using default location');
  }

  // ===== FETCH ATTENDANCES =====
  Future<void> fetchAttendances({String? date, int page = 1}) async {
    if (_isLoading) return;

    _isLoading = true;
    if (page == 1) {
      _error = null;
    }
    notifyListeners();

    final employeeUuid = await _getCurrentEmployeeUuid();
    var localDrafts = <Attendance>[];

    try {
      await syncOfflineActions(silent: true, refreshAfterSync: false);
      localDrafts = await _loadLocalAttendances(employeeUuid: employeeUuid);

      final headers = await _getHeaders();
      final dateParam = date ?? DateTime.now().toIso8601String().split('T')[0];

      final url =
          '${ApiConstants.baseUrl}${ApiConstants.attendanceEndpoint}?date=$dateParam&page=$page';
      print('Fetching attendances from: $url');

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Parse JSON di background
        final Map<String, dynamic> data = await compute(
          _parseAttendanceJson,
          response.body,
        );

        if (data['success'] == true) {
          final Map<String, dynamic> responseData = data['data'] ?? {};
          final List<dynamic> attendancesData = responseData['data'] ?? [];

          // Parse attendances di background jika datanya banyak
          if (attendancesData.length > 50) {
            final List<Attendance> parsedAttendances = await compute(
              _parseAttendanceList,
              attendancesData,
            );

            if (page == 1) {
              _attendances = parsedAttendances;
            } else {
              _attendances.addAll(parsedAttendances);
            }
          } else {
            final newAttendances = attendancesData
                .map((json) => Attendance.fromJson(json))
                .toList();

            if (page == 1) {
              _attendances = newAttendances;
            } else {
              _attendances.addAll(newAttendances);
            }
          }

          // Meta data
          final meta = responseData['meta'] ?? {};
          _currentPage = meta['current_page'] ?? page;
          _lastPage = meta['last_page'] ?? 1;
          _total = meta['total'] ?? 0;
          _perPage = meta['per_page'] ?? 50;

          print('Loaded ${_attendances.length} attendances, total: $_total');

          _mergeOfflineAttendances(localDrafts);
          _syncNotice = localDrafts.isNotEmpty
              ? 'Ada ${localDrafts.length} data absensi offline menunggu sinkronisasi.'
              : null;
          _findTodayAttendance();
        } else {
          _applyOfflineFallback(
            localDrafts,
            fallbackMessage:
                'Server sedang offline. Data absensi lokal tetap tersedia.',
          );
          _error = null;
        }
      } else {
        _applyOfflineFallback(
          localDrafts,
          fallbackMessage:
              'Server belum bisa diakses. Data absensi lokal tetap tersedia.',
        );
        _error = null;
      }
    } on TimeoutException catch (e) {
      print('Timeout fetching attendances: $e');
      _applyOfflineFallback(
        localDrafts,
        fallbackMessage:
            'Koneksi ke server timeout. Data absensi lokal tetap ditampilkan.',
      );
      _error = null;
    } on SocketException catch (e) {
      print('Socket exception fetching attendances: $e');
      _applyOfflineFallback(
        localDrafts,
        fallbackMessage:
            'Anda sedang offline. Data absensi lokal tetap ditampilkan.',
      );
      _error = null;
    } catch (e) {
      print('Exception fetching attendances: $e');
      if (_isOfflineException(e)) {
        _applyOfflineFallback(
          localDrafts,
          fallbackMessage:
              'Jaringan tidak tersedia. Data absensi lokal tetap ditampilkan.',
        );
        _error = null;
      } else {
        _error = 'Error: $e';
        if (localDrafts.isNotEmpty) {
          _mergeOfflineAttendances(localDrafts);
          _findTodayAttendance();
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

  static List<Attendance> _parseAttendanceList(List<dynamic> data) {
    return data.map((json) => Attendance.fromJson(json)).toList();
  }

  // ===== FIND TODAY'S ATTENDANCE =====
  void _findTodayAttendance() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    try {
      _todayAttendance = _attendances.firstWhere((att) => att.date == today);
    } catch (e) {
      _todayAttendance = null;
    }
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

    _isClockingIn = true;
    _error = null;
    _lastActionQueued = false;
    _lastActionMessage = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'employee_uuid': employeeUuid,
        if (photo != null) 'photo': photo,
        if (location != null) 'location': location,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

      return _submitAttendanceAction(
        action: 'clock_in',
        endpoint: ApiConstants.clockInEndpoint,
        successStatusCodes: const {200, 201},
        employeeUuid: employeeUuid,
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

    _isClockingOut = true;
    _error = null;
    _lastActionQueued = false;
    _lastActionMessage = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'employee_uuid': employeeUuid,
        if (photo != null) 'photo': photo,
        if (location != null) 'location': location,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

      return _submitAttendanceAction(
        action: 'clock_out',
        endpoint: ApiConstants.clockOutEndpoint,
        successStatusCodes: const {200, 201},
        employeeUuid: employeeUuid,
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

    try {
      final headers = await _getHeaders();

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
          employeeUuid: employeeUuid,
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
        employeeUuid: employeeUuid,
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
        employeeUuid: employeeUuid,
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
        employeeUuid: employeeUuid,
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
          employeeUuid: employeeUuid,
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

  Future<void> _queueOfflineAttendanceAction({
    required String action,
    required String endpoint,
    required String employeeUuid,
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
      'date': formattedDate,
      'created_at': actionTime.millisecondsSinceEpoch,
      'retry_count': 0,
      'last_error': failureReason,
    });

    await _upsertAttendanceDraft(
      action: action,
      employeeUuid: employeeUuid,
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
    required Map<String, dynamic> body,
    required DateTime actionTime,
  }) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(actionTime);
    final formattedTime = DateFormat('HH:mm:ss').format(actionTime);
    final existingDraft = await _databaseHelper.getAttendanceDraft(
      employeeUuid,
      formattedDate,
    );
    final currentAttendance = _findAttendanceByDate(
      employeeUuid,
      formattedDate,
    );

    final draftData = <String, dynamic>{
      'employee_uuid': employeeUuid,
      'date': formattedDate,
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
        clockIn: draftData['clock_in']?.toString(),
        clockOut: draftData['clock_out']?.toString(),
        clockInPhoto: draftData['clock_in_photo']?.toString(),
        clockOutPhoto: draftData['clock_out_photo']?.toString(),
        clockInLocation: draftData['clock_in_location']?.toString(),
        clockOutLocation: draftData['clock_out_location']?.toString(),
        isPendingSync: true,
      ),
    ]);
    _findTodayAttendance();
  }

  Attendance? _findAttendanceByDate(String employeeUuid, String date) {
    try {
      return _attendances.firstWhere(
        (attendance) =>
            attendance.date == date &&
            (attendance.employeeUuid == null ||
                attendance.employeeUuid == employeeUuid),
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
    if (_isSyncingOfflineQueue) {
      return false;
    }

    final pendingItems = await _databaseHelper.getOfflineQueueItems(
      feature: 'attendance',
      employeeUuid: employeeUuid,
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
          final headers = await _getHeaders();
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
    final pendingItems = await _databaseHelper.getOfflineQueueItems(
      feature: 'attendance',
      employeeUuid: employeeUuid,
    );
    final pendingKeys = pendingItems
        .map(
          (item) =>
              '${item['employee_uuid']?.toString() ?? ''}::${item['date']?.toString() ?? ''}',
        )
        .toSet();
    final drafts = await _databaseHelper.getAttendanceDrafts(
      employeeUuid: employeeUuid,
    );

    for (final draft in drafts) {
      final key =
          '${draft['employee_uuid']?.toString() ?? ''}::${draft['date']?.toString() ?? ''}';
      if (!pendingKeys.contains(key)) {
        final employeeUuid = draft['employee_uuid']?.toString() ?? '';
        final date = draft['date']?.toString() ?? '';
        if (employeeUuid.isNotEmpty && date.isNotEmpty) {
          await _databaseHelper.deleteAttendanceDraft(employeeUuid, date);
        }
      }
    }
  }

  Future<void> _restoreLocalAttendanceState() async {
    final employeeUuid = await _getCurrentEmployeeUuid();
    final localAttendances = await _loadLocalAttendances(
      employeeUuid: employeeUuid,
    );

    if (localAttendances.isEmpty) {
      return;
    }

    _mergeOfflineAttendances(localAttendances);
    _findTodayAttendance();
    await _refreshPendingSyncState(notify: false);
    notifyListeners();
  }

  Future<List<Attendance>> _loadLocalAttendances({String? employeeUuid}) async {
    final drafts = await _databaseHelper.getAttendanceDrafts(
      employeeUuid: employeeUuid,
    );

    return drafts
        .map((draft) {
          return Attendance.fromJson({
            'employee_uuid': draft['employee_uuid'],
            'date': draft['date'],
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
  }) {
    if (localDrafts.isNotEmpty) {
      _attendances = _sortAttendances(localDrafts);
    } else {
      _attendances = _sortAttendances(_attendances);
    }
    _findTodayAttendance();
    _syncNotice = fallbackMessage;
  }

  List<Attendance> _sortAttendances(Iterable<Attendance> items) {
    final sorted = items.toList(growable: false);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return List<Attendance>.from(sorted);
  }

  String _attendanceKey(Attendance attendance) {
    return '${attendance.employeeUuid ?? 'self'}::${attendance.date}';
  }

  Future<String?> _getCurrentEmployeeUuid() async {
    final rawUserData = await SessionStorage.getUserData();
    if (rawUserData == null || rawUserData.isEmpty) {
      return null;
    }

    try {
      final decoded = json.decode(rawUserData);
      if (decoded is Map<String, dynamic>) {
        final employeeUuid = decoded['employee_uuid']?.toString();
        final uuid = decoded['uuid']?.toString();
        return (employeeUuid != null && employeeUuid.isNotEmpty)
            ? employeeUuid
            : uuid;
      }
    } catch (e) {
      print('Error decoding user data for attendance sync: $e');
    }

    return null;
  }

  Future<void> _refreshPendingSyncState({bool notify = true}) async {
    final employeeUuid = await _getCurrentEmployeeUuid();
    _pendingSyncCount = await _databaseHelper.countOfflineQueueItems(
      feature: 'attendance',
      employeeUuid: employeeUuid,
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
      await fetchAttendances();
      await getAttendanceSummary();
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
  Future<void> loadLocations() async {
    await fetchSettings(); // Ambil dari API, bukan dari local storage
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
    return Setting(
      companyName: json['company_name']?.toString(),
      timezone: json['timezone']?.toString(),
      dateFormat: json['date_format']?.toString(),
      currency: json['currency']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
