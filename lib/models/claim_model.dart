class ClaimModel {
  final String id;
  final int? employeeId;
  final String? employeeUuid;
  final String? employeeName;
  final String? employeeImmediateSupervisor;
  final String? claimNumber;
  final String title;
  final double amount;
  final DateTime date;
  final String status;
  final String type;
  final String claimType;
  final String description;
  final String currency;
  final String? attachmentUrl;
  final int? approverId;
  final String? approverName;
  final bool isPendingSync;

  const ClaimModel({
    required this.id,
    this.employeeId,
    this.employeeUuid,
    this.employeeName,
    this.employeeImmediateSupervisor,
    this.claimNumber,
    required this.title,
    required this.amount,
    required this.date,
    required this.status,
    required this.type,
    required this.claimType,
    required this.description,
    this.currency = 'IDR',
    this.attachmentUrl,
    this.approverId,
    this.approverName,
    this.isPendingSync = false,
  });

  factory ClaimModel.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'];
    final approver = json['approver'];

    return ClaimModel(
      id: json['id']?.toString() ?? '',
      employeeId: _parseInt(
        json['employee_id'] ??
            (employee is Map<String, dynamic> ? employee['id'] : null),
      ),
      employeeUuid:
          (employee is Map<String, dynamic> ? employee['uuid'] : null)
              ?.toString() ??
          json['employee_uuid']?.toString(),
      employeeName:
          (employee is Map<String, dynamic> ? employee['name'] : null)
              ?.toString() ??
          json['employee_name']?.toString(),
      employeeImmediateSupervisor: _normalizeKey(
        employee is Map<String, dynamic>
            ? employee['immediate_supervisor']
            : json['employee_immediate_supervisor'],
      ),
      claimNumber: json['claim_number']?.toString(),
      title: json['title']?.toString() ?? '',
      amount: _parseDouble(json['amount']),
      date: _parseDate(
        json['expense_date'] ?? json['date'] ?? json['created_at'],
      ),
      status: json['status']?.toString().toLowerCase() ?? 'submitted',
      type: json['category']?.toString() ?? json['type']?.toString() ?? 'other',
      claimType: json['claim_type']?.toString() ?? 'expense',
      description:
          json['notes']?.toString() ?? json['description']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'IDR',
      attachmentUrl: json['attachment_url']?.toString(),
      approverId: _parseInt(
        json['approver_id'] ??
            (approver is Map<String, dynamic> ? approver['id'] : null),
      ),
      approverName:
          (approver is Map<String, dynamic> ? approver['name'] : null)
              ?.toString() ??
          json['approver_name']?.toString(),
      isPendingSync: json['is_pending_sync'] == true,
    );
  }

  ClaimModel copyWith({
    String? id,
    int? employeeId,
    String? employeeUuid,
    String? employeeName,
    String? employeeImmediateSupervisor,
    String? claimNumber,
    String? title,
    double? amount,
    DateTime? date,
    String? status,
    String? type,
    String? claimType,
    String? description,
    String? currency,
    String? attachmentUrl,
    int? approverId,
    String? approverName,
    bool? isPendingSync,
  }) {
    return ClaimModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeUuid: employeeUuid ?? this.employeeUuid,
      employeeName: employeeName ?? this.employeeName,
      employeeImmediateSupervisor:
          employeeImmediateSupervisor ?? this.employeeImmediateSupervisor,
      claimNumber: claimNumber ?? this.claimNumber,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      status: status ?? this.status,
      type: type ?? this.type,
      claimType: claimType ?? this.claimType,
      description: description ?? this.description,
      currency: currency ?? this.currency,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      approverId: approverId ?? this.approverId,
      approverName: approverName ?? this.approverName,
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }

  Map<String, dynamic> toRequestPayload({required int employeeId}) {
    return {
      'employee_id': employeeId,
      'claim_type': claimType,
      'category': type,
      'title': title,
      'amount': amount,
      'currency': currency,
      'expense_date': date.toIso8601String().split('T').first,
      if (description.trim().isNotEmpty) 'notes': description.trim(),
    };
  }

  String get displayStatus {
    if (isPendingSync) {
      return 'Pending Sync';
    }

    switch (status) {
      case 'draft':
        return 'Draft';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'paid':
        return 'Paid';
      default:
        return 'Submitted';
    }
  }

  String get displayCategory => _titleize(type);

  String get displayClaimType => _titleize(claimType);

  bool get isEditable {
    final normalizedStatus = status.trim().toLowerCase();
    return normalizedStatus == 'draft' ||
        normalizedStatus == 'submitted' ||
        normalizedStatus == 'rejected';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'employee_uuid': employeeUuid,
      'employee_name': employeeName,
      'employee_immediate_supervisor': employeeImmediateSupervisor,
      'claim_number': claimNumber,
      'title': title,
      'amount': amount,
      'expense_date': date.toIso8601String(),
      'status': status,
      'category': type,
      'claim_type': claimType,
      'notes': description,
      'currency': currency,
      'attachment_url': attachmentUrl,
      'approver_id': approverId,
      'approver_name': approverName,
      'is_pending_sync': isPendingSync,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '');
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    final raw = value?.toString();
    if (raw == null || raw.isEmpty) {
      return DateTime.now();
    }

    return DateTime.tryParse(raw) ?? DateTime.now();
  }

  static String? _normalizeKey(dynamic value) {
    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  static String _titleize(String raw) {
    if (raw.trim().isEmpty) {
      return '-';
    }

    return raw
        .split('_')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

class ClaimEmployeeOption {
  const ClaimEmployeeOption({
    required this.id,
    required this.uuid,
    required this.name,
    this.immediateSupervisor,
  });

  final int id;
  final String uuid;
  final String name;
  final String? immediateSupervisor;

  factory ClaimEmployeeOption.fromJson(Map<String, dynamic> json) {
    return ClaimEmployeeOption(
      id: ClaimModel._parseInt(json['id'] ?? json['employee_id']) ?? 0,
      uuid: (json['uuid'] ?? json['employee_uuid'] ?? '').toString().trim(),
      name: (json['name'] ?? '').toString().trim().isNotEmpty
          ? (json['name'] ?? '').toString().trim()
          : 'Employee',
      immediateSupervisor: ClaimModel._normalizeKey(
        json['immediate_supervisor'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'immediate_supervisor': immediateSupervisor,
    };
  }
}
