import 'package:flutter/material.dart';
import '../models/performance_model.dart';

class PerformanceProvider with ChangeNotifier {
  List<KpiModel> _kpis = [];
  List<KpiEvaluationModel> _evaluations = [];
  String _selectedPeriod = DateTime.now().toString().substring(0, 7); // YYYY-MM
  bool _isLoading = false;

  List<KpiModel> get kpis => _kpis;
  List<KpiEvaluationModel> get evaluations => _evaluations;
  String get selectedPeriod => _selectedPeriod;
  bool get isLoading => _isLoading;

  PerformanceProvider() {
    _loadMockData();
  }

  Future<void> setPeriod(String period) async {
    _selectedPeriod = period;
    await _loadMockData();
  }

  Future<void> _loadMockData() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1)); // Simulate API delay

    // Mock KPIs
    _kpis = [
      KpiModel(
        id: '1',
        title: 'Achieve Monthly Sales Target',
        category: 'Financial',
        target: 100000,
        weight: 40,
        unit: 'USD',
      ),
      KpiModel(
        id: '2',
        title: 'Customer Satisfaction Score (CSAT)',
        category: 'Quality',
        target: 4.5,
        weight: 30,
        unit: 'Score',
      ),
      KpiModel(
        id: '3',
        title: 'Complete Training Modules',
        category: 'Learning',
        target: 5,
        weight: 10,
        unit: 'Modules',
      ),
      KpiModel(
        id: '4',
        title: 'On-Time Project Delivery',
        category: 'Operational',
        target: 100,
        weight: 20,
        unit: '%',
      ),
    ];

    // Mock Evaluations for current period
    // For demo purposes, we always show some data if it matches current month or prev month
    if (true) {
      _evaluations = [
        KpiEvaluationModel(
          id: 'e1',
          kpiId: '1',
          employeeId: 'u1',
          period: _selectedPeriod,
          actual: 85000,
          evaluatedAt: DateTime.now(),
        ),
        KpiEvaluationModel(
          id: 'e2',
          kpiId: '2',
          employeeId: 'u1',
          period: _selectedPeriod,
          actual: 4.2,
          evaluatedAt: DateTime.now(),
        ),
        KpiEvaluationModel(
          id: 'e3',
          kpiId: '3',
          employeeId: 'u1',
          period: _selectedPeriod,
          actual: 3,
          evaluatedAt: DateTime.now(),
        ),
        // KPI 4 not yet evaluated
      ];
    }

    _isLoading = false;
    notifyListeners();
  }

  double getEvaluationValue(String kpiId) {
    try {
      final evaluation = _evaluations.firstWhere(
        (e) => e.kpiId == kpiId,
        orElse: () => KpiEvaluationModel(
          id: '',
          kpiId: '',
          employeeId: '',
          period: '',
          actual: 0,
          evaluatedAt: DateTime.now(),
        ),
      );
      return evaluation.id.isEmpty ? 0.0 : evaluation.actual;
    } catch (e) {
      return 0.0;
    }
  }

  bool hasEvaluation(String kpiId) {
    return _evaluations.any((e) => e.kpiId == kpiId);
  }

  PerformanceSummary get summary {
    double totalScore = 0;
    int completed = 0;

    for (var kpi in _kpis) {
      if (hasEvaluation(kpi.id)) {
        final actual = getEvaluationValue(kpi.id);
        // Calculate score contribution: (Actual / Target) * Weight
        if (kpi.target > 0) {
          double achievement = (actual / kpi.target);
          if (achievement > 1.2) achievement = 1.2; // Cap at 120%
          totalScore += achievement * kpi.weight;
        }
        completed++;
      }
    }

    String grade;
    if (totalScore >= 90) {
      grade = 'A';
    } else if (totalScore >= 80) {
      grade = 'B';
    } else if (totalScore >= 70) {
      grade = 'C';
    } else if (totalScore >= 60) {
      grade = 'D';
    } else {
      grade = 'E';
    }

    return PerformanceSummary(
      period: _selectedPeriod,
      overallScore: totalScore,
      grade: grade,
      totalKpis: _kpis.length,
      completedKpis: completed,
    );
  }
}
