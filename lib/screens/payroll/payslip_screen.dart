import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/payroll_provider.dart';
import '../../models/payroll_model.dart';

class PayslipScreen extends StatefulWidget {
  const PayslipScreen({super.key});

  @override
  State<PayslipScreen> createState() => _PayslipScreenState();
}

class _PayslipScreenState extends State<PayslipScreen> {
  static const int _pageSize = 20;

  int _visibleCount = _pageSize;
  String _query = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PayrollProvider>().fetchPayslips();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Payslips',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<PayrollProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.payslips.isEmpty) {
            return const Center(child: Text('No payslips available'));
          }

          final payslips = _filteredPayslips(provider.payslips);
          final visiblePayslips = payslips.take(_visibleCount).toList();
          final hiddenCount = payslips.length - visiblePayslips.length;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: visiblePayslips.length + 2 + (hiddenCount > 0 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildFilters(provider.payslips);
              }
              if (index == 1) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Menampilkan ${visiblePayslips.length} dari ${payslips.length} payslip',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }
              final payslipIndex = index - 2;
              if (payslipIndex >= visiblePayslips.length) {
                return Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _visibleCount += _pageSize;
                    }),
                    icon: const Icon(Icons.expand_more_rounded),
                    label: Text('Muat 20 lagi ($hiddenCount tersisa)'),
                  ),
                );
              }
              final payslip = visiblePayslips[payslipIndex];
              return _buildPayslipCard(context, payslip);
            },
          );
        },
      ),
    );
  }

  Widget _buildFilters(List<Payslip> payslips) {
    final statuses = {
      'all': 'All',
      for (final payslip in payslips)
        payslip.status.toLowerCase(): payslip.status,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Cari payslip',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (value) => setState(() {
              _query = value;
              _visibleCount = _pageSize;
            }),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: statuses.containsKey(_statusFilter)
                ? _statusFilter
                : 'all',
            decoration: const InputDecoration(labelText: 'Status'),
            items: statuses.entries
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() {
              _statusFilter = value ?? 'all';
              _visibleCount = _pageSize;
            }),
          ),
        ],
      ),
    );
  }

  List<Payslip> _filteredPayslips(List<Payslip> payslips) {
    final query = _query.trim().toLowerCase();
    return payslips.where((payslip) {
      if (_statusFilter != 'all' &&
          payslip.status.toLowerCase() != _statusFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      return [
        payslip.id,
        payslip.month,
        payslip.year,
        payslip.status,
      ].join(' ').toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildPayslipCard(BuildContext context, Payslip payslip) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        childrenPadding: const EdgeInsets.all(20),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${payslip.month} ${payslip.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    payslip.status,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(payslip.netSalary),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        children: [
          const Divider(),
          _buildDetailSection('Earnings', payslip.earningsDetail, Colors.green),
          const SizedBox(height: 16),
          _buildDetailSection(
            'Deductions',
            payslip.deductionsDetail,
            Colors.red,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Net Salary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                currencyFormat.format(payslip.netSalary),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Generating Payslip PDF...')),
                );
                await Provider.of<PayrollProvider>(
                  context,
                  listen: false,
                ).downloadPayslip(payslip.id);
                if (!context.mounted) return;
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Payslip PDF saved to app documents/payslips',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('Download PDF'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    Map<String, double> items,
    Color amountColor,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ...items.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  currencyFormat.format(entry.value),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: amountColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
