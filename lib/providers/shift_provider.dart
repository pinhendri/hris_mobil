import 'package:flutter/material.dart';
import '../models/shift_model.dart';
import '../models/shift_day_model.dart';
import '../models/shift_assignment_model.dart';
import '../services/api_service.dart';
import '../services/offline_support.dart';

class ShiftProvider with ChangeNotifier {
  List<Shift> _shifts = [];
  List<ShiftAssignment> _orders = [];
  bool _isLoading = false;
  String? _error;
  bool _isUsingCachedData = false;

  List<Shift> get shifts => _shifts;
  List<ShiftAssignment> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isUsingCachedData => _isUsingCachedData;
  int get totalShifts => _shifts.length;

  final ApiService _apiService = ApiService();

  // ===== SHIFT METHODS =====

  // Fetch shift days by shift ID
  Future<List<ShiftDay>> fetchShiftDays(String shiftId) async {
    try {
      print('🔄 Fetching shift days for shift: $shiftId');

      final response = await _apiService.get('/shift-days/by-shift/$shiftId');

      print('📥 Shift days response: $response');

      if (response is Map<String, dynamic>) {
        final success = response['success'] ?? false;
        final data = response['data'];

        if (success == true && data is Map) {
          final shiftDaysData = data['shift_days'];
          if (shiftDaysData is List) {
            return shiftDaysData.map<ShiftDay>((json) {
              if (json is Map<String, dynamic>) {
                return ShiftDay(
                  id: json['id']?.toString() ?? '',
                  shiftId: json['shift_id']?.toString() ?? shiftId,
                  dayOfWeek: _getDayNumber(json['day_of_week']),
                  dayOfWeekString: json['day_of_week'] ?? 'Mon',
                  clockIn: json['clock_in'] ?? '08:00',
                  clockOut: json['clock_out'] ?? '17:00',
                  breakMinutes: json['break_minutes'] ?? 60,
                );
              }
              return ShiftDay(
                id: '',
                shiftId: shiftId,
                dayOfWeek: 1,
                dayOfWeekString: 'Mon',
                clockIn: '08:00',
                clockOut: '17:00',
                breakMinutes: 60,
              );
            }).toList();
          }
        }
      }

      return [];
    } catch (e) {
      print('❌ Error fetching shift days: $e');
      return [];
    }
  }

  // Helper to convert day string to number
  int _getDayNumber(String? dayString) {
    switch (dayString) {
      case 'Mon':
        return 1;
      case 'Tue':
        return 2;
      case 'Wed':
        return 3;
      case 'Thu':
        return 4;
      case 'Fri':
        return 5;
      case 'Sat':
        return 6;
      case 'Sun':
        return 7;
      default:
        return 1;
    }
  }

