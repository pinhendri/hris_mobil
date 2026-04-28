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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final screenBackgroundColor = isDark
        ? const Color(0xFF121212)
        : Colors.grey[50];
    final primaryTextColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance & KPI'),
        elevation: 0,
        backgroundColor: surfaceColor,
        foregroundColor: primaryTextColor,
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: screenBackgroundColor,
      body: provider.isLoading && !provider.hasData
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: provider.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPeriodSelector(context, provider),
                  if (provider.isUsingCachedData) ...[
                    const SizedBox(height: 16),
                    _buildInfoBanner(
                      context: context,
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
                      context: context,
                      icon: Icons.info_outline,
                      title: 'Some performance data may be incomplete',
                      message: provider.error!,
                      color: Colors.redAccent,
                    ),
                  ],
                  if (!provider.hasData && provider.error != null) ...[
                    const SizedBox(height: 20),
                    _buildStateCard(
                      context: context,
                      icon: Icons.cloud_off_outlined,
                      title: 'Unable to load performance data',
                      message: provider.error!,
                      actionLabel: 'Try Again',
                      onPressed: provider.refresh,
                    ),
                  ] else if (!provider.hasData) ...[
                    const SizedBox(height: 20),
                    _buildStateCard(
                      context: context,
                      icon: Icons.assignment_outlined,
                      title: 'No KPI assigned yet',
                      message:
                          'Your personal KPI assignments will appear here once they are available.',
                      actionLabel: 'Refresh',
                      onPressed: provider.refresh,
                    ),
                  ] else ...[
                    const SizedBox(height: 20),
                    _buildSummaryCard(
                      context,
                      summary,
                      provider.currentPeriodHistory,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'KPI Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...provider.kpis.map(
                      (kpi) => _buildKpiCard(context, kpi, provider),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector(
    BuildContext context,
    PerformanceProvider provider,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF303030) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Evaluation Period',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: primaryTextColor,
            ),
          ),
          DropdownButton<String>(
            value: provider.selectedPeriod,
            underline: const SizedBox(),
            dropdownColor: surfaceColor,
            iconEnabledColor: secondaryTextColor,
            style: TextStyle(color: primaryTextColor),
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
    BuildContext context,
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
    required BuildContext context,
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.32 : 0.18),
        ),
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(color: secondaryTextColor, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF303030) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: secondaryTextColor, height: 1.4),
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

  Widget _buildKpiCard(
    BuildContext context,
    KpiModel kpi,
    PerformanceProvider provider,
  ) {
    final hasEvaluation = provider.hasEvaluation(kpi);
    final actual = provider.getEvaluationValue(kpi);
    final progress = kpi.target > 0 ? (actual / kpi.target) : 0.0;
    final cappedProgress = progress > 1.0 ? 1.0 : progress;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF303030) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
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
                  color: Colors.blue.withValues(alpha: isDark ? 0.18 : 0.1),
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: primaryTextColor,
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
                  color: hasEvaluation ? primaryTextColor : secondaryTextColor,
                ),
              ),
              Text(
                'Target: ${_formatTarget(kpi)}',
                style: TextStyle(color: secondaryTextColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: cappedProgress,
              backgroundColor: isDark
                  ? const Color(0xFF2A2A2A)
                  : Colors.grey[200],
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
                style: TextStyle(fontSize: 12, color: secondaryTextColor),
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
