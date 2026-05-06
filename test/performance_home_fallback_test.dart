import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/models/performance_model.dart';
import 'package:hris_mobile/utils/performance_home_fallback.dart';

void main() {
  group('selectDisplayHistoryEntry', () {
    test('uses the selected period when it exists in history', () {
      final history = [
        PerformanceHistoryModel(
          period: '2026-04',
          finalScore: 100,
          grade: 'A',
          isLocked: false,
        ),
        PerformanceHistoryModel(
          period: '2026-03',
          finalScore: 80,
          grade: 'B',
          isLocked: false,
        ),
      ];

      final selected = selectDisplayHistoryEntry(
        history,
        selectedPeriod: '2026-03',
      );

      expect(selected?.period, '2026-03');
      expect(selected?.finalScore, 80);
    });

    test('falls back to the latest history when selected period is empty', () {
      final history = [
        PerformanceHistoryModel(
          period: '2026-03',
          finalScore: 80,
          grade: 'B',
          isLocked: false,
        ),
        PerformanceHistoryModel(
          period: '2026-04',
          finalScore: 100,
          grade: 'A',
          isLocked: false,
        ),
      ];

      final selected = selectDisplayHistoryEntry(
        history,
        selectedPeriod: '2026-05',
      );

      expect(selected?.period, '2026-04');
      expect(selected?.finalScore, 100);
    });
  });

  group('extractEmployeeHistoryFromEvaluationList', () {
    test('maps the matching employee score from evaluation list data', () {
      final history = extractEmployeeHistoryFromEvaluationList({
        'data': [
          {
            'employee_id': 8988,
            'period': '2026-04',
            'final_score': '100.00',
            'grade': 'A',
            'is_locked': false,
          },
          {
            'employee_id': 777,
            'period': '2026-04',
            'final_score': '55.00',
            'grade': 'C',
          },
        ],
      }, employeeId: 8988);

      expect(history, hasLength(1));
      expect(history.first.period, '2026-04');
      expect(history.first.finalScore, 100);
      expect(history.first.grade, 'A');
    });
  });
}