  // Fetch all shifts from /api/shifts endpoint
  Future<void> fetchShifts() async {
    _isLoading = true;
    _error = null;
    _isUsingCachedData = false;
    notifyListeners();

    try {
      print('🔄 Fetching shifts from API...');

      final response = await _apiService.get('/shifts');

      print('📥 Raw API Response: $response');

      if (response is Map<String, dynamic>) {
        final success = response['success'] ?? false;
        final message = response['message'] ?? 'No message';
        final data = response['data'];

        if (success == true) {
          List<dynamic> items = [];

          // Handle paginated response
          if (data is Map && data.containsKey('data')) {
            print('📥 Data is paginated response');
            items = data['data'] as List? ?? [];
          }
          // Handle direct array response
          else if (data is List) {
            print('📥 Data is direct List with length: ${data.length}');
            items = data;
          }

          // Parse shifts without days first
          final shiftsWithoutDays = _parseShiftList(items);

          // Then fetch shift days for each shift
          List<Shift> shiftsWithDays = [];
          for (var shift in shiftsWithoutDays) {
            final shiftDays = await fetchShiftDays(shift.id);
            shiftsWithDays.add(shift.copyWith(shiftDays: shiftDays));
          }

          _shifts = shiftsWithDays;
          await OfflineSupport.saveJsonCache(
            _cacheKey,
            _shifts.map((shift) => shift.toJson()).toList(),
          );
        } else {
          final loadedFromCache = await _loadCachedShifts();
          if (!loadedFromCache) {
            _error = message;
            _shifts = [];
          }
          print('❌ API Error: $message');
        }
      } else {
        print('❌ Response is not a Map. Type: ${response.runtimeType}');
        final loadedFromCache = await _loadCachedShifts();
        if (!loadedFromCache) {
          _error = 'Invalid response format';
          _shifts = [];
        }
      }
    } catch (e) {
      print('❌ Error fetching shifts: $e');
      final loadedFromCache = await _loadCachedShifts();
      if (!loadedFromCache) {
        _error = e.toString();
        _shifts = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
      print('✅ fetchShifts completed. _shifts length: ${_shifts.length}');
    }
  }

  // Fetch single shift by ID with its days
  Future<Shift?> fetchShiftById(String id) async {
    try {
      print('🔄 Fetching shift by ID: $id');

      final response = await _apiService.get('/shifts/$id');

      if (response is Map<String, dynamic>) {
        final success = response['success'] ?? false;
        final data = response['data'];

        if (success == true && data is Map<String, dynamic>) {
          // Parse shift days if included
          List<ShiftDay> shiftDays = [];
          if (data['shift_days'] != null && data['shift_days'] is List) {
            shiftDays = (data['shift_days'] as List).map((dayJson) {
              return ShiftDay(
                id: dayJson['id']?.toString() ?? '',
                shiftId: dayJson['shift_id']?.toString() ?? id,
                dayOfWeek: _getDayNumber(dayJson['day_of_week']),
                dayOfWeekString: dayJson['day_of_week'] ?? 'Mon',
                clockIn: dayJson['clock_in'] ?? '08:00',
                clockOut: dayJson['clock_out'] ?? '17:00',
                breakMinutes: dayJson['break_minutes'] ?? 60,
              );
            }).toList();
          } else {
            // If not included, fetch separately
            shiftDays = await fetchShiftDays(id);
          }

          return Shift(
            id: data['id']?.toString() ?? '',
            name: data['name']?.toString() ?? '',
            description: data['description']?.toString() ?? '',
            startTime: data['clock_in']?.toString() ?? '',
            endTime: data['clock_out']?.toString() ?? '',
            breakMinutes: data['break_minutes'] ?? 60,
            graceClockIn: data['grace_clock_in'] ?? 0,
            graceClockOut: data['grace_clock_out'] ?? 0,
            isNightShift: data['is_night_shift'] ?? false,
            isFlexible: data['is_flexible'] ?? false,
            isActive: data['is_active'] ?? true,
            shiftDays: shiftDays,
          );
        }
      }

      return null;
    } catch (e) {
      print('❌ Error fetching shift by ID: $e');
      return null;
    }
  }

  // Helper method to parse shift list
  List<Shift> _parseShiftList(List<dynamic> items) {
    if (items.isEmpty) {
      print('⚠️ Data list is empty');
      return [];
    }

    print('📥 First item sample: ${items.first}');
    print(
      '📥 First item keys: ${items.first is Map ? (items.first as Map).keys : 'Not a Map'}',
    );

    final shifts = items.map<Shift>((json) {
      print('📥 Processing item: $json');

      if (json is Map<String, dynamic>) {
        final id = json['id']?.toString() ?? '';
        final name = json['name']?.toString() ?? '';
        final description = json['description']?.toString() ?? '';
        final clockIn = json['clock_in']?.toString() ?? '';
        final clockOut = json['clock_out']?.toString() ?? '';
        final breakMinutes = json['break_minutes'] ?? 60;

        print(
          '📥 Parsed - id: $id, name: $name, description: $description, clockIn: $clockIn, clockOut: $clockOut',
        );

        return Shift(
          id: id,
          name: name,
          description: description,
          startTime: clockIn,
          endTime: clockOut,
          breakMinutes: breakMinutes is int ? breakMinutes : 60,
          graceClockIn: json['grace_clock_in'] ?? 0,
          graceClockOut: json['grace_clock_out'] ?? 0,
          isNightShift: json['is_night_shift'] ?? false,
          isFlexible: json['is_flexible'] ?? false,
          isActive: json['is_active'] ?? true,
          shiftDays: [], // Akan diisi nanti
        );
      } else {
        print('❌ Item is not a Map: $json');
        return Shift(
          id: '',
          name: '',
          description: '',
          startTime: '',
          endTime: '',
          breakMinutes: 60,
          graceClockIn: 0,
          graceClockOut: 0,
          isNightShift: false,
          isFlexible: false,
          isActive: false,
          shiftDays: [],
        );
      }
    }).toList();

    final validShifts = shifts.where((shift) => shift.id.isNotEmpty).toList();

    print('✅ Successfully converted ${validShifts.length} shifts');

    for (var i = 0; i < validShifts.length; i++) {
      final shift = validShifts[i];
      print(
        '📋 Shift $i: id=${shift.id}, name=${shift.name}, start=${shift.startTime}, end=${shift.endTime}',
      );
    }

    return validShifts;
  }

  // Get shift by ID
  Shift? getShiftById(String id) {
    try {
      return _shifts.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  // Add new shift
  Future<bool> addShift(Shift shift) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Simpan shift utama
      final Map<String, dynamic> shiftData = {
        'name': shift.name,
        'description': shift.description,
        'grace_clock_in': shift.graceClockIn,
        'grace_clock_out': shift.graceClockOut,
        'break_minutes': shift.breakMinutes,
        'is_night_shift': shift.isNightShift,
        'is_flexible': shift.isFlexible,
        'is_active': shift.isActive,
      };

      print('📤 Adding shift with data: $shiftData');

      final shiftResponse = await _apiService.post('/shifts', shiftData);

      print('📥 Add shift response: $shiftResponse');

      if (shiftResponse is Map && shiftResponse['success'] == true) {
        final newShiftId = shiftResponse['data']['id'].toString();

        // 2. Simpan shift days jika ada
        if (shift.shiftDays.isNotEmpty) {
          final List<Map<String, dynamic>> daysData = shift.shiftDays.map((
            day,
          ) {
            // PERBAIKAN: Format waktu tanpa detik
            String clockIn = day.clockIn;
            String clockOut = day.clockOut;

            // Jika waktu mengandung detik (format HH:mm:ss), potong detiknya
            if (clockIn.length > 5 && clockIn.contains(':')) {
              clockIn = clockIn.substring(0, 5);
            }
            if (clockOut.length > 5 && clockOut.contains(':')) {
              clockOut = clockOut.substring(0, 5);
            }

            return {
              'shift_id': newShiftId,
              'day_of_week': day.dayOfWeekString,
              'clock_in': clockIn, // Format HH:mm
              'clock_out': clockOut, // Format HH:mm
              'break_minutes': day.breakMinutes,
            };
          }).toList();

          print('📤 Adding shift days with data: $daysData');

          final daysResponse = await _apiService.post(
            '/shift-days/bulk-update',
            {'shift_id': newShiftId, 'days': daysData},
          );

          print('📥 Add shift days response: $daysResponse');

          // Cek jika ada error validasi
          if (daysResponse is Map && daysResponse['success'] == false) {
            print('❌ Bulk update failed: ${daysResponse['errors']}');
            _error = daysResponse['message'] ?? 'Failed to add shift days';
            return false;
          }
        }

        await fetchShifts(); // Refresh list
        return true;
      } else {
        _error = shiftResponse['message'] ?? 'Failed to add shift';
        return false;
      }
    } catch (e) {
      print('❌ Error adding shift: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update shift
  Future<bool> updateShift(Shift shift) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Update shift utama
      final Map<String, dynamic> shiftData = {
        'name': shift.name,
        'description': shift.description,
        'grace_clock_in': shift.graceClockIn,
        'grace_clock_out': shift.graceClockOut,
        'break_minutes': shift.breakMinutes,
        'is_night_shift': shift.isNightShift,
        'is_flexible': shift.isFlexible,
        'is_active': shift.isActive,
      };

      print('📤 Updating shift ${shift.id} with data: $shiftData');

      final shiftResponse = await _apiService.put(
        '/shifts/${shift.id}',
        shiftData,
      );

      print('📥 Update shift response: $shiftResponse');

      if (shiftResponse is Map && shiftResponse['success'] == true) {
        // 2. Update shift days menggunakan bulk update
        if (shift.shiftDays.isNotEmpty) {
          final List<Map<String, dynamic>> daysData = shift.shiftDays.map((
            day,
          ) {
            // PERBAIKAN: Format waktu tanpa detik
            String clockIn = day.clockIn;
            String clockOut = day.clockOut;

            // Jika waktu mengandung detik (format HH:mm:ss), potong detiknya
            if (clockIn.length > 5 && clockIn.contains(':')) {
              clockIn = clockIn.substring(0, 5); // Ambil hanya HH:mm
            }
            if (clockOut.length > 5 && clockOut.contains(':')) {
              clockOut = clockOut.substring(0, 5); // Ambil hanya HH:mm
            }

            return {
              'shift_id': shift.id,
              'day_of_week': day.dayOfWeekString,
              'clock_in': clockIn, // Format HH:mm
              'clock_out': clockOut, // Format HH:mm
              'break_minutes': day.breakMinutes,
            };
          }).toList();

          print('📤 Updating shift days with data: $daysData');

          final daysResponse = await _apiService.post(
            '/shift-days/bulk-update',
            {'shift_id': shift.id, 'days': daysData},
          );

          print('📥 Update shift days response: $daysResponse');

          // Cek jika ada error validasi
          if (daysResponse is Map && daysResponse['success'] == false) {
            print('❌ Bulk update failed: ${daysResponse['errors']}');
            _error = daysResponse['message'] ?? 'Failed to update shift days';
            return false;
          }
        } else {
          // Jika tidak ada shift days, hapus semua yang ada dengan bulk update kosong
          print('📤 No shift days, deleting all for shift ${shift.id}');
          final deleteResponse = await _apiService.post(
            '/shift-days/bulk-update',
            {
              'shift_id': shift.id,
              'days': [], // Kirim array kosong untuk menghapus semua
            },
          );
          print('📥 Delete shift days response: $deleteResponse');
        }

        await fetchShifts(); // Refresh list
        return true;
      } else {
        _error = shiftResponse['message'] ?? 'Failed to update shift';
        return false;
      }
    } catch (e) {
      print('❌ Error updating shift: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete shift
  Future<bool> deleteShift(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📤 Deleting shift with id: $id');

      // Cek apakah shift memiliki shift days
      final shiftDays = await fetchShiftDays(id);
      if (shiftDays.isNotEmpty) {
        print(
          '📤 Shift has ${shiftDays.length} shift days, they will be deleted automatically by backend',
        );
      }

      final response = await _apiService.delete('/shifts/$id');

      print('📥 Delete shift response: $response');

      if (response is Map && response['success'] == true) {
        _shifts.removeWhere((s) => s.id == id);
        return true;
      } else {
        _error = response['message'] ?? 'Failed to delete shift';
        return false;
      }
    } catch (e) {
      print('❌ Error deleting shift: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete single shift day
  Future<bool> deleteShiftDay(String shiftId, String shiftDayId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📤 Deleting shift day with id: $shiftDayId for shift: $shiftId');

      final response = await _apiService.delete('/shift-days/$shiftDayId');

      print('📥 Delete shift day response: $response');

      if (response is Map && response['success'] == true) {
        // Update local data
        final shiftIndex = _shifts.indexWhere((s) => s.id == shiftId);
        if (shiftIndex != -1) {
          final updatedShift = _shifts[shiftIndex].copyWith(
            shiftDays: _shifts[shiftIndex].shiftDays
                .where((d) => d.id != shiftDayId)
                .toList(),
          );
          _shifts[shiftIndex] = updatedShift;
        }
        return true;
      } else {
        _error = response['message'] ?? 'Failed to delete shift day';
        return false;
      }
    } catch (e) {
      print('❌ Error deleting shift day: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get active shifts (for dropdown)
  Future<List<Shift>> getActiveShifts() async {
    try {
      print('🔄 Fetching active shifts...');

      final response = await _apiService.get('/shifts/active');

      if (response is Map<String, dynamic>) {
        final success = response['success'] ?? false;
        final data = response['data'];

        if (success == true && data is List) {
          return data.map<Shift>((json) {
            if (json is Map<String, dynamic>) {
              return Shift(
                id: json['id']?.toString() ?? '',
                name: json['name']?.toString() ?? '',
                description: json['description']?.toString() ?? '',
                startTime: '',
                endTime: '',
                breakMinutes: 0,
                graceClockIn: 0,
                graceClockOut: 0,
                isNightShift: false,
                isFlexible: false,
                isActive: true,
                shiftDays: [],
              );
            }
            return Shift(
              id: '',
              name: '',
              description: '',
              startTime: '',
              endTime: '',
              breakMinutes: 0,
              graceClockIn: 0,
              graceClockOut: 0,
              isNightShift: false,
              isFlexible: false,
              isActive: false,
              shiftDays: [],
            );
          }).toList();
        }
      }

      return [];
    } catch (e) {
      print('❌ Error fetching active shifts: $e');
      return [];
    }
  }

  // ===== SHIFT ASSIGNMENT METHODS =====

  // Fetch all shift assignments (orders)
  Future<void> fetchShiftAssignments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement when backend ready
      // final response = await _apiService.get('/shift-assignments');

      // For now, use local data
      _orders = [];

      print('✅ Loaded ${_orders.length} shift assignments');
    } catch (e) {
      print('❌ Error fetching shift assignments: $e');
      _error = e.toString();
      _orders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Assign shift to employee
  Future<bool> assignShiftToEmployee(String employeeId, String shiftId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement when backend ready
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      print('❌ Error assigning shift: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Assign shift to department
  Future<bool> assignShiftToDepartment(
    String departmentId,
    String shiftId,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement when backend ready
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      print('❌ Error assigning shift to department: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get assigned shift for employee
  Future<Shift?> getAssignedShiftForEmployee(String employeeId) async {
    try {
      // TODO: Implement when backend ready
      return null;
    } catch (e) {
      print('❌ Error getting assigned shift for employee: $e');
      return null;
    }
  }

  // Get assigned shift for department
  Future<Shift?> getAssignedShiftForDepartment(String departmentId) async {
    try {
      // TODO: Implement when backend ready
      return null;
    } catch (e) {
      print('❌ Error getting assigned shift for department: $e');
      return null;
    }
  }

  // Clear employee assignment
  Future<bool> clearEmployeeAssignment(String employeeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement when backend ready
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      print('❌ Error clearing employee assignment: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear department assignment
  Future<bool> clearDepartmentAssignment(String departmentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement when backend ready
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      print('❌ Error clearing department assignment: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add shift order (bulk assignment)
  Future<bool> addShiftOrder({
    required String shiftId,
    required List<String> employeeIds,
    required List<String> departmentIds,
    required DateTime startDate,
    DateTime? endDate,
    bool active = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement when backend ready
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      print('❌ Error creating shift order: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete shift order
  Future<bool> deleteShiftOrder(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement when backend ready
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      print('❌ Error deleting shift order: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle shift order active status
  Future<bool> toggleShiftOrderActive(String id, bool value) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement when backend ready
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      print('❌ Error toggling shift order: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get active shift for employee
  Future<Shift?> getShiftFor(String? employeeId, String? departmentId) async {
    if (employeeId == null && departmentId == null) return null;

    try {
      if (_shifts.isNotEmpty) {
        return _shifts.first;
      }
      return null;
    } catch (e) {
      print('❌ Error getting shift for employee/department: $e');
      return null;
    }
  }

  // Refresh all data
  Future<void> refreshData() async {
    await fetchShifts();
    await fetchShiftAssignments();
  }

  // Clear all data
  void clear() {
    _shifts = [];
    _orders = [];
    _error = null;
    _isUsingCachedData = false;
    notifyListeners();
  }

  String get _cacheKey => 'shifts::master';

  Future<bool> _loadCachedShifts() async {
    final cached = await OfflineSupport.getJsonCache(_cacheKey);
    if (cached is! List) {
      return false;
    }

    _shifts = cached
        .whereType<Map>()
        .map((item) => Shift.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    _error = null;
    _isUsingCachedData = true;
    return true;
  }
}
