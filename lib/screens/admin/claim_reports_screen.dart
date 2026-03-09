import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/claim_provider.dart';
import '../../models/claim_model.dart';

class ClaimReportsScreen extends StatefulWidget {
  const ClaimReportsScreen({super.key});

  @override
  State<ClaimReportsScreen> createState() => _ClaimReportsScreenState();
}

class _ClaimReportsScreenState extends State<ClaimReportsScreen> {
  String _range = '30';

  List<ClaimModel> _filterByRange(List<ClaimModel> claims) {
    if (_range == 'all') return claims;
    final now = DateTime.now();
    if (_range == '7') {
      final from = now.subtract(const Duration(days: 7));
      return claims.where((c) => c.date.isAfter(from)).toList();
    }
    if (_range == 'month') {
      final from = DateTime(now.year, now.month, 1);
      return claims.where((c) => c.date.isAfter(from) || c.date.isAtSameMomentAs(from)).toList();
    }
    final from = now.subtract(const Duration(days: 30));
    return claims.where((c) => c.date.isAfter(from)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Claim Reports',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Consumer<ClaimProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filtered = _filterByRange(provider.claims);

          if (filtered.isEmpty) {
            return Center(
              child: Text(
                'No claims in this period',
                style: GoogleFonts.poppins(color: AppColors.textSecondary),
              ),
            );
          }

          final totalClaims = filtered.length;
          final pendingManager =
              filtered.where((c) => c.status == 'pending').length;
          final pendingHr =
              filtered.where((c) => c.status == 'manager_approved').length;
          final approved =
              filtered.where((c) => c.status == 'approved').length;
          final rejected =
              filtered.where((c) => c.status == 'rejected').length;

          final totalApprovedAmount = filtered
              .where((c) => c.status == 'approved')
              .fold<double>(0, (sum, c) => sum + c.amount);

          final byType = <String, double>{};
          for (final c in filtered.where((c) => c.status == 'approved')) {
            byType[c.type] = (byType[c.type] ?? 0) + c.amount;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Overview',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    DropdownButton<String>(
                      value: _range,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: '7',
                          child: Text('Last 7 days'),
                        ),
                        DropdownMenuItem(
                          value: '30',
                          child: Text('Last 30 days'),
                        ),
                        DropdownMenuItem(
                          value: 'month',
                          child: Text('This month'),
                        ),
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All time'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          _range = val;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _statCard(
                      title: 'Total Claims',
                      value: totalClaims.toString(),
                      color: AppColors.primary,
                    ),
                    _statCard(
                      title: 'Pending (Manager)',
                      value: pendingManager.toString(),
                      color: Colors.orange,
                    ),
                    _statCard(
                      title: 'Pending (HR)',
                      value: pendingHr.toString(),
                      color: Colors.blue,
                    ),
                    _statCard(
                      title: 'Approved',
                      value: approved.toString(),
                      color: Colors.green,
                    ),
                    _statCard(
                      title: 'Rejected',
                      value: rejected.toString(),
                      color: Colors.red,
                    ),
                    _statCard(
                      title: 'Approved Amount',
                      value:
                          NumberFormat.currency(symbol: '\$').format(totalApprovedAmount),
                      color: Colors.teal,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Approved Amount by Category',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: byType.entries.map((e) {
                    final label = e.key.toUpperCase();
                    final value = e.value;
                    final pct = totalApprovedAmount == 0
                        ? 0.0
                        : (value / totalApprovedAmount).clamp(0.0, 1.0);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                label,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                NumberFormat.currency(symbol: '\$')
                                    .format(value),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              backgroundColor:
                                  AppColors.inputBackground.withValues(alpha: 0.7),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

