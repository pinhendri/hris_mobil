import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/performance_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/performance_provider.dart';

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PerformanceProvider(context.read<AuthProvider>()),
      child: const _PerformanceScreenContent(),
    );
  }
}

class _PerformanceScreenContent extends StatelessWidget {
  const _PerformanceScreenContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PerformanceProvider>();
    final summary = provider.summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance & KPI'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.grey[50],
      body: provider.isLoading && !provider.hasData
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: provider.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPeriodSelector(provider),
                  if (provider.isUsingCachedData) ...[
                    const SizedBox(height: 16),
                    _buildInfoBanner(
                      icon: Icons.wifi_off_rounded,
                      title: 'Showing cached performance data',
                      message:
                          'Latest server data could not be reached, so the app is showing the last saved result.',
                      color: Colors.amber,
                    ),
                  ],
                  if (provider.error != null && provider.hasData) ...[
                    const SizedBox(height: 16),
                    _buildInfoBanner(
                      icon: Icons.info_outline,
                      title: 'Some performance data may be incomplete',
                      message: provider.error!,
                      color: Colors.redAccent,
                    ),
                  ],
                  if (!provider.hasData && provider.error != null) ...[
                    const SizedBox(height: 20),
                    _buildStateCard(
                      icon: Icons.cloud_off_outlined,
                      title: 'Unable to load performance data',
                      message: provider.error!,
                      actionLabel: 'Try Again',
                      onPressed: provider.refresh,
                    ),
                  ] else if (!provider.hasData) ...[
                    const SizedBox(height: 20),
                    _buildStateCard(
                      icon: Icons.assignment_outlined,
                      title: 'No KPI assigned yet',
                      message:
                          'Your personal KPI assignments will appear here once they are available.',
                      actionLabel: 'Refresh',
                      onPressed: provider.refresh,
                    ),
                  ] else ...[
                    const SizedBox(height: 20),
                    _buildSummaryCard(summary, provider.currentPeriodHistory),
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
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector(PerformanceProvider provider) {
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
            items: provider.availablePeriods.map((value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(_formatPeriodLabel(value)),
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

  Widget _buildSummaryCard(
    PerformanceSummary summary,
    PerformanceHistoryModel? history,
  ) {
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
            _formatNumber(summary.overallScore),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  summary.grade == '-'
                      ? 'No Evaluation Yet'
                      : 'Grade ${summary.grade}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (history != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    history.isLocked ? 'Locked' : 'Draft',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
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

  Widget _buildInfoBanner({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: Colors.black54, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateCard({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.blueGrey),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.black54, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: onPressed, child: Text(actionLabel)),
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
    final hasEvaluation = provider.hasEvaluation(kpi);
    final actual = provider.getEvaluationValue(kpi);
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
                'Actual: ${hasEvaluation ? _formatNumber(actual) : '-'}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: hasEvaluation ? Colors.black87 : Colors.grey,
                ),
              ),
              Text(
                'Target: ${_formatTarget(kpi)}',
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
                'Weight: ${_formatNumber(kpi.weight)}%',
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

  String _formatTarget(KpiModel kpi) {
    final unitSuffix = kpi.unit.isEmpty ? '' : ' ${kpi.unit}';
    return '${_formatNumber(kpi.target)}$unitSuffix';
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }

  String _formatPeriodLabel(String value) {
    final parsed = DateTime.tryParse('$value-01');
    if (parsed == null) {
      return value;
    }

    return DateFormat('MMM yyyy').format(parsed);
  }
}
