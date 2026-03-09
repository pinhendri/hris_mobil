class KpiModel {
  final String id;
  final String title;
  final String category;
  final double target;
  final double weight;
  final String unit; // e.g., "%", "USD", "Units"

  KpiModel({
    required this.id,
    required this.title,
    required this.category,
    required this.target,
    required this.weight,
    this.unit = '',
  });
}

class KpiEvaluationModel {
  final String id;
  final String kpiId;
  final String employeeId;
  final String period; // YYYY-MM
  final double actual;
  final String? comment;
  final DateTime evaluatedAt;

  KpiEvaluationModel({
    required this.id,
    required this.kpiId,
    required this.employeeId,
    required this.period,
    required this.actual,
    this.comment,
    required this.evaluatedAt,
  });
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
