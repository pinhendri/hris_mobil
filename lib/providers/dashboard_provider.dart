import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import '../services/offline_support.dart';
import '../services/session_storage.dart';

Map<String, dynamic> _summarizeEmployeesForDashboard(
  Map<String, dynamic> payload,
) {
  final response = payload['response'];
  final companyCode = (payload['companyCode'] as String?)?.trim() ?? '';
  final now =
      DateTime.tryParse(payload['now'] as String? ?? '') ?? DateTime.now();
  final currentMonthStart = DateTime(now.year, now.month, 1);
  final currentMonthEnd = DateTime(now.year, now.month + 1, 0);

  List<Map<String, dynamic>> employeeMaps = const [];

  if (response is Map<String, dynamic>) {
    final data = response['data'];

    if (data is List) {
      employeeMaps = data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    } else if (data is Map<String, dynamic>) {
      final nestedList = data['data'];
      final employeesList = data['employees'];
      final deepNestedList = nestedList is Map<String, dynamic>
          ? nestedList['data']
          : null;
      final sourceList = nestedList is List
          ? nestedList
          : employeesList is List
          ? employeesList
          : deepNestedList is List
          ? deepNestedList
          : const [];

      employeeMaps = sourceList
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }
  }

  final filteredEmployees = employeeMaps
      .where((employee) {
        if (companyCode.isEmpty) {
          return true;
        }

        final itemCode = (employee['c_code'] ?? employee['company_code'] ?? '')
            .toString();
        return itemCode == companyCode;
      })
      .toList(growable: false);

  var activeEmployees = 0;
  var newHires = 0;
  final employeeIds = <String>[];
  final employeeUuids = <String>[];
  final recentCandidates = <Map<String, dynamic>>[];

  for (final employee in filteredEmployees) {
    final status = (employee['status'] ?? '').toString().toLowerCase();
    if (!const [
      'inactive',
      'deactive',
      'terminated',
      'resigned',
    ].contains(status)) {
      activeEmployees++;
    }

    final id = employee['id']?.toString() ?? '';
    if (id.isNotEmpty) {
      employeeIds.add(id);
    }

    final uuid = (employee['uuid'] ?? employee['employee_uuid'] ?? '')
        .toString();
    if (uuid.isNotEmpty) {
      employeeUuids.add(uuid);
    }

    final joinDate = (employee['join_date'] ?? '').toString();
    if (joinDate.isEmpty) {
      continue;
    }

    try {
      final parsedJoinDate = DateTime.parse(joinDate);
      if (parsedJoinDate.isAfter(
            currentMonthStart.subtract(const Duration(days: 1)),
          ) &&
          parsedJoinDate.isBefore(
            currentMonthEnd.add(const Duration(days: 1)),
          )) {
        newHires++;
      }

      recentCandidates.add(employee);
    } catch (_) {
      // Ignore invalid dates from the API payload.
    }
  }

  recentCandidates.sort((a, b) {
    try {
      final aDate = DateTime.parse((a['join_date'] ?? '').toString());
      final bDate = DateTime.parse((b['join_date'] ?? '').toString());
      return bDate.compareTo(aDate);
    } catch (_) {
      return 0;
    }
  });

  final recentActivities = recentCandidates
      .take(5)
      .map((employee) {
        final id = int.tryParse((employee['id'] ?? '').toString()) ?? 0;
        return <String, dynamic>{
          'id': id,
          'name': (employee['name'] ?? '').toString(),
          'createdAt': (employee['join_date'] ?? '').toString(),
          'positionName':
              (employee['position'] ?? employee['position_name'] ?? '')
                  .toString(),
        };
      })
      .toList(growable: false);

  return <String, dynamic>{
    'totalEmployees': filteredEmployees.length,
    'activeEmployees': activeEmployees,
    'newHires': newHires,
    'employeeIds': employeeIds,
    'employeeUuids': employeeUuids,
    'recentActivities': recentActivities,
  };
}

class DashboardProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  List<RecentActivity> _recentActivities = [];

  int _totalEmployees = 0;
  int _activeEmployees = 0;
  int _attendanceToday = 0;
  int _onLeave = 0;
  int _newHires = 0;
  int _openPositions = 0;

  String? _currentCompanyCode;
  bool _isUsingCachedData = false;

  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalEmployees => _totalEmployees;
  int get activeEmployees => _activeEmployees;
  int get attendanceToday => _attendanceToday;
  int get onLeave => _onLeave;
  int get newHires => _newHires;
  int get openPositions => _openPositions;
  bool get isUsingCachedData => _isUsingCachedData;

  List<RecentActivity> get recentActivities => _recentActivities;

  Future<String> _getToken() async {
    return SessionStorage.getToken();
  }

  Future<dynamic> _getJsonResponse({
    required String label,
    required Uri uri,
    required Map<String, String> headers,
    int attempts = 2,
  }) async {
    Object? lastError;

    for (int attempt = 1; attempt <= attempts; attempt++) {
      final response = await http.get(uri, headers: headers);
      print('GET $label attempt $attempt -> ${response.statusCode}');

      if (response.statusCode != 200) {
        lastError = Exception('HTTP ${response.statusCode}: ${response.body}');
        if (attempt < attempts) {
          await Future.delayed(const Duration(milliseconds: 250));
          continue;
        }
        throw lastError;
      }

      final rawBody = utf8.decode(response.bodyBytes);

      try {
        return json.decode(rawBody);
      } on FormatException catch (e) {
        lastError = e;
        print('Invalid JSON from $label on attempt $attempt: $e');
        if (attempt < attempts) {
          await Future.delayed(const Duration(milliseconds: 250));
          continue;
        }
        rethrow;
      }
    }

    throw lastError ?? Exception('Failed to fetch $label');
  }

  Future<void> fetchDashboardData({String? companyCode}) async {
    if (_isLoading) {
      print('Dashboard fetch already running, skip duplicate call.');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentCompanyCode = companyCode;
      _isUsingCachedData = false;
      print('Dashboard init for company: $companyCode');

      final token = await _getToken();
      if (token.isEmpty) {
        _error = 'Not authenticated';
        return;
      }

      final authHeaders = <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final employeeBody = await _getJsonResponse(
        label: 'employees',
        uri: Uri.parse('${ApiConstants.baseUrl}/api/employees'),
        headers: authHeaders,
      );

      final employeeSummary = await compute(_summarizeEmployeesForDashboard, {
        'response': employeeBody,
        'companyCode': _currentCompanyCode,
        'now': DateTime.now().toIso8601String(),
      });

      final filteredEmployeeIds = List<String>.from(
        employeeSummary['employeeIds'] as List? ?? const [],
      );
      final filteredEmployeeUuids = List<String>.from(
        employeeSummary['employeeUuids'] as List? ?? const [],
      );
      final recentActivityMaps = List<Map<String, dynamic>>.from(
        employeeSummary['recentActivities'] as List? ?? const [],
      );
      _totalEmployees = employeeSummary['totalEmployees'] as int? ?? 0;
      _activeEmployees = employeeSummary['activeEmployees'] as int? ?? 0;
      _newHires = employeeSummary['newHires'] as int? ?? 0;
      _recentActivities = recentActivityMaps
          .map(
            (activity) => RecentActivity(
              id: activity['id'] as int? ?? 0,
              name: activity['name']?.toString() ?? '',
              createdAt: activity['createdAt']?.toString() ?? '',
              positionName: activity['positionName']?.toString() ?? '',
            ),
          )
          .toList(growable: false);

      final recruitmentFuture = _getJsonResponse(
        label: 'recruitment',
        uri: Uri.parse('${ApiConstants.baseUrl}/api/recruitment'),
        headers: authHeaders,
      );
      final attendanceFuture = _getJsonResponse(
        label: 'attendance',
        uri: Uri.parse('${ApiConstants.baseUrl}/api/attendances?today=true'),
        headers: authHeaders,
      );
      final leaveFuture = _getJsonResponse(
        label: 'leave',
        uri: Uri.parse(
          '${ApiConstants.baseUrl}/api/leave-requests?status=approved&today=true',
        ),
        headers: authHeaders,
      );

      try {
        final recruitmentBody = await recruitmentFuture;

        if (recruitmentBody is Map<String, dynamic>) {
          final openPositions = recruitmentBody['openPositions'];
          final dataPositions = recruitmentBody['data'];
          final positions = openPositions is List
              ? openPositions
              : dataPositions is List
              ? dataPositions
              : const [];

          _openPositions = positions.where((position) {
            if (position is! Map<String, dynamic>) {
              return false;
            }

            return position['c_code'] == _currentCompanyCode ||
                position['company_code'] == _currentCompanyCode;
          }).length;
        } else {
          _openPositions = 0;
        }
      } catch (e) {
        print('Recruitment fetch failed: $e');
        _openPositions = 0;
      }

      try {
        final attendanceBody = await attendanceFuture;

        if (attendanceBody is Map<String, dynamic> &&
            attendanceBody['success'] == true &&
            attendanceBody['data'] is List) {
          final allAttendance = attendanceBody['data'] as List;
          final employeeIdSet = filteredEmployeeIds.toSet();

          _attendanceToday = allAttendance.where((attendance) {
            if (attendance is! Map<String, dynamic>) {
              return false;
            }

            return employeeIdSet.contains(
              attendance['employee_id']?.toString(),
            );
          }).length;
        } else {
          _attendanceToday = 0;
        }
      } catch (e) {
        print('Attendance fetch failed: $e');
        _attendanceToday = 0;
      }

      try {
        final leaveBody = await leaveFuture;

        if (leaveBody is Map<String, dynamic> &&
            leaveBody['success'] == true &&
            leaveBody['data'] is List) {
          final allLeave = leaveBody['data'] as List;
          final employeeUuidSet = filteredEmployeeUuids.toSet();

          _onLeave = allLeave.where((leave) {
            if (leave is! Map<String, dynamic>) {
              return false;
            }

            return employeeUuidSet.contains(leave['employee_uuid']);
          }).length;
        } else {
          _onLeave = 0;
        }
      } catch (e) {
        print('Leave fetch failed: $e');
        _onLeave = 0;
      }

      print(
        'Dashboard ready: total=$_totalEmployees active=$_activeEmployees attendance=$_attendanceToday leave=$_onLeave new=$_newHires open=$_openPositions',
      );
      await OfflineSupport.saveJsonCache(_cacheKey, _toCachePayload());
    } catch (e) {
      print('Dashboard fatal error: $e');
      final loadedFromCache = await _loadFromCache();
      if (!loadedFromCache) {
        _error = e.toString();
      } else {
        _isUsingCachedData = true;
        _error = null;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String get _cacheKey => 'dashboard::${_currentCompanyCode ?? 'default'}';

  Map<String, dynamic> _toCachePayload() {
    return {
      'currentCompanyCode': _currentCompanyCode,
      'totalEmployees': _totalEmployees,
      'activeEmployees': _activeEmployees,
      'attendanceToday': _attendanceToday,
      'onLeave': _onLeave,
      'newHires': _newHires,
      'openPositions': _openPositions,
      'recentActivities': _recentActivities
          .map(
            (activity) => {
              'id': activity.id,
              'name': activity.name,
              'createdAt': activity.createdAt,
              'positionName': activity.positionName,
            },
          )
          .toList(growable: false),
    };
  }

  Future<bool> _loadFromCache() async {
    final cached = await OfflineSupport.getJsonCache(_cacheKey);
    if (cached is! Map<String, dynamic>) {
      return false;
    }

    _currentCompanyCode = cached['currentCompanyCode']?.toString();
    _totalEmployees = cached['totalEmployees'] as int? ?? 0;
    _activeEmployees = cached['activeEmployees'] as int? ?? 0;
    _attendanceToday = cached['attendanceToday'] as int? ?? 0;
    _onLeave = cached['onLeave'] as int? ?? 0;
    _newHires = cached['newHires'] as int? ?? 0;
    _openPositions = cached['openPositions'] as int? ?? 0;

    final activities = cached['recentActivities'];
    if (activities is List) {
      _recentActivities = activities
          .whereType<Map>()
          .map(
            (activity) => RecentActivity(
              id: activity['id'] as int? ?? 0,
              name: activity['name']?.toString() ?? '',
              createdAt: activity['createdAt']?.toString() ?? '',
              positionName: activity['positionName']?.toString() ?? '',
            ),
          )
          .toList(growable: false);
    } else {
      _recentActivities = [];
    }

    return true;
  }
}

class RecentActivity {
  final int id;
  final String name;
  final String createdAt;
  final String positionName;

  const RecentActivity({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.positionName,
  });
}
