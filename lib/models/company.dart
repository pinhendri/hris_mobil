class Company {
  final int id;
  final String companyName;
  final String cCode;

  Company({
    required this.id,
    required this.companyName,
    required this.cCode,
  });

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'] as int? ?? 0,
      companyName: map['company_name'] as String? ?? '',
      cCode: map['c_code'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_name': companyName,
      'c_code': cCode,
    };
  }
}