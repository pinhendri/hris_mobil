import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../data/models/correction_model.dart';

class CorrectionProvider with ChangeNotifier {
  List<CorrectionRequest> _requests = [];
  bool _isLoading = false;
  String? _error;
  AttendanceData? _attendanceData;

  final ApiService _apiService = ApiService();

  List<CorrectionRequest> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AttendanceData? get attendanceData => _attendanceData;

  // Fetch all correction requests
  Future<void> fetchRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement when backend ready
      await Future.delayed(const Duration(milliseconds: 500));
      _requests = [];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get attendance for correction
  Future<AttendanceData> getAttendanceForCorrection({
    required String employeeUuid,
    required String date,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Getting attendance for correction: $employeeUuid, $date');
      
      final response = await _apiService.get(
        '/attendances/getAttendanceForCorrection?employee_uuid=$employeeUuid&date=$date'
      );
      
      print('📥 Attendance correction response: $response');

      if (response is Map<String, dynamic>) {
        final success = response['success'] ?? false;
        
        if (success) {
          final data = response['data'];
          _attendanceData = AttendanceData.fromJson(data);
          return _attendanceData!;
        } else {
          throw Exception(response['message'] ?? 'Failed to get attendance');
        }
      }
      throw Exception('Invalid response format');
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update attendance correction
  Future<bool> updateAttendanceCorrection({
    required String identifier,
    required Map<String, dynamic> data,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Updating attendance correction: $identifier');
      print('📤 Data: $data');
      
      final response = await _apiService.put(
        '/attendances/attendance-correction/$identifier',
        data
      );
      
      print('📥 Update response: $response');

      if (response is Map<String, dynamic>) {
        final success = response['success'] ?? false;
        
        if (success) {
          return true;
        } else {
          _error = response['message'] ?? 'Failed to update attendance';
          return false;
        }
      }
      return false;
    } catch (e) {
      print('❌ Error updating attendance: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Approve correction request
  Future<bool> approveRequest(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement when backend ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Update local list
      final index = _requests.indexWhere((r) => r.id == id);
      if (index != -1) {
        // Create new instance with updated status
        _requests[index] = CorrectionRequest(
          id: _requests[index].id,
          type: _requests[index].type,
          description: _requests[index].description,
          status: 'Approved',
          targetDate: _requests[index].targetDate,
          employeeId: _requests[index].employeeId,
          details: _requests[index].details,
        );
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reject correction request
  Future<bool> rejectRequest(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement when backend ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Update local list
      final index = _requests.indexWhere((r) => r.id == id);
      if (index != -1) {
        // Create new instance with updated status
        _requests[index] = CorrectionRequest(
          id: _requests[index].id,
          type: _requests[index].type,
          description: _requests[index].description,
          status: 'Rejected',
          targetDate: _requests[index].targetDate,
          employeeId: _requests[index].employeeId,
          details: _requests[index].details,
        );
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
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
}