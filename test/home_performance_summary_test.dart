import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/models/performance_model.dart';
import 'package:hris_mobile/utils/home_performance_summary.dart';

void main() {
  group('formatHomePerformanceScore', () {
    test('shows dash when performance data is not available', () {
      final summary = PerformanceSummary(
        period: '2026-05',
        overallScore: 0,
        grade: '-',
        totalKpis: 0,
        completedKpis: 0,
      );

      expect(formatHomePerformanceScore(summary, hasData: false), '-');
    });

    test('formats whole number scores without decimals', () {
      final summary = PerformanceSummary(
        period: '2026-05',
        overallScore: 88,
        grade: 'B',
        totalKpis: 4,
        completedKpis: 4,
      );

      expect(formatHomePerformanceScore(summary, hasData: true), '88');
    });

    test('formats fractional scores with one decimal', () {
      final summary = PerformanceSummary(
        period: '2026-05',
        overallScore: 86.45,
        grade: 'B',
        totalKpis: 4,
        completedKpis: 3,
      );

      expect(formatHomePerformanceScore(summary, hasData: true), '86.5');
    });
  });
}
