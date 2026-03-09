class Employee {
  final String id;
  final String uuid;
  final String name;
  final String position;
  final String department;
  final String status;
  final String joinDate;
  final String? avatarUrl;
  final String? email;
  final String? phone;
  final double salary;
  final String? cCode;
  final String? companyCode;
  final String? positionName;
  final String? departmentDescription;

  // New fields for extended form
  final String? gender;
  final String? dateOfBirth;
  final String? nationality;
  final String? address;
  final String? maritalStatus;
  final String? emergencyContactName;
  final String? emergencyContactRelationship;
  final String? emergencyContactPhone;
  final String? managerId;
  final String? employmentType;
  final String? officeLocation;
  final String? shiftType;
  final String? workSchedule;
  final String? bankAccountNumber;
  final String? bankName;
  final String? accountType;
  final String? highestEducation;
  final String? degree;
  final String? institution;
  final String? graduationYear;
  final String? previousEmployers;
  final int? yearsOfExperience;
  final List<String>? skills;
  final String? certifications;
  final String? medicalConditions;
  final String? bloodType;
  final String? emergencyMedicalInfo;
  final String? tin;
  final String? ssn;
  final String? workAuthorization;
  final String? contractType;
  final bool? companyPoliciesAcknowledged;
  final List<String>? assignedEquipment;
  final String? trainingPlan;
  final List<String>? systemAccess;
  final bool? handbookAcknowledged;

  Employee({
    required this.id,
    required this.uuid,
    required this.name,
    required this.position,
    required this.department,
    required this.status,
    required this.joinDate,
    this.avatarUrl,
    this.email,
    this.phone,
    this.salary = 0.0,
    this.cCode,
    this.companyCode,
    this.positionName,
    this.departmentDescription,
    this.gender,
    this.dateOfBirth,
    this.nationality,
    this.address,
    this.maritalStatus,
    this.emergencyContactName,
    this.emergencyContactRelationship,
    this.emergencyContactPhone,
    this.managerId,
    this.employmentType,
    this.officeLocation,
    this.shiftType,
    this.workSchedule,
    this.bankAccountNumber,
    this.bankName,
    this.accountType,
    this.highestEducation,
    this.degree,
    this.institution,
    this.graduationYear,
    this.previousEmployers,
    this.yearsOfExperience,
    this.skills,
    this.certifications,
    this.medicalConditions,
    this.bloodType,
    this.emergencyMedicalInfo,
    this.tin,
    this.ssn,
    this.workAuthorization,
    this.contractType,
    this.companyPoliciesAcknowledged,
    this.assignedEquipment,
    this.trainingPlan,
    this.systemAccess,
    this.handbookAcknowledged,
  });

  // Helper method untuk parse salary dengan aman
  static double _parseSalary(dynamic value) {
    if (value == null) return 0.0;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    
    if (value is String) {
      String cleanValue = value.replaceAll(RegExp(r'[^\d.-]'), '');
      if (cleanValue.isEmpty) return 0.0;
      try {
        return double.parse(cleanValue);
      } catch (e) {
        print('⚠️ Error parsing salary string: "$value" -> "$cleanValue"');
        return 0.0;
      }
    }
    
    print('⚠️ Unknown salary type: ${value.runtimeType}');
    return 0.0;
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'].toString(),
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? '',
      position: json['position_name'] ?? json['position'] ?? '',
      department: json['department_description'] ?? json['department'] ?? '',
      status: json['status'] ?? 'Active',
      joinDate: json['join_date'] ?? json['created_at'] ?? '',
      avatarUrl: json['avatar'],
      email: json['email'],
      phone: json['phone'],
      salary: _parseSalary(json['salary']),
      cCode: json['c_code'],
      companyCode: json['company_code'],
      positionName: json['position_name'],
      departmentDescription: json['department_description'],
      gender: json['gender'],
      dateOfBirth: json['date_of_birth'],
      nationality: json['nationality'],
      address: json['address'],
      maritalStatus: json['marital_status'],
      emergencyContactName: json['emergency_contact_name'],
      emergencyContactRelationship: json['emergency_contact_relationship'],
      emergencyContactPhone: json['emergency_contact_phone'],
      managerId: json['manager_id'],
      employmentType: json['employment_type'],
      officeLocation: json['office_location'],
      shiftType: json['shift_type'],
      workSchedule: json['work_schedule'],
      bankAccountNumber: json['bank_account_number'],
      bankName: json['bank_name'],
      accountType: json['account_type'],
      highestEducation: json['highest_education'],
      degree: json['degree'],
      institution: json['institution'],
      graduationYear: json['graduation_year'],
      previousEmployers: json['previous_employers'],
      yearsOfExperience: json['years_of_experience'],
      skills: json['skills'] != null ? List<String>.from(json['skills']) : null,
      certifications: json['certifications'],
      medicalConditions: json['medical_conditions'],
      bloodType: json['blood_type'],
      emergencyMedicalInfo: json['emergency_medical_info'],
      tin: json['tin'],
      ssn: json['ssn'],
      workAuthorization: json['work_authorization'],
      contractType: json['contract_type'],
      companyPoliciesAcknowledged: json['company_policies_acknowledged'],
      assignedEquipment: json['assigned_equipment'] != null ? List<String>.from(json['assigned_equipment']) : null,
      trainingPlan: json['training_plan'],
      systemAccess: json['system_access'] != null ? List<String>.from(json['system_access']) : null,
      handbookAcknowledged: json['handbook_acknowledged'],
    );
  }

  // TAMBAHKAN METHOD COPYWITH DI SINI
  Employee copyWith({
    String? id,
    String? uuid,
    String? name,
    String? position,
    String? department,
    String? status,
    String? joinDate,
    String? avatarUrl,
    String? email,
    String? phone,
    double? salary,
    String? cCode,
    String? companyCode,
    String? positionName,
    String? departmentDescription,
    String? gender,
    String? dateOfBirth,
    String? nationality,
    String? address,
    String? maritalStatus,
    String? emergencyContactName,
    String? emergencyContactRelationship,
    String? emergencyContactPhone,
    String? managerId,
    String? employmentType,
    String? officeLocation,
    String? shiftType,
    String? workSchedule,
    String? bankAccountNumber,
    String? bankName,
    String? accountType,
    String? highestEducation,
    String? degree,
    String? institution,
    String? graduationYear,
    String? previousEmployers,
    int? yearsOfExperience,
    List<String>? skills,
    String? certifications,
    String? medicalConditions,
    String? bloodType,
    String? emergencyMedicalInfo,
    String? tin,
    String? ssn,
    String? workAuthorization,
    String? contractType,
    bool? companyPoliciesAcknowledged,
    List<String>? assignedEquipment,
    String? trainingPlan,
    List<String>? systemAccess,
    bool? handbookAcknowledged,
  }) {
    return Employee(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      position: position ?? this.position,
      department: department ?? this.department,
      status: status ?? this.status,
      joinDate: joinDate ?? this.joinDate,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      salary: salary ?? this.salary,
      cCode: cCode ?? this.cCode,
      companyCode: companyCode ?? this.companyCode,
      positionName: positionName ?? this.positionName,
      departmentDescription: departmentDescription ?? this.departmentDescription,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      nationality: nationality ?? this.nationality,
      address: address ?? this.address,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactRelationship: emergencyContactRelationship ?? this.emergencyContactRelationship,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      managerId: managerId ?? this.managerId,
      employmentType: employmentType ?? this.employmentType,
      officeLocation: officeLocation ?? this.officeLocation,
      shiftType: shiftType ?? this.shiftType,
      workSchedule: workSchedule ?? this.workSchedule,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankName: bankName ?? this.bankName,
      accountType: accountType ?? this.accountType,
      highestEducation: highestEducation ?? this.highestEducation,
      degree: degree ?? this.degree,
      institution: institution ?? this.institution,
      graduationYear: graduationYear ?? this.graduationYear,
      previousEmployers: previousEmployers ?? this.previousEmployers,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      skills: skills ?? this.skills,
      certifications: certifications ?? this.certifications,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      bloodType: bloodType ?? this.bloodType,
      emergencyMedicalInfo: emergencyMedicalInfo ?? this.emergencyMedicalInfo,
      tin: tin ?? this.tin,
      ssn: ssn ?? this.ssn,
      workAuthorization: workAuthorization ?? this.workAuthorization,
      contractType: contractType ?? this.contractType,
      companyPoliciesAcknowledged: companyPoliciesAcknowledged ?? this.companyPoliciesAcknowledged,
      assignedEquipment: assignedEquipment ?? this.assignedEquipment,
      trainingPlan: trainingPlan ?? this.trainingPlan,
      systemAccess: systemAccess ?? this.systemAccess,
      handbookAcknowledged: handbookAcknowledged ?? this.handbookAcknowledged,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'position': position,
      'department': department,
      'status': status,
      'join_date': joinDate,
      'avatar': avatarUrl,
      'email': email,
      'phone': phone,
      'salary': salary,
      'c_code': cCode,
      'company_code': companyCode,
      'position_name': positionName,
      'department_description': departmentDescription,
      'gender': gender,
      'date_of_birth': dateOfBirth,
      'nationality': nationality,
      'address': address,
      'marital_status': maritalStatus,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_relationship': emergencyContactRelationship,
      'emergency_contact_phone': emergencyContactPhone,
      'manager_id': managerId,
      'employment_type': employmentType,
      'office_location': officeLocation,
      'shift_type': shiftType,
      'work_schedule': workSchedule,
      'bank_account_number': bankAccountNumber,
      'bank_name': bankName,
      'account_type': accountType,
      'highest_education': highestEducation,
      'degree': degree,
      'institution': institution,
      'graduation_year': graduationYear,
      'previous_employers': previousEmployers,
      'years_of_experience': yearsOfExperience,
      'skills': skills,
      'certifications': certifications,
      'medical_conditions': medicalConditions,
      'blood_type': bloodType,
      'emergency_medical_info': emergencyMedicalInfo,
      'tin': tin,
      'ssn': ssn,
      'work_authorization': workAuthorization,
      'contract_type': contractType,
      'company_policies_acknowledged': companyPoliciesAcknowledged,
      'assigned_equipment': assignedEquipment,
      'training_plan': trainingPlan,
      'system_access': systemAccess,
      'handbook_acknowledged': handbookAcknowledged,
    };
  }
}