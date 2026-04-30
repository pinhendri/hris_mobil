import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class PayrollSettingsScreen extends StatefulWidget {
  const PayrollSettingsScreen({super.key});

  @override
  State<PayrollSettingsScreen> createState() => _PayrollSettingsScreenState();
}

class _PayrollSettingsScreenState extends State<PayrollSettingsScreen> {
  final ApiService _apiService = ApiService();
  final _controllers = <String, TextEditingController>{};
  bool _loading = true;
  bool _saving = false;

  static const _fields = <String, String>{
    'bpjs_kesehatan_percent': 'BPJS Kesehatan (%)',
    'bpjs_ketenaga_percent': 'BPJS Ketenagakerjaan (%)',
    'bpjs_jpensiun_percent': 'BPJS JPensiun (%)',
    'pajak_percent': 'Pajak PPh 21 (%)',
    'thr_percent': 'THR (%)',
    'thr_month': 'Bulan THR',
    'bonus_percent': 'Bonus (%)',
    'religion_id': 'Religion ID',
    'meal_allowance': 'Meal Allowance',
    'emp_type': 'Employee Type',
  };

  @override
  void initState() {
    super.initState();
    for (final key in _fields.keys) {
      _controllers[key] = TextEditingController();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchSettings());
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Payroll')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pengaturan Payroll',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kelola parameter payroll yang dipakai perhitungan gaji.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        ..._fields.entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextField(
                              controller: _controllers[entry.key],
                              keyboardType: entry.key == 'emp_type'
                                  ? TextInputType.text
                                  : TextInputType.number,
                              decoration: InputDecoration(
                                labelText: entry.value,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _saveSettings,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _fetchSettings() async {
    final companyCode = context.read<AuthProvider>().getCompanyCode();
    setState(() => _loading = true);
    try {
      final query = Uri(
        queryParameters: {if (companyCode.isNotEmpty) 'c_code': companyCode},
      ).query;
      final response = await _apiService.get(
        query.isEmpty ? '/payroll/settings' : '/payroll/settings?$query',
      );
      final data = response is Map ? response['data'] : null;
      if (data is Map) {
        for (final key in _fields.keys) {
          _controllers[key]?.text = data[key]?.toString() ?? '';
        }
      }
    } catch (error) {
      _showMessage('Gagal mengambil pengaturan payroll: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    final companyCode = context.read<AuthProvider>().getCompanyCode();
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        for (final key in _fields.keys)
          key: key == 'emp_type'
              ? _controllers[key]?.text.trim() ?? ''
              : num.tryParse(_controllers[key]?.text.trim() ?? '') ?? 0,
        if (companyCode.isNotEmpty) 'c_code': companyCode,
      };
      await _apiService.put('/payroll/settings', payload);
      _showMessage('Payroll settings berhasil diupdate.');
    } catch (error) {
      _showMessage('Gagal update payroll settings: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
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
