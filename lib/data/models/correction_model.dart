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
  final bool isPendingSync;

  AttendanceData({
    this.id,
    required this.employeeUuid,
    this.clockIn,
    this.clockOut,
    this.status,
    required this.date,
    required this.exists,
    this.employee,
    this.isPendingSync = false,
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
      isPendingSync: json['is_pending_sync'] == true,
    );
  }

  AttendanceData copyWith({
    int? id,
    String? employeeUuid,
    String? clockIn,
    String? clockOut,
    String? status,
    String? date,
    bool? exists,
    Map<String, dynamic>? employee,
    bool? isPendingSync,
  }) {
    return AttendanceData(
      id: id ?? this.id,
      employeeUuid: employeeUuid ?? this.employeeUuid,
      clockIn: clockIn ?? this.clockIn,
      clockOut: clockOut ?? this.clockOut,
      status: status ?? this.status,
      date: date ?? this.date,
      exists: exists ?? this.exists,
      employee: employee ?? this.employee,
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_uuid': employeeUuid,
      'clock_in': clockIn,
      'clock_out': clockOut,
      'status': status,
      'date': date,
      'exists': exists,
      'employee': employee,
      'is_pending_sync': isPendingSync,
    };
  }
}
