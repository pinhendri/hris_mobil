String _stringFromAccessValue(dynamic value) {
  if (value is Map) {
    for (final key in const ['name', 'permission', 'slug', 'code', 'key']) {
      final item = value[key]?.toString().trim() ?? '';
      if (item.isNotEmpty) return item;
    }
    return '';
  }

  return value?.toString().trim() ?? '';
}

List<String> _stringListFromDynamic(dynamic value) {
  if (value is List) {
    final items = value
        .map(_stringFromAccessValue)
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);

    return items;
  }

  if (value is String) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  return const [];
}

List<String> _permissionListFromMap(Map<String, dynamic> map) {
  final values = <String>{
    ..._stringListFromDynamic(map['permissions']),
    ..._stringListFromDynamic(map['permission_names']),
    ..._stringListFromDynamic(map['direct_permissions']),
  };

  void collectRolePermissions(dynamic roles) {
    if (roles is! List) return;

    for (final role in roles) {
      if (role is! Map) continue;
      final roleMap = Map<String, dynamic>.from(role);
      values.addAll(_stringListFromDynamic(roleMap['permissions']));
      values.addAll(_stringListFromDynamic(roleMap['permission_names']));
    }
  }

  collectRolePermissions(map['roles']);
  collectRolePermissions(map['groups']);
  collectRolePermissions(map['group_roles']);

  values.removeWhere((item) => item.trim().isEmpty);
  return values.toList(growable: false);
}

// lib/models/user.dart
class User {
  final int id;
  final String name;
  final String email;
  final String uuid;
  final String? employeeUuid;
  final String? employeeRecordId;
  final String position;
  final String role;
  final List<String> roles;
  final String selectedCCode;
  final List<String> permissions;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.uuid,
    this.employeeUuid,
    this.employeeRecordId,
    required this.position,
    this.role = '',
    this.roles = const [],
    required this.selectedCCode,
    required this.permissions,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    final roleNames = _stringListFromDynamic(map['roles']);
    final primaryRole = map['role']?.toString().trim() ?? '';
    final List<String> normalizedRoles = roleNames.isNotEmpty
        ? roleNames
        : (primaryRole.isNotEmpty ? <String>[primaryRole] : const <String>[]);
    final employeeRaw = map['employee'];
    final employeeMap = employeeRaw is Map
        ? Map<String, dynamic>.from(employeeRaw)
        : null;
    final resolvedEmployeeUuid =
        employeeMap?['uuid']?.toString().trim() ??
        employeeMap?['employee_uuid']?.toString().trim() ??
        map['employee_uuid']?.toString().trim() ??
        map['employeeUuid']?.toString().trim() ??
        '';
    final resolvedEmployeeRecordId =
        employeeMap?['id']?.toString().trim() ??
        employeeMap?['employee_id']?.toString().trim() ??
        map['employee_id']?.toString().trim() ??
        map['employeeId']?.toString().trim() ??
        '';

    return User(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      uuid: map['uuid'] ?? '',
      employeeUuid: resolvedEmployeeUuid.isNotEmpty
          ? resolvedEmployeeUuid
          : null,
      employeeRecordId: resolvedEmployeeRecordId.isNotEmpty
          ? resolvedEmployeeRecordId
          : null,
      position: map['position'] ?? '',
      role: primaryRole,
      roles: normalizedRoles,
      selectedCCode: map['selectedCCode'] ?? map['selected_c_code'] ?? '',
      permissions: _permissionListFromMap(map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'uuid': uuid,
      'employee_uuid': employeeUuid,
      'employee_id': employeeRecordId,
      'position': position,
      'role': role,
      'roles': roles,
      'selected_c_code': selectedCCode,
      'permissions': permissions,
    };
  }

  // Prioritaskan UUID employee jika tersedia.
  String get employeeId => employeeUuid ?? uuid;
}
