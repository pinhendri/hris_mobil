import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/claim_model.dart';
import '../../providers/claim_provider.dart';

class ClaimsScreen extends StatefulWidget {
  const ClaimsScreen({super.key});

  @override
  State<ClaimsScreen> createState() => _ClaimsScreenState();
}

class _ClaimsScreenState extends State<ClaimsScreen> {
  final NumberFormat _idrFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Claims & Reimbursement',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<ClaimProvider>(
        builder: (context, provider, child) {
          final claims = provider.myClaims;

          if (provider.isLoading && claims.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && claims.isEmpty) {
            return _buildStateView(
              icon: Icons.receipt_long_outlined,
              message: provider.error!,
              actionLabel: 'Retry',
              onAction: provider.refresh,
            );
          }

          if (claims.isEmpty) {
            return _buildStateView(
              icon: Icons.receipt_long_outlined,
              message: 'Belum ada claim untuk akun ini.',
              actionLabel: 'Refresh',
              onAction: provider.refresh,
            );
          }

          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: claims.length,
              itemBuilder: (context, index) {
                final claim = claims[index];
                return GestureDetector(
                  onTap: claim.isEditable
                      ? () => _showClaimDialog(context, existing: claim)
                      : null,
                  child: _buildClaimCard(claim),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showClaimDialog(context),
        backgroundColor: const Color(0xFF1A237E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStateView({
    required IconData icon,
    required String message,
    required String actionLabel,
    required Future<void> Function() onAction,
  }) {
    return RefreshIndicator(
      onRefresh: onAction,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(icon, size: 72, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimCard(ClaimModel claim) {
    final statusColor = _statusColor(claim.status);
    final statusIcon = _statusIcon(claim.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        claim.title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(claim.date),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      if (claim.claimNumber != null &&
                          claim.claimNumber!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          claim.claimNumber!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  _formatCurrency(claim.amount, claim.currency),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A237E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              claim.description,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMetaChip(
                  icon: _getTypeIcon(claim.type),
                  label: claim.displayCategory,
                ),
                _buildMetaChip(
                  icon: Icons.account_tree_outlined,
                  label: claim.displayClaimType,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        claim.displayStatus,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF4B5563)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'paid':
        return Colors.teal;
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.highlight_off;
      case 'paid':
        return Icons.paid_outlined;
      default:
        return Icons.schedule_outlined;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'medical':
        return Icons.medical_services_outlined;
      case 'transport':
        return Icons.directions_car_outlined;
      case 'meals':
        return Icons.restaurant_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  String _formatCurrency(double amount, String currency) {
    if (currency.toUpperCase() == 'IDR') {
      return _idrFormat.format(amount);
    }

    return NumberFormat.currency(symbol: '$currency ').format(amount);
  }

  void _showClaimDialog(BuildContext context, {ClaimModel? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final amountController = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(0) : '',
    );
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );

    DateTime selectedDate = existing?.date ?? DateTime.now();
    String selectedCategory = existing?.type ?? 'transport';
    String selectedClaimType = existing?.claimType ?? 'expense';
    bool isSaving = false;

    final claimProvider = context.read<ClaimProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogBuilderContext, setState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Submit Claim' : 'Edit Claim',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: 'Rp ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedClaimType,
                      decoration: const InputDecoration(
                        labelText: 'Claim Type',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'expense',
                          child: Text('Expense'),
                        ),
                        DropdownMenuItem(
                          value: 'reimbursement',
                          child: Text('Reimbursement'),
                        ),
                        DropdownMenuItem(
                          value: 'travel',
                          child: Text('Travel'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          selectedClaimType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: const [
                        DropdownMenuItem(
                          value: 'transport',
                          child: Text('Transport'),
                        ),
                        DropdownMenuItem(
                          value: 'medical',
                          child: Text('Medical'),
                        ),
                        DropdownMenuItem(value: 'meals', child: Text('Meals')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          selectedCategory = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogBuilderContext,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now(),
                        );

                        if (picked == null) {
                          return;
                        }

                        setState(() {
                          selectedDate = picked;
                        });
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date of Expense',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd MMM yyyy').format(selectedDate),
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                            const Icon(Icons.calendar_today, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          final amount = double.tryParse(
                            amountController.text.replaceAll(',', ''),
                          );
                          final description = descriptionController.text.trim();

                          if (title.isEmpty ||
                              amount == null ||
                              amount <= 0 ||
                              description.isEmpty) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please fill title, amount, and description.',
                                ),
                              ),
                            );
                            return;
                          }

                          final limits = <String, double>{
                            'transport': 1000000,
                            'medical': 3000000,
                            'meals': 1500000,
                            'other': 1000000,
                          };
                          final maxAllowed =
                              limits[selectedCategory] ?? 1000000;
                          if (amount > maxAllowed) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Amount exceeds the category limit.',
                                ),
                              ),
                            );
                            return;
                          }

                          setState(() {
                            isSaving = true;
                          });

                          final claim = ClaimModel(
                            id: existing?.id ?? '',
                            employeeId: existing?.employeeId,
                            employeeUuid: existing?.employeeUuid,
                            employeeName: existing?.employeeName,
                            claimNumber: existing?.claimNumber,
                            title: title,
                            amount: amount,
                            date: selectedDate,
                            status: existing?.status ?? 'submitted',
                            type: selectedCategory,
                            claimType: selectedClaimType,
                            description: description,
                            currency: existing?.currency ?? 'IDR',
                            attachmentUrl: existing?.attachmentUrl,
                            approverName: existing?.approverName,
                          );

                          final success = existing == null
                              ? await claimProvider.submitClaim(claim)
                              : await claimProvider.updateClaim(claim);

                          if (!mounted) {
                            return;
                          }

                          if (success) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  claimProvider.lastActionMessage ??
                                      (existing == null
                                          ? 'Claim submitted.'
                                          : 'Claim updated.'),
                                ),
                                backgroundColor: claimProvider.lastActionQueued
                                    ? Colors.orange
                                    : null,
                              ),
                            );
                            return;
                          }

                          setState(() {
                            isSaving = false;
                          });

                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                claimProvider.error ?? 'Failed to save claim.',
                              ),
                            ),
                          );
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(existing == null ? 'Submit' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
