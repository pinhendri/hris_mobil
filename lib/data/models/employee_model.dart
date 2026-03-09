// lib/models/employee_model.dart
class Employee {
  final String id;
  final String uuid;
  final String name;
  final String? email;
  final String? phone;
  final String position;
  final String? department;
  final String? status;
  final String? joinDate;
  final double? salary;
  final String? avatarUrl;
  final String? departmentDescription;
  final String? positionName;

  Employee({
    required this.id,
    required this.uuid,
    required this.name,
    this.email,
    this.phone,
    required this.position,
    this.department,
    this.status,
    this.joinDate,
    this.salary,
    this.avatarUrl,
    this.departmentDescription,
    this.positionName,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    print('📦 Employee.fromJson - Raw JSON: $json');
    
    final uuid = json['uuid']?.toString() ?? '';
    final id = json['id']?.toString() ?? '';
    
    print('📦 Employee.fromJson - UUID: $uuid, ID: $id');
    
    return Employee(
      id: id,
      uuid: uuid,
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      position: json['position_name'] ?? 
                json['position']?.toString() ?? 
                json['position_id']?.toString() ?? 
                '',
      department: json['department_description'] ?? 
                  json['department']?.toString() ?? 
                  json['department_id']?.toString(),
      status: json['status'],
      joinDate: json['join_date'] ?? json['joined_at'],
      salary: json['salary'] != null 
          ? double.tryParse(json['salary'].toString()) 
          : null,
      avatarUrl: json['avatar'] ?? json['profile_picture'],
      departmentDescription: json['department_description'],
      positionName: json['position_name'],
    );
  }

  // METHOD COPYWITH
  Employee copyWith({
    String? id,
    String? uuid,
    String? name,
    String? email,
    String? phone,
    String? position,
    String? department,
    String? status,
    String? joinDate,
    double? salary,
    String? avatarUrl,
    String? departmentDescription,
    String? positionName,
  }) {
    return Employee(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      position: position ?? this.position,
      department: department ?? this.department,
      status: status ?? this.status,
      joinDate: joinDate ?? this.joinDate,
      salary: salary ?? this.salary,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      departmentDescription: departmentDescription ?? this.departmentDescription,
      positionName: positionName ?? this.positionName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'email': email,
      'phone': phone,
      'position': position,
      'department': department,
      'status': status,
      'join_date': joinDate,
      'salary': salary?.toString(),
      'avatar': avatarUrl,
      'department_description': departmentDescription,
      'position_name': positionName,
    };
  }
}