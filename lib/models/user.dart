// lib/models/user.dart
class User {
  final int id;
  final String name;
  final String email;
  final String uuid;
  final String? employeeUuid; // Tambahkan field ini (nullable karena mungkin tidak selalu ada)
  final String position;
  final String selectedCCode;
  final List<String> permissions;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.uuid,
    this.employeeUuid, // Optional, karena mungkin tidak selalu ada
    required this.position,
    required this.selectedCCode,
    required this.permissions,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      uuid: map['uuid'] ?? '',
      // Coba ambil dari berbagai kemungkinan field
      employeeUuid: map['employee_uuid']?.toString() ??
          map['employeeUuid']?.toString() ??
          map['uuid'] ?? // Fallback ke uuid jika tidak ada
          null,
      position: map['position'] ?? '',
      selectedCCode: map['selectedCCode'] ?? map['selected_c_code'] ?? '', // Support kedua format
      permissions: List<String>.from(map['permissions'] ?? []),
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
      'selected_c_code': selectedCCode,
      'permissions': permissions,

    };
  }

  // Helper method untuk mendapatkan UUID karyawan (prioritaskan employeeUuid)
  String get employeeId => employeeUuid ?? uuid;
}