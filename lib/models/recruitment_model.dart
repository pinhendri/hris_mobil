class OpenPosition {
  final int id;
  final String title;
  final String positionId;
  final String department;
  final int applicants;
  final String status;
  final String urgency;
  final String requirement;
  final String? cCode;
  final String datePosted;

  OpenPosition({
    required this.id,
    required this.title,
    required this.positionId,
    required this.department,
    required this.applicants,
    required this.status,
    required this.urgency,
    required this.requirement,
    this.cCode,
    required this.datePosted,
  });

  factory OpenPosition.fromJson(Map<String, dynamic> json) {
    return OpenPosition(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      positionId: json['position_id']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      applicants: json['applicants'] ?? 0,
      status: json['status'] ?? 'Active',
      urgency: json['urgency'] ?? 'Medium',
      requirement: json['requirement'] ?? '',
      cCode: json['c_code'],
      datePosted: json['date_posted'] ?? json['created_at'] ?? '',
    );
  }
}

class Application {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? departmentId;
  final String? positionId;
  final String? positionName;
  final String status;
  final String? time;
  final String? cv;
  final String? createdAt;
  final String? updatedAt;
  final String? cCode;

  Application({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.departmentId,
    this.positionId,
    this.positionName,
    required this.status,
    this.time,
    this.cv,
    this.createdAt,
    this.updatedAt,
    this.cCode,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      departmentId: json['department_id']?.toString(),
      positionId: json['position_id']?.toString(),
      positionName: json['position_name'] ?? json['position']?.toString(),
      status: json['status'] ?? 'Applied',
      time: json['time'] ?? json['applied_at'],
      cv: json['cv'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      cCode: json['c_code'] ?? json['company_code'],
    );
  }
}

class PipelineStage {
  final String stage;
  final int count;
  final List<Candidate> candidates;

  PipelineStage({
    required this.stage,
    required this.count,
    this.candidates = const [],
  });

  factory PipelineStage.fromJson(Map<String, dynamic> json) {
    return PipelineStage(
      stage: json['stage'] ?? '',
      count: json['count'] ?? 0,
      candidates: (json['candidates'] as List? ?? [])
          .map((c) => Candidate.fromJson(c))
          .toList(),
    );
  }
}

class Candidate {
  final String name;
  final String? avatar;
  final String? position;

  Candidate({
    required this.name,
    this.avatar,
    this.position,
  });

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      name: json['name'] ?? '',
      avatar: json['avatar'],
      position: json['position'],
    );
  }
}

class RecruitmentMetrics {
  final double conversionRate;
  final double averageTimeToHire;

  RecruitmentMetrics({
    required this.conversionRate,
    required this.averageTimeToHire,
  });

  factory RecruitmentMetrics.fromJson(Map<String, dynamic> json) {
    return RecruitmentMetrics(
      conversionRate: (json['conversionRate'] ?? 0).toDouble(),
      averageTimeToHire: (json['averageTimeToHire'] ?? 0).toDouble(),
    );
  }
}

class Department {
  final int id;
  final String name;

  Department({
    required this.id,
    required this.name,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class Position {
  final int id;
  final String namaJabatan;

  Position({
    required this.id,
    required this.namaJabatan,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      id: int.tryParse(json['id'].toString()) ?? 0,
      namaJabatan: json['nama_jabatan'] ?? json['name'] ?? '',
    );
  }
}