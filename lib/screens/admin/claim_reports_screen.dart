import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/claim_model.dart';
import '../../providers/claim_provider.dart';
import 'admin_palette.dart';

class ClaimReportsScreen extends StatefulWidget {
  const ClaimReportsScreen({super.key});

  @override
  State<ClaimReportsScreen> createState() => _ClaimReportsScreenState();
}

class _ClaimReportsScreenState extends State<ClaimReportsScreen> {
  final NumberFormat _idrFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String _range = '30';

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  Color get _screenBackgroundColor => AdminPalette.page(context);

  Color get _surfaceColor => AdminPalette.surface(context);

  Color get _surfaceBorderColor => AdminPalette.border(context);

  Color get _primaryTextColor => AdminPalette.text(context);

  Color get _secondaryTextColor => AdminPalette.mutedText(context);

  List<BoxShadow> get _cardShadow => _isDarkMode
      ? const []
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ];

  List<ClaimModel> _filterByRange(List<ClaimModel> claims) {
    if (_range == 'all') {
      return claims;
    }

    final now = DateTime.now();
    if (_range == '7') {
      final from = now.subtract(const Duration(days: 7));
      return claims.where((claim) => !claim.date.isBefore(from)).toList();
    }

    if (_range == 'month') {
      final from = DateTime(now.year, now.month, 1);
      return claims.where((claim) => !claim.date.isBefore(from)).toList();
    }

    final from = now.subtract(const Duration(days: 30));
    return claims.where((claim) => !claim.date.isBefore(from)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Claim Reports',
          style: GoogleFonts.poppins(
            color: _primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _surfaceColor,
        surfaceTintColor: _surfaceColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: _primaryTextColor),
      ),
      body: Consumer<ClaimProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.claims.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.claims.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart_outlined,
                      size: 72,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: _secondaryTextColor),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: provider.refresh,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _secondaryTextColor,
                        side: BorderSide(color: _surfaceBorderColor),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final filtered = _filterByRange(provider.claims);

          if (filtered.isEmpty) {
            return Center(
              child: Text(
                'No claims in this period',
                style: GoogleFonts.poppins(color: _secondaryTextColor),
              ),
            );
          }

          final totalClaims = filtered.length;
          final submitted = filtered
              .where((claim) => claim.status == 'submitted')
              .length;
          final approved = filtered
              .where((claim) => claim.status == 'approved')
              .length;
          final paid = filtered.where((claim) => claim.status == 'paid').length;
          final rejected = filtered
              .where((claim) => claim.status == 'rejected')
              .length;

          final totalClaimAmount = filtered.fold<double>(
            0,
            (sum, claim) => sum + claim.amount,
          );
          final paidAmount = filtered
              .where((claim) => claim.status == 'paid')
              .fold<double>(0, (sum, claim) => sum + claim.amount);

          final byCategory = <String, double>{};
          for (final claim in filtered) {
            byCategory[claim.displayCategory] =
                (byCategory[claim.displayCategory] ?? 0) + claim.amount;
          }

          final categoryEntries = byCategory.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                          color: _primaryTextColor,
                        ),
                      ),
                      DropdownButton<String>(
                        value: _range,
                        underline: const SizedBox(),
                        dropdownColor: _surfaceColor,
                        style: GoogleFonts.poppins(color: _primaryTextColor),
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
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _range = value;
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
                        title: 'Submitted',
                        value: submitted.toString(),
                        color: Colors.orange,
                      ),
                      _statCard(
                        title: 'Approved',
                        value: approved.toString(),
                        color: Colors.green,
                      ),
                      _statCard(
                        title: 'Paid',
                        value: paid.toString(),
                        color: Colors.teal,
                      ),
                      _statCard(
                        title: 'Rejected',
                        value: rejected.toString(),
                        color: Colors.red,
                      ),
                      _statCard(
                        title: 'Total Amount',
                        value: _formatCurrency(totalClaimAmount),
                        color: Colors.indigo,
                      ),
                      _statCard(
                        title: 'Paid Amount',
                        value: _formatCurrency(paidAmount),
                        color: Colors.blueGrey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Claim Amount by Category',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: categoryEntries.map((entry) {
                      final value = entry.value;
                      final percentage = totalClaimAmount == 0
                          ? 0.0
                          : (value / totalClaimAmount).clamp(0.0, 1.0);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _surfaceBorderColor),
                          boxShadow: _cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _primaryTextColor,
                                  ),
                                ),
                                Text(
                                  _formatCurrency(value),
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
                                value: percentage,
                                minHeight: 6,
                                backgroundColor: AppColors.inputBackground
                                    .withValues(alpha: _isDarkMode ? 0.3 : 0.7),
                                valueColor: const AlwaysStoppedAnimation<Color>(
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
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _surfaceBorderColor),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _secondaryTextColor,
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

  String _formatCurrency(double amount) {
    return _idrFormat.format(amount);
  }
}
