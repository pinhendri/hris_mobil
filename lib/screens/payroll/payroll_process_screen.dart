import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';

class PayrollProcessScreen extends StatefulWidget {
  const PayrollProcessScreen({super.key});

  @override
  State<PayrollProcessScreen> createState() => _PayrollProcessScreenState();
}

class _PayrollProcessScreenState extends State<PayrollProcessScreen> {
  static const int _pageSize = 20;

  final ApiService _apiService = ApiService();
  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  late int _year = DateTime.now().year;
  late int _month = DateTime.now().month;
  late DateTime _cutoffStart = DateTime(
    DateTime.now().year,
    DateTime.now().month - 1,
    25,
  );
  late DateTime _cutoffEnd = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    24,
  );

  bool _loading = false;
  bool _mealLoading = false;
  String _query = '';
  String _statusFilter = 'all';
  int _visibleCount = _pageSize;
  int _mealVisibleCount = _pageSize;
  List<Map<String, dynamic>> _employees = const [];
  List<Map<String, dynamic>> _allowances = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPayroll());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payroll')),
      body: RefreshIndicator(
        onRefresh: _fetchPayroll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPeriodCard(),
            const SizedBox(height: 12),
            _buildMealAllowanceCard(),
            const SizedBox(height: 12),
            _buildPayrollCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Periode Payroll',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
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
                        : (value) {
                            setState(() => _month = value ?? _month);
                            _fetchPayroll();
                          },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _year,
                    decoration: const InputDecoration(labelText: 'Tahun'),
                    items: List.generate(8, (index) {
                      final year = DateTime.now().year - 4 + index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text('$year'),
                      );
                    }),
                    onChanged: _loading
                        ? null
                        : (value) {
                            setState(() => _year = value ?? _year);
                            _fetchPayroll();
                          },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealAllowanceCard() {
    final visibleAllowances = _allowances.take(_mealVisibleCount).toList();
    final hiddenCount = _allowances.length - visibleAllowances.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meal Allowance (25 - 24)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _mealLoading
                        ? null
                        : () => _pickCutoffDate(isStart: true),
                    icon: const Icon(Icons.date_range_outlined),
                    label: Text(_dateValue(_cutoffStart)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _mealLoading
                        ? null
                        : () => _pickCutoffDate(isStart: false),
                    icon: const Icon(Icons.event_outlined),
                    label: Text(_dateValue(_cutoffEnd)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _mealLoading ? null : _fetchMealAllowance,
                icon: _mealLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restaurant_outlined),
                label: Text(
                  _mealLoading ? 'Menghitung...' : 'Hitung Meal Allowance',
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_allowances.isEmpty)
              const Text(
                'Belum ada data meal allowance. Hitung terlebih dahulu.',
              )
            else ...[
              Text(
                'Menampilkan ${visibleAllowances.length} dari ${_allowances.length} data',
              ),
              const SizedBox(height: 8),
              for (final item in visibleAllowances) _buildAllowanceTile(item),
              if (hiddenCount > 0)
                Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _mealVisibleCount += _pageSize;
                    }),
                    icon: const Icon(Icons.expand_more_rounded),
                    label: Text('Muat 20 lagi ($hiddenCount tersisa)'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPayrollCard() {
    final filtered = _filteredEmployees();
    final visible = filtered.take(_visibleCount).toList();
    final hiddenCount = filtered.length - visible.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Proses Payroll',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _loading ? null : _fetchPayroll,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Cari karyawan',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) => setState(() {
                _query = value;
                _visibleCount = _pageSize;
              }),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _statusFilter,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(
                  value: 'unprocessed',
                  child: Text('Belum diproses'),
                ),
                DropdownMenuItem(
                  value: 'processed',
                  child: Text('Sudah diproses'),
                ),
              ],
              onChanged: (value) => setState(() {
                _statusFilter = value ?? 'all';
                _visibleCount = _pageSize;
              }),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _generateAllPayroll,
                    icon: const Icon(Icons.playlist_add_check_rounded),
                    label: const Text('Generate Payroll'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _fetchPayrollReport,
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Print Payroll'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_employees.isEmpty)
              const Text('Tidak ada data karyawan payroll untuk periode ini.')
            else if (filtered.isEmpty)
              const Text('Tidak ada karyawan yang cocok dengan filter.')
            else ...[
              Text(
                'Menampilkan ${visible.length} dari ${filtered.length} karyawan',
              ),
              const SizedBox(height: 8),
              for (final employee in visible) _buildEmployeeTile(employee),
              if (hiddenCount > 0)
                Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _visibleCount += _pageSize;
                    }),
                    icon: const Icon(Icons.expand_more_rounded),
                    label: Text('Muat 20 lagi ($hiddenCount tersisa)'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAllowanceTile(Map<String, dynamic> item) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(_readString(item, const ['name'], fallback: '-')),
      subtitle: Text(
        'Workdays ${_readString(item, const ['workDays'], fallback: '0')} | Absensi ${_readString(item, const ['attendanceCount'], fallback: '0')}',
      ),
      trailing: Text(
        _currency.format(_readNum(item, const ['total'])),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildEmployeeTile(Map<String, dynamic> employee) {
    final processed = _isProcessed(employee);
    final totalDeduction = _calculateTotalDeduction(employee);
    final id = _readString(employee, const ['id', 'employee_id', 'uuid']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _readString(employee, const [
                    'name',
                    'employee_name',
                  ], fallback: '-'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              _StatusBadge(
                processed ? 'Sudah Diproses' : 'Belum Diproses',
                processed: processed,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _readString(employee, const [
              'position',
              'position_name',
            ], fallback: '-'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _MiniInfo(
                'Basic',
                _currency.format(_readNum(employee, const ['basic_salary'])),
              ),
              _MiniInfo(
                'Allowance',
                _currency.format(
                  _readNum(employee, const ['allowance', 'allowances']),
                ),
              ),
              _MiniInfo(
                'Meal',
                _currency.format(_readNum(employee, const ['meal_allowance'])),
              ),
              _MiniInfo(
                'THR',
                _currency.format(_readNum(employee, const ['thr'])),
              ),
              _MiniInfo('Deduction', _currency.format(totalDeduction)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: processed
                ? OutlinedButton.icon(
                    onPressed: () => _showSlip(employee),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('Slip Individu'),
                  )
                : FilledButton.icon(
                    onPressed: id.isEmpty ? null : () => _processEmployee(id),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Proses Payroll'),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchPayroll() async {
    setState(() => _loading = true);
    try {
      final response = await _apiService.get(
        '/payroll?year=$_year&month=$_month',
      );
      if (!mounted) return;
      setState(() {
        _employees = _extractRecords(response);
        _visibleCount = _pageSize;
      });
    } catch (error) {
      _showMessage('Gagal ambil data payroll: $error');
      if (mounted) setState(() => _employees = const []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchMealAllowance() async {
    setState(() => _mealLoading = true);
    try {
      final query = Uri(
        queryParameters: {
          'cutoff_start': _dateValue(_cutoffStart),
          'cutoff_end': _dateValue(_cutoffEnd),
        },
      ).query;
      final response = await _apiService.get(
        '/payroll/meal-allowance-all?$query',
      );
      if (!mounted) return;
      setState(() {
        _allowances = _extractRecords(
          response,
          keys: const ['processed', 'data'],
        );
        _mealVisibleCount = _pageSize;
      });
      _showMessage('Meal allowance berhasil dihitung.');
    } catch (error) {
      _showMessage('Gagal hitung meal allowance: $error');
      if (mounted) setState(() => _allowances = const []);
    } finally {
      if (mounted) setState(() => _mealLoading = false);
    }
  }

  Future<void> _generateAllPayroll() async {
    final confirmed = await _confirm(
      'Generate Payroll?',
      'Payroll $_month/$_year akan diproses untuk semua karyawan.',
    );
    if (!confirmed) return;

    setState(() => _loading = true);
    try {
      await _apiService.post('/payroll/generate', {
        'year': _year,
        'month': _month,
      });
      _showMessage('Semua payroll berhasil diproses.');
      await _fetchPayroll();
    } catch (error) {
      _showMessage('Gagal proses semua payroll: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _processEmployee(String employeeId) async {
    setState(() => _loading = true);
    try {
      await _apiService.post('/payroll/$employeeId/process', {
        'year': _year,
        'month': _month,
      });
      _showMessage('Payroll berhasil diproses.');
      await _fetchPayroll();
    } catch (error) {
      _showMessage('Gagal proses payroll: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchPayrollReport() async {
    try {
      final response = await _apiService.get(
        '/payroll/report?year=$_year&month=$_month',
      );
      final records = _extractRecords(response);
      _showMessage(
        records.isEmpty
            ? 'Belum ada data payroll.'
            : 'Payroll report tersedia: ${records.length} record.',
      );
    } catch (error) {
      _showMessage('Gagal ambil report payroll: $error');
    }
  }

  Future<void> _pickCutoffDate({required bool isStart}) async {
    final current = isStart ? _cutoffStart : _cutoffEnd;
    final selected = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(DateTime.now().year - 3),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (selected == null) return;
    setState(() {
      if (isStart) {
        _cutoffStart = selected;
      } else {
        _cutoffEnd = selected;
      }
    });
  }

  Future<bool> _confirm(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Lanjut'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSlip(Map<String, dynamic> employee) {
    final gross =
        _readNum(employee, const ['basic_salary']) +
        _readNum(employee, const ['allowance', 'allowances']) +
        _readNum(employee, const ['meal_allowance']) +
        _readNum(employee, const ['thr']) +
        _readNum(employee, const ['bonus']);
    final deduction = _calculateTotalDeduction(employee);
    final net = gross - deduction;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Slip Individu',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _slipRow(
              'Nama',
              _readString(employee, const [
                'name',
                'employee_name',
              ], fallback: '-'),
            ),
            _slipRow(
              'Jabatan',
              _readString(employee, const [
                'position',
                'position_name',
              ], fallback: '-'),
            ),
            _slipRow('Gaji Kotor', _currency.format(gross)),
            _slipRow('Total Potongan', _currency.format(deduction)),
            const Divider(),
            _slipRow('Gaji Bersih', _currency.format(net), bold: true),
          ],
        ),
      ),
    );
  }

  Widget _slipRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filteredEmployees() {
    final query = _query.trim().toLowerCase();
    return _employees.where((employee) {
      final processed = _isProcessed(employee);
      if (_statusFilter == 'processed' && !processed) return false;
      if (_statusFilter == 'unprocessed' && processed) return false;
      if (query.isEmpty) return true;
      return [
        _readString(employee, const ['name', 'employee_name']),
        _readString(employee, const ['position', 'position_name']),
        _readString(employee, const ['id', 'employee_id', 'uuid']),
      ].join(' ').toLowerCase().contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> _extractRecords(
    dynamic response, {
    List<String> keys = const ['data'],
  }) {
    if (response is List) {
      return response.whereType<Map>().map(Map<String, dynamic>.from).toList();
    }
    if (response is Map) {
      for (final key in keys) {
        final value = response[key];
        if (value is List) {
          return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
        }
        if (value is Map && value['data'] is List) {
          return (value['data'] as List)
              .whereType<Map>()
              .map(Map<String, dynamic>.from)
              .toList();
        }
      }
      if (response['success'] == true && response['data'] is List) {
        return (response['data'] as List)
            .whereType<Map>()
            .map(Map<String, dynamic>.from)
            .toList();
      }
    }
    return const [];
  }

  bool _isProcessed(Map<String, dynamic> employee) {
    final value = employee['payrollProcessed'] ?? employee['payroll_processed'];
    if (value is bool) return value;
    return value.toString().toLowerCase() == 'true' || value.toString() == '1';
  }

  double _calculateTotalDeduction(Map<String, dynamic> employee) {
    final basic = _readNum(employee, const ['basic_salary']);
    final bpjsKesehatan =
        basic * _readNum(employee, const ['bpjs_kesehatan']) / 100;
    final bpjsTk =
        basic * _readNum(employee, const ['bpjs_ketenagakerjaan']) / 100;
    final bpjsJp = basic * _readNum(employee, const ['bpjs_jp']) / 100;
    final pph = _readNum(employee, const ['pph21', 'pkp', 'tax']);
    return bpjsKesehatan + bpjsTk + bpjsJp + pph;
  }

  double _readNum(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(
        (value ?? '').toString().replaceAll(',', ''),
      );
      if (parsed != null) return parsed;
    }
    return 0;
  }

  String _readString(
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
    return fallback;
  }

  String _dateValue(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final bool processed;

  const _StatusBadge(this.label, {required this.processed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: processed ? const Color(0xFFE7F8EF) : const Color(0xFFFFF7D6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: processed ? const Color(0xFF16834A) : const Color(0xFF946200),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;

  const _MiniInfo(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
