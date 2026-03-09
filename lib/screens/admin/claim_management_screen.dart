import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/claim_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/claim_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ClaimManagementScreen extends StatelessWidget {
  const ClaimManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'Claim Management',
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Manager'),
              Tab(text: 'HR'),
              Tab(text: 'All'),
            ],
          ),
        ),
        body: Consumer<ClaimProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final claims = provider.claims;

            if (claims.isEmpty) {
              return Center(
                child: Text(
                  'No claims found',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary),
                ),
              );
            }

            final managerClaims =
                claims.where((c) => c.status == 'pending').toList();
            final hrClaims =
                claims.where((c) => c.status == 'manager_approved').toList();

            return TabBarView(
              children: [
                _ClaimList(
                  claims: managerClaims,
                  stage: _ApprovalStage.manager,
                ),
                _ClaimList(
                  claims: hrClaims,
                  stage: _ApprovalStage.hr,
                ),
                _ClaimList(
                  claims: claims,
                  stage: _ApprovalStage.readOnly,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum _ApprovalStage { manager, hr, readOnly }

class _ClaimList extends StatelessWidget {
  final List<ClaimModel> claims;
  final _ApprovalStage stage;

  const _ClaimList({
    required this.claims,
    required this.stage,
  });

  @override
  Widget build(BuildContext context) {
    if (claims.isEmpty) {
      return Center(
        child: Text(
          'No claims in this stage',
          style: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: claims.length,
      itemBuilder: (context, index) {
        final claim = claims[index];
        return _ClaimManagementCard(
          claim: claim,
          stage: stage,
        );
      },
    );
  }
}

class _ClaimManagementCard extends StatelessWidget {
  final ClaimModel claim;
  final _ApprovalStage stage;

  const _ClaimManagementCard({
    required this.claim,
    required this.stage,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'manager_approved':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final claimProvider = Provider.of<ClaimProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );
    final statusColor = _statusColor(claim.status);
    final canActManager = stage == _ApprovalStage.manager &&
        claim.status == 'pending';
    final canActHr =
        stage == _ApprovalStage.hr && claim.status == 'manager_approved';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(claim.date),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
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
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            claim.description,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  claim.status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    claim.type.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (canActManager || canActHr)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    claimProvider.updateStatus(claim.id, 'rejected');
                    // notificationProvider.addNotification(
                    //   title: 'Claim Rejected',
                    //   message: 'Your claim "${claim.title}" has been rejected.',
                    //   type: 'warning',
                    // );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Claim rejected')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (stage == _ApprovalStage.manager) {
                      claimProvider.updateStatus(
                        claim.id,
                        'manager_approved',
                      );
                      // notificationProvider.addNotification(
                      //   title: 'Claim Manager Approved',
                      //   message:
                      //       'Your claim "${claim.title}" has been approved by your manager and is pending HR review.',
                      //   type: 'info',
                      // );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Moved to HR approval'),
                        ),
                      );
                    } else if (stage == _ApprovalStage.hr) {
                      claimProvider.updateStatus(
                        claim.id,
                        'approved',
                      );
                      // notificationProvider.addNotification(
                      //   title: 'Claim Approved',
                      //   message:
                      //       'Your claim "${claim.title}" has been approved for reimbursement.',
                      //   type: 'success',
                      // );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Claim approved')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    stage == _ApprovalStage.manager ? 'Approve (Manager)' : 'Approve (HR)',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
