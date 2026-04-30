import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class PayrollCorrectionScreen extends StatefulWidget {
  const PayrollCorrectionScreen({super.key});

  @override
  State<PayrollCorrectionScreen> createState() =>
      _PayrollCorrectionScreenState();
}

class _PayrollCorrectionScreenState extends State<PayrollCorrectionScreen> {
  final ApiService _apiService = ApiService();
  late int _year = DateTime.now().year;
  late int _month = DateTime.now().month;
  bool _loading = false;
  List<Map<String, dynamic>> _employees = const [];
  List<Map<String, dynamic>> _histories = const [];

  @override
  Widget build(BuildContext context) {
    final hasProcessedData =
        _employees.any((employee) => employee['payrollProcessed'] == true) ||
        _histories.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Koreksi Payroll')),
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
                    'Koreksi Payroll',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pilih periode untuk melihat, memproses, atau menghapus payroll.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    value: _year,
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
                    value: _month,
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
                          onPressed: _loading ? null : _loadAllData,
                          icon: const Icon(Icons.search),
                          label: const Text('Cari Data'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _loading || _employees.isEmpty
                              ? null
                              : _processAllPayroll,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Proses Semua'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading || !hasProcessedData
                          ? null
                          : _deleteAllPayroll,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Hapus Payroll untuk Proses Ulang'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_employees.isEmpty && _histories.isEmpty)
            const _EmptyState(message: 'Belum ada data payroll.')
          else ...[
            _SummaryCard(
              title: 'Data Payroll Karyawan',
              subtitle: '${_monthName(_month)} $_year',
              value: '${_employees.length} orang',
            ),
            const SizedBox(height: 12),
            ..._employees.map(_buildEmployeeCard),
            if (_histories.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'History Payroll',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ..._histories.map(_buildHistoryCard),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    final employeeId = _readString(employee['id']);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _readString(employee['name'], fallback: 'Karyawan'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(_readString(employee['position'], fallback: '-')),
            const Divider(height: 18),
            _row(
              'Gaji Pokok',
              _formatCurrency(_readNum(employee['basic_salary'])),
            ),
            _row('Allowance', _formatCurrency(_readNum(employee['allowance']))),
            _row(
              'Meal Allowance',
              _formatCurrency(_readNum(employee['meal_allowance'])),
            ),
            _row(
              'Status',
              employee['payrollProcessed'] == true
                  ? 'Sudah diproses'
                  : 'Belum diproses',
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loading || employeeId.isEmpty
                    ? null
                    : () => _processIndividualPayroll(employeeId),
                icon: const Icon(Icons.play_arrow_outlined),
                label: const Text('Proses Payroll'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> history) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _readString(
                history['name'] ?? history['employee_name'],
                fallback: 'Karyawan',
              ),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _row('Gross', _formatCurrency(_readNum(history['gross_salary']))),
            _row(
              'Deduction',
              _formatCurrency(_readNum(history['total_deduction'])),
            ),
            _row('Net', _formatCurrency(_readNum(history['net_salary']))),
          ],
        ),
      ),
    );
  }

  Future<void> _loadAllData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _apiService.get('/payroll?year=$_year&month=$_month'),
        _apiService.get('/payroll/report?year=$_year&month=$_month'),
      ]);

      final payrollData = results[0] is Map ? results[0]['data'] : null;
      final reportData = results[1];

      setState(() {
        _employees = payrollData is List
            ? payrollData
                  .whereType<Map>()
                  .map(Map<String, dynamic>.from)
                  .toList()
            : const [];
        _histories = reportData is List
            ? reportData
                  .whereType<Map>()
                  .map(Map<String, dynamic>.from)
                  .toList()
            : const [];
      });
    } catch (error) {
      _showMessage('Gagal mengambil data payroll: $error');
      setState(() {
        _employees = const [];
        _histories = const [];
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _processAllPayroll() async {
    setState(() => _loading = true);
    try {
      await _apiService.post('/payroll/generate', {
        'year': _year,
        'month': _month,
      });
      _showMessage('Payroll berhasil diproses untuk semua karyawan.');
      await _loadAllData();
    } catch (error) {
      _showMessage('Gagal memproses payroll: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _processIndividualPayroll(String employeeId) async {
    setState(() => _loading = true);
    try {
      await _apiService.post('/payroll/$employeeId/process', {
        'year': _year,
        'month': _month,
      });
      _showMessage('Payroll berhasil diproses.');
      await _loadAllData();
    } catch (error) {
      _showMessage('Gagal memproses payroll: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deleteAllPayroll() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Payroll?'),
            content: Text(
              'Data payroll ${_monthName(_month)} $_year akan dihapus untuk proses ulang.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    setState(() => _loading = true);
    try {
      await _apiService.post('/payroll/delete-process-all', {
        'year': _year,
        'month': _month,
      });
      _showMessage('Payroll berhasil dihapus.');
      await _loadAllData();
    } catch (error) {
      _showMessage('Gagal menghapus payroll: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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

num _readNum(Object? value) {
  if (value is num) {
    return value;
  }
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

String _formatCurrency(num value) {
  final text = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final reverseIndex = text.length - i;
    buffer.write(text[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }
  return 'Rp ${buffer.toString()}';
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final String title;
  final String subtitle;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(value, style: Theme.of(context).textTheme.titleSmall),
      ),
    );
  }
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
