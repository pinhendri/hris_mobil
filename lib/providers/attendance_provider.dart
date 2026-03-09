import 'dart:convert';
import 'dart:math';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../core/constants/api_constants.dart';
import '../data/models/attendance_model.dart';
import '../data/models/attendance_location.dart';

class AttendanceProvider with ChangeNotifier {
  List<Attendance> _attendances = [];
  Attendance? _todayAttendance;
  bool _isLoading = false;
  String? _error;
  bool _isClockingIn = false;
  bool _isClockingOut = false;

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

  // ===== HEADERS =====
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isNotEmpty) {
      print('Token from SharedPreferences: ${token.substring(0, min(20, token.length))}...');
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ===== INITIALIZE =====
  Future<void> initialize() async {
    await fetchSettings();
  }

  // ===== FETCH SETTINGS FROM API =====
  Future<void> fetchSettings() async {
    try {
      print('🔄 Fetching settings from API...');
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/settings'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

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
            print('📍 Location: ${_settings?.latitude}, ${_settings?.longitude}');
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
    _error = null;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      final dateParam = date ?? DateTime.now().toIso8601String().split('T')[0];

      final url = '${ApiConstants.baseUrl}${ApiConstants.attendanceEndpoint}?date=$dateParam&page=$page';
      print('Fetching attendances from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Parse JSON di background
        final Map<String, dynamic> data = await compute(_parseAttendanceJson, response.body);

        if (data['success'] == true) {
          final Map<String, dynamic> responseData = data['data'] ?? {};
          final List<dynamic> attendancesData = responseData['data'] ?? [];

          // Parse attendances di background jika datanya banyak
          if (attendancesData.length > 50) {
            final List<Attendance> parsedAttendances = await compute(
                _parseAttendanceList,
                attendancesData
            );

            if (page == 1) {
              _attendances = parsedAttendances;
            } else {
              _attendances.addAll(parsedAttendances);
            }
          } else {
            final newAttendances = attendancesData.map((json) => Attendance.fromJson(json)).toList();

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

          // Cari absensi hari ini
          _findTodayAttendance();
        } else {
          _error = data['message'] ?? 'Gagal memuat data absensi';
        }
      } else {
        _error = 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error: $e';
      print('Exception fetching attendances: $e');
    } finally {
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
      _todayAttendance = _attendances.firstWhere(
            (att) => att.date == today,
      );
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
    notifyListeners();

    try {
      final headers = await _getHeaders();

      final body = {
        'employee_uuid': employeeUuid,
        if (photo != null) 'photo': photo,
        if (location != null) 'location': location,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

      print('Clock in request: $body');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.clockInEndpoint}'),
        headers: headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

      print('Clock in response status: ${response.statusCode}');
      print('Clock in response body: ${response.body}');

      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (data['success'] == true) {
          print('Clock in successful');
          _refreshDataAfterAction();
          return true;
        } else {
          _error = data['message'] ?? 'Clock in gagal';
          print('Clock in failed: $_error');
          return false;
        }
      } else {
        _error = data['message'] ?? 'Clock in gagal (${response.statusCode})';
        print('Clock in error: $_error');
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      print('Exception clocking in: $e');
      return false;
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
    notifyListeners();

    try {
      final headers = await _getHeaders();

      final body = {
        'employee_uuid': employeeUuid,
        if (photo != null) 'photo': photo,
        if (location != null) 'location': location,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

      print('Clock out request: $body');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.clockOutEndpoint}'),
        headers: headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

      print('Clock out response status: ${response.statusCode}');
      print('Clock out response body: ${response.body}');

      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          print('Clock out successful');
          _refreshDataAfterAction();
          return true;
        } else {
          _error = data['message'] ?? 'Clock out gagal';
          print('Clock out failed: $_error');
          return false;
        }
      } else {
        _error = data['message'] ?? 'Clock out gagal (${response.statusCode})';
        print('Clock out error: $_error');
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      print('Exception clocking out: $e');
      return false;
    } finally {
      _isClockingOut = false;
      notifyListeners();
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

      final url = '${ApiConstants.baseUrl}${ApiConstants.dailyReportEndpoint}?date=$dateParam';
      print('Fetching daily report from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

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

      final url = '${ApiConstants.baseUrl}${ApiConstants.attendanceSummaryEndpoint}?date=$dateParam';
      print('Fetching attendance summary from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          _summary = data['data'];
          print('Summary loaded: $_summary');
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error getting attendance summary: $e');
    }
  }

  // ===== LOAD NEXT PAGE =====
  Future<void> loadNextPage({String? date}) async {
    if (_currentPage < _lastPage && !_isLoading) {
      await fetchAttendances(date: date, page: _currentPage + 1);
    }
  }

  // ===== REFRESH DATA =====
  Future<void> refreshData() async {
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
          longitude
      );
      print('Distance to ${loc.name}: ${distance.toStringAsFixed(2)} meters (radius: ${loc.radius})');
      if (distance <= loc.radius) {
        return true;
      }
    }
    return false;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000;

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double sinDLat = sin(dLat / 2);
    double sinDLon = sin(dLon / 2);
    double cosLat1 = cos(_toRadians(lat1));
    double cosLat2 = cos(_toRadians(lat2));

    double a = sinDLat * sinDLat +
        cosLat1 * cosLat2 *
            sinDLon * sinDLon;

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

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.attendanceCorrectionEndpoint}'),
        headers: headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

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
        _error = data['message'] ?? 'Gagal mengajukan koreksi (${response.statusCode})';
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

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.attendanceCorrectionEndpoint}/requests'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

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

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.attendanceCorrectionEndpoint}/$requestId/approve'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

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

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.attendanceCorrectionEndpoint}/$requestId/reject'),
        headers: headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

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

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.attendanceCorrectionEndpoint}?employee_uuid=$employeeUuid&date=$formattedDate'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

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

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.attendanceCorrectionEndpoint}/request'),
        headers: headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          return true;
        } else {
          _error = data['message'] ?? 'Gagal mengajukan koreksi';
          return false;
        }
      } else {
        _error = data['message'] ?? 'Gagal mengajukan koreksi (${response.statusCode})';
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

  Future<List<Map<String, dynamic>>> getCorrectionHistory(String employeeUuid) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.attendanceCorrectionEndpoint}/history?employee_uuid=$employeeUuid'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

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

      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.attendanceCorrectionEndpoint}/$requestId'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

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