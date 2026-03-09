import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/employee_model.dart'; // Import dari file model
import '../services/api_service.dart';

class EmployeeProvider with ChangeNotifier {
  List<Employee> _employees = [];
  bool _isLoading = false;
  String? _error;
  int _totalEmployees = 0;
  int _currentPage = 1;
  int _lastPage = 1;

  List<Employee> get employees => _employees;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalEmployees => _totalEmployees;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;

  final ApiService _apiService = ApiService();

  // Fetch employees dari API dengan filter company code
  Future<void> fetchEmployees({
    String? search,
    String? department,
    int page = 1,
    int perPage = 12,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Build URL with query parameters
      String url = '/employees?page=$page&per_page=$perPage';
      
      if (search != null && search.isNotEmpty) {
        url += '&search=$search';
      }
      
      if (department != null && department.isNotEmpty) {
        url += '&department=$department';
      }

      // Panggil API dengan endpoint yang benar
      final response = await _apiService.get(url);
      
      print('📥 Employees API Response: $response');
      
      if (response['success'] == true) {
        final data = response['data'];
        
        // Handle pagination response
        if (data is Map && data.containsKey('data')) {
          // Response dengan pagination (dari method index)
          final List<dynamic> items = data['data'] ?? [];
          _employees = items.map((json) {
            print('📦 Processing employee JSON: $json');
            return Employee.fromJson(json);
          }).toList();
          
          // Update pagination info
          final meta = data['meta'] ?? {};
          _currentPage = meta['current_page'] ?? 1;
          _lastPage = meta['last_page'] ?? 1;
          _totalEmployees = meta['total'] ?? 0;
        } else if (data is List) {
          // Response tanpa pagination
          _employees = data.map((json) {
            print('📦 Processing employee JSON: $json');
            return Employee.fromJson(json);
          }).toList();
          _totalEmployees = _employees.length;
        }
        
        print('✅ Loaded ${_employees.length} employees');
        
        // Tampilkan semua UUID untuk verifikasi
        for (var emp in _employees) {
          print('   - ${emp.name}: UUID=${emp.uuid}, ID=${emp.id}');
        }
        
        _error = null;
      } else {
        _error = response['message'] ?? 'Failed to load employees';
        _employees = [];
      }
    } catch (e) {
      print('❌ Error fetching employees: $e');
      _error = e.toString();
      _employees = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch all employees tanpa pagination (untuk dropdown dll)
  Future<void> fetchAllEmployees({
    String? search,
    String? department,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Build URL with query parameters
      String url = '/employees/list';
      final queryParams = <String>[];
      
      if (search != null && search.isNotEmpty) {
        queryParams.add('search=$search');
      }
      
      if (department != null && department.isNotEmpty) {
        queryParams.add('department=$department');
      }
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      // Panggil endpoint list untuk mendapatkan semua employees
      final response = await _apiService.get(url);
      
      print('📥 Employees List API Response: $response');
      
      if (response['success'] == true) {
        final data = response['data'];
        
        if (data is List) {
          _employees = data.map((json) {
            print('📦 Processing employee JSON: $json');
            return Employee.fromJson(json);
          }).toList();
          _totalEmployees = _employees.length;
          print('✅ Loaded ${_employees.length} employees from list');
        } else if (data is Map && data.containsKey('data')) {
          final List<dynamic> items = data['data'] ?? [];
          _employees = items.map((json) {
            print('📦 Processing employee JSON: $json');
            return Employee.fromJson(json);
          }).toList();
          _totalEmployees = _employees.length;
        }
        
        // Tampilkan semua UUID untuk verifikasi
        for (var emp in _employees) {
          print('   - ${emp.name}: UUID=${emp.uuid}');
        }
        
        _error = null;
      } else {
        _error = response['message'] ?? 'Failed to load employees';
        _employees = [];
      }
    } catch (e) {
      print('❌ Error fetching all employees: $e');
      _error = e.toString();
      _employees = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get employee by UUID (prioritaskan UUID)
  Employee? getEmployeeByUuid(String uuid) {
    try {
      return _employees.firstWhere((e) => e.uuid == uuid);
    } catch (e) {
      return null;
    }
  }

  // Get employee by ID atau UUID
  Employee? getEmployeeById(String id) {
    try {
      return _employees.firstWhere(
        (e) => e.id == id || e.uuid == id,
      );
    } catch (e) {
      return null;
    }
  }

  // Fetch single employee detail by UUID
  Future<Employee?> fetchEmployeeDetail(String uuid) async {
    try {
      final response = await _apiService.get('/employees/$uuid');
      
      print('📥 Employee Detail API Response: $response');
      
      if (response['success'] == true) {
        final data = response['data'];
        return Employee.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching employee detail: $e');
      return null;
    }
  }

  // Update employee department - Menggunakan copyWith dari model
  Future<bool> updateEmployeeDepartment(
    String employeeId,
    String newDepartment,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Cari employee yang akan diupdate
      final employee = getEmployeeById(employeeId);
      if (employee == null) {
        throw Exception('Employee not found');
      }

      print('🔄 Updating employee department: ${employee.name} to $newDepartment');

      // Buat data untuk update
      final updateData = {
        'name': employee.name,
        'email': employee.email,
        'position': employee.position,
        'department': newDepartment,
        'status': employee.status,
        'phone': employee.phone,
        'join_date': employee.joinDate,
        'salary': employee.salary?.toString(),
      };

      // Panggil API update dengan UUID
      final response = await _apiService.put('/employees/${employee.uuid}', updateData);
      
      if (response['success'] == true) {
        // Update local data menggunakan copyWith dari model
        final index = _employees.indexWhere((e) => e.uuid == employee.uuid);
        if (index != -1) {
          _employees[index] = employee.copyWith(department: newDepartment);
        }
        
        _error = null;
        print('✅ Employee department updated successfully');
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update employee department';
        return false;
      }
    } catch (e) {
      print('❌ Error updating employee department: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update complete employee data
  Future<bool> updateEmployee(Employee updatedEmployee) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Buat data untuk update
      final updateData = {
        'name': updatedEmployee.name,
        'email': updatedEmployee.email,
        'position': updatedEmployee.position,
        'department': updatedEmployee.department,
        'status': updatedEmployee.status,
        'phone': updatedEmployee.phone,
        'join_date': updatedEmployee.joinDate,
        'salary': updatedEmployee.salary?.toString(),
      };

      // Panggil API update dengan UUID
      final response = await _apiService.put('/employees/${updatedEmployee.uuid}', updateData);
      
      if (response['success'] == true) {
        // Update local data
        final index = _employees.indexWhere((e) => e.uuid == updatedEmployee.uuid);
        if (index != -1) {
          _employees[index] = updatedEmployee;
        }
        
        _error = null;
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update employee';
        return false;
      }
    } catch (e) {
      print('❌ Error updating employee: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new employee
  Future<bool> createEmployee(Map<String, dynamic> employeeData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/employees', employeeData);
      
      if (response['success'] == true) {
        // Refresh employee list
        await fetchEmployees();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to create employee';
        return false;
      }
    } catch (e) {
      print('❌ Error creating employee: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete employee
  Future<bool> deleteEmployee(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Cari employee berdasarkan UUID
      final employee = getEmployeeByUuid(id);
      if (employee == null) {
        throw Exception('Employee not found');
      }

      final response = await _apiService.delete('/employees/${employee.uuid}');
      
      if (response['success'] == true) {
        // Remove from local list
        _employees.removeWhere((e) => e.uuid == id || e.id == id);
        return true;
      } else {
        _error = response['message'] ?? 'Failed to delete employee';
        return false;
      }
    } catch (e) {
      print('❌ Error deleting employee: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get active employees count
  int getActiveEmployeesCount() {
    return _employees.where((e) {
      final status = e.status?.toLowerCase() ?? '';
      return status != 'inactive' && status != 'deactive';
    }).length;
  }

  // Get employees by department
  List<Employee> getEmployeesByDepartment(String department) {
    return _employees.where((e) => e.department == department).toList();
  }

  // Search employees locally
  List<Employee> searchEmployees(String query) {
    if (query.isEmpty) return _employees;
    final searchLower = query.toLowerCase();
    
    return _employees.where((e) {
      final nameMatch = e.name.toLowerCase().contains(searchLower);
      final emailMatch = e.email?.toLowerCase().contains(searchLower) ?? false;
      final positionMatch = e.position.toLowerCase().contains(searchLower);
      final departmentMatch = e.department?.toLowerCase().contains(searchLower) ?? false;
      
      return nameMatch || emailMatch || positionMatch || departmentMatch;
    }).toList();
  }

  // Load next page
  Future<void> loadNextPage() async {
    if (_currentPage < _lastPage && !_isLoading) {
      await fetchEmployees(page: _currentPage + 1);
    }
  }

  // Refresh employees
  Future<void> refreshEmployees() async {
    await fetchEmployees();
  }

  // Clear data
  void clear() {
    _employees = [];
    _error = null;
    _totalEmployees = 0;
    _currentPage = 1;
    _lastPage = 1;
    notifyListeners();
  }
}

// HAPUS BAGIAN INI - Class Employee didefinisikan di models/employee_model.dart
// HAPUS SEMUA KODE DARI SINI SAMPAI AKHIR FILE
// ...