import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/claim_model.dart';
import '../../providers/claim_provider.dart';
import 'admin_palette.dart';

class ClaimManagementScreen extends StatelessWidget {
  const ClaimManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenBackgroundColor = AdminPalette.page(context);
    final surfaceColor = AdminPalette.surface(context);
    final primaryTextColor = AdminPalette.text(context);
    final secondaryTextColor = AdminPalette.mutedText(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: screenBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Claim Management',
            style: GoogleFonts.poppins(
              color: primaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: surfaceColor,
          surfaceTintColor: surfaceColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: primaryTextColor),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: secondaryTextColor,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Submitted'),
              Tab(text: 'Approved'),
              Tab(text: 'All'),
            ],
          ),
        ),
        body: Consumer<ClaimProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.claims.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null && provider.claims.isEmpty) {
              return _StateMessage(
                message: provider.error!,
                actionLabel: 'Retry',
                onAction: provider.refresh,
              );
            }

            final claims = provider.claims;
            final submittedClaims = claims
                .where((claim) => claim.status == 'submitted')
                .toList();
            final approvedClaims = claims
                .where((claim) => claim.status == 'approved')
                .toList();

            return TabBarView(
              children: [
                _ClaimList(
                  claims: submittedClaims,
                  stage: _ApprovalStage.submitted,
                ),
                _ClaimList(
                  claims: approvedClaims,
                  stage: _ApprovalStage.approved,
                ),
                _ClaimList(claims: claims, stage: _ApprovalStage.readOnly),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum _ApprovalStage { submitted, approved, readOnly }

class _StateMessage extends StatelessWidget {
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  const _StateMessage({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDarkMode
        ? const Color(0xFFCBD5E1)
        : AppColors.textSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 72,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: secondaryTextColor),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: secondaryTextColor,
                side: BorderSide(
                  color: isDarkMode
                      ? const Color(0xFF253041)
                      : AppColors.border,
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClaimList extends StatelessWidget {
  final List<ClaimModel> claims;
  final _ApprovalStage stage;

  const _ClaimList({required this.claims, required this.stage});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDarkMode
        ? const Color(0xFFCBD5E1)
        : AppColors.textSecondary;

    if (claims.isEmpty) {
      return Center(
        child: Text(
          'No claims in this stage',
          style: GoogleFonts.poppins(color: secondaryTextColor),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: context.read<ClaimProvider>().refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: claims.length,
        itemBuilder: (context, index) {
          return _ClaimManagementCard(claim: claims[index], stage: stage);
        },
      ),
    );
  }
}

class _ClaimManagementCard extends StatelessWidget {
  final ClaimModel claim;
  final _ApprovalStage stage;

  const _ClaimManagementCard({required this.claim, required this.stage});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode ? const Color(0xFF111827) : Colors.white;
    final surfaceBorderColor = isDarkMode
        ? const Color(0xFF253041)
        : AppColors.border;
    final primaryTextColor = isDarkMode
        ? const Color(0xFFF8FAFC)
        : AppColors.textPrimary;
    final secondaryTextColor = isDarkMode
        ? const Color(0xFFCBD5E1)
        : AppColors.textSecondary;
    final claimProvider = context.watch<ClaimProvider>();
    final statusColor = _statusColor(claim.status);
    final canApprove =
        stage == _ApprovalStage.submitted && claim.status == 'submitted';
    final canMarkPaid =
        stage == _ApprovalStage.approved && claim.status == 'approved';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: surfaceBorderColor),
        boxShadow: isDarkMode
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
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
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      claim.employeeName ?? 'Unknown employee',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(claim.date),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                    if (claim.claimNumber != null &&
                        claim.claimNumber!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        claim.claimNumber!,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: secondaryTextColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                _formatCurrency(claim.amount, claim.currency),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            claim.description,
            style: GoogleFonts.poppins(fontSize: 13, color: secondaryTextColor),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(label: claim.displayCategory),
              _InfoChip(label: claim.displayClaimType),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  claim.displayStatus,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (claim.approverName != null && claim.approverName!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Approver: ${claim.approverName!}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: secondaryTextColor,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (canApprove || canMarkPaid)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canApprove)
                  OutlinedButton(
                    onPressed: claimProvider.isSubmitting
                        ? null
                        : () async {
                            final success = await claimProvider.rejectClaim(
                              claim.id,
                            );
                            if (!context.mounted) {
                              return;
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Claim rejected.'
                                      : claimProvider.error ??
                                            'Failed to reject claim.',
                                ),
                              ),
                            );
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: surfaceBorderColor),
                    ),
                    child: const Text('Reject'),
                  ),
                if (canApprove) const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: claimProvider.isSubmitting
                      ? null
                      : () async {
                          final success = canApprove
                              ? await claimProvider.approveClaim(claim.id)
                              : await claimProvider.markClaimPaid(claim.id);

                          if (!context.mounted) {
                            return;
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? canApprove
                                          ? 'Claim approved.'
                                          : 'Claim marked as paid.'
                                    : claimProvider.error ??
                                          'Failed to update claim.',
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canApprove ? Colors.green : Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(canApprove ? 'Approve' : 'Mark Paid'),
                ),
              ],
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

  String _formatCurrency(double amount, String currency) {
    if (currency.toUpperCase() == 'IDR') {
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      return formatter.format(amount);
    }

    return NumberFormat.currency(symbol: '$currency ').format(amount);
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceMutedColor = isDarkMode
        ? const Color(0xFF0F172A)
        : AppColors.inputBackground;
    final secondaryTextColor = isDarkMode
        ? const Color(0xFFCBD5E1)
        : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: surfaceMutedColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: secondaryTextColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
