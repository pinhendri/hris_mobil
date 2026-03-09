// providers/department_provider.dart

import 'package:flutter/material.dart';
import '../models/department_model.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart'; // Import AuthProvider
import 'package:provider/provider.dart';

class DepartmentProvider extends ChangeNotifier {
  List<Department> _departments = [];
  bool _isLoading = false;
  String? _error;
  String? _currentCcode; // Store current company code
  
  // For dropdown selections
  List<String> _availableRoles = ['Manager', 'Supervisor', 'Lead', 'Staff'];
  List<String> _availableTypes = ['Department', 'Division', 'Team', 'Unit'];
  List<String> _availableLocations = ['Jakarta', 'Bandung', 'Surabaya', 'Medan', 'Remote'];

  List<Department> get departments => _departments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentCcode => _currentCcode;
  List<String> get availableRoles => _availableRoles;
  List<String> get availableTypes => _availableTypes;
  List<String> get availableLocations => _availableLocations;

  // Set current company code from AuthProvider
  void setCurrentCcode(String ccode) {
    _currentCcode = ccode;
    notifyListeners();
  }

  Future<void> fetchDepartments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final apiService = ApiService();
      
      // Build URL with query parameters if needed
      // Note: The backend already filters by c_code from cache, so we don't need to pass it in URL
      // But if you want to pass it explicitly, you can uncomment the code below
      
      String endpoint = '/departments';
      
      // If you want to pass c_code explicitly in URL (optional)
      // if (_currentCcode != null && _currentCcode!.isNotEmpty) {
      //   endpoint += '?c_code=$_currentCcode';
      // }
      
      print('📡 Fetching departments with endpoint: $endpoint');
      print('📡 Current company code: $_currentCcode');
      
      final response = await apiService.get(endpoint);
      
      print('📥 Response: $response');
      
      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        _departments = data.map((json) => Department.fromJson(json)).toList();
        
        // Optional: Filter client-side if needed (backend already filters)
        // if (_currentCcode != null && _currentCcode!.isNotEmpty) {
        //   _departments = _departments.where((dept) => dept.cCode == _currentCcode).toList();
        // }
        
        print('✅ Loaded ${_departments.length} departments');
        print('✅ Filtered by c_code: ${response['filtered_by_c_code'] ?? 'none'}');
        _error = null;
      } else {
        _error = response['message'] ?? 'Failed to load departments';
        _departments = [];
      }
    } catch (e) {
      print('❌ Error fetching departments: $e');
      _error = e.toString();
      _departments = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get departments filtered by c_code (client-side filtering as backup)
  List<Department> getDepartmentsByCcode(String? cCode) {
    if (cCode == null || cCode.isEmpty) return _departments;
    
    // This assumes your department model has a cCode field
    // If not, you'll need to add it to the model
    return _departments.where((dept) => dept.cCode == cCode).toList();
  }

  // Calculate total employees across all departments
  int getTotalEmployees() {
    return _departments.fold<int>(0, (sum, d) => sum + (d.employees ?? 0));
  }

  // Calculate total budget across all departments
  double getTotalBudget() {
    return _departments.fold<double>(0.0, (sum, d) => sum + (d.budget ?? 0));
  }

  Future<bool> addDepartment(Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final apiService = ApiService();
      
      // Add company code to the data if available
      if (_currentCcode != null && _currentCcode!.isNotEmpty) {
        data['c_code'] = _currentCcode;
      }
      
      final response = await apiService.post('/departments', data);
      
      if (response['success'] == true) {
        await fetchDepartments(); // Refresh the list
        return true;
      } else {
        _error = response['message'] ?? 'Failed to create department';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateDepartment(int id, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final apiService = ApiService();
      
      // Add company code to the data if available
      if (_currentCcode != null && _currentCcode!.isNotEmpty) {
        data['c_code'] = _currentCcode;
      }
      
      final response = await apiService.put('/departments/$id', data);
      
      if (response['success'] == true) {
        await fetchDepartments(); // Refresh the list
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update department';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteDepartment(int id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final apiService = ApiService();
      final response = await apiService.delete('/departments/$id');
      
      if (response['success'] == true) {
        await fetchDepartments(); // Refresh the list
        return true;
      } else {
        _error = response['message'] ?? 'Failed to delete department';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to get department by ID
  Department? getDepartmentById(int id) {
    try {
      return _departments.firstWhere((dept) => dept.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get child departments (if you have parent-child relationship)
  List<Department> getChildrenDepartments(int parentId) {
    return _departments.where((dept) => dept.parentId == parentId).toList();
  }

  // Clear data (useful for logout)
  void clear() {
    _departments = [];
    _error = null;
    _currentCcode = null;
    notifyListeners();
  }
}