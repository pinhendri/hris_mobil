import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class TalentManagementMobileScreen extends StatefulWidget {
  const TalentManagementMobileScreen({super.key});

  @override
  State<TalentManagementMobileScreen> createState() =>
      _TalentManagementMobileScreenState();
}

class _TalentManagementMobileScreenState
    extends State<TalentManagementMobileScreen> {
  final ApiService _apiService = ApiService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _competencies = const [];
  List<Map<String, dynamic>> _talentReviews = const [];
  List<Map<String, dynamic>> _successionPlans = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _apiService.get('/talent');
      final data = response is Map ? response['data'] : null;
      if (!mounted) return;
      setState(() {
        _competencies = _records(data, 'competencies');
        _talentReviews = _records(data, 'talent_reviews');
        _successionPlans = _records(data, 'succession_plans');
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat Talent Management: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _DevelopmentScaffold(
      title: 'Manajemen Talenta',
      loading: _loading,
      error: _error,
      onRefresh: _loadData,
      children: [
        _SummaryBand(
          items: [
            _SummaryItem('Competencies', _competencies.length),
            _SummaryItem('Talent Review', _talentReviews.length),
            _SummaryItem('Succession', _successionPlans.length),
          ],
        ),
        _SimpleRecordSection(
          title: 'Competency Catalog',
          emptyText: 'Belum ada competency.',
          records: _competencies,
          titleKeys: const ['name'],
          subtitleKeys: const ['category', 'target_role'],
        ),
        _SimpleRecordSection(
          title: 'Talent Review',
          emptyText: 'Belum ada talent review.',
          records: _talentReviews,
          titleKeys: const ['employee_name', 'name'],
          subtitleKeys: const [
            'readiness_level',
            'risk_of_loss',
            'performance_rating',
            'potential_rating',
          ],
        ),
        _SimpleRecordSection(
          title: 'Succession Plan',
          emptyText: 'Belum ada succession plan.',
          records: _successionPlans,
          titleKeys: const ['position_name', 'name'],
          subtitleKeys: const ['readiness_level', 'development_actions'],
        ),
      ],
    );
  }
}

class EmployeeRelationsMobileScreen extends StatefulWidget {
  const EmployeeRelationsMobileScreen({super.key});

  @override
  State<EmployeeRelationsMobileScreen> createState() =>
      _EmployeeRelationsMobileScreenState();
}

class _EmployeeRelationsMobileScreenState
    extends State<EmployeeRelationsMobileScreen> {
  final ApiService _apiService = ApiService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _cases = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _apiService.get('/employee-relations');
      final data = response is Map ? response['data'] : null;
      if (!mounted) return;
      setState(() => _cases = _records(data, 'cases'));
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat Hubungan Karyawan: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final open = _cases.where((item) {
      final status = _read(item, const ['status']).toLowerCase();
      return status == 'open' || status == 'investigating';
    }).length;

    return _DevelopmentScaffold(
      title: 'Hubungan Karyawan',
      loading: _loading,
      error: _error,
      onRefresh: _loadData,
      children: [
        _SummaryBand(
          items: [
            _SummaryItem('Cases', _cases.length),
            _SummaryItem('Open', open),
            _SummaryItem('Closed', _cases.length - open),
          ],
        ),
        _SimpleRecordSection(
          title: 'Case Register',
          emptyText: 'Belum ada case employee relations.',
          records: _cases,
          titleKeys: const ['subject', 'case_type'],
          subtitleKeys: const ['status', 'severity', 'case_date'],
        ),
      ],
    );
  }
}

class _DevelopmentScaffold extends StatelessWidget {
  final String title;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final List<Widget> children;

  const _DevelopmentScaffold({
    required this.title,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? _ErrorState(message: error!, onRetry: onRefresh)
          : RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: children,
              ),
            ),
    );
  }
}

class _SummaryBand extends StatelessWidget {
  final List<_SummaryItem> items;

  const _SummaryBand({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            for (final item in items)
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${item.value}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SimpleRecordSection extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<Map<String, dynamic>> records;
  final List<String> titleKeys;
  final List<String> subtitleKeys;

  const _SimpleRecordSection({
    required this.title,
    required this.emptyText,
    required this.records,
    required this.titleKeys,
    required this.subtitleKeys,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (records.isEmpty)
              Text(emptyText)
            else
              for (final item in records.take(20))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_read(item, titleKeys, fallback: '-')),
                  subtitle: Text(_joinValues(item, subtitleKeys)),
                ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem {
  final String label;
  final int value;

  const _SummaryItem(this.label, this.value);
}

List<Map<String, dynamic>> _records(dynamic data, String key) {
  if (data is Map && data[key] is List) {
    return (data[key] as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
  return const [];
}

String _joinValues(Map<String, dynamic> item, List<String> keys) {
  final values = keys
      .map((key) => _read(item, [key]))
      .where((value) => value.isNotEmpty)
      .toList();
  return values.isEmpty ? '-' : values.join(' | ');
}

String _read(
  Map<String, dynamic> item,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = item[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }

  final employee = item['employee'];
  if (employee is Map) {
    final nested = Map<String, dynamic>.from(employee);
    for (final key in keys) {
      final value = nested[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
  }

  return fallback;
}
