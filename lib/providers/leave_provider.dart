import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/leave_model.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart'; // Tambahkan import

class LeaveProvider with ChangeNotifier {
  List<LeaveRequest> _leaveRequests = [];
  LeaveBalance? _leaveBalance;
  bool _isLoading = false;
  String? _error;
  String? _selectedCCode;
  int? _correctEmployeeId; // <-- ADD THIS to store the correct employee ID

  final AuthProvider _authProvider;

  List<LeaveRequest> get leaveRequests => _leaveRequests;
  LeaveBalance? get leaveBalance => _leaveBalance;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get correctEmployeeId => _correctEmployeeId; // <-- ADD getter

  LeaveProvider(this._authProvider);

  void setCompanyCode(String cCode) {
    _selectedCCode = cCode;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Ambil data dari API
  Future<void> fetchLeaveData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📡 Fetching leave requests...');
      final requestsResponse = await ApiService().get('/leave-requests');
      print('📥 Response: $requestsResponse');

      if (requestsResponse['success'] == true) {
        final List data = requestsResponse['data'] ?? [];
        _leaveRequests = data.map((json) => LeaveRequest.fromJson(json)).toList();
        print('✅ Loaded ${_leaveRequests.length} leave requests');
      } else {
        _error = requestsResponse['message'] ?? 'Failed to load leave requests';
        print('❌ Error: $_error');
      }

      print('📡 Fetching leave balance...');
      final balanceResponse = await ApiService().get('/leave-balance');
      print('📥 Balance response: $balanceResponse');

      if (balanceResponse['success'] == true && balanceResponse['data'] != null) {
        _leaveBalance = LeaveBalance.fromJson(balanceResponse['data']);

        // 🔴 SIMPAN EMPLOYEE_ID YANG BENAR DARI RESPONSE BALANCE (numeric ID)
        final correctEmployeeId = balanceResponse['data']['employee_id'];
        if (correctEmployeeId != null) {
          _correctEmployeeId = correctEmployeeId is int
              ? correctEmployeeId
              : int.tryParse(correctEmployeeId.toString());

          print('✅ Correct numeric employee ID from balance: $_correctEmployeeId');
        }

        print('✅ Loaded leave balance');
      }

    } catch (e) {
      _error = 'Connection error: $e';
      print('❌ Error fetching leave data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitLeaveRequestWithUser({
    required String employeeUuid, // Terima dari luar
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required int days,
    required String reason,
    required String cCode,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
      final formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);

      final requestData = {
        'employee_uuid': employeeUuid,
        'type': type,
        'start_date': formattedStartDate,
        'end_date': formattedEndDate,
        'days': days,
        'reason': reason,
        'c_code': cCode,
      };

      print('📤 Submitting leave request: $requestData');
      print('   Employee UUID: $employeeUuid');

      final response = await ApiService().post('/leave-requests', requestData);
      print('📥 Submit response: $response');

      if (response['success'] == true) {
        await fetchLeaveData();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to submit request';
        print('❌ Submit error: $_error');
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      print('❌ Error submitting leave request: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Submit leave request ke API - UBAH DARI employeeId KE employeeUuid
  // Submit leave request ke API
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
    notifyListeners();

    try {
      // Validasi user dari authProvider
      if (_authProvider.user == null) {
        throw Exception('User not logged in');
      }

      // 🔴 GUNAKAN NUMERIC EMPLOYEE_ID YANG DIDAPAT DARI BALANCE RESPONSE
      if (_correctEmployeeId == null) {
        // Jika belum ada, coba fetch dulu balance-nya
        await fetchLeaveData();

        if (_correctEmployeeId == null) {
          throw Exception('Could not get numeric employee ID. Please try again.');
        }
      }

      final formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
      final formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);

      final requestData = {
        'employee_id': _correctEmployeeId, // <-- KIRIM NUMERIC ID, BUKAN UUID
        'type': type,
        'start_date': formattedStartDate,
        'end_date': formattedEndDate,
        'days': days,
        'reason': reason,
        'c_code': cCode,
      };

      print('📤 Submitting leave request: $requestData');
      print('   Numeric Employee ID: $_correctEmployeeId');

      final response = await ApiService().post('/leave-requests', requestData);
      print('📥 Submit response: $response');

      if (response['success'] == true) {
        await fetchLeaveData(); // Refresh data setelah sukses
        return true;
      } else {
        _error = response['message'] ?? 'Failed to submit request';
        print('❌ Submit error: $_error');
        return false;
      }

    } catch (e) {
      _error = 'Error: $e';
      print('❌ Error submitting leave request: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }



  // Approve request
  Future<bool> approveRequest(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('📤 Approving request: $id');
      final response = await ApiService().put('/leave-requests/$id', {
        'status': 'Approved',
      });

      print('📥 Approve response: $response');

      if (response['success'] == true) {
        await fetchLeaveData();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error approving request: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reject request
  Future<bool> rejectRequest(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('📤 Rejecting request: $id');
      final response = await ApiService().put('/leave-requests/$id', {
        'status': 'Rejected',
      });

      print('📥 Reject response: $response');

      if (response['success'] == true) {
        await fetchLeaveData();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error rejecting request: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hitung sisa cuti
  int getRemainingDays(String type) {
    if (_leaveBalance == null) return 0;

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
}