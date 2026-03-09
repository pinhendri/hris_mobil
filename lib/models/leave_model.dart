class LeaveRequest {
  final String id;
  final String uuid;
  final String employeeName;
  final String employeeAvatar;
  final String? immediateSupervisor; // UUID dari atasan - PENTING UNTUK APPROVE/REJECT
  final String type;
  final String startDate;
  final String endDate;
  final int days;
  final String status;
  final String? avatarUrl; 
  final String reason;
  final String createdAt;

  LeaveRequest({
    required this.id,
    required this.uuid,
    required this.employeeName,
    required this.employeeAvatar,
    this.immediateSupervisor, // TAMBAHKAN FIELD INI
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.status,
     this.avatarUrl,
    required this.reason,
    required this.createdAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'] ?? {};

    // Log untuk debugging
    print('📦 Parsing LeaveRequest:');
    print('  - immediate_supervisor from json: ${json['immediate_supervisor']}');
    print('  - from employee: ${employee['immediate_supervisor']}');

    return LeaveRequest(
      id: json['id']?.toString() ?? '',
      uuid: json['uuid'] ?? '',
      employeeName: employee['name'] ?? json['employee_name'] ?? 'Unknown',
      employeeAvatar: employee['avatar'] ?? json['employee_avatar'] ?? '',
      // 🔴 AMBIL immediate_supervisor DARI RESPONSE - PENTING UNTUK LOGIC APPROVE/REJECT
      immediateSupervisor: json['immediate_supervisor'] ?? employee['immediate_supervisor'],
      type: json['type'] ?? 'Annual Leave',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      days: json['days'] ?? 0,
      status: json['status'] ?? 'Pending',
      avatarUrl: json['avatar_url'],
      reason: json['reason'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class LeaveBalance {
  final int annualUsed;
  final int annualTotal;
  final int sickUsed;
  final int sickTotal;
  final int personalUsed;
  final int personalTotal;

  LeaveBalance({
    required this.annualUsed,
    required this.annualTotal,
    required this.sickUsed,
    required this.sickTotal,
    required this.personalUsed,
    required this.personalTotal,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    print('📦 Parsing LeaveBalance from JSON: $json');

    // 🔴 PERBAIKAN: Sesuaikan dengan struktur response dari API
    // API mengembalikan format: {annual_used: 0, annual_total: 12, ...}
    // BUKAN format nested {annual: {used: 0, total: 12}}

    return LeaveBalance(
      annualUsed: json['annual_used'] ?? 0,
      annualTotal: json['annual_total'] ?? 12,
      sickUsed: json['sick_used'] ?? 0,
      sickTotal: json['sick_total'] ?? 14,
      personalUsed: json['personal_used'] ?? 0,
      personalTotal: json['personal_total'] ?? 3,
    );
  }
}