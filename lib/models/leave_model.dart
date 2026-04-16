class LeaveRequest {
  final String id;
  final String uuid;
  final String employeeName;
  final String employeeAvatar;
  final String? immediateSupervisor;
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
    this.immediateSupervisor,
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
    final employee = json['employee'];
    final employeeMap = employee is Map<String, dynamic>
        ? employee
        : <String, dynamic>{};

    return LeaveRequest(
      id: json['id']?.toString() ?? '',
      uuid:
          employeeMap['uuid']?.toString() ??
          json['employee_uuid']?.toString() ??
          json['uuid']?.toString() ??
          '',
      employeeName:
          employeeMap['name']?.toString() ??
          json['employee_name']?.toString() ??
          'Unknown',
      employeeAvatar:
          employeeMap['avatar']?.toString() ??
          json['employee_avatar']?.toString() ??
          '',
      immediateSupervisor:
          json['immediate_supervisor']?.toString() ??
          employeeMap['immediate_supervisor']?.toString(),
      type: json['type']?.toString() ?? 'Annual Leave',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      days: json['days'] is int
          ? json['days'] as int
          : int.tryParse(json['days']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'Pending',
      avatarUrl: json['avatar_url']?.toString(),
      reason: json['reason']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
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

  bool get isCompanyLeave => type.toLowerCase().contains('company');
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

class CompanyLeaveBatch {
  final String id;
  final String uuid;
  final String title;
  final String description;
  final String leaveType;
  final String startDate;
  final String endDate;
  final int days;
  final int totalEmployees;
  final int processedEmployees;
  final int skippedEmployees;
  final String createdAt;
  final String creatorName;

  CompanyLeaveBatch({
    required this.id,
    required this.uuid,
    required this.title,
    required this.description,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.totalEmployees,
    required this.processedEmployees,
    required this.skippedEmployees,
    required this.createdAt,
    required this.creatorName,
  });

  factory CompanyLeaveBatch.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'];
    final creatorMap = creator is Map<String, dynamic>
        ? creator
        : <String, dynamic>{};

    return CompanyLeaveBatch(
      id: json['id']?.toString() ?? '',
      uuid: json['uuid']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Company Leave',
      description: json['description']?.toString() ?? '',
      leaveType: json['leave_type']?.toString() ?? 'Company Leave',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      days: json['days'] is int
          ? json['days'] as int
          : int.tryParse(json['days']?.toString() ?? '0') ?? 0,
      totalEmployees: json['total_employees'] is int
          ? json['total_employees'] as int
          : int.tryParse(json['total_employees']?.toString() ?? '0') ?? 0,
      processedEmployees: json['processed_employees'] is int
          ? json['processed_employees'] as int
          : int.tryParse(json['processed_employees']?.toString() ?? '0') ?? 0,
      skippedEmployees: json['skipped_employees'] is int
          ? json['skipped_employees'] as int
          : int.tryParse(json['skipped_employees']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
      creatorName: creatorMap['name']?.toString() ?? '',
    );
  }
}
