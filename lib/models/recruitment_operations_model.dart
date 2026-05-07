class RecruitmentOperationsData {
  final List<RecruitmentOpsApplicationOption> applications;
  final List<RecruitmentOpsInterviewerOption> interviewers;
  final List<InterviewSchedule> schedules;
  final List<JobOffer> offers;

  const RecruitmentOperationsData({
    this.applications = const [],
    this.interviewers = const [],
    this.schedules = const [],
    this.offers = const [],
  });

  factory RecruitmentOperationsData.fromJson(Map<String, dynamic> json) {
    return RecruitmentOperationsData(
      applications: _readList(
        json['applications'],
        RecruitmentOpsApplicationOption.fromJson,
      ),
      interviewers: _readList(
        json['interviewers'],
        RecruitmentOpsInterviewerOption.fromJson,
      ),
      schedules: _readList(json['schedules'], InterviewSchedule.fromJson),
      offers: _readList(json['offers'], JobOffer.fromJson),
    );
  }
}

class RecruitmentOpsApplicationOption {
  final int id;
  final String name;
  final String? status;
  final String? positionName;

  const RecruitmentOpsApplicationOption({
    required this.id,
    required this.name,
    this.status,
    this.positionName,
  });

  factory RecruitmentOpsApplicationOption.fromJson(Map<String, dynamic> json) {
    final position = json['position'];
    return RecruitmentOpsApplicationOption(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString(),
      positionName: position is Map
          ? position['nama_jabatan']?.toString()
          : json['position_name']?.toString() ?? json['position']?.toString(),
    );
  }
}

class RecruitmentOpsInterviewerOption {
  final int id;
  final String name;

  const RecruitmentOpsInterviewerOption({required this.id, required this.name});

  factory RecruitmentOpsInterviewerOption.fromJson(Map<String, dynamic> json) {
    return RecruitmentOpsInterviewerOption(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
    );
  }
}

class InterviewSchedule {
  final int id;
  final int applicationId;
  final String interviewType;
  final String scheduledAt;
  final String status;
  final RecruitmentOpsApplicationOption? application;
  final RecruitmentOpsInterviewerOption? interviewer;
  final InterviewFeedback? feedback;

  const InterviewSchedule({
    required this.id,
    required this.applicationId,
    required this.interviewType,
    required this.scheduledAt,
    required this.status,
    this.application,
    this.interviewer,
    this.feedback,
  });

  factory InterviewSchedule.fromJson(Map<String, dynamic> json) {
    final application = json['application'];
    final interviewer = json['interviewer'];
    final feedback = json['feedback'];

    return InterviewSchedule(
      id: _toInt(json['id']),
      applicationId: _toInt(json['application_id']),
      interviewType: json['interview_type']?.toString() ?? '',
      scheduledAt: json['scheduled_at']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      application: application is Map
          ? RecruitmentOpsApplicationOption.fromJson(
              Map<String, dynamic>.from(application),
            )
          : null,
      interviewer: interviewer is Map
          ? RecruitmentOpsInterviewerOption.fromJson(
              Map<String, dynamic>.from(interviewer),
            )
          : null,
      feedback: feedback is Map
          ? InterviewFeedback.fromJson(Map<String, dynamic>.from(feedback))
          : null,
    );
  }
}

class InterviewFeedback {
  final int id;
  final int rating;
  final String recommendation;
  final String? summary;
  final String? strengths;
  final String? concerns;

  const InterviewFeedback({
    required this.id,
    required this.rating,
    required this.recommendation,
    this.summary,
    this.strengths,
    this.concerns,
  });

  factory InterviewFeedback.fromJson(Map<String, dynamic> json) {
    return InterviewFeedback(
      id: _toInt(json['id']),
      rating: _toInt(json['rating']),
      recommendation: json['recommendation']?.toString() ?? '',
      summary: json['summary']?.toString(),
      strengths: json['strengths']?.toString(),
      concerns: json['concerns']?.toString(),
    );
  }
}

class JobOffer {
  final int id;
  final int applicationId;
  final String offeredPosition;
  final num proposedSalary;
  final String? startDate;
  final String offerStatus;
  final RecruitmentOpsApplicationOption? application;

  const JobOffer({
    required this.id,
    required this.applicationId,
    required this.offeredPosition,
    required this.proposedSalary,
    this.startDate,
    required this.offerStatus,
    this.application,
  });

  factory JobOffer.fromJson(Map<String, dynamic> json) {
    final application = json['application'];
    return JobOffer(
      id: _toInt(json['id']),
      applicationId: _toInt(json['application_id']),
      offeredPosition: json['offered_position']?.toString() ?? '',
      proposedSalary: _toNum(json['proposed_salary']),
      startDate: json['start_date']?.toString(),
      offerStatus: json['offer_status']?.toString() ?? '',
      application: application is Map
          ? RecruitmentOpsApplicationOption.fromJson(
              Map<String, dynamic>.from(application),
            )
          : null,
    );
  }
}

List<T> _readList<T>(Object? value, T Function(Map<String, dynamic>) mapper) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => mapper(Map<String, dynamic>.from(item)))
      .toList();
}

int _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

num _toNum(Object? value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}
