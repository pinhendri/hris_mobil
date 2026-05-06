class TaskModel {
  final String id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final bool isCompleted;
  final String priority; // 'high', 'medium', 'low'
  final String type; // 'onboarding', 'offboarding', 'regular'
  final String? assigneeEmployeeId;
  final String? assigneeName;
  final String? createdByName;
  final String assignmentScope; // 'self', 'subordinate'
  final bool canToggle;
  final bool canEdit;
  final bool canDelete;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.isCompleted = false,
    required this.priority,
    required this.type,
    this.assigneeEmployeeId,
    this.assigneeName,
    this.createdByName,
    this.assignmentScope = 'self',
    this.canToggle = true,
    this.canEdit = true,
    this.canDelete = true,
  });

  bool get isAssignedToSubordinate => assignmentScope == 'subordinate';

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    String? priority,
    String? type,
    String? assigneeEmployeeId,
    String? assigneeName,
    String? createdByName,
    String? assignmentScope,
    bool? canToggle,
    bool? canEdit,
    bool? canDelete,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      type: type ?? this.type,
      assigneeEmployeeId: assigneeEmployeeId ?? this.assigneeEmployeeId,
      assigneeName: assigneeName ?? this.assigneeName,
      createdByName: createdByName ?? this.createdByName,
      assignmentScope: assignmentScope ?? this.assignmentScope,
      canToggle: canToggle ?? this.canToggle,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
    );
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final assigneeEmployeeId = _firstString([
      json['assignee_employee_uuid'],
      json['assigneeEmployeeUuid'],
      json['assigned_to_uuid'],
      json['assignedToUuid'],
      json['assigned_to_employee_uuid'],
      json['assignedToEmployeeUuid'],
      json['assigned_employee_uuid'],
      json['target_employee_uuid'],
      json['recipient_employee_uuid'],
      json['employee_uuid'],
      json['assignee_employee_id'],
      json['assigneeEmployeeId'],
      json['assigned_to'],
      json['assignedTo'],
      json['employee_id'],
    ]);

    return TaskModel(
      id: json['id'].toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      description: (json['description'] ?? json['notes'] ?? '').toString(),
      dueDate: _parseDateTime(json['due_date'] ?? json['dueDate']),
      isCompleted: _parseBool(
        json['is_completed'] ?? json['isCompleted'] ?? json['completed'],
      ),
      priority: _normalizePriority(json['priority']),
      type: _normalizeType(json['type']),
      assigneeEmployeeId: assigneeEmployeeId,
      assigneeName: _firstString([
        json['assignee_name'],
        json['assigneeName'],
        json['assigned_to_name'],
        json['assignedToName'],
        json['employee_name'],
      ]),
      createdByName: _firstString([
        json['created_by_name'],
        json['createdByName'],
        json['creator_name'],
        json['created_by'],
      ]),
      assignmentScope: _normalizeAssignmentScope(
        json['assignment_scope'],
        assigneeEmployeeId: assigneeEmployeeId,
      ),
      canToggle: _parseBool(json['can_toggle'] ?? json['canToggle'] ?? true),
      canEdit: _parseBool(json['can_edit'] ?? json['canEdit'] ?? true),
      canDelete: _parseBool(json['can_delete'] ?? json['canDelete'] ?? true),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final normalized = value?.toString().trim().toLowerCase();
    return normalized == '1' ||
        normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'completed' ||
        normalized == 'done';
  }

  static String _normalizePriority(dynamic value) {
    final normalized = value?.toString().trim().toLowerCase();
    switch (normalized) {
      case 'high':
      case 'low':
        return normalized!;
      default:
        return 'medium';
    }
  }

  static String _normalizeType(dynamic value) {
    final normalized = value?.toString().trim().toLowerCase();
    switch (normalized) {
      case 'onboarding':
      case 'offboarding':
        return normalized!;
      default:
        return 'regular';
    }
  }

  static String _normalizeAssignmentScope(
    dynamic value, {
    String? assigneeEmployeeId,
  }) {
    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == 'subordinate') {
      return 'subordinate';
    }

    return (assigneeEmployeeId?.trim().isNotEmpty ?? false)
        ? 'subordinate'
        : 'self';
  }

  static String? _firstString(List<dynamic> values) {
    for (final value in values) {
      final normalized = value?.toString().trim() ?? '';
      if (normalized.isNotEmpty && normalized.toLowerCase() != 'null') {
        return normalized;
      }
    }

    return null;
  }
}
