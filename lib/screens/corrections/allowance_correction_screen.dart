import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class AllowanceCorrectionScreen extends StatefulWidget {
  const AllowanceCorrectionScreen({super.key});

  @override
  State<AllowanceCorrectionScreen> createState() =>
      _AllowanceCorrectionScreenState();
}

class _AllowanceCorrectionScreenState extends State<AllowanceCorrectionScreen> {
  final ApiService _apiService = ApiService();
  DateTime? _cutoffStart;
  DateTime? _cutoffEnd;
  bool _loading = false;
  List<Map<String, dynamic>> _records = const [];

  @override
  Widget build(BuildContext context) {
    final total = _records.fold<num>(
      0,
      (sum, record) => sum + _readNum(record['total']),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Koreksi Tunjangan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FilterCard(
            title: 'Koreksi Meal Allowance',
            subtitle:
                'Pilih periode cutoff untuk melihat atau menghapus meal allowance.',
            children: [
              _DateButton(
                label: 'Tanggal Awal',
                value: _cutoffStart,
                onTap: () => _pickDate(isStart: true),
              ),
              const SizedBox(height: 10),
              _DateButton(
                label: 'Tanggal Akhir',
                value: _cutoffEnd,
                onTap: () => _pickDate(isStart: false),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _fetchAllowanceRecords,
                      icon: const Icon(Icons.search),
                      label: const Text('Cari Data'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _loading || _records.isEmpty
                          ? null
                          : _deleteAllowance,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Hapus'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_records.isEmpty)
            const _EmptyState(message: 'Belum ada data allowance.')
          else ...[
            _SummaryCard(
              title: 'Data Meal Allowance',
              value: '${_records.length} record',
              subtitle: 'Total: ${_formatCurrency(total)}',
            ),
            const SizedBox(height: 12),
            ..._records.map(
              (record) => _DataCard(
                title: _readString(record['name'], fallback: 'Karyawan'),
                subtitle: _formatCurrency(_readNum(record['total'])),
                rows: {
                  'Workdays': _readString(record['workDays']),
                  'Attendance': _readString(record['attendanceCount']),
                  'Absent': _readString(record['absentCount']),
                  'Late': _readString(record['lateCount']),
                  'Sick': _readString(record['sickCount']),
                  'Izin': _readString(record['izinCount']),
                  'Status': _readNum(record['total']) > 0
                      ? 'Tersimpan'
                      : 'Belum Diproses',
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_cutoffStart ?? now) : (_cutoffEnd ?? now),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      if (isStart) {
        _cutoffStart = picked;
      } else {
        _cutoffEnd = picked;
      }
    });
  }

  Future<void> _fetchAllowanceRecords() async {
    if (!_hasPeriod()) {
      _showMessage('Pilih tanggal awal dan akhir terlebih dahulu.');
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await _apiService.get(
        '/payroll/meal-allowance?cutoff_start=${_dateValue(_cutoffStart!)}&cutoff_end=${_dateValue(_cutoffEnd!)}',
      );
      final data = response is Map ? response['data'] : null;
      setState(() {
        _records = data is List
            ? data.whereType<Map>().map(Map<String, dynamic>.from).toList()
            : const [];
      });
      if (_records.isEmpty) {
        _showMessage('Tidak ada data untuk periode yang dipilih.');
      }
    } catch (error) {
      _showMessage('Gagal mengambil data allowance: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deleteAllowance() async {
    if (!_hasPeriod()) {
      _showMessage('Pilih tanggal awal dan akhir terlebih dahulu.');
      return;
    }

    final confirmed = await _confirm(
      'Hapus Allowance?',
      'Data meal allowance periode ini akan dihapus.',
    );
    if (!confirmed) {
      return;
    }

    setState(() => _loading = true);
    try {
      await _apiService.post('/payroll/delete-meal-allowance-all', {
        'cutoff_start': _dateValue(_cutoffStart!),
        'cutoff_end': _dateValue(_cutoffEnd!),
      });
      setState(() => _records = const []);
      _showMessage('Allowance berhasil dihapus.');
    } catch (error) {
      _showMessage('Gagal menghapus allowance: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  bool _hasPeriod() => _cutoffStart != null && _cutoffEnd != null;

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Ya'),
              ),
            ],
          ),
        ) ??
        false;
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

String _dateValue(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _readString(Object? value, {String fallback = '0'}) {
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

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_today_outlined),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text('$label: ${value == null ? '-' : _dateValue(value!)}'),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

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

class _DataCard extends StatelessWidget {
  const _DataCard({
    required this.title,
    required this.subtitle,
    required this.rows,
  });

  final String title;
  final String subtitle;
  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const Divider(height: 18),
            ...rows.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.key)),
                    Text(entry.value),
                  ],
                ),
              ),
            ),
          ],
        ),
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
