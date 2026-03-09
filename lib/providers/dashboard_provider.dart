import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/employee_model.dart';

class DashboardProvider with ChangeNotifier {
  // ================= STATE =================
  bool _isLoading = false;
  String? _error;

  List<Employee> _allEmployees = []; // Semua employees dari API
  List<Employee> _filteredEmployees = []; // Employees setelah filter c_code
  
  List<RecentActivity> _recentActivities = [];

  int _totalEmployees = 0;
  int _activeEmployees = 0;
  int _attendanceToday = 0;
  int _onLeave = 0;
  int _newHires = 0;
  int _openPositions = 0;

  String? _currentCompanyCode;

  // ================= GETTERS =================
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalEmployees => _totalEmployees;
  int get activeEmployees => _activeEmployees;
  int get attendanceToday => _attendanceToday;
  int get onLeave => _onLeave;
  int get newHires => _newHires;
  int get openPositions => _openPositions;

  List<RecentActivity> get recentActivities => _recentActivities;

  // ================= HELPERS =================
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  // Function untuk mengekstrak employees data (sama seperti di React)
  List<Employee> _extractEmployeesData(dynamic response) {
    print('📦 Extracting employees data from response');
    
    if (response == null) {
      print('⚠️ No response');
      return [];
    }
    
    // Cek berbagai kemungkinan struktur data
    if (response['data'] == null) {
      print('⚠️ No data in response');
      return [];
    }
    
    final data = response['data'];
    
    // Case 1: response.data adalah array langsung
    if (data is List) {
      print('✅ Employees data is direct array, count: ${data.length}');
      return data.map((e) => Employee.fromJson(e)).toList();
    }
    
    // Case 2: response.data.data adalah array
    if (data['data'] != null && data['data'] is List) {
      print('✅ Employees data from data.data array, count: ${data['data'].length}');
      return (data['data'] as List).map((e) => Employee.fromJson(e)).toList();
    }
    
    // Case 3: response.data.data.data adalah array (pagination)
    if (data['data'] != null && data['data']['data'] != null && data['data']['data'] is List) {
      print('✅ Employees data from data.data.data array, count: ${data['data']['data'].length}');
      return (data['data']['data'] as List).map((e) => Employee.fromJson(e)).toList();
    }
    
    // Case 4: response.data memiliki field employees
    if (data['employees'] != null && data['employees'] is List) {
      print('✅ Employees data from employees field, count: ${data['employees'].length}');
      return (data['employees'] as List).map((e) => Employee.fromJson(e)).toList();
    }
    
    print('❌ Could not extract employees data');
    return [];
  }

  // Function untuk filter berdasarkan company code (sama seperti di React)
  List<Employee> _filterByCompanyCode(List<Employee> employees, String? companyCode) {
    if (companyCode == null || companyCode.isEmpty) {
      print('ℹ️ No company code provided, returning all data');
      return employees;
    }
    
    if (employees.isEmpty) {
      print('ℹ️ No data to filter');
      return employees;
    }
    
    print('🔍 Filtering ${employees.length} employees for company: $companyCode');
    
    final filtered = employees.where((emp) {
      // Coba ambil dari berbagai field yang mungkin
      final itemCode = emp.cCode ?? emp.companyCode ?? '';
      return itemCode == companyCode;
    }).toList();
    
    print('✅ Filtered to ${filtered.length} employees for company: $companyCode');
    
    // Log sample untuk debugging
    if (filtered.isNotEmpty) {
      print('📋 Sample filtered employees:');
      filtered.take(3).forEach((emp) {
        print('   - ${emp.name}: c_code=${emp.cCode ?? emp.companyCode}');
      });
    } else {
      // Jika tidak ada yang cocok, tampilkan sample dari all employees
      print('⚠️ No matches found. Sample from all employees:');
      employees.take(3).forEach((emp) {
        print('   - ${emp.name}: c_code=${emp.cCode ?? emp.companyCode}');
      });
    }
    
    return filtered;
  }

  // Hitung active employees (sama seperti di React)
  int _calculateActiveEmployees(List<Employee> employees) {
    return employees.where((emp) {
      final status = (emp.status ?? '').toLowerCase();
      return !['inactive', 'deactive', 'terminated', 'resigned'].contains(status);
    }).length;
  }

