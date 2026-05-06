class BroadcastDepartmentOption {
  final int id;
  final String name;
  final String description;
  final int employeeCount;

  const BroadcastDepartmentOption({
    required this.id,
    required this.name,
    required this.description,
    required this.employeeCount,
  });

  factory BroadcastDepartmentOption.fromJson(Map<String, dynamic> json) {
    return BroadcastDepartmentOption(
      id: _parseInt(json['id']),
      name: _parseString(json['name']),
      description: _parseString(json['description']),
      employeeCount: _parseInt(
        json['employee_count'] ?? json['employees'] ?? json['employee_total'],
      ),
    );
  }
}

class BroadcastEmployeeOption {
  final int id;
  final String name;
  final String email;
  final String employeeId;
  final int departmentId;
  final String departmentName;

  const BroadcastEmployeeOption({
    required this.id,
    required this.name,
    required this.email,
    required this.employeeId,
    required this.departmentId,
    required this.departmentName,
  });

  factory BroadcastEmployeeOption.fromJson(Map<String, dynamic> json) {
    return BroadcastEmployeeOption(
      id: _parseInt(json['id']),
      name: _parseString(json['name']),
      email: _parseString(json['email']),
      employeeId: _parseString(
        json['employee_id'] ?? json['nik_employee'] ?? json['nik'],
      ),
      departmentId: _parseInt(json['department_id'] ?? json['department']),
      departmentName: _parseString(
        json['department_name'] ??
            json['department_description'] ??
            json['department'],
      ),
    );
  }
}

class BroadcastHistoryItem {
  final int id;
  final String title;
  final String message;
  final DateTime? sentAt;
  final int calendarEventId;
  final DateTime? eventStartsAt;
  final DateTime? eventEndsAt;
  final String eventLocation;
  final String sentBy;
  final int recipientCount;
  final String type;
  final String status;
  final String priority;

  const BroadcastHistoryItem({
    required this.id,
    required this.title,
    required this.message,
    required this.sentAt,
    required this.calendarEventId,
    required this.eventStartsAt,
    required this.eventEndsAt,
    required this.eventLocation,
    required this.sentBy,
    required this.recipientCount,
    required this.type,
    required this.status,
    required this.priority,
  });

  factory BroadcastHistoryItem.fromJson(Map<String, dynamic> json) {
    return BroadcastHistoryItem(
      id: _parseInt(json['id']),
      title: _parseString(json['title']),
      message: _parseString(json['message']),
      sentAt: _parseDate(
        json['sent_at'] ?? json['created_at'] ?? json['updated_at'],
      ),
      calendarEventId: _parseInt(json['calendar_event_id']),
      eventStartsAt: _parseDate(json['event_starts_at']),
      eventEndsAt: _parseDate(json['event_ends_at']),
      eventLocation: _parseString(json['event_location']),
      sentBy: _parseString(
        json['sent_by'] ?? json['sender_name'] ?? json['created_by'],
      ),
      recipientCount: _parseInt(json['recipient_count']),
      type: _parseString(json['type'], fallback: 'all'),
      status: _parseString(json['status'], fallback: 'sent'),
      priority: _parseString(json['priority'], fallback: 'medium'),
    );
  }

  bool get isCalendarEvent => calendarEventId > 0 || eventStartsAt != null;
}

int _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is double) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value.trim()) ?? 0;
  }

  return 0;
}

String _parseString(dynamic value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }

  final normalized = value.toString().trim();
  return normalized.isEmpty ? fallback : normalized;
}

DateTime? _parseDate(dynamic value) {
  final raw = _parseString(value);
  if (raw.isEmpty) {
    return null;
  }

  return DateTime.tryParse(raw);
}
