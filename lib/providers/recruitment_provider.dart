import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/session_storage.dart';
import '../models/recruitment_model.dart';

class RecruitmentProvider with ChangeNotifier {
  List<OpenPosition> _openPositions = [];
  List<PipelineStage> _pipeline = [];
  List<Application> _applications = [];
  RecruitmentMetrics _metrics = RecruitmentMetrics(
    conversionRate: 0,
    averageTimeToHire: 0,
  );
  List<Department> _departments = [];
  List<Position> _positions = [];

  bool _isLoading = false;
  String? _error;
  String? _filteredByCCode;

  final Map<int, String> _requirementsCache = {};

  // Getters
  List<OpenPosition> get openPositions => _openPositions;
  List<PipelineStage> get pipeline => _pipeline;
  List<Application> get applications => _applications;
  RecruitmentMetrics get metrics => _metrics;
  List<Department> get departments => _departments;
  List<Position> get positions => _positions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get filteredByCCode => _filteredByCCode;

  final ApiService _apiService = ApiService();

  // Fetch all recruitment data
  Future<void> fetchRecruitmentData() async {
    _isLoading = true;
    notifyListeners();

    try {
      print('🔄 Fetching recruitment data...');
      final response = await _apiService.get('/recruitment');

      print('📥 Recruitment API Response: $response');

      if (response is Map<String, dynamic>) {
        // Parse openPositions
        if (response['openPositions'] is List) {
          final items = response['openPositions'] as List;
          print('📦 Raw openPositions count: ${items.length}');

          _openPositions = items.map((p) {
            print('📦 Processing open position: $p');
            return OpenPosition.fromJson(p);
          }).toList();

          print('✅ Parsed ${_openPositions.length} open positions');
        } else {
          _openPositions = [];
        }

        // Parse applications
        if (response['applications'] is List) {
          _applications = (response['applications'] as List)
              .map((a) => Application.fromJson(a))
              .toList();
        } else {
          _applications = [];
        }

        // Handle statusCounts
        Map<String, dynamic> statusCounts = {};
        if (response['statusCounts'] is Map) {
          statusCounts = response['statusCounts'] as Map<String, dynamic>;
        } else {
          print('⚠️ statusCounts is a List, using empty Map');
        }

        // Build pipeline
        const stages = [
          'Applied',
          'Screening',
          'Interview',
          'Offer',
          'Hired',
          'Rejected',
          'Withdrawn',
        ];
        _pipeline = stages.map((stage) {
          final key = stage.toLowerCase();
          int count = 0;

          if (statusCounts.containsKey(key)) {
            final value = statusCounts[key];
            if (value is int) {
              count = value;
            } else if (value is String) {
              count = int.tryParse(value) ?? 0;
            } else if (value is double) {
              count = value.toInt();
            }
          }

          return PipelineStage(stage: stage, count: count);
        }).toList();

        // Parse metrics
        if (response['metrics'] is Map) {
          final metricsData = response['metrics'] as Map;
          _metrics = RecruitmentMetrics(
            conversionRate: (metricsData['conversionRate'] ?? 0).toDouble(),
            averageTimeToHire: (metricsData['averageTimeToHire'] ?? 0)
                .toDouble(),
          );
        }

        _filteredByCCode = response['filtered_by_c_code']?.toString();

        print('✅ Loaded ${_openPositions.length} open positions');
        print('✅ Loaded ${_applications.length} applications');
      }
    } catch (e) {
      print('❌ Error fetching recruitment data: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch departments
  Future<void> fetchDepartments() async {
    try {
      print('🔄 Fetching departments...');
      final response = await _apiService.get('/departments');

      print('📥 Departments API Response: $response');

      if (response is Map<String, dynamic>) {
        if (response['data'] is List) {
          _departments = (response['data'] as List)
              .map((d) => Department.fromJson(d))
              .toList();
        }
      } else if (response is List) {
        _departments = response.map((d) => Department.fromJson(d)).toList();
      }

      print('✅ Loaded ${_departments.length} departments');
    } catch (e) {
      print('❌ Error fetching departments: $e');
      _departments = [];
    } finally {
      notifyListeners();
    }
  }

  // Fetch positions
  Future<void> fetchPositions() async {
    try {
      print('🔄 Fetching positions...');
      final response = await _apiService.get('/employees/master/position');

      print('📥 Positions API Response: $response');

      if (response is Map<String, dynamic>) {
        if (response['data'] is List) {
          _positions = (response['data'] as List)
              .map((p) => Position.fromJson(p))
              .toList();
        }
      } else if (response is List) {
        _positions = response.map((p) => Position.fromJson(p)).toList();
      }

      print('✅ Loaded ${_positions.length} positions');
    } catch (e) {
      print('❌ Error fetching positions: $e');
      _positions = [];
    } finally {
      notifyListeners();
    }
  }

  // Fetch job requirement by ID
  Future<String?> fetchJobRequirement(int jobId) async {
    if (_requirementsCache.containsKey(jobId)) {
      return _requirementsCache[jobId];
    }

    try {
      print('🔄 Fetching job requirement for job $jobId...');
      final response = await _apiService.get('/recruitment/jobs/$jobId');

      if (response is Map<String, dynamic> && response['success'] == true) {
        final requirement =
            response['data']['requirement'] ?? 'No requirement specified';
        _requirementsCache[jobId] = requirement;
        return requirement;
      }
      return '';
    } catch (e) {
      print('❌ Error fetching job requirement: $e');
      return '';
    }
  }

  // Create new job posting
  Future<bool> createJob(Map<String, dynamic> jobData) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('🔄 Creating new job with data: $jobData');
      final response = await _apiService.post('/recruitment/jobs', jobData);

      print('📥 Create job response: $response');

      if (response is Map<String, dynamic>) {
        await fetchRecruitmentData();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error creating job: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method untuk mendapatkan token dari berbagai sumber
  Future<String> _getTokenFromMultipleSources() async {
    try {
      final token = await SessionStorage.getToken();
      final prefs = await SharedPreferences.getInstance();
      final possibleKeys = [
        'auth_token',
        'token',
        'access_token',
        'user_token',
        'api_token',
        'bearer_token',
        'jwt_token',
        'login_token',
        'session_token',
      ];
      print('ðŸ”‘ Using token: ${token.isNotEmpty ? 'found' : 'not found'}');
      return token;

      // Coba semua kemungkinan key
      for (var key in possibleKeys) {
        final token = prefs.getString(key);
        if (token != null && token.isNotEmpty) {
          print('✅ Token found with key: $key');
          return token;
        }
      }

      // Jika tidak ditemukan, log semua keys yang ada untuk debugging
      print('⚠️ No token found in SharedPreferences');
      final allKeys = prefs.getKeys();
      print('📋 Available SharedPreferences keys: $allKeys');

      // Coba baca semua nilai string untuk mencari token
      for (var key in allKeys) {
        final value = prefs.get(key);
        if (value is String && value.length > 20) {
          print(
            '🔍 Possible token in key: $key = ${value.substring(0, min(20, value.length))}...',
          );
        }
      }

      return '';
    } catch (e) {
      print('❌ Error getting token from multiple sources: $e');
      return '';
    }
  }

  // Helper method untuk mendapatkan headers dengan token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getTokenFromMultipleSources();
    print('🔑 Using token: ${token != null ? 'found' : 'not found'}');

    return {'Authorization': 'Bearer $token', 'Accept': 'application/json'};
  }

  // Add new application with CV file
  Future<bool> addApplicationWithCV(
    Map<String, dynamic> applicationData,
    File cvFile,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('🔄 Adding new application with CV: $applicationData');

      // Dapatkan token dari multiple sources
      final token = await _getTokenFromMultipleSources();

      if (token.isEmpty) {
        _error = 'Authentication token not found. Please login again.';
        print('❌ Token not found in any storage');
        return false;
      }

      print('✅ Token found: ${token.substring(0, min(20, token.length))}...');

      // Buat multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/api/recruitment/applications'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Add fields
      applicationData.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Add file
      var fileStream = http.ByteStream(cvFile.openRead());
      var fileLength = await cvFile.length();

      var multipartFile = http.MultipartFile(
        'cv',
        fileStream,
        fileLength,
        filename: cvFile.path.split('/').last,
        contentType: MediaType('application', 'pdf'),
      );

      request.files.add(multipartFile);

      print('📤 Sending request to: ${request.url}');
      print('📤 Headers: ${request.headers}');
      print('📤 Fields: ${request.fields}');
      print('📤 File: ${multipartFile.filename} (${fileLength} bytes)');

      // Send request dengan timeout
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      var response = await http.Response.fromStream(streamedResponse);

      print('📥 Add application response status: ${response.statusCode}');
      print('📥 Add application response body: ${response.body}');

      if (response.statusCode == 401) {
        _error = 'Session expired. Please login again.';
        return false;
      } else if (response.statusCode >= 200 && response.statusCode < 300) {
        await fetchRecruitmentData();
        return true;
      } else {
        _error = 'Failed to add application: ${response.body}';
        return false;
      }
    } catch (e) {
      print('❌ Error adding application with CV: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Close job posting
  Future<bool> closeJob(int jobId) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('🔄 Closing job $jobId...');
      final response = await _apiService.put(
        '/recruitment/jobs/$jobId/close',
        {},
      );

      print('📥 Close job response: $response');

      if (response is Map<String, dynamic> && response['success'] == true) {
        await fetchRecruitmentData();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error closing job: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update application status
  // Update application status
  Future<bool> updateApplicationStatus(int applicationId, String status) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('🔄 Updating application $applicationId status to $status...');

      // ENDPOINT YANG BENAR - Sesuai dengan route Laravel
      final response = await _apiService.put(
        '/recruitment/applications/$applicationId', // Perhatikan: tanpa /status di akhir
        {'status': status},
      );

      print('📥 Update status response: $response');

      if (response is Map<String, dynamic>) {
        // Cek berbagai kemungkinan struktur response
        if (response['success'] == true) {
          await fetchRecruitmentData();
          return true;
        } else if (response['status'] == 'success') {
          await fetchRecruitmentData();
          return true;
        } else if (response['application'] != null) {
          await fetchRecruitmentData();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('❌ Error updating status: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Public method untuk mendapatkan token (untuk digunakan di screen)
  Future<String> getToken() async {
    return await _getTokenFromMultipleSources();
  }

  // Get department name by ID
  String getDepartmentName(String? departmentId) {
    if (departmentId == null || departmentId.isEmpty) return 'Unknown';

    final dept = _departments.firstWhere(
      (d) => d.id.toString() == departmentId,
      orElse: () => Department(id: 0, name: 'Unknown'),
    );

    return dept.name != 'Unknown' ? dept.name : 'Dept $departmentId';
  }

  // Get urgency badge color
  Color getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Get status badge color
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'hired':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'interview':
      case 'screening':
        return Colors.blue;
      case 'offer':
        return Colors.purple;
      case 'applied':
      default:
        return Colors.orange;
    }
  }

  // Refresh all data
  Future<void> refreshData() async {
    print('🔄 refreshData started');
    await fetchRecruitmentData();
    print('✅ fetchRecruitmentData completed');
    await fetchDepartments();
    print('✅ fetchDepartments completed');
    await fetchPositions();
    print('✅ fetchPositions completed');
    print('🔔 Final state - openPositions: ${_openPositions.length}');
    notifyListeners();
  }
}

// Helper function untuk min value
int min(int a, int b) => a < b ? a : b;
