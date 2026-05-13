class Employee {
  final String id;
  final String uuid;
  final String? nik;
  final String? nikEmployee;
  final String name;
  final String position;
  final String? positionId;
  final String department;
  final String? departmentId;
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
  final String? shiftId;
  final String? shiftName;
  final String? clockIn;
  final String? clockOut;
  final String? supervisorName;
  final String? religionId;
  final String? religionName;
  final String? ptkpCode;
  final String? taxNumber;
  final String? flag;
  final String? endDate;
  final String? cvUrl;

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
    this.nik,
    this.nikEmployee,
    required this.name,
    required this.position,
    this.positionId,
    required this.department,
    this.departmentId,
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
    this.shiftId,
    this.shiftName,
    this.clockIn,
    this.clockOut,
    this.supervisorName,
    this.religionId,
    this.religionName,
    this.ptkpCode,
    this.taxNumber,
    this.flag,
    this.endDate,
    this.cvUrl,
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

  static String? _asString(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  static Map<String, dynamic>? _asStringMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static String? _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = _asString(json[key]);
      if (value != null) return value;
    }
    return null;
  }

  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;

    if (value is List) {
      final items = value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
      return items.isEmpty ? null : items;
    }

    if (value is String) {
      final items = value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
      return items.isEmpty ? null : items;
    }

    return null;
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value.toString().trim().toLowerCase();
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    final positionMap = _asStringMap(json['position']);
    final departmentMap = _asStringMap(json['department']);
    final supervisorMap = _asStringMap(json['supervisor']);
    final shiftMap = _asStringMap(json['shift']);

    final positionName =
        _firstString(json, ['position_name', 'nama_jabatan']) ??
        _firstString(positionMap ?? const {}, [
          'position_name',
          'nama_jabatan',
          'name',
          'description',
        ]);
    final departmentName =
        _firstString(json, ['department_description', 'department_name']) ??
        _firstString(departmentMap ?? const {}, [
          'description',
          'department_description',
          'department_name',
          'name',
        ]);
    final shiftName =
        _firstString(json, ['shift_name', 'shift_description']) ??
        _firstString(shiftMap ?? const {}, [
          'name',
          'description',
          'deskripsi',
          'shift_name',
        ]);

    return Employee(
      id: json['id'].toString(),
      uuid: json['uuid']?.toString() ?? '',
      nik: json['nik']?.toString(),
      nikEmployee: json['nik_employee']?.toString(),
      name: json['name'] ?? '',
      position: positionName ?? _asString(json['position']) ?? '',
      positionId:
          _asString(json['position_id']) ??
          _asString(positionMap?['id']) ??
          _asString(json['position']),
      department: departmentName ?? _asString(json['department']) ?? '',
      departmentId:
          _asString(json['department_id']) ??
          _asString(departmentMap?['id']) ??
          _asString(json['department']),
      status: json['status'] ?? 'Active',
      joinDate: json['join_date'] ?? json['created_at'] ?? '',
      avatarUrl: _firstString(json, ['avatar', 'profile_picture', 'photo']),
      email: _asString(json['email']),
      phone: _asString(json['phone']),
      salary: _parseSalary(json['salary'] ?? json['basic_salary']),
      cCode: _asString(json['c_code']),
      companyCode: _asString(json['company_code']),
      positionName: positionName,
      departmentDescription: departmentName,
      shiftId: _asString(json['shift_id']) ?? _asString(shiftMap?['id']),
      shiftName: shiftName,
      clockIn: _asString(json['clock_in']) ?? _asString(shiftMap?['clock_in']),
      clockOut:
          _asString(json['clock_out']) ?? _asString(shiftMap?['clock_out']),
      supervisorName:
          _asString(json['supervisor_name']) ??
          _asString(supervisorMap?['name']),
      religionId:
          _asString(json['religion_id']) ??
          _asString(_asStringMap(json['religion'])?['id']),
      religionName:
          json['religion_name']?.toString() ??
          _asString(_asStringMap(json['religion'])?['name']),
      ptkpCode: json['ptkp_code']?.toString(),
      taxNumber: json['tax_number']?.toString(),
      flag: json['flag']?.toString(),
      endDate: _firstString(json, ['enddate', 'end_date', 'contract_end_date']),
      cvUrl: _firstString(json, ['cv', 'cv_url', 'resume']),
      gender: json['gender'],
      dateOfBirth: json['date_of_birth'],
      nationality: json['nationality'],
      address: json['address'],
      maritalStatus: json['marital_status'],
      emergencyContactName: json['emergency_contact_name'],
      emergencyContactRelationship: json['emergency_contact_relationship'],
      emergencyContactPhone: json['emergency_contact_phone'],
      managerId:
          _asString(supervisorMap?['uuid']) ??
          _asString(supervisorMap?['id']) ??
          json['manager_id']?.toString() ??
          json['immediate_supervisor']?.toString(),
      employmentType: json['employment_type'],
      officeLocation: json['office_location'],
      shiftType: shiftName ?? json['shift_type']?.toString(),
      workSchedule: json['work_schedule'],
      bankAccountNumber: json['bank_account_number'],
      bankName: json['bank_name'],
      accountType: json['account_type'],
      highestEducation: json['highest_education'],
      degree: json['degree'],
      institution: json['institution'],
      graduationYear: json['graduation_year'],
      previousEmployers: json['previous_employers'],
      yearsOfExperience: _parseInt(json['years_of_experience']),
      skills: _parseStringList(json['skills']),
      certifications: json['certifications'],
      medicalConditions: json['medical_conditions'],
      bloodType: json['blood_type'],
      emergencyMedicalInfo: json['emergency_medical_info'],
      tin: json['tin']?.toString() ?? json['tax_number']?.toString(),
      ssn: json['ssn'],
      workAuthorization: json['work_authorization'],
      contractType: json['contract_type'],
      companyPoliciesAcknowledged: _parseBool(
        json['company_policies_acknowledged'],
      ),
      assignedEquipment: _parseStringList(json['assigned_equipment']),
      trainingPlan: json['training_plan'],
      systemAccess: _parseStringList(json['system_access']),
      handbookAcknowledged: _parseBool(json['handbook_acknowledged']),
    );
  }

  // TAMBAHKAN METHOD COPYWITH DI SINI
  Employee copyWith({
    String? id,
    String? uuid,
    String? nik,
    String? nikEmployee,
    String? name,
    String? position,
    String? positionId,
    String? department,
    String? departmentId,
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
    String? shiftId,
    String? shiftName,
    String? clockIn,
    String? clockOut,
    String? supervisorName,
    String? religionId,
    String? religionName,
    String? ptkpCode,
    String? taxNumber,
    String? flag,
    String? endDate,
    String? cvUrl,
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
      nik: nik ?? this.nik,
      nikEmployee: nikEmployee ?? this.nikEmployee,
      name: name ?? this.name,
      position: position ?? this.position,
      positionId: positionId ?? this.positionId,
      department: department ?? this.department,
      departmentId: departmentId ?? this.departmentId,
      status: status ?? this.status,
      joinDate: joinDate ?? this.joinDate,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      salary: salary ?? this.salary,
      cCode: cCode ?? this.cCode,
      companyCode: companyCode ?? this.companyCode,
      positionName: positionName ?? this.positionName,
      departmentDescription:
          departmentDescription ?? this.departmentDescription,
      shiftId: shiftId ?? this.shiftId,
      shiftName: shiftName ?? this.shiftName,
      clockIn: clockIn ?? this.clockIn,
      clockOut: clockOut ?? this.clockOut,
      supervisorName: supervisorName ?? this.supervisorName,
      religionId: religionId ?? this.religionId,
      religionName: religionName ?? this.religionName,
      ptkpCode: ptkpCode ?? this.ptkpCode,
      taxNumber: taxNumber ?? this.taxNumber,
      flag: flag ?? this.flag,
      endDate: endDate ?? this.endDate,
      cvUrl: cvUrl ?? this.cvUrl,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      nationality: nationality ?? this.nationality,
      address: address ?? this.address,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactRelationship:
          emergencyContactRelationship ?? this.emergencyContactRelationship,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
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
      companyPoliciesAcknowledged:
          companyPoliciesAcknowledged ?? this.companyPoliciesAcknowledged,
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
      'nik': nik,
      'nik_employee': nikEmployee,
      'name': name,
      'position': position,
      'position_id': positionId,
      'department': department,
      'department_id': departmentId,
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
      'shift_id': shiftId,
      'shift_name': shiftName,
      'clock_in': clockIn,
      'clock_out': clockOut,
      'supervisor_name': supervisorName,
      'religion_id': religionId,
      'religion_name': religionName,
      'ptkp_code': ptkpCode,
      'tax_number': taxNumber,
      'flag': flag,
      'enddate': endDate,
      'cv': cvUrl,
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
