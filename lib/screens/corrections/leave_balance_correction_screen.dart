import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class LeaveBalanceCorrectionScreen extends StatefulWidget {
  const LeaveBalanceCorrectionScreen({super.key});

  @override
  State<LeaveBalanceCorrectionScreen> createState() =>
      _LeaveBalanceCorrectionScreenState();
}

class _LeaveBalanceCorrectionScreenState
    extends State<LeaveBalanceCorrectionScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = false;
  int _page = 1;
  int _lastPage = 1;
  List<Map<String, dynamic>> _balances = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchBalances());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companyCode = context.watch<AuthProvider>().getCompanyCode();

    return Scaffold(
      appBar: AppBar(title: const Text('Koreksi Saldo Cuti')),
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
                    'Manajemen Saldo Cuti Karyawan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    companyCode.isEmpty
                        ? 'Company belum dipilih'
                        : 'Company: $companyCode',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Cari nama atau NIK',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _fetchBalances(page: 1),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loading
                              ? null
                              : () => _fetchBalances(page: 1),
                          icon: const Icon(Icons.search),
                          label: const Text('Cari'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _loading ? null : _initializeAll,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Inisialisasi'),
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
          else if (_balances.isEmpty)
            const _EmptyState(
              message:
                  'Belum ada data saldo cuti. Silakan inisialisasi terlebih dahulu.',
            )
          else ...[
            ..._balances.map(_buildBalanceCard),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _page <= 1 || _loading
                        ? null
                        : () => _fetchBalances(page: _page - 1),
                    child: const Text('Previous'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('$_page / $_lastPage'),
                ),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _page >= _lastPage || _loading
                        ? null
                        : () => _fetchBalances(page: _page + 1),
                    child: const Text('Next'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceCard(Map<String, dynamic> balance) {
    final employee = balance['employee'] is Map
        ? Map<String, dynamic>.from(balance['employee'])
        : <String, dynamic>{};
    final annualRemaining =
        _readInt(balance['annual_total']) - _readInt(balance['annual_used']);
    final sickRemaining =
        _readInt(balance['sick_total']) - _readInt(balance['sick_used']);
    final personalRemaining =
        _readInt(balance['personal_total']) -
        _readInt(balance['personal_used']);
    final totalRemaining = annualRemaining + sickRemaining + personalRemaining;

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
            const SizedBox(height: 2),
            Text(_readString(employee['nik_employee'], fallback: '-')),
            Text(_readString(employee['position_name'], fallback: '-')),
            const Divider(height: 18),
            _row('Cuti Tahunan', '$annualRemaining hari'),
            _row('Cuti Sakit', '$sickRemaining hari'),
            _row('Cuti Pribadi', '$personalRemaining hari'),
            _row('Total Sisa', '$totalRemaining hari'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : () => _openEditSheet(balance),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Koreksi'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading
                        ? null
                        : () => _resetBalance(_readString(balance['uuid'])),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchBalances({int page = 1}) async {
    final companyCode = context.read<AuthProvider>().getCompanyCode();
    setState(() => _loading = true);
    try {
      final query = Uri(
        queryParameters: {
          'page': '$page',
          'search': _searchController.text.trim(),
          if (companyCode.isNotEmpty) 'c_code': companyCode,
        },
      ).query;
      final response = await _apiService.get(
        '/leave-balance/leave-balances?$query',
      );
      final root = response is Map ? response['data'] : null;
      final data = root is Map ? root['data'] : null;
      final meta = root is Map ? root['meta'] : null;

      setState(() {
        _balances = data is List
            ? data.whereType<Map>().map(Map<String, dynamic>.from).toList()
            : const [];
        _page = _readInt(
          meta is Map ? meta['current_page'] : page,
          fallback: page,
        );
        _lastPage = _readInt(meta is Map ? meta['last_page'] : 1, fallback: 1);
      });
    } catch (error) {
      _showMessage('Gagal mengambil saldo cuti: $error');
      setState(() => _balances = const []);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _initializeAll() async {
    final confirmed = await _confirm(
      'Inisialisasi Saldo Cuti?',
      'Saldo cuti akan dibuat untuk semua karyawan yang belum memiliki saldo.',
    );
    if (!confirmed) {
      return;
    }

    final companyCode = context.read<AuthProvider>().getCompanyCode();
    setState(() => _loading = true);
    try {
      await _apiService.post('/leave-balance/leave-balances/initialize', {
        if (companyCode.isNotEmpty) 'c_code': companyCode,
      });
      _showMessage('Saldo cuti berhasil diinisialisasi.');
      await _fetchBalances(page: 1);
    } catch (error) {
      _showMessage('Gagal inisialisasi saldo: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _resetBalance(String uuid) async {
    if (uuid.isEmpty) {
      return;
    }

    final confirmed = await _confirm(
      'Reset Saldo Cuti?',
      'Saldo cuti akan direset ke nilai default.',
    );
    if (!confirmed) {
      return;
    }

    final companyCode = context.read<AuthProvider>().getCompanyCode();
    setState(() => _loading = true);
    try {
      await _apiService.post('/leave-balance/leave-balances/$uuid/reset', {
        if (companyCode.isNotEmpty) 'c_code': companyCode,
      });
      _showMessage('Saldo cuti berhasil direset.');
      await _fetchBalances(page: _page);
    } catch (error) {
      _showMessage('Gagal reset saldo: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openEditSheet(Map<String, dynamic> balance) async {
    final annualTotal = TextEditingController(
      text: _readString(balance['annual_total'], fallback: '0'),
    );
    final annualUsed = TextEditingController(
      text: _readString(balance['annual_used'], fallback: '0'),
    );
    final sickTotal = TextEditingController(
      text: _readString(balance['sick_total'], fallback: '0'),
    );
    final sickUsed = TextEditingController(
      text: _readString(balance['sick_used'], fallback: '0'),
    );
    final personalTotal = TextEditingController(
      text: _readString(balance['personal_total'], fallback: '0'),
    );
    final personalUsed = TextEditingController(
      text: _readString(balance['personal_used'], fallback: '0'),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                'Koreksi Saldo Cuti',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _numberField('Annual Total', annualTotal),
              _numberField('Annual Used', annualUsed),
              _numberField('Sick Total', sickTotal),
              _numberField('Sick Used', sickUsed),
              _numberField('Personal Total', personalTotal),
              _numberField('Personal Used', personalUsed),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  await _updateBalance(
                    uuid: _readString(balance['uuid']),
                    annualTotal: annualTotal.text,
                    annualUsed: annualUsed.text,
                    sickTotal: sickTotal.text,
                    sickUsed: sickUsed.text,
                    personalTotal: personalTotal.text,
                    personalUsed: personalUsed.text,
                  );
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Update Saldo'),
              ),
            ],
          ),
        );
      },
    );

    annualTotal.dispose();
    annualUsed.dispose();
    sickTotal.dispose();
    sickUsed.dispose();
    personalTotal.dispose();
    personalUsed.dispose();
  }

  Future<void> _updateBalance({
    required String uuid,
    required String annualTotal,
    required String annualUsed,
    required String sickTotal,
    required String sickUsed,
    required String personalTotal,
    required String personalUsed,
  }) async {
    if (uuid.isEmpty) {
      return;
    }

    final companyCode = context.read<AuthProvider>().getCompanyCode();
    setState(() => _loading = true);
    try {
      await _apiService.put('/leave-balance/leave-balances/$uuid', {
        'annual_total': int.tryParse(annualTotal) ?? 0,
        'annual_used': int.tryParse(annualUsed) ?? 0,
        'sick_total': int.tryParse(sickTotal) ?? 0,
        'sick_used': int.tryParse(sickUsed) ?? 0,
        'personal_total': int.tryParse(personalTotal) ?? 0,
        'personal_used': int.tryParse(personalUsed) ?? 0,
        if (companyCode.isNotEmpty) 'c_code': companyCode,
      });
      _showMessage('Saldo cuti berhasil diupdate.');
      await _fetchBalances(page: _page);
    } catch (error) {
      _showMessage('Gagal update saldo: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _numberField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      ),
    );
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

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _readInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
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
