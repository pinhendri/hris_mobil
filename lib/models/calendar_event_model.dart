class CalendarEventInvitee {
  final String employeeUuid;
  final String employeeName;
  final String status;

  const CalendarEventInvitee({
    required this.employeeUuid,
    required this.employeeName,
    required this.status,
  });

  factory CalendarEventInvitee.fromJson(Map<String, dynamic> json) {
    return CalendarEventInvitee(
      employeeUuid: json['employee_uuid']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'invited',
    );
  }
}

class CalendarEvent {
  final int id;
  final String uuid;
  final String title;
  final String description;
  final String location;
  final DateTime startsAt;
  final DateTime? endsAt;
  final bool isCompanyWide;
  final String cCode;
  final String createdByName;
  final int inviteCount;
  final bool isUserInvited;
  final List<CalendarEventInvitee> invitedEmployees;

  const CalendarEvent({
    required this.id,
    required this.uuid,
    required this.title,
    required this.description,
    required this.location,
    required this.startsAt,
    required this.endsAt,
    required this.isCompanyWide,
    required this.cCode,
    required this.createdByName,
    required this.inviteCount,
    required this.isUserInvited,
    required this.invitedEmployees,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    final invitees = (json['invited_employees'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CalendarEventInvitee.fromJson)
        .toList(growable: false);

    return CalendarEvent(
      id: json['id'] as int? ?? 0,
      uuid: json['uuid']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      startsAt:
          DateTime.tryParse(json['starts_at']?.toString() ?? '') ??
          DateTime.now(),
      endsAt: DateTime.tryParse(json['ends_at']?.toString() ?? ''),
      isCompanyWide: json['is_company_wide'] == true,
      cCode: json['c_code']?.toString() ?? '',
      createdByName: json['created_by_name']?.toString() ?? 'System',
      inviteCount: json['invite_count'] as int? ?? invitees.length,
      isUserInvited: json['is_user_invited'] == true,
      invitedEmployees: invitees,
    );
  }

  List<String> get invitedEmployeeUuids {
    return invitedEmployees.map((invitee) => invitee.employeeUuid).toList();
  }
}
