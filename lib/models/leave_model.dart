class LeaveRequest {
  final String id;
  final String uuid;
  final String employeeName;
  final String employeeAvatar;
  final String?
  immediateSupervisor; // UUID dari atasan - PENTING UNTUK APPROVE/REJECT
  final String type;
  final String startDate;
  final String endDate;
  final int days;
  final String status;
  final String? avatarUrl;
  final String reason;
  final String createdAt;
  final bool isPendingSync;

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
    this.isPendingSync = false,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'] ?? {};

    // Log untuk debugging
    print('📦 Parsing LeaveRequest:');
    print(
      '  - immediate_supervisor from json: ${json['immediate_supervisor']}',
    );
    print('  - from employee: ${employee['immediate_supervisor']}');

    return LeaveRequest(
      id: json['id']?.toString() ?? '',
      uuid: json['uuid'] ?? '',
      employeeName: employee['name'] ?? json['employee_name'] ?? 'Unknown',
      employeeAvatar: employee['avatar'] ?? json['employee_avatar'] ?? '',
      // 🔴 AMBIL immediate_supervisor DARI RESPONSE - PENTING UNTUK LOGIC APPROVE/REJECT
      immediateSupervisor:
          json['immediate_supervisor'] ?? employee['immediate_supervisor'],
      type: json['type'] ?? 'Annual Leave',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      days: json['days'] ?? 0,
      status: json['status'] ?? 'Pending',
      avatarUrl: json['avatar_url'],
      reason: json['reason'] ?? '',
      createdAt: json['created_at'] ?? '',
      isPendingSync: json['is_pending_sync'] == true,
    );
  }

  LeaveRequest copyWith({
    String? id,
    String? uuid,
    String? employeeName,
    String? employeeAvatar,
    String? immediateSupervisor,
    String? type,
    String? startDate,
    String? endDate,
    int? days,
    String? status,
    String? avatarUrl,
    String? reason,
    String? createdAt,
    bool? isPendingSync,
  }) {
    return LeaveRequest(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      employeeName: employeeName ?? this.employeeName,
      employeeAvatar: employeeAvatar ?? this.employeeAvatar,
      immediateSupervisor: immediateSupervisor ?? this.immediateSupervisor,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      days: days ?? this.days,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'employee_name': employeeName,
      'employee_avatar': employeeAvatar,
      'immediate_supervisor': immediateSupervisor,
      'type': type,
      'start_date': startDate,
      'end_date': endDate,
      'days': days,
      'status': status,
      'avatar_url': avatarUrl,
      'reason': reason,
      'created_at': createdAt,
      'is_pending_sync': isPendingSync,
    };
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
      annualUsed: json['annual_used'] ?? json['annual']?['used'] ?? 0,
      annualTotal: json['annual_total'] ?? json['annual']?['total'] ?? 12,
      sickUsed: json['sick_used'] ?? json['sick']?['used'] ?? 0,
      sickTotal: json['sick_total'] ?? json['sick']?['total'] ?? 14,
      personalUsed: json['personal_used'] ?? json['personal']?['used'] ?? 0,
      personalTotal: json['personal_total'] ?? json['personal']?['total'] ?? 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'annual_used': annualUsed,
      'annual_total': annualTotal,
      'sick_used': sickUsed,
      'sick_total': sickTotal,
      'personal_used': personalUsed,
      'personal_total': personalTotal,
    };
  }
}
