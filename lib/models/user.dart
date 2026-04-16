List<String> _stringListFromDynamic(dynamic value) {
  if (value is List) {
    final items = value
        .map((item) {
          if (item is Map<String, dynamic>) {
            return item['name']?.toString() ?? '';
          }

          return item?.toString() ?? '';
        })
        .map((item) => item.trim())
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

// lib/models/user.dart
class User {
  final int id;
  final String name;
  final String email;
  final String uuid;
  final String? employeeUuid;
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
        map['uuid']?.toString().trim() ??
        '';

    return User(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      uuid: map['uuid'] ?? '',
      employeeUuid: resolvedEmployeeUuid.isNotEmpty
          ? resolvedEmployeeUuid
          : null,
      position: map['position'] ?? '',
      role: primaryRole,
      roles: normalizedRoles,
      selectedCCode: map['selectedCCode'] ?? map['selected_c_code'] ?? '',
      permissions: _stringListFromDynamic(map['permissions']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'uuid': uuid,
      'employee_uuid': employeeUuid,
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
