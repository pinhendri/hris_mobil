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
    final employeeData = json['employee'] as Map<String, dynamic>?;

    // Handle jika dari endpoint lain yang langsung punya field employee_xxx
    final employeeUuid =
        employeeData?['uuid'] ?? json['employee_uuid'] as String?;

    final employeeName = employeeData?['name'] as String?;
    final employeePosition = employeeData?['position'] as String?;
    final employeeNik = employeeData?['nik_employee'] as String?;

    return Attendance(
      uuid: json['uuid'] as String?,
      employeeUuid: employeeUuid,
      employeeName: employeeName,
      employeePosition: employeePosition,
      employeeNik: employeeNik,
      date: json['date'] ?? DateTime.now().toIso8601String().split('T')[0],
      clockIn: json['clock_in'] as String?,
      clockOut: json['clock_out'] as String?,
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
  bool get hasClockIn => clockIn != null && clockIn!.isNotEmpty;
  bool get hasClockOut => clockOut != null && clockOut!.isNotEmpty;

  String get clockInTimeFormatted {
    if (!hasClockIn) return '-';
    try {
      // Format: HH:mm:ss atau HH:mm
      if (clockIn!.contains(':')) {
        final parts = clockIn!.split(':');
        if (parts.length >= 2) {
          return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
        }
      }
      return clockIn!;
    } catch (e) {
      return clockIn!.substring(0, clockIn!.length > 5 ? 5 : clockIn!.length);
    }
  }

  String get clockOutTimeFormatted {
    if (!hasClockOut) return '-';
    try {
      if (clockOut!.contains(':')) {
        final parts = clockOut!.split(':');
        if (parts.length >= 2) {
          return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
        }
      }
      return clockOut!;
    } catch (e) {
      return clockOut!.substring(
        0,
        clockOut!.length > 5 ? 5 : clockOut!.length,
      );
    }
  }

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
}
