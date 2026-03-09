import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/user.dart';
import '../models/company.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isAuthenticated = false;
  User? _user;
  String? _token;
  List<Company> _companyAssignments = [];
  Company? _selectedCompany;
  String? _companyCode; // <-- SUDAH BAIK

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  User? get user => _user;
  String? get token => _token;
  List<Company> get companyAssignments => _companyAssignments;
  Company? get selectedCompany => _selectedCompany;
  String? get companyCode => _companyCode; // <-- TAMBAHKAN GETTER

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
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // HAPUS SEMUA DATA LAMA SEBELUM SIMPAN YANG BARU
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // Simpan token
        _token = data['data']['token']?.toString() ?? '';
        await prefs.setString('token', _token!);

        // Simpan user
        final userMap = data['data']['user'] as Map<String, dynamic>? ?? {};
        _user = User.fromMap(userMap);

        // SIMPAN USER KE STORAGE
        await prefs.setString('user_data', jsonEncode(userMap));

        // Simpan company assignments
        final rawCompanies = data['data']['company_assignments'] as List<dynamic>? ?? [];
        _companyAssignments = rawCompanies.map<Company>((c) {
          return Company.fromMap(c as Map<String, dynamic>);
        }).toList();

        // SIMPAN COMPANY ASSIGNMENTS KE STORAGE
        await prefs.setString('company_assignments', jsonEncode(rawCompanies));

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
          await prefs.setString('company_code', companyCode);
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
          'message': data['message']?.toString() ?? 'Login failed'
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.setSelectedCompanyEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'company_id': companyId,
          'c_code': cCode
        }),
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
        await prefs.setString('company_code', cCode);

        _isLoading = false;
        notifyListeners();
        return {'success': true, 'data': data['data'] ?? {}};
      } else {
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to select company'
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.getUserInfoEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final userMap = data['data']['user'] as Map<String, dynamic>? ?? {};
        _user = User.fromMap(userMap);

        // UPDATE STORAGE
        await prefs.setString('user_data', jsonEncode(userMap));

        final rawCompanies = data['data']['company_assignments'] as List<dynamic>? ?? [];
        _companyAssignments = rawCompanies.map<Company>((c) {
          return Company.fromMap(c as Map<String, dynamic>);
        }).toList();

        // UPDATE STORAGE
        await prefs.setString('company_assignments', jsonEncode(rawCompanies));

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
          await prefs.setString('company_code', userMap['selected_c_code']);
        }

        _isLoading = false;
        notifyListeners();
        return {'success': true, 'data': data['data']};
      } else {
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get user info'
        };
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  // ===== CHANGE PASSWORD =====
  Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.changePasswordEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'current_password': oldPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPassword
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      _isLoading = false;
      notifyListeners();

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? (response.statusCode == 200 ? 'Password changed successfully' : 'Failed to change password')
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  // ===== UPDATE PROFILE =====
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> updatedData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.updateProfileEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(updatedData),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (data['data'] != null) {
          _user = User.fromMap(data['data']);
          // UPDATE STORAGE
          await prefs.setString('user_data', jsonEncode(data['data']));
        }
        _isLoading = false;
        notifyListeners();
        return {'success': true, 'message': data['message'] ?? 'Profile updated successfully'};
      } else {
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update profile'
        };
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  // ===== LOGOUT =====
  Future<Map<String, dynamic>> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isNotEmpty) {
        await http.post(
          Uri.parse(ApiConstants.baseUrl + ApiConstants.logoutEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token'
          },
        );
      }
    } catch (e) {
      // Abaikan error logout
    } finally {
      await SharedPreferences.getInstance().then((prefs) => prefs.clear());
      _token = null;
      _user = null;
      _companyAssignments = [];
      _selectedCompany = null;
      _companyCode = null; // <-- RESET COMPANY CODE
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
    }

    return {'success': true, 'message': 'Logged out successfully'};
  }

  // ===== LOAD USER FROM STORAGE =====
  Future<void> loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

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
      _companyCode = prefs.getString('company_code'); // <-- LOAD COMPANY CODE

      // LOAD SELECTED COMPANY
      if (_companyCode != null && _companyCode!.isNotEmpty && _companyAssignments.isNotEmpty) {
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
      await getUserInfo();
    }
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
}