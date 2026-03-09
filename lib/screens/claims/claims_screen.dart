import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/claim_provider.dart';
import '../../models/claim_model.dart';
import '../../providers/notification_provider.dart';

class ClaimsScreen extends StatefulWidget {
  const ClaimsScreen({super.key});

  @override
  State<ClaimsScreen> createState() => _ClaimsScreenState();
}

class _ClaimsScreenState extends State<ClaimsScreen> {
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
        backgroundColor: const Color(0xFF1a237e),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<ClaimProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.claims.length,
              itemBuilder: (context, index) {
                final claim = provider.claims[index];
                return GestureDetector(
                  onTap: claim.status == 'pending'
                      ? () => _showAddClaimDialog(context, existing: claim)
                      : null,
                  child: _buildClaimCard(context, claim),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddClaimDialog(context),
        backgroundColor: const Color(0xFF1a237e),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildClaimCard(BuildContext context, ClaimModel claim) {
    Color statusColor;
    IconData statusIcon;

    switch (claim.status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'manager_approved':
        statusColor = Colors.blue;
        statusIcon = Icons.verified_outlined;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.highlight_off;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
    }

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        DateFormat('MMM dd, yyyy').format(claim.date),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${claim.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1a237e),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getTypeIcon(claim.type),
                        size: 16,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      claim.type.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        claim.status.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
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

  void _showAddClaimDialog(BuildContext context, {ClaimModel? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final amountController = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(2) : '',
    );
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    DateTime selectedDate = existing?.date ?? DateTime.now();
    String selectedType = existing?.type ?? 'transport';

    final claimProvider = Provider.of<ClaimProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '\$',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      items: const [
                        DropdownMenuItem(
                          value: 'transport',
                          child: Text('Travel & Transport'),
                        ),
                        DropdownMenuItem(
                          value: 'medical',
                          child: Text('Medical'),
                        ),
                        DropdownMenuItem(
                          value: 'meals',
                          child: Text('Meals / Entertainment'),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text('Other / Misc'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedType = val;
                          });
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
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
                              DateFormat('MMM dd, yyyy').format(selectedDate),
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                            const Icon(Icons.calendar_today, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final amount =
                        double.tryParse(
                          amountController.text.replaceAll(',', ''),
                        ) ??
                        0;
                    final description = descriptionController.text.trim();

                    if (title.isEmpty || amount <= 0 || description.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please fill title, amount, and description',
                          ),
                        ),
                      );
                      return;
                    }

                    final limits = <String, double>{
                      'transport': 100,
                      'medical': 200,
                      'meals': 150,
                      'other': 100,
                    };
                    final maxAllowed = limits[selectedType] ?? 100;
                    if (amount > maxAllowed) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Amount exceeds limit for this category (max \$${maxAllowed.toStringAsFixed(0)}).',
                          ),
                        ),
                      );
                      return;
                    }

                    if (existing == null) {
  final newClaim = ClaimModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    title: title,
    amount: amount,
    date: selectedDate,
    status: 'pending',
    type: selectedType,
    description: description,
  );
  claimProvider.submitClaim(newClaim);
                      // Provider.of<NotificationProvider>(context, listen: false)
                      //     .createApprovalNotification(
                      //   type: 'claim',
                      //   title: 'Claim Approval Required',
                      //   message:
                      //       'Claim "$title" amount \$${amount.toStringAsFixed(2)} needs approval.',
                      //   data: {
                      //     'claim_title': title,
                      //     'claim_amount': amount,
                      //     'claim_type': selectedType,
                      //     'claim_date': DateFormat('yyyy-MM-dd')
                      //         .format(selectedDate),
                      //   },
                      //   recipients: ['manager', 'admin'],
                      // );
                   } else {
  final updated = ClaimModel(
    id: existing.id,
    title: title,
    amount: amount,
    date: selectedDate,
    status: existing.status,
    type: selectedType,
    description: description,
    attachmentUrl: existing.attachmentUrl,
  );
  claimProvider.updateClaim(updated);
}

                    Navigator.pop(dialogContext);
                  },
                  child: Text(existing == null ? 'Submit' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
