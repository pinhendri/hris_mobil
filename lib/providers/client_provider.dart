import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/models/client_model.dart';
import '../data/models/assignment_model.dart'; // Tambahkan import ini
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClientProvider with ChangeNotifier {
  List<Client> _clients = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalClients = 0;
  String? _error;

  // Tambahan untuk assignment
  List<EmployeeAssignment> _assignedEmployees = [];
  List<AvailableEmployee> _availableEmployees = [];

  final ApiService _apiService = ApiService();

  List<Client> get clients => _clients;
  bool get isLoading => _isLoading;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get totalClients => _totalClients;
  String? get error => _error;

  // Getter untuk assignment
  List<EmployeeAssignment> get assignedEmployees => _assignedEmployees;
  List<AvailableEmployee> get availableEmployees => _availableEmployees;

  Future<void> fetchClients({int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Fetching clients page $page...');
      
      final response = await _apiService.get('/clients?page=$page');
      
      print('📥 Raw API Response: $response');
      
      if (response is Map<String, dynamic>) {
        final success = response['success'] ?? false;
        final message = response['message'] ?? 'No message';
        final data = response['data'];
        
        if (success == true) {
          List<dynamic> items = [];
          
          if (data is Map && data.containsKey('data')) {
            print('📥 Data is paginated response');
            items = data['data'] as List? ?? [];
          } else if (data is List) {
            print('📥 Data is direct List with length: ${data.length}');
            items = data;
          }
          
          print('📥 Items count: ${items.length}');
          
          _clients = items.map<Client>((json) {
            print('📥 Processing client: $json');
            return Client.fromJson(json);
          }).toList();
          
          final pagination = response['pagination'] ?? {};
          _currentPage = pagination['current_page'] ?? page;
          _lastPage = pagination['last_page'] ?? 1;
          _totalClients = pagination['total'] ?? _clients.length;
          
          print('✅ Loaded ${_clients.length} clients');
        } else {
          _error = message;
          _clients = [];
          print('❌ API Error: $message');
        }
      } else {
        print('❌ Response is not a Map. Type: ${response.runtimeType}');
        _error = 'Invalid response format';
        _clients = [];
      }
    } catch (e) {
      print('❌ Error fetching clients: $e');
      _error = e.toString();
      _clients = [];
    } finally {
      _isLoading = false;
      notifyListeners();
      print('✅ fetchClients completed. _clients length: ${_clients.length}');
    }
  }

  Future<void> fetchClientDetail(String uuid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Fetching client detail for uuid: $uuid');
      
      final response = await _apiService.get('/clients/$uuid');
      
      if (response is Map<String, dynamic>) {
        final success = response['success'] ?? false;
        final data = response['data'];
        
        if (success == true && data is Map<String, dynamic>) {
          final client = Client.fromJson(data);
          
          final index = _clients.indexWhere((c) => c.id == uuid);
          if (index != -1) {
            _clients[index] = client;
          } else {
            _clients.add(client);
          }
          
          print('✅ Client detail fetched: ${client.name}');
        } else {
          _error = response['message'] ?? 'Failed to fetch client detail';
        }
      }
    } catch (e) {
      print('❌ Error fetching client detail: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createClient(Map<String, dynamic> clientData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Creating client with data: $clientData');
      
      final response = await _apiService.post('/clients', clientData);
      
      if (response is Map<String, dynamic>) {
        final success = response['success'] ?? false;
        
        if (success == true) {
          await fetchClients();
          return true;
        } else {
          _error = response['message'] ?? 'Failed to create client';
          return false;
        }
      }
      return false;
    } catch (e) {
      print('❌ Error creating client: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateClient(String uuid, Map<String, dynamic> clientData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Updating client $uuid with data: $clientData');
      
      final response = await _apiService.put('/clients/$uuid', clientData);
      
      if (response is Map<String, dynamic>) {
        final success = response['success'] ?? false;
        
        if (success == true) {
          final updatedClient = Client.fromJson(response['data']);
          final index = _clients.indexWhere((c) => c.id == uuid);
          if (index != -1) {
            _clients[index] = updatedClient;
          }
          return true;
        } else {
          _error = response['message'] ?? 'Failed to update client';
          return false;
        }
      }
      return false;
    } catch (e) {
      print('❌ Error updating client: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteClient(String uuid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Deleting client: $uuid');
      
      final response = await _apiService.delete('/clients/$uuid');
      
      if (response is Map<String, dynamic>) {
        final success = response['success'] ?? false;
        
        if (success == true) {
          _clients.removeWhere((c) => c.id == uuid);
          return true;
        } else {
          _error = response['message'] ?? 'Failed to delete client';
          return false;
        }
      }
      return false;
    } catch (e) {
      print('❌ Error deleting client: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> extendContract(String uuid, String newEndDate) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Extending contract for client $uuid to: $newEndDate');
      
      final response = await _apiService.post('/clients/$uuid/extend', {
        'new_end_date': newEndDate
      });
      
      if (response is Map<String, dynamic>) {
        final success = response['success'] ?? false;
        
        if (success == true) {
          final updatedClient = Client.fromJson(response['data']);
          final index = _clients.indexWhere((c) => c.id == uuid);
          if (index != -1) {
            _clients[index] = updatedClient;
          }
          return true;
        } else {
          _error = response['message'] ?? 'Failed to extend contract';
          return false;
        }
      }
      return false;
    } catch (e) {
      print('❌ Error extending contract: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== EMPLOYEE ASSIGNMENT METHODS ==========

  // Fetch employees assigned to a client
  Future<List<EmployeeAssignment>> fetchAssignedEmployees(String clientUuid) async {
    try {
      print('🔄 Fetching assigned employees for client: $clientUuid');
      
      final response = await _apiService.get('/clients/$clientUuid/employees');
      
      print('📥 Assigned employees response: $response');
      
      if (response is Map<String, dynamic>) {
        final success = response['success'] ?? false;
        
        if (success == true) {
          final List<dynamic> data = response['data'] ?? [];
          _assignedEmployees = data.map((json) => EmployeeAssignment.fromJson(json)).toList();
          print('✅ Loaded ${_assignedEmployees.length} assigned employees');
        } else {
          _assignedEmployees = [];
        }
      }
      return _assignedEmployees;
    } catch (e) {
      print('❌ Error fetching assigned employees: $e');
      _error = e.toString();
      return [];
    } finally {
      notifyListeners();
    }
  }

  // Fetch available employees (yang belum diassign ke client tertentu)
  Future<List<AvailableEmployee>> fetchAvailableEmployees(String clientUuid) async {
    try {
      print('🔄 Fetching available employees for client: $clientUuid');
      
      // Fetch assigned employees first to know which ones are already assigned
      await fetchAssignedEmployees(clientUuid);
      
      // Fetch all employees
      final response = await _apiService.get('/employees?per_page=100');
      
      print('📥 Available employees response: $response');
      
      if (response is Map<String, dynamic>) {
        final success = response['success'] ?? false;
        
        if (success == true) {
          List<dynamic> allEmployees = [];
          
          // Handle berbagai format response
          if (response['data'] is Map && response['data']['data'] != null) {
            allEmployees = response['data']['data'];
          } else if (response['data'] is List) {
            allEmployees = response['data'];
          }
          
          // Dapatkan UUID employee yang sudah diassign
          final assignedUuids = _assignedEmployees.map((e) => e.uuid).toSet();
          
          // Filter employee yang belum diassign
          _availableEmployees = allEmployees
              .where((emp) => !assignedUuids.contains(emp['uuid']))
              .map((json) => AvailableEmployee.fromJson(json))
              .toList();
              
          print('✅ Loaded ${_availableEmployees.length} available employees');
        } else {
          _availableEmployees = [];
        }
      }
      return _availableEmployees;
    } catch (e) {
      print('❌ Error fetching available employees: $e');
      _error = e.toString();
      return [];
    } finally {
      notifyListeners();
    }
  }

  // Assign employees to client (method ini sudah ada, kita perbaiki)
  Future<bool> assignEmployees(String clientUuid, List<String> employeeUuids, String shiftDate, {String? role}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Assigning employees to client $clientUuid');
      print('📤 Employee UUIDs: $employeeUuids');
      print('📤 Shift Date: $shiftDate');
      print('📤 Role: $role');

      final response = await _apiService.post('/clients/$clientUuid/assign', {
        'employee_uuids': employeeUuids,
        'shift_date': shiftDate,
        'role': role,
      });

      print('📥 Assign response: $response');

      if (response is Map<String, dynamic>) {
        final success = response['success'] ?? false;

        if (success == true) {
          // Refresh data setelah assign berhasil
          await fetchAssignedEmployees(clientUuid);
          await fetchAvailableEmployees(clientUuid);
          return true;
        } else {
          _error = response['message'] ?? 'Failed to assign employees';
          return false;
        }
      }
      return false;
    } catch (e) {
      print('❌ Error assigning employees: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Remove assigned employee from client (method ini sudah ada, kita perbaiki)
  Future<bool> removeAssignedEmployee(String clientUuid, String employeeUuid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Removing employee $employeeUuid from client $clientUuid');

      final response = await _apiService.delete('/clients/$clientUuid/employees/$employeeUuid');

      print('📥 Remove response: $response');

      if (response is Map<String, dynamic>) {
        final success = response['success'] ?? false;

        if (success == true) {
          // Refresh data setelah remove berhasil
          await fetchAssignedEmployees(clientUuid);
          await fetchAvailableEmployees(clientUuid);
          return true;
        } else {
          _error = response['message'] ?? 'Failed to remove employee';
          return false;
        }
      }
      return false;
    } catch (e) {
      print('❌ Error removing employee: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get client employees (method yang sudah ada, kita biarkan saja)
  Future<List<dynamic>> getClientEmployees(String uuid, {int perPage = 100}) async {
    try {
      print('🔄 Getting employees for client $uuid');
      
      final response = await _apiService.get('/clients/$uuid/employees?per_page=$perPage');
      
      if (response is Map<String, dynamic>) {
        final success = response['success'] ?? false;
        
        if (success == true) {
          return response['data'] ?? [];
        }
      }
      return [];
    } catch (e) {
      print('❌ Error getting client employees: $e');
      _error = e.toString();
      return [];
    }
  }

  Future<Map<String, dynamic>?> getClientStats() async {
    try {
      print('🔄 Getting client stats');
      
      final response = await _apiService.get('/clients/stats');
      
      if (response is Map<String, dynamic>) {
        final success = response['success'] ?? false;
        
        if (success == true) {
          return response['data'];
        }
      }
      return null;
    } catch (e) {
      print('❌ Error getting client stats: $e');
      _error = e.toString();
      return null;
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= _lastPage && page != _currentPage) {
      fetchClients(page: page);
    }
  }

  void refreshClients() {
    fetchClients(page: _currentPage);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}