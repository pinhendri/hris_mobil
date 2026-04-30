import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class PphReportScreen extends StatefulWidget {
  const PphReportScreen({super.key});

  @override
  State<PphReportScreen> createState() => _PphReportScreenState();
}

class _PphReportScreenState extends State<PphReportScreen> {
  final ApiService _apiService = ApiService();
  late int _year = DateTime.now().year;
  late int _month = DateTime.now().month;
  bool _loading = false;
  List<Map<String, dynamic>> _reports = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchReports());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan PPh')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Laporan PPh',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lihat dan generate laporan PPh berdasarkan periode payroll.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    initialValue: _year,
                    decoration: const InputDecoration(labelText: 'Tahun'),
                    items: List.generate(10, (index) {
                      final year = DateTime.now().year - 5 + index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text('$year'),
                      );
                    }),
                    onChanged: _loading
                        ? null
                        : (value) => setState(() => _year = value ?? _year),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: _month,
                    decoration: const InputDecoration(labelText: 'Bulan'),
                    items: List.generate(12, (index) {
                      final month = index + 1;
                      return DropdownMenuItem(
                        value: month,
                        child: Text(_monthName(month)),
                      );
                    }),
                    onChanged: _loading
                        ? null
                        : (value) => setState(() => _month = value ?? _month),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : _fetchReports,
                          icon: const Icon(Icons.search),
                          label: const Text('Cari'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _loading ? null : _generateReport,
                          icon: const Icon(Icons.add_chart_outlined),
                          label: const Text('Generate'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_reports.isEmpty)
            const _EmptyState(message: 'Belum ada laporan PPh.')
          else
            ..._reports.map(_buildReportCard),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final id = _readString(report['id']);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _readString(
                report['title'] ?? report['name'],
                fallback: 'Laporan PPh',
              ),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _row(
              'Periode',
              '${_readString(report['month'], fallback: '$_month')} / ${_readString(report['year'], fallback: '$_year')}',
            ),
            _row('Status', _readString(report['status'], fallback: '-')),
            _row(
              'Total PPh',
              _readString(
                report['total_pph'] ?? report['total'],
                fallback: '-',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: id.isEmpty ? null : () => _submitReport(id),
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Submit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: id.isEmpty ? null : () => _deleteReport(id),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchReports() async {
    final companyCode = context.read<AuthProvider>().getCompanyCode();
    setState(() => _loading = true);
    try {
      final query = Uri(
        queryParameters: {
          'year': '$_year',
          'month': '$_month',
          if (companyCode.isNotEmpty) 'c_code': companyCode,
        },
      ).query;
      final response = await _apiService.get('/pph/reports?$query');
      final data = response is Map ? response['data'] : null;
      setState(() {
        _reports = data is List
            ? data.whereType<Map>().map(Map<String, dynamic>.from).toList()
            : data is Map && data['data'] is List
            ? (data['data'] as List)
                  .whereType<Map>()
                  .map(Map<String, dynamic>.from)
                  .toList()
            : const [];
      });
    } catch (error) {
      _showMessage('Gagal mengambil laporan PPh: $error');
      setState(() => _reports = const []);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _generateReport() async {
    final companyCode = context.read<AuthProvider>().getCompanyCode();
    setState(() => _loading = true);
    try {
      await _apiService.post('/pph/reports/generate', {
        'year': _year,
        'month': _month,
        if (companyCode.isNotEmpty) 'c_code': companyCode,
      });
      _showMessage('Laporan PPh berhasil dibuat.');
      await _fetchReports();
    } catch (error) {
      _showMessage('Gagal generate laporan PPh: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _submitReport(String id) async {
    try {
      await _apiService.post('/pph/reports/$id/submit', {});
      _showMessage('Laporan PPh berhasil disubmit.');
      await _fetchReports();
    } catch (error) {
      _showMessage('Gagal submit laporan PPh: $error');
    }
  }

  Future<void> _deleteReport(String id) async {
    try {
      await _apiService.delete('/pph/reports/$id');
      _showMessage('Laporan PPh berhasil dihapus.');
      await _fetchReports();
    } catch (error) {
      _showMessage('Gagal hapus laporan PPh: $error');
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

String _monthName(int month) {
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return months[(month - 1).clamp(0, 11)];
}

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Center(child: Text(message)),
      ),
    );
  }
}
