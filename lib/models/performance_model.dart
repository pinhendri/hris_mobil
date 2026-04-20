class KpiModel {
  final String id;
  final String masterKpiDetailId;
  final String employeeKpiId;
  final String title;
  final String category;
  final double target;
  final double weight;
  final String unit;

  KpiModel({
    required this.id,
    this.masterKpiDetailId = '',
    this.employeeKpiId = '',
    required this.title,
    required this.category,
    required this.target,
    required this.weight,
    this.unit = '',
  });

  factory KpiModel.fromAssignment(Map<String, dynamic> json) {
    return KpiModel(
      id: _readString(json, const [
        'composite_id',
        'master_kpi_detail_id',
        'employee_kpi_id',
        'id',
      ]),
      masterKpiDetailId: _readString(json, const [
        'master_kpi_detail_id',
        'detail_id',
      ]),
      employeeKpiId: _readString(json, const ['employee_kpi_id']),
      title: _readString(json, const [
        'goal_name',
        'goalName',
        'goal',
        'title',
        'name',
      ], fallback: 'Untitled KPI'),
      category: _readString(json, const ['category'], fallback: 'General'),
      target: _readDouble(json['target'] ?? json['target_value']),
      weight: _readDouble(json['weight']),
      unit: _readString(json, const ['unit', 'target_unit', 'uom']),
    );
  }

  factory KpiModel.fromJson(Map<String, dynamic> json) {
    return KpiModel(
      id: _readString(json, const ['id']),
      masterKpiDetailId: _readString(json, const ['masterKpiDetailId']),
      employeeKpiId: _readString(json, const ['employeeKpiId']),
      title: _readString(json, const ['title'], fallback: 'Untitled KPI'),
      category: _readString(json, const ['category'], fallback: 'General'),
      target: _readDouble(json['target']),
      weight: _readDouble(json['weight']),
      unit: _readString(json, const ['unit']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'masterKpiDetailId': masterKpiDetailId,
      'employeeKpiId': employeeKpiId,
      'title': title,
      'category': category,
      'target': target,
      'weight': weight,
      'unit': unit,
    };
  }
}

class KpiEvaluationModel {
  final String id;
  final String kpiId;
  final String masterKpiDetailId;
  final String employeeKpiId;
  final String employeeId;
  final String period;
  final double actual;
  final String? comment;
  final DateTime evaluatedAt;
  final double score;
  final double finalScore;
  final String grade;
  final bool isLocked;

  KpiEvaluationModel({
    required this.id,
    required this.kpiId,
    this.masterKpiDetailId = '',
    this.employeeKpiId = '',
    required this.employeeId,
    required this.period,
    required this.actual,
    this.comment,
    required this.evaluatedAt,
    this.score = 0.0,
    this.finalScore = 0.0,
    this.grade = '',
    this.isLocked = false,
  });

  factory KpiEvaluationModel.fromEvaluation(
    Map<String, dynamic> json, {
    required String fallbackPeriod,
    required String fallbackEmployeeId,
  }) {
    final masterKpiDetailId = _readString(json, const [
      'master_kpi_detail_id',
      'kpi_id',
      'detail_id',
    ]);
    final employeeKpiId = _readString(json, const ['employee_kpi_id']);

    return KpiEvaluationModel(
      id: _readString(json, const ['id', 'evaluation_id']),
      kpiId: masterKpiDetailId.isNotEmpty
          ? masterKpiDetailId
          : _readString(json, const [
              'employee_kpi_id',
              'kpi_id',
              'master_kpi_detail_id',
              'detail_id',
              'id',
            ]),
      masterKpiDetailId: masterKpiDetailId,
      employeeKpiId: employeeKpiId,
      employeeId: _readString(json, const [
        'employee_id',
        'employee_uuid',
      ], fallback: fallbackEmployeeId),
      period: _readString(json, const ['period'], fallback: fallbackPeriod),
      actual: _readDouble(
        json['actual'] ?? json['actual_value'] ?? json['value'],
      ),
      comment: _readNullableString(json, const [
        'comment',
        'notes',
        'achievement_notes',
      ]),
      evaluatedAt: _readDateTime(json, const [
        'updated_at',
        'evaluated_at',
        'created_at',
      ]),
      score: _readDouble(json['score']),
      finalScore: _readDouble(json['final_score']),
      grade: _readString(json, const ['grade']),
      isLocked: _readBool(json['is_locked']),
    );
  }

  factory KpiEvaluationModel.fromJson(Map<String, dynamic> json) {
    return KpiEvaluationModel(
      id: _readString(json, const ['id']),
      kpiId: _readString(json, const ['kpiId']),
      masterKpiDetailId: _readString(json, const ['masterKpiDetailId']),
      employeeKpiId: _readString(json, const ['employeeKpiId']),
      employeeId: _readString(json, const ['employeeId']),
      period: _readString(json, const ['period']),
      actual: _readDouble(json['actual']),
      comment: _readNullableString(json, const ['comment']),
      evaluatedAt: _readDateTime(json, const ['evaluatedAt']),
      score: _readDouble(json['score']),
      finalScore: _readDouble(json['finalScore']),
      grade: _readString(json, const ['grade']),
      isLocked: _readBool(json['isLocked']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kpiId': kpiId,
      'masterKpiDetailId': masterKpiDetailId,
      'employeeKpiId': employeeKpiId,
      'employeeId': employeeId,
      'period': period,
      'actual': actual,
      'comment': comment,
      'evaluatedAt': evaluatedAt.toIso8601String(),
      'score': score,
      'finalScore': finalScore,
      'grade': grade,
      'isLocked': isLocked,
    };
  }
}

class PerformanceHistoryModel {
  final String period;
  final double finalScore;
  final String grade;
  final bool isLocked;

  PerformanceHistoryModel({
    required this.period,
    required this.finalScore,
    required this.grade,
    required this.isLocked,
  });

  factory PerformanceHistoryModel.fromJson(Map<String, dynamic> json) {
    return PerformanceHistoryModel(
      period: _readString(json, const ['period']),
      finalScore: _readDouble(json['final_score'] ?? json['finalScore']),
      grade: _readString(json, const ['grade']),
      isLocked: _readBool(json['is_locked'] ?? json['isLocked']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'final_score': finalScore,
      'grade': grade,
      'is_locked': isLocked,
    };
  }
}

class PerformanceSummary {
  final String period;
  final double overallScore;
  final String grade;
  final int totalKpis;
  final int completedKpis;

  PerformanceSummary({
    required this.period,
    required this.overallScore,
    required this.grade,
    required this.totalKpis,
    required this.completedKpis,
  });
}

String _readString(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) {
      continue;
    }

    final normalized = value.toString().trim();
    if (normalized.isNotEmpty && normalized.toLowerCase() != 'null') {
      return normalized;
    }
  }

  return fallback;
}

String? _readNullableString(Map<String, dynamic> json, List<String> keys) {
  final value = _readString(json, keys);
  return value.isEmpty ? null : value;
}

double _readDouble(dynamic value) {
  if (value == null) {
    return 0.0;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString()) ?? 0.0;
}

bool _readBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final normalized = value?.toString().trim().toLowerCase() ?? '';
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}

DateTime _readDateTime(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) {
      continue;
    }

    final parsed = DateTime.tryParse(value.toString());
    if (parsed != null) {
      return parsed;
    }
  }

  return DateTime.now();
}
