import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/performance_provider.dart';
import '../../models/performance_model.dart';
import 'package:intl/intl.dart';

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PerformanceProvider(),
      child: const _PerformanceScreenContent(),
    );
  }
}

class _PerformanceScreenContent extends StatelessWidget {
  const _PerformanceScreenContent();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PerformanceProvider>(context);
    final summary = provider.summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance & KPI'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.grey[50],
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.setPeriod(provider.selectedPeriod),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodSelector(context, provider),
                    const SizedBox(height: 20),
                    _buildSummaryCard(summary),
                    const SizedBox(height: 24),
                    const Text(
                      'KPI Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...provider.kpis.map((kpi) => _buildKpiCard(kpi, provider)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodSelector(
    BuildContext context,
    PerformanceProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Evaluation Period',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          DropdownButton<String>(
            value: provider.selectedPeriod,
            underline: const SizedBox(),
            items:
                [
                  // Generate last 6 months
                  for (int i = 0; i < 6; i++)
                    DateFormat(
                      'yyyy-MM',
                    ).format(DateTime.now().subtract(Duration(days: 30 * i))),
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                provider.setPeriod(newValue);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(PerformanceSummary summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Overall Performance Score',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            summary.overallScore.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Grade ${summary.grade}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryStat('Total KPIs', summary.totalKpis.toString()),
              Container(height: 30, width: 1, color: Colors.white24),
              _buildSummaryStat('Completed', summary.completedKpis.toString()),
              Container(height: 30, width: 1, color: Colors.white24),
              _buildSummaryStat(
                'Pending',
                (summary.totalKpis - summary.completedKpis).toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildKpiCard(KpiModel kpi, PerformanceProvider provider) {
    final hasEvaluation = provider.hasEvaluation(kpi.id);
    final actual = provider.getEvaluationValue(kpi.id);
    final progress = kpi.target > 0 ? (actual / kpi.target) : 0.0;
    final cappedProgress = progress > 1.0 ? 1.0 : progress;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  kpi.category,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (hasEvaluation)
                const Icon(Icons.check_circle, color: Colors.green, size: 20)
              else
                const Icon(Icons.pending, color: Colors.orange, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            kpi.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Actual: ${actual.toStringAsFixed(1)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: hasEvaluation ? Colors.black87 : Colors.grey,
                ),
              ),
              Text(
                'Target: ${kpi.target.toStringAsFixed(1)} ${kpi.unit}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: cappedProgress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(progress),
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weight: ${kpi.weight}%',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getProgressColor(progress),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.7) return Colors.blue;
    if (progress >= 0.4) return Colors.orange;
    return Colors.red;
  }
}
