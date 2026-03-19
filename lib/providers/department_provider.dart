import 'package:flutter/material.dart';

import '../models/department_model.dart';
import '../services/api_service.dart';
import '../services/offline_support.dart';

class DepartmentProvider extends ChangeNotifier {
  List<Department> _departments = [];
  bool _isLoading = false;
  String? _error;
  String? _currentCcode;
  bool _isUsingCachedData = false;

  final List<String> _availableRoles = [
    'Manager',
    'Supervisor',
    'Lead',
    'Staff',
  ];
  final List<String> _availableTypes = [
    'Department',
    'Division',
    'Team',
    'Unit',
  ];
  final List<String> _availableLocations = [
    'Jakarta',
    'Bandung',
    'Surabaya',
    'Medan',
    'Remote',
  ];

  List<Department> get departments => _departments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentCcode => _currentCcode;
  bool get isUsingCachedData => _isUsingCachedData;
  List<String> get availableRoles => _availableRoles;
  List<String> get availableTypes => _availableTypes;
  List<String> get availableLocations => _availableLocations;

  void setCurrentCcode(String ccode) {
    _currentCcode = ccode;
    notifyListeners();
  }

  Future<void> fetchDepartments() async {
    _isLoading = true;
    _error = null;
    _isUsingCachedData = false;
    notifyListeners();

    try {
      final response = await ApiService().get('/departments');

      if (response is Map<String, dynamic> && response['success'] == true) {
        final data = response['data'];
        final items = data is List ? List<dynamic>.from(data) : <dynamic>[];

        _departments = items
            .whereType<Map>()
            .map((json) => Department.fromJson(Map<String, dynamic>.from(json)))
            .toList(growable: false);
        _error = null;

        await OfflineSupport.saveJsonCache(
          _cacheKey,
          _departments.map((department) => department.toJson()).toList(),
        );
      } else {
        final loadedFromCache = await _loadFromCache();
        if (!loadedFromCache) {
          _error = response is Map<String, dynamic>
              ? response['message']?.toString() ?? 'Failed to load departments'
              : 'Failed to load departments';
          _departments = [];
        }
      }
    } catch (error) {
      final loadedFromCache = await _loadFromCache();
      if (!loadedFromCache) {
        _error = error.toString();
        _departments = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Department> getDepartmentsByCcode(String? cCode) {
    if (cCode == null || cCode.isEmpty) {
      return _departments;
    }

    return _departments.where((dept) => dept.cCode == cCode).toList();
  }

  int getTotalEmployees() {
    return _departments.fold<int>(0, (sum, d) => sum + (d.employees));
  }

  double getTotalBudget() {
    return _departments.fold<double>(0.0, (sum, d) => sum + (d.budget ?? 0));
  }

  Future<bool> addDepartment(Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_currentCcode != null && _currentCcode!.isNotEmpty) {
        data['c_code'] = _currentCcode;
      }

      final response = await ApiService().post('/departments', data);

      if (response is Map<String, dynamic> && response['success'] == true) {
        await fetchDepartments();
        return true;
      }

      _error = response is Map<String, dynamic>
          ? response['message']?.toString() ?? 'Failed to create department'
          : 'Failed to create department';
      return false;
    } catch (error) {
      _error = error.toString();
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

      if (_currentCcode != null && _currentCcode!.isNotEmpty) {
        data['c_code'] = _currentCcode;
      }

      final response = await ApiService().put('/departments/$id', data);

      if (response is Map<String, dynamic> && response['success'] == true) {
        await fetchDepartments();
        return true;
      }

      _error = response is Map<String, dynamic>
          ? response['message']?.toString() ?? 'Failed to update department'
          : 'Failed to update department';
      return false;
    } catch (error) {
      _error = error.toString();
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

      final response = await ApiService().delete('/departments/$id');

      if (response is Map<String, dynamic> && response['success'] == true) {
        await fetchDepartments();
        return true;
      }

      _error = response is Map<String, dynamic>
          ? response['message']?.toString() ?? 'Failed to delete department'
          : 'Failed to delete department';
      return false;
    } catch (error) {
      _error = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Department? getDepartmentById(int id) {
    try {
      return _departments.firstWhere((dept) => dept.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Department> getChildrenDepartments(int parentId) {
    return _departments.where((dept) => dept.parentId == parentId).toList();
  }

  void clear() {
    _departments = [];
    _error = null;
    _currentCcode = null;
    _isUsingCachedData = false;
    notifyListeners();
  }

  String get _cacheKey => 'departments::${_currentCcode ?? 'all'}';

  Future<bool> _loadFromCache() async {
    final cached = await OfflineSupport.getJsonCache(_cacheKey);
    if (cached is! List) {
      return false;
    }

    _departments = cached
        .whereType<Map>()
        .map((item) => Department.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    _error = null;
    _isUsingCachedData = true;
    return true;
  }
}
