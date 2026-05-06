class EmployeeContextFallback {
  const EmployeeContextFallback({required this.id, required this.uuid});

  final int id;
  final String uuid;
}

EmployeeContextFallback? employeeContextFromLeaveBalance(dynamic response) {
  if (response is! Map) {
    return null;
  }

  final map = Map<String, dynamic>.from(response);
  final data = map['data'];
  final payload = data is Map ? Map<String, dynamic>.from(data) : map;
  final id = _readInt(payload['employee_id'] ?? payload['id']);
  if (id <= 0) {
    return null;
  }

  return EmployeeContextFallback(
    id: id,
    uuid: _readString(payload, const ['uuid', 'employee_uuid']),
  );
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    final normalized = value?.toString().trim() ?? '';
    if (normalized.isNotEmpty && normalized.toLowerCase() != 'null') {
      return normalized;
    }
  }

  return '';
}

int _readInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.round();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}
