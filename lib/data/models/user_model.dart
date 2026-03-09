class User {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String? position;
  final String? uuid;
  final List<String> permissions;
  final String? selectedCCode;
  final int? selectedCompanyId;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.position,
    this.uuid,
    this.permissions = const [],
    this.selectedCCode,
    this.selectedCompanyId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatar: json['avatar'],
      position: json['position'],
      uuid: json['uuid'],
      permissions: json['permissions'] != null
          ? List<String>.from(json['permissions'])
          : [],
      selectedCCode: json['selected_c_code'],
      selectedCompanyId: json['selected_company_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'position': position,
      'uuid': uuid,
      'permissions': permissions,
      'selected_c_code': selectedCCode,
      'selected_company_id': selectedCompanyId,
    };
  }
}

class Company {
  final int id;
  final String cCode;
  final String companyName;

  Company({
    required this.id,
    required this.cCode,
    required this.companyName,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      cCode: json['c_code'],
      companyName: json['company_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'c_code': cCode,
      'company_name': companyName,
    };
  }
}
