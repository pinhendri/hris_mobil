import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/user.dart';
import '../models/company.dart';
import '../services/offline_support.dart';
import '../services/session_storage.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isAuthenticated = false;
  User? _user;
  String? _token;
  List<Company> _companyAssignments = [];
  Company? _selectedCompany;
  String? _companyCode; // <-- SUDAH BAIK
  bool _isSyncingOfflineProfile = false;
  int _pendingProfileSyncCount = 0;
  String? _lastProfileUpdateMessage;
  bool _lastProfileUpdateQueued = false;
  Timer? _offlineProfileSyncTimer;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  User? get user => _user;
  String? get token => _token;
  List<Company> get companyAssignments => _companyAssignments;
  Company? get selectedCompany => _selectedCompany;
  String? get companyCode => _companyCode; // <-- TAMBAHKAN GETTER
  List<String> get permissions => _user?.permissions ?? const [];
  List<String> get roles => _user?.roles ?? const [];
  bool get isSyncingOfflineProfile => _isSyncingOfflineProfile;
  int get pendingProfileSyncCount => _pendingProfileSyncCount;
  String? get lastProfileUpdateMessage => _lastProfileUpdateMessage;
  bool get lastProfileUpdateQueued => _lastProfileUpdateQueued;

  static const Set<String> _adminPermissions = {
    'view-settings',
    'create-settings',
    'edit-settings',
    'view-department',
    'create-department',
    'edit-department',
    'delete-department',
    'view-employee',
    'create-employee',
    'edit-employee',
    'delete-employee',
    'view-attendance',
    'create-attendance',
    'edit-attendance',
    'view-leave',
    'create-leave',
    'edit-leave',
    'view-payroll',
    'create-payroll',
    'edit-payroll',
    'edit-payroll-settings',
    'view-reports',
    'view-roles',
    'assign-roles',
    'view-permissions',
    'view-recruitment',
    'create-recruitment',
    'edit-recruitment',
    'view-client',
    'create-client',
    'edit-client',
    'delete-client',
    'view-kpi',
    'edit-kpi',
  };

  static const Set<String> _adminRoles = {
    'super-admin',
    'admin',
    'administrator',
    'hr',
    'hr-admin',
  };

  AuthProvider() {
    unawaited(_bootstrapOfflineProfileSync());
  }

  Future<void> _bootstrapOfflineProfileSync() async {
    await _refreshPendingProfileSyncCount(notify: false);
    _offlineProfileSyncTimer ??= Timer.periodic(const Duration(seconds: 45), (
      _,
    ) {
      unawaited(_syncOfflineProfileUpdates(silent: true));
    });
  }

  @override
  void dispose() {
    _offlineProfileSyncTimer?.cancel();
    super.dispose();
  }

  // ===== SET USER (METHOD BARU) =====
  Future<void> setUser(Map<String, dynamic> userData) async {
    _user = User.fromMap(userData);

    // Update selected company jika ada dalam userData
    if (userData['selected_c_code'] != null) {
      _selectedCompany = Company(
        id: userData['selected_company_id'] ?? 0,
        cCode: userData['selected_c_code'] ?? '',
        companyName: '',
      );
      _companyCode = userData['selected_c_code']; // <-- SIMPAN COMPANY CODE
    }

    notifyListeners();
  }

  // ===== LOGIN =====
  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.loginEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // HAPUS DATA SESI LAMA TANPA MENGGANGGU PREFERENSI APP LAIN
        await SessionStorage.clearSession();

        // Simpan token
        _token = data['data']['token']?.toString() ?? '';
        if (_token != null && _token!.isNotEmpty) {
          await SessionStorage.saveToken(_token!);
        }

        // Simpan user
        final userMap = data['data']['user'] as Map<String, dynamic>? ?? {};
        _user = User.fromMap(userMap);

        // SIMPAN USER KE STORAGE
        await SessionStorage.saveUserData(jsonEncode(userMap));

        // Simpan company assignments
        final rawCompanies =
            data['data']['company_assignments'] as List<dynamic>? ?? [];
        _companyAssignments = rawCompanies.map<Company>((c) {
          return Company.fromMap(c as Map<String, dynamic>);
        }).toList();

        // SIMPAN COMPANY ASSIGNMENTS KE STORAGE
        await SessionStorage.saveCompanyAssignments(jsonEncode(rawCompanies));

        // AMBIL COMPANY CODE DARI RESPONSE
        String? companyCode;

        // Coba dari user.selectedCCode
        if (_user?.selectedCCode != null && _user!.selectedCCode.isNotEmpty) {
          companyCode = _user!.selectedCCode;
        }
        // Jika tidak ada, coba dari company assignments pertama
        else if (_companyAssignments.isNotEmpty) {
          companyCode = _companyAssignments.first.cCode;
        }

        // Simpan company code
        if (companyCode != null && companyCode.isNotEmpty) {
          _companyCode = companyCode; // <-- SIMPAN DI MEMORY
          await SessionStorage.saveCompanyCode(companyCode);
          print('✅ Company code saved: $companyCode');
        }

        // Jika hanya ada 1 company, langsung set sebagai selected
        if (_companyAssignments.length == 1) {
          _selectedCompany = _companyAssignments.first;
        }

        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();

        return {
          'success': true,
          'user': userMap,
          'company_assignments': rawCompanies,
          'company_code': companyCode,
        };
      } else {
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': data['message']?.toString() ?? 'Login failed',
        };
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  // ===== SET SELECTED COMPANY =====
  Future<Map<String, dynamic>> setSelectedCompany({
    required int companyId,
    required String cCode,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await SessionStorage.getToken();
      if (token.isEmpty) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse(
          ApiConstants.baseUrl + ApiConstants.setSelectedCompanyEndpoint,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'company_id': companyId, 'c_code': cCode}),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Cari company yang dipilih
        try {
          _selectedCompany = _companyAssignments.firstWhere(
            (c) => c.id == companyId,
          );
        } catch (e) {
          // Jika tidak ditemukan, buat company baru
          _selectedCompany = Company(
            id: companyId,
            cCode: cCode,
            companyName: '',
          );
        }

        // SIMPAN SELECTED COMPANY CODE
        _companyCode = cCode; // <-- SIMPAN DI MEMORY
        await SessionStorage.saveCompanyCode(cCode);

        _isLoading = false;
        notifyListeners();
        return {'success': true, 'data': data['data'] ?? {}};
      } else {
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to select company',
        };
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  // ===== GET USER INFO =====
  Future<Map<String, dynamic>> getUserInfo() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await SessionStorage.getToken();
      if (token.isEmpty) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.getUserInfoEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final userMap = data['data']['user'] as Map<String, dynamic>? ?? {};
        _user = User.fromMap(userMap);

        // UPDATE STORAGE
        await SessionStorage.saveUserData(jsonEncode(userMap));

        final rawCompanies =
            data['data']['company_assignments'] as List<dynamic>? ?? [];
        _companyAssignments = rawCompanies.map<Company>((c) {
          return Company.fromMap(c as Map<String, dynamic>);
        }).toList();

        // UPDATE STORAGE
        await SessionStorage.saveCompanyAssignments(jsonEncode(rawCompanies));

        // Cek selected company dari response
        if (userMap['selected_c_code'] != null) {
          try {
            _selectedCompany = _companyAssignments.firstWhere(
              (c) => c.cCode == userMap['selected_c_code'],
            );
          } catch (e) {
            _selectedCompany = Company(
              id: userMap['selected_company_id'] ?? 0,
              cCode: userMap['selected_c_code'] ?? '',
              companyName: '',
            );
          }

          // SIMPAN COMPANY CODE
          _companyCode = userMap['selected_c_code']; // <-- SIMPAN DI MEMORY
          await SessionStorage.saveCompanyCode(
            userMap['selected_c_code'].toString(),
          );
        }

        _isLoading = false;
        await _syncOfflineProfileUpdates(silent: true);
        notifyListeners();
        return {
          'success': true,
          'data': data['data'],
          'status_code': response.statusCode,
        };
      } else {
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get user info',
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  // ===== CHANGE PASSWORD =====
  Future<Map<String, dynamic>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await SessionStorage.getToken();
      if (token.isEmpty) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.changePasswordEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': oldPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPassword,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      _isLoading = false;
      notifyListeners();

      return {
        'success': response.statusCode == 200,
        'message':
            data['message'] ??
            (response.statusCode == 200
                ? 'Password changed successfully'
                : 'Failed to change password'),
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  // ===== UPDATE PROFILE =====
  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> updatedData,
  ) async {
    _isLoading = true;
    _lastProfileUpdateQueued = false;
    _lastProfileUpdateMessage = null;
    notifyListeners();

    try {
      final token = await SessionStorage.getToken();
      if (token.isEmpty) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http
          .post(
            Uri.parse(
              ApiConstants.baseUrl + ApiConstants.updateProfileEndpoint,
            ),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(updatedData),
          )
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (data['data'] != null) {
          _user = User.fromMap(data['data']);
          // UPDATE STORAGE
          await SessionStorage.saveUserData(jsonEncode(data['data']));
        }
        _lastProfileUpdateQueued = false;
        _lastProfileUpdateMessage =
            data['message']?.toString() ?? 'Profile updated successfully';
        await _refreshPendingProfileSyncCount(notify: false);
        _isLoading = false;
        notifyListeners();
        return {'success': true, 'message': _lastProfileUpdateMessage};
      } else if (response.statusCode >= 500 || response.statusCode == 408) {
        await _queueProfileUpdate(updatedData, data['message']);
        _isLoading = false;
        notifyListeners();
        return {
          'success': true,
          'queued': true,
          'message': _lastProfileUpdateMessage,
        };
      } else {
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      if (OfflineSupport.isLikelyOfflineError(e)) {
        await _queueProfileUpdate(updatedData, e);
        _isLoading = false;
        notifyListeners();
        return {
          'success': true,
          'queued': true,
          'message': _lastProfileUpdateMessage,
        };
      }

      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  // ===== LOGOUT =====
  Future<Map<String, dynamic>> logout() async {
    _isLoading = true;
    notifyListeners();

    final token = await SessionStorage.getToken();

    await SessionStorage.clearSession();
    _resetSessionState();
    _isLoading = false;
    notifyListeners();

    if (token.isNotEmpty) {
      unawaited(_revokeServerSession(token));
    }

    return {'success': true, 'message': 'Logged out successfully'};
  }

  // ===== LOAD USER FROM STORAGE =====
  Future<void> loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = await SessionStorage.getToken();

    if (token.isNotEmpty) {
      _token = token;
      _isAuthenticated = true;

      // LOAD USER DARI STORAGE DULU
      final userJson = prefs.getString('user_data');
      if (userJson != null) {
        try {
          final userMap = jsonDecode(userJson);
          _user = User.fromMap(userMap);
          print('✅ Loaded user from storage: ${_user?.id} - ${_user?.name}');
        } catch (e) {
          print('❌ Error loading user from storage: $e');
        }
      }

      // LOAD COMPANY ASSIGNMENTS
      final companiesJson = prefs.getString('company_assignments');
      if (companiesJson != null) {
        try {
          final List companiesList = jsonDecode(companiesJson);
          _companyAssignments = companiesList.map<Company>((c) {
            return Company.fromMap(c as Map<String, dynamic>);
          }).toList();
        } catch (e) {
          print('❌ Error loading companies from storage: $e');
        }
      }

      // LOAD COMPANY CODE
      _companyCode =
          await SessionStorage.getCompanyCode(); // <-- LOAD COMPANY CODE

      // LOAD SELECTED COMPANY
      if (_companyCode != null &&
          _companyCode!.isNotEmpty &&
          _companyAssignments.isNotEmpty) {
        try {
          _selectedCompany = _companyAssignments.firstWhere(
            (c) => c.cCode == _companyCode,
          );
          print('✅ Loaded selected company: ${_selectedCompany?.cCode}');
        } catch (e) {
          print('❌ Selected company not found in assignments');
        }
      }

      // Coba ambil user info dari server untuk update
      final result = await getUserInfo();
      final statusCode = result['status_code'] as int?;
      if (result['success'] != true &&
          (statusCode == 401 || statusCode == 403)) {
        await SessionStorage.clearSession();
        _token = null;
        _user = null;
        _companyAssignments = [];
        _selectedCompany = null;
        _companyCode = null;
        _isAuthenticated = false;
      } else {
        await _syncOfflineProfileUpdates(silent: true);
      }
    }
    await _refreshPendingProfileSyncCount(notify: false);
    notifyListeners();
  }

  // ===== HELPER: CLEAR SELECTED COMPANY =====
  void clearSelectedCompany() {
    _selectedCompany = null;
    _companyCode = null; // <-- RESET COMPANY CODE
    notifyListeners();
  }

  // ===== HELPER: GET COMPANY CODE =====
  String getCompanyCode() {
    // Prioritaskan dari _companyCode
    if (_companyCode != null && _companyCode!.isNotEmpty) {
      return _companyCode!;
    }

    // Kedua dari selected company
    if (_selectedCompany != null && _selectedCompany!.cCode.isNotEmpty) {
      return _selectedCompany!.cCode;
    }

    // Ketiga dari user.selectedCCode
    if (_user != null && _user!.selectedCCode.isNotEmpty) {
      return _user!.selectedCCode;
    }

    // Keempat dari company assignments pertama
    if (_companyAssignments.isNotEmpty) {
      return _companyAssignments.first.cCode;
    }

    return '';
  }

  // ===== HELPER: GET EMPLOYEE ID =====
  int getEmployeeId() {
    return _user?.id ?? 0;
  }

  // ===== HELPER: GET EMPLOYEE UUID =====
  String getEmployeeUuid() {
    return _user?.employeeUuid ?? _user?.uuid ?? '';
  }

  bool hasPermission(String permission) {
    final normalized = _normalizeAccessKey(permission);
    if (normalized.isEmpty) {
      return true;
    }

    final permissionSet = _normalizedAccessSet(permissions);
    if (_hasFullAccess(permissionSet)) {
      return true;
    }

    return permissionSet.contains(normalized);
  }

  bool hasAnyPermission(Iterable<String> requiredPermissions) {
    final normalizedPermissions = requiredPermissions
        .map(_normalizeAccessKey)
        .where((permission) => permission.isNotEmpty);

    for (final permission in normalizedPermissions) {
      if (hasPermission(permission)) {
        return true;
      }
    }

    return false;
  }

  bool hasAllPermissions(Iterable<String> requiredPermissions) {
    final normalizedPermissions = requiredPermissions
        .map(_normalizeAccessKey)
        .where((permission) => permission.isNotEmpty)
        .toList(growable: false);

    if (normalizedPermissions.isEmpty) {
      return true;
    }

    return normalizedPermissions.every(hasPermission);
  }

  bool hasRole(String role) {
    final normalized = _normalizeAccessKey(role);
    if (normalized.isEmpty) {
      return false;
    }

    return _normalizedAccessSet(roles).contains(normalized);
  }

  bool hasAnyRole(Iterable<String> requiredRoles) {
    final normalizedRoles = requiredRoles
        .map(_normalizeAccessKey)
        .where((role) => role.isNotEmpty);

    for (final role in normalizedRoles) {
      if (hasRole(role)) {
        return true;
      }
    }

    return false;
  }

  bool get canAccessAdminPanel {
    return hasAnyPermission(_adminPermissions) || hasAnyRole(_adminRoles);
  }

  bool get canAccessEmployeeModule {
    return hasAnyPermission([
      'view-employee',
      'create-employee',
      'edit-employee',
      'delete-employee',
    ]);
  }

  bool get canViewAllEmployeeData {
    final normalizedRoles = {
      ..._normalizedAccessSet(roles),
      _normalizeAccessKey(_user?.role ?? ''),
    }..removeWhere((role) => role.isEmpty);

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

  bool get shouldUseSelfEmployeeScope {
    return !canViewAllEmployeeData;
  }

  bool get canViewEmployeeScreen {
    return canAccessEmployeeModule || shouldUseSelfEmployeeScope;
  }

  bool get canAccessEmployeeMasterModule {
    return hasAnyPermission([
      'create-employee',
      'edit-employee',
      'delete-employee',
    ]);
  }

  bool get canAccessDepartmentModule {
    return hasAnyPermission([
      'view-department',
      'create-department',
      'edit-department',
      'delete-department',
    ]);
  }

  bool get canAccessAttendanceModule {
    return hasAnyPermission([
      'view-attendance',
      'create-attendance',
      'edit-attendance',
    ]);
  }

  bool get canAccessLeaveModule {
    return hasAnyPermission(['view-leave', 'create-leave', 'edit-leave']);
  }

  bool get canAccessPayrollModule {
    return hasAnyPermission([
      'view-payroll',
      'create-payroll',
      'edit-payroll',
      'edit-payroll-settings',
    ]);
  }

  bool get canAccessClaimsModule {
    return canAccessPayrollModule || hasPermission('view-reports');
  }

  bool get canAccessPerformanceModule {
    return hasAnyPermission([
      'view-performance',
      'create-performance',
      'edit-performance',
      'view-kpi',
      'edit-kpi',
    ]);
  }

  bool get canAccessRecruitmentModule {
    return hasAnyPermission([
      'view-recruitment',
      'create-recruitment',
      'edit-recruitment',
    ]);
  }

  bool get canAccessClientModule {
    return hasAnyPermission([
      'view-client',
      'create-client',
      'edit-client',
      'delete-client',
    ]);
  }

  bool get canAccessDocumentsModule {
    return hasAnyPermission([
      'view-documents',
      'create-documents',
      'edit-documents',
      'delete-documents',
    ]);
  }

  bool get canAccessInventoryModule {
    return hasAnyPermission([
      'view-inventory',
      'view-inventory-master',
      'view-inventory-request',
      'view-inventory-receipt',
      'view-inventory-issued',
      'view-inventory-report',
      'approve-requests-stock',
      'manage-inventory',
      'issue-stock',
    ]);
  }

  bool get canAccessSettingsModule {
    return hasAnyPermission([
      'view-settings',
      'create-settings',
      'edit-settings',
    ]);
  }

  bool get canManageSettingsModule {
    return hasAnyPermission(['create-settings', 'edit-settings']);
  }

  bool get canAccessShiftAssignmentModule {
    return canManageSettingsModule;
  }

  bool get canAccessReportsModule {
    return hasAnyPermission(['view-reports', 'view-payroll']);
  }

  bool get canAccessCorrectionsModule {
    return canAccessAttendanceModule;
  }

  bool get canAccessLocationModule {
    return canAccessAttendanceModule;
  }

  Future<void> _queueProfileUpdate(
    Map<String, dynamic> updatedData,
    Object? error,
  ) async {
    await _applyLocalProfileUpdate(updatedData);
    await OfflineSupport.enqueueRequest(
      feature: 'profile',
      action: 'update_profile',
      endpoint: ApiConstants.updateProfileEndpoint,
      method: 'POST',
      payload: updatedData,
      employeeUuid: _user?.employeeUuid ?? _user?.uuid,
      lastError: error != null ? OfflineSupport.normalizeMessage(error) : null,
    );
    _lastProfileUpdateQueued = true;
    _lastProfileUpdateMessage =
        'Perubahan profil disimpan offline dan akan dikirim saat server online.';
    await _refreshPendingProfileSyncCount(notify: false);
  }

  Future<void> _applyLocalProfileUpdate(
    Map<String, dynamic> updatedData,
  ) async {
    final baseUser = _user?.toJson() ?? const <String, dynamic>{};
    final mergedUser = <String, dynamic>{...baseUser, ...updatedData};
    _user = User.fromMap(mergedUser);
    await SessionStorage.saveUserData(jsonEncode(mergedUser));
  }

  Future<void> _syncOfflineProfileUpdates({bool silent = false}) async {
    if (_isSyncingOfflineProfile) {
      return;
    }

    final token = await SessionStorage.getToken();
    if (token.isEmpty) {
      return;
    }

    _isSyncingOfflineProfile = true;
    if (!silent) {
      notifyListeners();
    }

    try {
      final currentEmployeeUuid = _user?.employeeUuid ?? _user?.uuid;
      final queuedRequests = await OfflineSupport.getQueuedRequests(
        feature: 'profile',
        employeeUuid: currentEmployeeUuid,
      );

      for (final item in queuedRequests) {
        final id = item['id'] as int?;
        if (id == null) {
          continue;
        }

        final payload = OfflineSupport.decodeQueuePayload(item);

        try {
          final response = await http
              .post(
                Uri.parse(
                  ApiConstants.baseUrl + ApiConstants.updateProfileEndpoint,
                ),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  'Authorization': 'Bearer $token',
                },
                body: jsonEncode(payload),
              )
              .timeout(const Duration(seconds: 15));

          final data = response.body.isNotEmpty
              ? jsonDecode(response.body) as Map<String, dynamic>
              : <String, dynamic>{};

          if (response.statusCode == 200 && data['success'] == true) {
            if (data['data'] is Map<String, dynamic>) {
              _user = User.fromMap(data['data']);
              await SessionStorage.saveUserData(jsonEncode(data['data']));
            }
            await OfflineSupport.deleteQueuedRequest(id);
            _lastProfileUpdateQueued = false;
            _lastProfileUpdateMessage =
                'Perubahan profil offline berhasil disinkronkan.';
          } else if (response.statusCode >= 400 && response.statusCode < 500) {
            await OfflineSupport.deleteQueuedRequest(id);
            _lastProfileUpdateQueued = false;
            _lastProfileUpdateMessage =
                data['message']?.toString() ??
                'Perubahan profil offline ditolak server dan dibatalkan.';
          } else {
            final retryCount =
                int.tryParse(item['retry_count']?.toString() ?? '0') ?? 0;
            await OfflineSupport.markQueuedRequestRetry(
              id,
              retryCount: retryCount + 1,
              lastError: data['message']?.toString(),
            );
            break;
          }
        } catch (error) {
          if (OfflineSupport.isLikelyOfflineError(error)) {
            final retryCount =
                int.tryParse(item['retry_count']?.toString() ?? '0') ?? 0;
            await OfflineSupport.markQueuedRequestRetry(
              id,
              retryCount: retryCount + 1,
              lastError: OfflineSupport.normalizeMessage(error),
            );
            break;
          }

          rethrow;
        }
      }
    } finally {
      _isSyncingOfflineProfile = false;
      await _refreshPendingProfileSyncCount(notify: false);
      if (!silent) {
        notifyListeners();
      }
    }
  }

  Future<void> _refreshPendingProfileSyncCount({bool notify = true}) async {
    final currentEmployeeUuid = _user?.employeeUuid ?? _user?.uuid;
    _pendingProfileSyncCount = await OfflineSupport.countQueuedRequests(
      feature: 'profile',
      employeeUuid: currentEmployeeUuid,
    );

    if (notify) {
      notifyListeners();
    }
  }

  void _resetSessionState() {
    _token = null;
    _user = null;
    _companyAssignments = [];
    _selectedCompany = null;
    _companyCode = null;
    _isAuthenticated = false;
    _isSyncingOfflineProfile = false;
    _pendingProfileSyncCount = 0;
    _lastProfileUpdateMessage = null;
    _lastProfileUpdateQueued = false;
  }

  Future<void> _revokeServerSession(String token) async {
    try {
      await http
          .post(
            Uri.parse(ApiConstants.baseUrl + ApiConstants.logoutEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Ignore best-effort logout failures on the server side.
    }
  }

  Set<String> _normalizedAccessSet(List<String> values) {
    return values
        .map(_normalizeAccessKey)
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  bool _hasFullAccess(Set<String> values) {
    return values.contains('*') ||
        values.contains('all') ||
        values.contains('admin');
  }

  String _normalizeAccessKey(String value) {
    return value.trim().toLowerCase();
  }
}
