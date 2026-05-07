import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/employee_model.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/offline_support.dart';
import '../services/session_storage.dart';

class EmployeeProvider with ChangeNotifier {
  List<Employee> _employees = [];
  Employee? _selectedEmployee;
  bool _isLoading = false;
  String? _error;
  int _totalEmployees = 0;
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isUsingCachedData = false;

  List<Employee> get employees => _employees;
  Employee? get selectedEmployee => _selectedEmployee;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalEmployees => _totalEmployees;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  bool get isUsingCachedData => _isUsingCachedData;

  final ApiService _apiService;

  EmployeeProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  // Frontend parity:
  // - hanya role HR/admin tertentu yang boleh melihat semua employee
  // - role lainnya melihat data dirinya sendiri
  Future<void> fetchEmployees({
    String? search,
    String? department,
    int page = 1,
    int perPage = 12,
  }) async {
    _isLoading = true;
    _error = null;
    _isUsingCachedData = false;
    notifyListeners();

    try {
      final currentUser = await _getCurrentUser();

      if (_shouldFetchSelfOnly(currentUser)) {
        final employee = await _fetchCurrentUserEmployee(currentUser);
        _employees = employee != null ? [employee] : [];
        _currentPage = 1;
        _lastPage = 1;
        _totalEmployees = _employees.length;
        _error = null;
        await _saveEmployeeCache(_selfCacheKey, _employees);
      } else {
        final result = await _fetchEmployeesFromIndex(
          search: search,
          department: department,
          page: page,
          perPage: perPage,
        );

        _employees = result.employees;
        _currentPage = result.currentPage;
        _lastPage = result.lastPage;
        _totalEmployees = result.totalEmployees;
        _error = null;
        await _saveEmployeeCache(
          _listCacheKey(
            search: search,
            department: department,
            page: page,
            perPage: perPage,
          ),
          _employees,
          currentPage: _currentPage,
          lastPage: _lastPage,
          totalEmployees: _totalEmployees,
        );
      }
    } catch (e) {
      debugPrint('Error fetching employees: $e');
      final currentUser = await _getStoredUser();
      final loadedFromCache = _shouldFetchSelfOnly(currentUser)
          ? await _loadEmployeeCache(_selfCacheKey)
          : await _loadEmployeeCache(
              _listCacheKey(
                search: search,
                department: department,
                page: page,
                perPage: perPage,
              ),
            );

      if (!loadedFromCache && _shouldFetchSelfOnly(currentUser)) {
        final employee = await _buildSelfEmployeeFromStorage();
        if (employee != null) {
          _employees = [employee];
          _currentPage = 1;
          _lastPage = 1;
          _totalEmployees = 1;
          _isUsingCachedData = true;
          _error = null;
        } else {
          _error = e.toString();
          _employees = [];
        }
      } else if (!loadedFromCache) {
        _error = e.toString();
        _employees = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCurrentUserEmployeeProfile() async {
    _isLoading = true;
    _error = null;
    _isUsingCachedData = false;
    notifyListeners();

    try {
      final currentUser = await _getCurrentUser();
      final employee = await _fetchCurrentUserEmployee(currentUser);

      _employees = employee != null ? [employee] : [];
      _selectedEmployee = employee;
      _currentPage = 1;
      _lastPage = 1;
      _totalEmployees = _employees.length;
      _error = null;
      await _saveEmployeeCache(_selfCacheKey, _employees);
    } catch (e) {
      debugPrint('Error fetching current employee profile: $e');
      final loadedFromCache = await _loadEmployeeCache(_selfCacheKey);

      if (!loadedFromCache) {
        final employee = await _buildSelfEmployeeFromStorage();
        if (employee != null) {
          _employees = [employee];
          _selectedEmployee = employee;
          _currentPage = 1;
          _lastPage = 1;
          _totalEmployees = 1;
          _isUsingCachedData = true;
          _error = null;
        } else {
          _error = e.toString();
          _employees = [];
          _selectedEmployee = null;
        }
      } else {
        _selectedEmployee = _employees.isNotEmpty ? _employees.first : null;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch all employees tanpa pagination (untuk dropdown admin dll)
  Future<void> fetchAllEmployees({
    String? search,
    String? department,
    String? companyCode,
  }) async {
    _isLoading = true;
    _error = null;
    _isUsingCachedData = false;
    notifyListeners();

    try {
      var url = '/employees/list';
      final queryParams = <String>[];
      final normalizedCompanyCode = companyCode?.trim() ?? '';

      if (search != null && search.isNotEmpty) {
        queryParams.add('search=${Uri.encodeQueryComponent(search)}');
      }

      if (department != null && department.isNotEmpty) {
        queryParams.add('department=${Uri.encodeQueryComponent(department)}');
      }

      if (normalizedCompanyCode.isNotEmpty) {
        queryParams.add(
          'c_code=${Uri.encodeQueryComponent(normalizedCompanyCode)}',
        );
      }

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await _apiService.get(url);
      debugPrint('Employees list API response: $response');

      if (response is Map && response['success'] == true) {
        final data = response['data'];

        if (data is List) {
          _employees = _mapEmployees(List<dynamic>.from(data));
          _totalEmployees = _employees.length;
        } else if (data is Map && data.containsKey('data')) {
          final items = List<dynamic>.from(data['data'] ?? const []);
          _employees = _mapEmployees(items);
          _totalEmployees = _employees.length;
        }

        _error = null;
        await _saveEmployeeCache(
          _allCacheKey(
            search: search,
            department: department,
            companyCode: normalizedCompanyCode,
          ),
          _employees,
          currentPage: 1,
          lastPage: 1,
          totalEmployees: _totalEmployees,
        );
      } else {
        _error = response is Map
            ? response['message']?.toString() ?? 'Failed to load employees'
            : 'Failed to load employees';
        _employees = [];
      }
    } catch (e) {
      debugPrint('Error fetching all employees: $e');
      final loadedFromCache = await _loadEmployeeCache(
        _allCacheKey(
          search: search,
          department: department,
          companyCode: companyCode,
        ),
      );
      if (!loadedFromCache) {
        _error = e.toString();
        _employees = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<User?> _getCurrentUser() async {
    try {
      final meResponse = await _apiService.get('/me');
      final meUser = _extractMeUserPayload(meResponse);

      if (meUser != null) {
        return User.fromMap(meUser);
      }
    } catch (e) {
      debugPrint('Error fetching current user from /me: $e');
    }

    return _getStoredUser();
  }

  Future<User?> _getStoredUser() async {
    final rawUserData = await SessionStorage.getUserData();
    if (rawUserData == null || rawUserData.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawUserData);
      if (decoded is Map<String, dynamic>) {
        return User.fromMap(decoded);
      }
    } catch (e) {
      debugPrint('Error decoding stored user data: $e');
    }

    return null;
  }

  bool _shouldFetchSelfOnly(User? user) {
    return !_canViewAllEmployees(user);
  }

  static String currentUserEmployeeUuid(User? user) {
    return user?.employeeUuid?.trim() ?? '';
  }

  bool _canViewAllEmployees(User? user) {
    final normalizedRoles = _normalizedRoleNames(user);

    for (final role in normalizedRoles) {
      if (role == 'super-admin' ||
          role == 'administrator' ||
          role == 'admin' ||
          role.contains('hrd') ||
          role.contains('hr')) {
        return true;
      }
    }

    return false;
  }

  Set<String> _normalizedRoleNames(User? user) {
    final roleNames = <String>{
      if (user?.role.trim().isNotEmpty ?? false)
        user!.role.trim().toLowerCase(),
      ...(user?.roles ?? const <String>[])
          .map((role) => role.trim().toLowerCase())
          .where((role) => role.isNotEmpty),
    };

    return roleNames;
  }

  Future<Employee?> _fetchCurrentUserEmployee(User? currentUser) async {
    final employeeUuid = currentUserEmployeeUuid(currentUser);

    if (employeeUuid.isNotEmpty) {
      final employee = await _fetchEmployeeDetailByUuid(employeeUuid);
      if (employee != null) {
        return employee;
      }
    }

    try {
      final meEmployeeResponse = await _apiService.get('/me/employee');
      debugPrint(
        '/me/employee response for employee profile: $meEmployeeResponse',
      );

      final meEmployeeData = _extractSingleEmployeePayload(meEmployeeResponse);
      if (meEmployeeData != null) {
        final meEmployee = Employee.fromJson(meEmployeeData);
        final meEmployeeUuid = meEmployee.uuid.isNotEmpty
            ? meEmployee.uuid
            : meEmployeeData['employee_uuid']?.toString().trim() ?? '';

        if (meEmployeeUuid.isNotEmpty) {
          final detailedEmployee = await _fetchEmployeeDetailByUuid(
            meEmployeeUuid,
          );
          if (detailedEmployee != null) {
            return detailedEmployee;
          }
        }

        await OfflineSupport.saveJsonCache(
          _detailCacheKey(
            meEmployee.uuid.isNotEmpty ? meEmployee.uuid : meEmployee.id,
          ),
          meEmployee.toJson(),
        );
        return meEmployee;
      }
    } catch (e) {
      debugPrint('Error fetching current employee from /me/employee: $e');
    }

    final meResponse = await _apiService.get('/me');
    debugPrint('/me response for employee fallback: $meResponse');

    final userData = _extractMeUserPayload(meResponse);
    if (userData == null) {
      return null;
    }

    final fallbackEmployee = <String, dynamic>{
      'id': userData['id'] ?? 0,
      'uuid':
          userData['employee_uuid']?.toString() ??
          userData['uuid']?.toString() ??
          employeeUuid,
      'name': userData['name'] ?? '',
      'email': userData['email'],
      'department_description':
          userData['department_description'] ??
          userData['department'] ??
          'Not Assigned',
      'status': userData['status'] ?? 'Active',
      'position': userData['position'] ?? 'Employee',
      'join_date':
          userData['join_date'] ??
          DateTime.now().toIso8601String().split('T').first,
      'avatar': userData['avatar'],
      'cv': userData['cv'],
    };

    final employee = Employee.fromJson(fallbackEmployee);
    await OfflineSupport.saveJsonCache(
      _detailCacheKey(employee.uuid.isNotEmpty ? employee.uuid : employee.id),
      employee.toJson(),
    );
    return employee;
  }

  Future<Employee?> _fetchEmployeeDetailByUuid(String employeeUuid) async {
    final response = await _apiService.get('/employees/$employeeUuid');
    debugPrint('Single employee response: $response');

    final employeeData = _extractSingleEmployeePayload(response);
    if (employeeData == null) {
      return null;
    }

    final employee = Employee.fromJson(employeeData);
    await OfflineSupport.saveJsonCache(
      _detailCacheKey(employee.uuid.isNotEmpty ? employee.uuid : employee.id),
      employee.toJson(),
    );
    return employee;
  }

  Future<_EmployeeFetchResult> _fetchEmployeesFromIndex({
    String? search,
    String? department,
    required int page,
    required int perPage,
  }) async {
    var url = '/employees?page=$page&per_page=$perPage';

    if (search != null && search.isNotEmpty) {
      url += '&search=$search';
    }

    if (department != null && department.isNotEmpty) {
      url += '&department=$department';
    }

    final response = await _apiService.get(url);
    debugPrint('Employees API response: $response');

    final result = _extractEmployeeListPayload(response);
    for (final emp in result.employees) {
      debugPrint('Loaded employee ${emp.name}: UUID=${emp.uuid}, ID=${emp.id}');
    }

    return result;
  }

  Map<String, dynamic>? _extractSingleEmployeePayload(dynamic response) {
    final payload = _extractDataPayload(response);

    if (payload is List && payload.isNotEmpty) {
      final firstItem = payload.first;
      if (firstItem is Map) {
        return Map<String, dynamic>.from(firstItem);
      }
    }

    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }

    return null;
  }

  Map<String, dynamic>? _extractMeUserPayload(dynamic response) {
    final payload = _extractDataPayload(response);

    if (payload is Map && payload['user'] is Map) {
      return Map<String, dynamic>.from(payload['user'] as Map);
    }

    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }

    return null;
  }

  _EmployeeFetchResult _extractEmployeeListPayload(dynamic response) {
    final employeesData = <Employee>[];
    var currentPage = 1;
    var lastPage = 1;
    var totalEmployees = 0;

    if (response is Map) {
      if (response['data'] is Map && response['data']['data'] is List) {
        final data = response['data'] as Map;
        final items = List<dynamic>.from(data['data'] ?? const []);
        employeesData.addAll(_mapEmployees(items));

        final meta = data['meta'] as Map? ?? const {};
        currentPage = _asInt(meta['current_page'], 1);
        lastPage = _asInt(meta['last_page'], 1);
        totalEmployees = _asInt(meta['total'], employeesData.length);
      } else if (response['data'] is List) {
        final items = List<dynamic>.from(response['data'] as List);
        employeesData.addAll(_mapEmployees(items));
        currentPage = _asInt(response['current_page'], 1);
        lastPage = _asInt(response['last_page'], 1);
        totalEmployees = _asInt(response['total'], employeesData.length);
      } else if (response['success'] == true && response['data'] is List) {
        final items = List<dynamic>.from(response['data'] as List);
        employeesData.addAll(_mapEmployees(items));
        totalEmployees = employeesData.length;
      }
    } else if (response is List) {
      employeesData.addAll(_mapEmployees(List<dynamic>.from(response)));
      totalEmployees = employeesData.length;
    }

    return _EmployeeFetchResult(
      employees: employeesData,
      currentPage: currentPage,
      lastPage: lastPage,
      totalEmployees: totalEmployees == 0
          ? employeesData.length
          : totalEmployees,
    );
  }

  dynamic _extractDataPayload(dynamic response) {
    if (response is Map) {
      final data = response['data'];
      if (data is Map && data['data'] != null) {
        return data['data'];
      }

      if (data != null) {
        return data;
      }
    }

    return response;
  }

  List<Employee> _mapEmployees(List<dynamic> items) {
    return items.whereType<Map>().map((json) {
      debugPrint('Processing employee JSON: $json');
      return Employee.fromJson(Map<String, dynamic>.from(json));
    }).toList();
  }

  int _asInt(dynamic value, int fallback) {
    if (value is int) {
      return value;
    }

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
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
      return _employees.firstWhere((e) => e.id == id || e.uuid == id);
    } catch (e) {
      return null;
    }
  }

  // Fetch single employee detail by UUID
  Future<Employee?> fetchEmployeeDetail(String uuid) async {
    try {
      final response = await _apiService.get('/employees/$uuid');
      debugPrint('Employee detail API response: $response');

      final data = _extractSingleEmployeePayload(response);
      if (data == null) {
        return await _loadCachedEmployeeDetail(uuid);
      }

      final employee = Employee.fromJson(data);
      _selectedEmployee = employee;
      await OfflineSupport.saveJsonCache(
        _detailCacheKey(uuid),
        employee.toJson(),
      );
      return employee;
    } catch (e) {
      debugPrint('Error fetching employee detail: $e');
      return _loadCachedEmployeeDetail(uuid);
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
      final employee = getEmployeeById(employeeId);
      if (employee == null) {
        throw Exception('Employee not found');
      }

      debugPrint(
        'Updating employee department: ${employee.name} to $newDepartment',
      );

      final updateData = {
        'name': employee.name,
        'email': employee.email,
        'position': employee.position,
        'department': newDepartment,
        'status': employee.status,
        'phone': employee.phone,
        'join_date': employee.joinDate,
        'salary': employee.salary.toString(),
      };

      final response = await _apiService.put(
        '/employees/${employee.uuid}',
        updateData,
      );

      if (response['success'] == true) {
        final index = _employees.indexWhere((e) => e.uuid == employee.uuid);
        if (index != -1) {
          _employees[index] = employee.copyWith(department: newDepartment);
        }

        _error = null;
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update employee department';
        return false;
      }
    } catch (e) {
      debugPrint('Error updating employee department: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update complete employee data
  Future<bool> updateEmployee(
    Employee updatedEmployee, {
    Map<String, dynamic>? overrideData,
  }) async {
    _isLoading = true;
    _selectedEmployee = null;
    notifyListeners();

    try {
      final updateData =
          overrideData ??
          {
            'nik': updatedEmployee.nik,
            'name': updatedEmployee.name,
            'email': updatedEmployee.email,
            'position': updatedEmployee.positionId ?? updatedEmployee.position,
            'department':
                updatedEmployee.departmentId ?? updatedEmployee.department,
            'status': updatedEmployee.status,
            'phone': updatedEmployee.phone,
            'join_date': updatedEmployee.joinDate,
            'salary': updatedEmployee.salary.toString(),
          };

      final response = await _apiService.put(
        '/employees/${updatedEmployee.uuid}',
        updateData,
      );

      if (response['success'] == true) {
        final data = _extractSingleEmployeePayload(response);
        _selectedEmployee = data != null
            ? Employee.fromJson(data)
            : updatedEmployee;
        await fetchEmployees();
        _error = null;
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update employee';
        return false;
      }
    } catch (e) {
      debugPrint('Error updating employee: $e');
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
    _error = null;
    _selectedEmployee = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/employees', employeeData);

      if (response['success'] == true) {
        final data = _extractSingleEmployeePayload(response);
        if (data != null) {
          _selectedEmployee = Employee.fromJson(data);
        }
        await fetchEmployees();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to create employee';
        return false;
      }
    } catch (e) {
      debugPrint('Error creating employee: $e');
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
      final employee = getEmployeeByUuid(id);
      if (employee == null) {
        throw Exception('Employee not found');
      }

      final response = await _apiService.delete('/employees/${employee.uuid}');

      if (response['success'] == true) {
        _employees.removeWhere((e) => e.uuid == id || e.id == id);
        return true;
      } else {
        _error = response['message'] ?? 'Failed to delete employee';
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting employee: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int getActiveEmployeesCount() {
    return _employees.where((e) {
      final status = e.status.toLowerCase();
      return status != 'inactive' && status != 'deactive';
    }).length;
  }

  List<Employee> getEmployeesByDepartment(String department) {
    return _employees.where((e) => e.department == department).toList();
  }

  List<Employee> searchEmployees(String query) {
    if (query.isEmpty) {
      return _employees;
    }

    final searchLower = query.toLowerCase();

    return _employees.where((e) {
      final nameMatch = e.name.toLowerCase().contains(searchLower);
      final emailMatch = e.email?.toLowerCase().contains(searchLower) ?? false;
      final positionMatch = e.position.toLowerCase().contains(searchLower);
      final departmentMatch = e.department.toLowerCase().contains(searchLower);

      return nameMatch || emailMatch || positionMatch || departmentMatch;
    }).toList();
  }

  static List<Employee> filterSubordinateTree({
    required List<Employee> employees,
    required String managerEmployeeId,
  }) {
    final normalizedManagerId = managerEmployeeId.trim();
    if (normalizedManagerId.isEmpty) {
      return const [];
    }

    final childrenByManager = <String, List<Employee>>{};
    for (final employee in employees) {
      final managerId = employee.managerId?.trim() ?? '';
      if (managerId.isEmpty) {
        continue;
      }

      childrenByManager
          .putIfAbsent(managerId, () => <Employee>[])
          .add(employee);
    }

    final result = <Employee>[];
    final visited = <String>{};
    final queue = <String>[normalizedManagerId];

    while (queue.isNotEmpty) {
      final currentManagerId = queue.removeAt(0);
      for (final child
          in childrenByManager[currentManagerId] ?? const <Employee>[]) {
        final childKey = child.uuid.trim().isNotEmpty
            ? child.uuid.trim()
            : child.id.trim();
        if (childKey.isEmpty || !visited.add(childKey)) {
          continue;
        }

        result.add(child);
        if (child.uuid.trim().isNotEmpty) {
          queue.add(child.uuid.trim());
        }
        if (child.id.trim().isNotEmpty &&
            child.id.trim() != child.uuid.trim()) {
          queue.add(child.id.trim());
        }
      }
    }

    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  Future<void> loadNextPage() async {
    if (_currentPage < _lastPage && !_isLoading) {
      await fetchEmployees(page: _currentPage + 1);
    }
  }

  Future<void> refreshEmployees() async {
    await fetchEmployees();
  }

  void clear() {
    _employees = [];
    _error = null;
    _totalEmployees = 0;
    _currentPage = 1;
    _lastPage = 1;
    _isUsingCachedData = false;
    notifyListeners();
  }

  String get _selfCacheKey => 'employees::self';

  String _listCacheKey({
    String? search,
    String? department,
    required int page,
    required int perPage,
  }) {
    return 'employees::list::${search ?? ''}::${department ?? ''}::$page::$perPage';
  }

  String _allCacheKey({
    String? search,
    String? department,
    String? companyCode,
  }) {
    return 'employees::all::${companyCode?.trim() ?? ''}::${search ?? ''}::${department ?? ''}';
  }

  String _detailCacheKey(String uuid) => 'employees::detail::$uuid';

  Future<void> _saveEmployeeCache(
    String key,
    List<Employee> employees, {
    int? currentPage,
    int? lastPage,
    int? totalEmployees,
  }) {
    return OfflineSupport.saveJsonCache(key, {
      'employees': employees.map((employee) => employee.toJson()).toList(),
      'currentPage': currentPage ?? _currentPage,
      'lastPage': lastPage ?? _lastPage,
      'totalEmployees': totalEmployees ?? _totalEmployees,
    });
  }

  Future<bool> _loadEmployeeCache(String key) async {
    final cached = await OfflineSupport.getJsonCache(key);
    if (cached is! Map<String, dynamic>) {
      return false;
    }

    final employees = cached['employees'];
    if (employees is! List) {
      return false;
    }

    _employees = employees
        .whereType<Map>()
        .map((item) => Employee.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    _currentPage = _asInt(cached['currentPage'], 1);
    _lastPage = _asInt(cached['lastPage'], 1);
    _totalEmployees = _asInt(cached['totalEmployees'], _employees.length);
    _isUsingCachedData = true;
    _error = null;
    return true;
  }

  Future<Employee?> _loadCachedEmployeeDetail(String uuid) async {
    final cached = await OfflineSupport.getJsonCache(_detailCacheKey(uuid));
    if (cached is! Map<String, dynamic>) {
      return null;
    }

    return Employee.fromJson(cached);
  }

  Future<Employee?> _buildSelfEmployeeFromStorage() async {
    final userData = await _getStoredUser();
    if (userData == null) {
      return null;
    }

    final fallbackEmployee = <String, dynamic>{
      'id': userData.id,
      'uuid': userData.employeeUuid ?? userData.uuid,
      'name': userData.name,
      'email': userData.email,
      'status': 'Active',
      'position': userData.position,
      'join_date': DateTime.now().toIso8601String().split('T').first,
    };

    return Employee.fromJson(fallbackEmployee);
  }
}

class _EmployeeFetchResult {
  final List<Employee> employees;
  final int currentPage;
  final int lastPage;
  final int totalEmployees;

  const _EmployeeFetchResult({
    required this.employees,
    required this.currentPage,
    required this.lastPage,
    required this.totalEmployees,
  });
}
