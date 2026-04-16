// lib/data/models/attendance_model.dart
import 'package:flutter/material.dart';

class Attendance {
  final String? uuid;
  final String? employeeUuid;
  final String? employeeName;
  final String? employeePosition;
  final String? employeeNik;
  final String date;
  final String? clockIn;
  final String? clockOut;
  final String? clockInPhoto;
  final String? clockInLocation;
  final String? clockOutPhoto;
  final String? clockOutLocation;
  final String? cCode;
  final Map<String, dynamic>? employee;
  final bool isPendingSync;

  Attendance({
    this.uuid,
    this.employeeUuid,
    this.employeeName,
    this.employeePosition,
    this.employeeNik,
    required this.date,
    this.clockIn,
    this.clockOut,
    this.clockInPhoto,
    this.clockInLocation,
    this.clockOutPhoto,
    this.clockOutLocation,
    this.cCode,
    this.employee,
    this.isPendingSync = false,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    // Handle nested employee object (dari endpoint index)
    final employeeRaw = json['employee'];
    final employeeData = employeeRaw is Map
        ? Map<String, dynamic>.from(employeeRaw)
        : null;

    // Handle jika dari endpoint lain yang langsung punya field employee_xxx
    final employeeUuid =
        employeeData?['uuid']?.toString() ??
        employeeData?['employee_uuid']?.toString() ??
        json['employee_uuid']?.toString() ??
        json['employeeUuid']?.toString();

    final employeeName =
        employeeData?['name']?.toString() ??
        json['employee_name']?.toString() ??
        json['name']?.toString();
    final employeePosition =
        employeeData?['position']?.toString() ??
        json['employee_position']?.toString() ??
        json['position']?.toString();
    final employeeNik =
        employeeData?['nik_employee']?.toString() ??
        json['employee_nik']?.toString() ??
        json['nik_employee']?.toString();

    return Attendance(
      uuid: json['uuid'] as String?,
      employeeUuid: employeeUuid,
      employeeName: employeeName,
      employeePosition: employeePosition,
      employeeNik: employeeNik,
      date: _normalizeDate(
        json['date']?.toString() ?? json['attendance_date']?.toString(),
      ),
      clockIn:
          json['clock_in']?.toString() ??
          json['clock_in_time']?.toString() ??
          json['check_in']?.toString(),
      clockOut:
          json['clock_out']?.toString() ??
          json['clock_out_time']?.toString() ??
          json['check_out']?.toString(),
      clockInPhoto: json['clock_in_photo'] as String?,
      clockInLocation: json['clock_in_location'] as String?,
      clockOutPhoto: json['clock_out_photo'] as String?,
      clockOutLocation: json['clock_out_location'] as String?,
      cCode: json['c_code'] as String?,
      employee: employeeData,
      isPendingSync:
          json['is_pending_sync'] == true || json['sync_status'] == 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'employee_uuid': employeeUuid,
      'employee': employee,
      'date': date,
      'clock_in': clockIn,
      'clock_out': clockOut,
      'clock_in_photo': clockInPhoto,
      'clock_in_location': clockInLocation,
      'clock_out_photo': clockOutPhoto,
      'clock_out_location': clockOutLocation,
      'c_code': cCode,
      'is_pending_sync': isPendingSync,
    };
  }

  // Helper methods
  bool get hasClockIn => _hasMeaningfulTime(clockIn);
  bool get hasClockOut => _hasMeaningfulTime(clockOut);

  String get clockInTimeFormatted => _formatDisplayTime(clockIn);

  String get clockOutTimeFormatted => _formatDisplayTime(clockOut);

  String get status {
    if (isPendingSync) return 'Pending Sync';
    if (hasClockIn && hasClockOut) return 'Completed';
    if (hasClockIn) return 'Checked In';
    return 'Absent';
  }

  Color get statusColor {
    if (isPendingSync) {
      return Colors.orange;
    }

    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Checked In':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String get statusBadge {
    if (isPendingSync) return 'Pending Sync';
    if (hasClockIn && hasClockOut) return 'Complete';
    if (hasClockIn) return 'Active';
    return 'Missed';
  }

  bool _hasMeaningfulTime(String? value) {
    final normalized = value?.trim() ?? '';
    return normalized.isNotEmpty &&
        normalized != '00:00:00' &&
        normalized != '00:00';
  }

  static String _normalizeDate(String? rawValue) {
    final normalized = rawValue?.trim() ?? '';
    if (normalized.isEmpty) {
      return DateTime.now().toIso8601String().split('T')[0];
    }

    final parsed = DateTime.tryParse(normalized);
    if (parsed != null) {
      return parsed.toIso8601String().split('T')[0];
    }

    final match = RegExp(r'^(\d{4}-\d{2}-\d{2})').firstMatch(normalized);
    if (match != null) {
      return match.group(1) ?? normalized;
    }

    return normalized;
  }

  String _formatDisplayTime(String? value) {
    final normalized = value?.trim() ?? '';
    if (!_hasMeaningfulTime(normalized)) {
      return '-';
    }

    final parsedDateTime = DateTime.tryParse(normalized);
    if (parsedDateTime != null) {
      final hour = parsedDateTime.hour.toString().padLeft(2, '0');
      final minute = parsedDateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    final timeMatch = RegExp(r'(\d{1,2}):(\d{2})(?::\d{2})?$').firstMatch(
      normalized,
    );
    if (timeMatch != null) {
      final hour = timeMatch.group(1)!.padLeft(2, '0');
      final minute = timeMatch.group(2)!;
      return '$hour:$minute';
    }

    return normalized.length > 5 ? normalized.substring(0, 5) : normalized;
  }
}
