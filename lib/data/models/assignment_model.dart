class EmployeeAssignment {
  final String uuid;
  final String name;
  final String? shiftDate;
  final String? role;
  final String? cCode;

  EmployeeAssignment({
    required this.uuid,
    required this.name,
    this.shiftDate,
    this.role,
    this.cCode,
  });

  factory EmployeeAssignment.fromJson(Map<String, dynamic> json) {
    return EmployeeAssignment(
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? '',
      shiftDate: json['shift_date'],
      role: json['role'],
      cCode: json['c_code'],
    );
  }
}

class AvailableEmployee {
  final String uuid;
  final String name;
  final String? position;
  final String? status;

  AvailableEmployee({
    required this.uuid,
    required this.name,
    this.position,
    this.status,
  });

  factory AvailableEmployee.fromJson(Map<String, dynamic> json) {
    return AvailableEmployee(
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? '',
      position: json['position'],
      status: json['status'],
    );
  }
}