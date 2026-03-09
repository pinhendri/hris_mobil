// models/department_model.dart

class Department {
  final int id;
  final String name;
  final String? employeeId;
  final int employees;
  final int saved;
  final double? budget;
  final String? description;
  final double growth;
  final String? head;
  final String? headAvatar;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional fields
  String? code;
  String? status;
  String? location;
  String? managerRole;
  int? parentId;
  String? headId;
  Map<String, dynamic>? kpis;
  String? cCode; // Add this field for company code filtering

  Department({
    required this.id,
    required this.name,
    this.employeeId,
    required this.employees,
    required this.saved,
    this.budget,
    this.description,
    required this.growth,
    this.head,
    this.headAvatar,
    required this.createdAt,
    required this.updatedAt,
    this.code,
    this.status,
    this.location,
    this.managerRole,
    this.parentId,
    this.headId,
    this.kpis,
    this.cCode, // Add to constructor
  });

  String get displayCode => code ?? 'DEPT-$id';
  String get type => 'Department';
  int get employeeCount => employees;
  String? get headName => head;

  factory Department.fromJson(Map<String, dynamic> json) {
    final int id = json['id'] is String 
        ? int.tryParse(json['id']) ?? 0 
        : (json['id'] as int?) ?? 0;
    
    final String? employeeId = json['employee_id']?.toString();
    
    final int employees = json['employees'] is String
        ? int.tryParse(json['employees']) ?? 0
        : (json['employees'] as int?) ?? 0;
    
    final int saved = json['saved'] is String
        ? int.tryParse(json['saved']) ?? 0
        : (json['saved'] as int?) ?? 0;
    
    final double? budget = json['budget'] != null
        ? double.tryParse(json['budget'].toString()) ?? 0.0
        : null;
    
    final double growth = json['growth'] != null
        ? double.tryParse(json['growth'].toString()) ?? 0.0
        : 0.0;
    
    DateTime parseDate(String? dateStr) {
      if (dateStr == null) return DateTime.now();
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return DateTime.now();
      }
    }

    return Department(
      id: id,
      name: json['name'] ?? '',
      employeeId: employeeId,
      employees: employees,
      saved: saved,
      budget: budget,
      description: json['description'],
      growth: growth,
      head: json['head'],
      headAvatar: json['head_avatar'],
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      code: json['code'] ?? 'DEPT-$id',
      status: json['status'] ?? 'Active',
      location: json['location'],
      managerRole: json['manager_role'],
      parentId: json['parent_id'] != null 
          ? int.tryParse(json['parent_id'].toString()) 
          : null,
      headId: json['head_id']?.toString(),
      kpis: json['kpis'],
      cCode: json['c_code'] ?? json['company_code'], // Try to get from response
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'employee_id': employeeId,
      'employees': employees,
      'saved': saved,
      'budget': budget,
      'description': description,
      'growth': growth,
      'head': head,
      'head_avatar': headAvatar,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'code': code,
      'status': status,
      'location': location,
      'manager_role': managerRole,
      'parent_id': parentId,
      'head_id': headId,
      'kpis': kpis,
      'c_code': cCode,
    };
  }

  Department copyWith({
    int? id,
    String? name,
    String? employeeId,
    int? employees,
    int? saved,
    double? budget,
    String? description,
    double? growth,
    String? head,
    String? headAvatar,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? code,
    String? status,
    String? location,
    String? managerRole,
    int? parentId,
    String? headId,
    Map<String, dynamic>? kpis,
    String? cCode,
  }) {
    return Department(
      id: id ?? this.id,
      name: name ?? this.name,
      employeeId: employeeId ?? this.employeeId,
      employees: employees ?? this.employees,
      saved: saved ?? this.saved,
      budget: budget ?? this.budget,
      description: description ?? this.description,
      growth: growth ?? this.growth,
      head: head ?? this.head,
      headAvatar: headAvatar ?? this.headAvatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      code: code ?? this.code,
      status: status ?? this.status,
      location: location ?? this.location,
      managerRole: managerRole ?? this.managerRole,
      parentId: parentId ?? this.parentId,
      headId: headId ?? this.headId,
      kpis: kpis ?? this.kpis,
      cCode: cCode ?? this.cCode,
    );
  }
}