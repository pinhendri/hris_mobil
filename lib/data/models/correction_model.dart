class CorrectionRequest {
  final String id;
  final String type;
  final String description;
  final String status;
  final DateTime? targetDate;
  final String employeeId;
  final Map<String, dynamic>? details;

  CorrectionRequest({
    required this.id,
    required this.type,
    required this.description,
    required this.status,
    this.targetDate,
    required this.employeeId,
    this.details,
  });
}

class AttendanceData {
  final int? id;
  final String employeeUuid;
  final String? clockIn;
  final String? clockOut;
  final String? status;
  final String date;
  final bool exists;
  final Map<String, dynamic>? employee;

  AttendanceData({
    this.id,
    required this.employeeUuid,
    this.clockIn,
    this.clockOut,
    this.status,
    required this.date,
    required this.exists,
    this.employee,
  });

  factory AttendanceData.fromJson(Map<String, dynamic> json) {
    return AttendanceData(
      id: json['id'],
      employeeUuid: json['employee_uuid'] ?? '',
      clockIn: json['clock_in'],
      clockOut: json['clock_out'],
      status: json['status'],
      date: json['date'] ?? '',
      exists: json['exists'] ?? false,
      employee: json['employee'],
    );
  }
}