  // Hitung new hires bulan ini (sama seperti di React)
  int _calculateNewHires(List<Employee> employees) {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentMonthEnd = DateTime(now.year, now.month + 1, 0);
    
    return employees.where((emp) {
      if (emp.joinDate.isEmpty) return false;
      try {
        final joinDate = DateTime.parse(emp.joinDate);
        return joinDate.isAfter(currentMonthStart.subtract(const Duration(days: 1))) && 
               joinDate.isBefore(currentMonthEnd.add(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).length;
  }

  // Get recent activities (sama seperti di React)
  List<RecentActivity> _getRecentActivities(List<Employee> employees) {
    final recent = employees
        .where((emp) => emp.joinDate.isNotEmpty)
        .toList()
          ..sort((a, b) {
            try {
              final aDate = DateTime.parse(a.joinDate);
              final bDate = DateTime.parse(b.joinDate);
              return bDate.compareTo(aDate);
            } catch (e) {
              return 0;
            }
          });
    
    return recent.take(5).map((emp) => RecentActivity(
      id: int.tryParse(emp.id) ?? 0,
      name: emp.name,
      createdAt: emp.joinDate,
      positionName: emp.position,
    )).toList();
  }

  // ================= FETCH =================
  Future<void> fetchDashboardData({String? companyCode}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 =========== START FETCH DASHBOARD ===========');
      print('🏢 Company Code: $companyCode');
      
      _currentCompanyCode = companyCode;
      
      final token = await _getToken();
      
      if (token.isEmpty) {
        print('❌ Token is empty!');
        _error = 'Not authenticated';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // ===== FETCH EMPLOYEES =====
      print('📡 Fetching employees from: ${ApiConstants.baseUrl}/api/employees');
      final empRes = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/employees'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Employees response status: ${empRes.statusCode}');
      
      if (empRes.statusCode == 200) {
        final body = json.decode(empRes.body);
        
        // Extract employees data (sama seperti di React)
        _allEmployees = _extractEmployeesData(body);
        print('👥 Total employees from API: ${_allEmployees.length}');
        
        // Filter berdasarkan company code (sama seperti di React)
        _filteredEmployees = _filterByCompanyCode(_allEmployees, _currentCompanyCode);
        
        // Hitung metrics dari hasil filter
        _totalEmployees = _filteredEmployees.length;
        _activeEmployees = _calculateActiveEmployees(_filteredEmployees);
        _newHires = _calculateNewHires(_filteredEmployees);
        _recentActivities = _getRecentActivities(_filteredEmployees);
        
        print('✅ Filtered employees: ${_filteredEmployees.length}');
        print('✅ Active employees: $_activeEmployees');
        print('✅ New hires: $_newHires');
        print('✅ Recent activities: ${_recentActivities.length}');
        
        // Tampilkan unique company codes untuk debugging
        final uniqueCodes = _allEmployees
            .map((e) => e.cCode ?? e.companyCode ?? 'null')
            .toSet()
            .toList();
        print('📋 Available company codes in data: $uniqueCodes');
        
      } else {
        print('❌ Failed to fetch employees: ${empRes.statusCode}');
        print('📦 Response: ${empRes.body}');
      }

      // ===== FETCH RECRUITMENT untuk open positions =====
      try {
        print('📡 Fetching recruitment data...');
        final recRes = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/api/recruitment'),
          headers: {'Authorization': 'Bearer $token'},
        );
        
        if (recRes.statusCode == 200) {
          final body = json.decode(recRes.body);
          
          if (body['openPositions'] != null && body['openPositions'] is List) {
            // Filter open positions berdasarkan company code
            final allPositions = body['openPositions'] as List;
            _openPositions = allPositions.where((pos) {
              return pos['c_code'] == _currentCompanyCode || 
                     pos['company_code'] == _currentCompanyCode;
            }).length;
          } else if (body['data'] != null && body['data'] is List) {
            final allPositions = body['data'] as List;
            _openPositions = allPositions.where((pos) {
              return pos['c_code'] == _currentCompanyCode || 
                     pos['company_code'] == _currentCompanyCode;
            }).length;
          }
          print('✅ Open positions: $_openPositions');
        }
      } catch (e) {
        print('⚠️ Recruitment error: $e');
        _openPositions = 0;
      }

      // ===== ATTENDANCE =====
      try {
        print('📡 Fetching attendance...');
        final attRes = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/api/attendances?today=true'),
          headers: {'Authorization': 'Bearer $token'},
        );
        
        if (attRes.statusCode == 200) {
          final body = json.decode(attRes.body);
          if (body['success'] == true && body['data'] != null) {
            if (body['data'] is List) {
              // Filter attendance berdasarkan employee yang ada di filteredEmployees
              final allAttendance = body['data'] as List;
              final filteredEmployeeIds = _filteredEmployees.map((e) => e.id).toSet();
              
              _attendanceToday = allAttendance.where((att) {
                return filteredEmployeeIds.contains(att['employee_id']?.toString());
              }).length;
            }
          }
        }
      } catch (e) {
        print('⚠️ Attendance error: $e');
        _attendanceToday = 0;
      }

      // ===== LEAVE =====
      try {
        print('📡 Fetching leave...');
        final leaveRes = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/api/leave-requests?status=approved&today=true'),
          headers: {'Authorization': 'Bearer $token'},
        );
        
        if (leaveRes.statusCode == 200) {
          final body = json.decode(leaveRes.body);
          if (body['success'] == true && body['data'] != null) {
            if (body['data'] is List) {
              // Filter leave berdasarkan employee yang ada di filteredEmployees
              final allLeave = body['data'] as List;
              final filteredEmployeeUuids = _filteredEmployees.map((e) => e.uuid).toSet();
              
              _onLeave = allLeave.where((leave) {
                return filteredEmployeeUuids.contains(leave['employee_uuid']);
              }).length;
            }
          }
        }
      } catch (e) {
        print('⚠️ Leave error: $e');
        _onLeave = 0;
      }
      
      print('\n✅ =========== DASHBOARD FETCH COMPLETED ===========');
      print('📊 FINAL METRICS:');
      print('   - Total Employees: $_totalEmployees');
      print('   - Active Employees: $_activeEmployees');
      print('   - Attendance Today: $_attendanceToday');
      print('   - On Leave: $_onLeave');
      print('   - New Hires: $_newHires');
      print('   - Open Positions: $_openPositions');
      print('================================================\n');
      
    } catch (e) {
      print('❌ Fatal Error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// ================= MODEL =================
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