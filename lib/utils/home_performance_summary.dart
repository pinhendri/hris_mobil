import '../models/performance_model.dart';

String formatHomePerformanceScore(
  PerformanceSummary summary, {
  required bool hasData,
}) {
  if (!hasData) {
    return '-';
  }

  final score = summary.overallScore;
  if (score == score.roundToDouble()) {
    return score.toStringAsFixed(0);
  }

  return score.toStringAsFixed(1);
}
