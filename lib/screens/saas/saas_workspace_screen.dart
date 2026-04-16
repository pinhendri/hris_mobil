import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_strings.dart';
import '../../models/company.dart';
import '../../models/saas_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/saas_provider.dart';
import '../../providers/theme_provider.dart';

class SaasWorkspaceScreen extends StatefulWidget {
  const SaasWorkspaceScreen({super.key});

  @override
  State<SaasWorkspaceScreen> createState() => _SaasWorkspaceScreenState();
}

class _SaasWorkspaceScreenState extends State<SaasWorkspaceScreen> {
  final TextEditingController _inviteEmailController = TextEditingController();
  final TextEditingController _inviteNameController = TextEditingController();
  String _inviteRole = 'member';
  String _inviteAuthMode = 'either';
  bool _isSubmittingInvitation = false;
  int? _revokingInvitationId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      context.read<SaasProvider>().loadWorkspace(
        includeAdminOverview: authProvider.canAccessPlatformAdmin,
      );
    });
  }

  @override
  void dispose() {
    _inviteEmailController.dispose();
    _inviteNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final saasProvider = context.watch<SaasProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final currentCompany =
        saasProvider.currentCompany ?? authProvider.selectedCompany;
    final companies = saasProvider.companies.isNotEmpty
        ? saasProvider.companies
        : authProvider.companyAssignments;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          context.tr('saas_workspace_title'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () {
          return context.read<SaasProvider>().loadWorkspace(
            includeAdminOverview: authProvider.canAccessPlatformAdmin,
            force: true,
          );
        },
        child: saasProvider.isLoading && !saasProvider.hasLoadedData
            ? ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? Colors.blue.shade300 : Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('saas_loading'),
                            style: GoogleFonts.poppins(
                              color: isDark
                                  ? Colors.white70
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  _buildHeroCard(
                    context: context,
                    isDark: isDark,
                    currentCompany: currentCompany,
                    trialStatus: saasProvider.trialStatus,
                    pendingInvitations: saasProvider.pendingInvitationsCount,
                  ),
                  if (saasProvider.error != null && !saasProvider.hasLoadedData)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _buildErrorCard(
                        context,
                        isDark,
                        saasProvider.error!,
                      ),
                    ),
                  const SizedBox(height: 20),
                  _buildMetricsGrid(
                    context: context,
                    isDark: isDark,
                    currentCompany: currentCompany,
                    companies: companies,
                    saasProvider: saasProvider,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    context: context,
                    isDark: isDark,
                    title: context.tr('saas_send_invitation'),
                    subtitle: currentCompany?.companyName.isNotEmpty == true
                        ? '${currentCompany!.companyName} (${currentCompany.cCode})'
                        : context.tr('saas_send_invitation_subtitle'),
                    child: _buildInvitationForm(
                      context: context,
                      isDark: isDark,
                      authProvider: authProvider,
                      saasProvider: saasProvider,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    context: context,
                    isDark: isDark,
                    title: context.tr('saas_accessible_companies'),
                    subtitle: context.tr('saas_accessible_companies_subtitle'),
                    child: companies.isEmpty
                        ? _buildEmptyState(
                            context,
                            isDark,
                            context.tr('saas_no_companies'),
                          )
                        : Column(
                            children: companies
                                .map(
                                  (company) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildCompanyTile(
                                      context: context,
                                      isDark: isDark,
                                      company: company,
                                      isActive:
                                          currentCompany?.cCode ==
                                          company.cCode,
                                      saasProvider: saasProvider,
                                      authProvider: authProvider,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    context: context,
                    isDark: isDark,
                    title: context.tr('saas_invitations'),
                    subtitle: context.tr('saas_invitations_subtitle'),
                    child: saasProvider.invitations.isEmpty
                        ? _buildEmptyState(
                            context,
                            isDark,
                            context.tr('saas_no_invitations'),
                          )
                        : Column(
                            children: saasProvider.invitations
                                .take(5)
                                .map(
                                  (invitation) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildInvitationTile(
                                      context,
                                      isDark,
                                      invitation,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                  ),
                  if (authProvider.canAccessPlatformAdmin &&
                      saasProvider.adminOverview != null) ...[
                    const SizedBox(height: 20),
                    _buildSectionCard(
                      context: context,
                      isDark: isDark,
                      title: context.tr('saas_admin_snapshot'),
                      subtitle: context.tr('saas_admin_snapshot_subtitle'),
                      child: Column(
                        children: [
                          _buildAdminMetric(
                            context,
                            isDark,
                            context.tr('saas_pending_upgrades_global'),
                            '${saasProvider.adminOverview!['pending_upgrade_requests'] ?? 0}',
                          ),
                          const SizedBox(height: 12),
                          _buildAdminMetric(
                            context,
                            isDark,
                            context.tr('saas_total_companies_global'),
                            '${saasProvider.adminOverview!['total_companies'] ?? 0}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildHeroCard({
    required BuildContext context,
    required bool isDark,
    required Company? currentCompany,
    required TrialStatus? trialStatus,
    required int pendingInvitations,
  }) {
    final tone = _trialTone(trialStatus);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0F172A), Color(0xFF1D4ED8)]
              : const [Color(0xFFE0F2FE), Color(0xFFDBEAFE)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.blue : Colors.lightBlue).withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isDark ? 0.12 : 0.7),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: isDark ? Colors.white : Colors.blue.shade700,
                  size: 24,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: tone.withOpacity(isDark ? 0.18 : 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: tone.withOpacity(0.24)),
                ),
                child: Text(
                  _trialLabel(context, trialStatus),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tone,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            currentCompany?.companyName.isNotEmpty == true
                ? currentCompany!.companyName
                : context.tr('saas_company_not_selected'),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            currentCompany?.cCode.isNotEmpty == true
                ? '${context.tr('saas_company_code')}: ${currentCompany!.cCode}'
                : context.tr('saas_workspace_subtitle'),
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildHeroChip(
                icon: Icons.apartment_rounded,
                label: context.tr('saas_current_company'),
                value: currentCompany?.cCode.isNotEmpty == true
                    ? currentCompany!.cCode
                    : '-',
                isDark: isDark,
              ),
              _buildHeroChip(
                icon: Icons.timelapse_outlined,
                label: context.tr('saas_days_remaining'),
                value: trialStatus?.daysRemaining?.toString() ?? '-',
                isDark: isDark,
              ),
              _buildHeroChip(
                icon: Icons.mark_email_unread_outlined,
                label: context.tr('saas_pending_invitations'),
                value: pendingInvitations.toString(),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid({
    required BuildContext context,
    required bool isDark,
    required Company? currentCompany,
    required List<Company> companies,
    required SaasProvider saasProvider,
  }) {
    final metrics = [
      (
        icon: Icons.business_center_outlined,
        title: context.tr('saas_accessible_companies'),
        value: companies.length.toString(),
        color: Colors.blue,
      ),
      (
        icon: Icons.card_membership_outlined,
        title: context.tr('saas_trial_status'),
        value: _shortTrialValue(context, saasProvider.trialStatus),
        color: _trialTone(saasProvider.trialStatus),
      ),
      (
        icon: Icons.mail_outline_rounded,
        title: context.tr('saas_pending_invitations'),
        value: saasProvider.pendingInvitationsCount.toString(),
        color: Colors.orange,
      ),
      (
        icon: Icons.apartment_outlined,
        title: context.tr('saas_company_code'),
        value: currentCompany?.cCode.isNotEmpty == true
            ? currentCompany!.cCode
            : '-',
        color: Colors.teal,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.22,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: metric.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(metric.icon, color: metric.color, size: 20),
              ),
              const Spacer(),
              Text(
                metric.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                metric.title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildCompanyTile({
    required BuildContext context,
    required bool isDark,
    required Company company,
    required bool isActive,
    required SaasProvider saasProvider,
    required AuthProvider authProvider,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark ? Colors.blue.withOpacity(0.14) : Colors.blue.shade50)
            : (isDark ? const Color(0xFF262626) : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? Colors.blue.withOpacity(0.35)
              : (isDark ? Colors.white10 : Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.blue.withOpacity(0.12)
                  : Colors.grey.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.business_outlined,
              color: isActive ? Colors.blue : Colors.grey,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.companyName.isNotEmpty
                      ? company.companyName
                      : company.cCode,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${company.cCode} • ${company.subscriptionStatus.isNotEmpty
                      ? company.subscriptionStatus
                      : company.status.isNotEmpty
                      ? company.status
                      : context.tr('saas_plan_unknown')}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          isActive
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    context.tr('saas_company_active'),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                )
              : ElevatedButton(
                  onPressed: saasProvider.isSwitchingCompany
                      ? null
                      : () => _handleSwitchCompany(
                          context,
                          company,
                          authProvider,
                          saasProvider,
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: saasProvider.isSwitchingCompany
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          context.tr('saas_switch_company'),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
        ],
      ),
    );
  }

  Widget _buildInvitationTile(
    BuildContext context,
    bool isDark,
    SaasInvitation invitation,
  ) {
    final isPending = invitation.status.toLowerCase() == 'pending';
    final isRevoking = _revokingInvitationId == invitation.id;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isPending ? Colors.orange : Colors.green).withOpacity(
                0.12,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isPending ? Icons.schedule_send_outlined : Icons.mark_email_read,
              color: isPending ? Colors.orange : Colors.green,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invitation.email,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${invitation.name.isNotEmpty ? invitation.name : '-'} • ${invitation.role.isNotEmpty ? invitation.role : context.tr('saas_role_unknown')}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${invitation.authMode.isNotEmpty ? invitation.authMode : context.tr('saas_invitation_auth_unknown')} • ${_formatExpiry(context, invitation.expiresAt)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: (isPending ? Colors.orange : Colors.green).withOpacity(
                    0.12,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  invitation.status.isNotEmpty
                      ? invitation.status
                      : context.tr('saas_status_unknown'),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPending ? Colors.orange.shade700 : Colors.green,
                  ),
                ),
              ),
              if (invitation.token.isNotEmpty) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _copyInvitationToken(context, invitation),
                  child: Text(context.tr('saas_copy_invitation_token')),
                ),
              ],
              if (isPending) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: isRevoking
                      ? null
                      : () => _revokeInvitation(context, invitation),
                  child: Text(
                    isRevoking
                        ? context.tr('saas_revoking_invitation')
                        : context.tr('saas_revoke_invitation'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMetric(
    BuildContext context,
    bool isDark,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.monitor_heart_outlined, color: Colors.indigo),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: isDark ? Colors.white60 : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, bool isDark, String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.red.withOpacity(0.12) : Colors.red.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.withOpacity(0.22)),
      ),
      child: Text(
        message,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: isDark ? Colors.red.shade100 : Colors.red.shade700,
        ),
      ),
    );
  }

  Widget _buildHeroChip({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isDark ? 0.1 : 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? Colors.white70 : Colors.blue.shade700,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : Colors.grey.shade700,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationForm({
    required BuildContext context,
    required bool isDark,
    required AuthProvider authProvider,
    required SaasProvider saasProvider,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _inviteEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: context.tr('saas_invitation_email'),
            hintText: context.tr('saas_invitation_email_hint'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _inviteNameController,
          decoration: InputDecoration(
            labelText: context.tr('saas_invitation_name'),
            hintText: context.tr('saas_invitation_name_hint'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _inviteRole,
          decoration: InputDecoration(
            labelText: context.tr('saas_invitation_role'),
            border: const OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'member', child: Text('Member')),
            DropdownMenuItem(value: 'manager', child: Text('Manager')),
            DropdownMenuItem(value: 'hr', child: Text('HR')),
            DropdownMenuItem(value: 'admin', child: Text('Admin')),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              _inviteRole = value;
            });
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _inviteAuthMode,
          decoration: InputDecoration(
            labelText: context.tr('saas_invitation_auth_mode'),
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(
              value: 'either',
              child: Text(context.tr('saas_auth_either')),
            ),
            DropdownMenuItem(
              value: 'manual',
              child: Text(context.tr('saas_auth_manual')),
            ),
            DropdownMenuItem(
              value: 'sso_only',
              child: Text(context.tr('saas_auth_sso_only')),
            ),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              _inviteAuthMode = value;
            });
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmittingInvitation
                ? null
                : () => _submitInvitation(context, authProvider, saasProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSubmittingInvitation
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    context.tr('saas_send_invitation'),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context.tr('saas_invitation_delivery_note'),
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Future<void> _submitInvitation(
    BuildContext context,
    AuthProvider authProvider,
    SaasProvider saasProvider,
  ) async {
    final email = _inviteEmailController.text.trim();
    final name = _inviteNameController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final tr = context.tr;

    if (email.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(tr('saas_invitation_email_required')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingInvitation = true;
    });

    final result = await saasProvider.createInvitation(
      email: email,
      name: name,
      role: _inviteRole,
      authMode: _inviteAuthMode,
      includeAdminOverview: authProvider.canAccessPlatformAdmin,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmittingInvitation = false;
    });

    if (result['success'] == true) {
      _inviteEmailController.clear();
      _inviteNameController.clear();
      setState(() {
        _inviteRole = 'member';
        _inviteAuthMode = 'either';
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? tr('saas_invitation_sent'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ?? tr('saas_invitation_failed'),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade400,
      ),
    );
  }

  Future<void> _copyInvitationToken(
    BuildContext context,
    SaasInvitation invitation,
  ) async {
    await Clipboard.setData(ClipboardData(text: invitation.token));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('saas_invitation_token_copied')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _revokeInvitation(
    BuildContext context,
    SaasInvitation invitation,
  ) async {
    final authProvider = context.read<AuthProvider>();
    final saasProvider = context.read<SaasProvider>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _revokingInvitationId = invitation.id;
    });

    final result = await saasProvider.revokeInvitation(
      invitationId: invitation.id,
      includeAdminOverview: authProvider.canAccessPlatformAdmin,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _revokingInvitationId = null;
    });

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ??
              (result['success'] == true
                  ? context.tr('saas_invitation_revoked')
                  : context.tr('saas_invitation_revoke_failed')),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: result['success'] == true ? null : Colors.red.shade400,
      ),
    );
  }

  Future<void> _handleSwitchCompany(
    BuildContext context,
    Company company,
    AuthProvider authProvider,
    SaasProvider saasProvider,
  ) async {
    final result = await saasProvider.switchCompany(
      authProvider: authProvider,
      company: company,
      includeAdminOverview: authProvider.canAccessPlatformAdmin,
    );

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      await context.read<DashboardProvider>().fetchDashboardData(
        companyCode: authProvider.getCompanyCode(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context
                .tr('saas_switch_success')
                .replaceAll('{code}', company.cCode),
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? context.tr('saas_switch_failed'),
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  Color _trialTone(TrialStatus? trialStatus) {
    if (trialStatus == null) {
      return Colors.blueGrey;
    }

    if (trialStatus.isExpired) {
      return Colors.red;
    }

    if (trialStatus.isInGracePeriod ||
        (trialStatus.daysRemaining != null &&
            trialStatus.daysRemaining! <= 3)) {
      return Colors.orange;
    }

    if (trialStatus.isTrial) {
      return Colors.blue;
    }

    return Colors.green;
  }

  String _trialLabel(BuildContext context, TrialStatus? trialStatus) {
    if (trialStatus == null) {
      return context.tr('saas_trial_unavailable');
    }

    if (trialStatus.isExpired) {
      return context.tr('saas_trial_expired');
    }

    if (trialStatus.isInGracePeriod) {
      return context.tr('saas_grace_period');
    }

    if (trialStatus.isTrial) {
      if (trialStatus.daysRemaining != null) {
        return context
            .tr('saas_trial_days')
            .replaceAll('{count}', trialStatus.daysRemaining.toString());
      }

      return context.tr('saas_trial_active');
    }

    return context.tr('saas_active_plan');
  }

  String _shortTrialValue(BuildContext context, TrialStatus? trialStatus) {
    if (trialStatus == null) {
      return '-';
    }

    if (trialStatus.isExpired) {
      return context.tr('saas_trial_expired');
    }

    if (trialStatus.isInGracePeriod) {
      return context.tr('saas_grace_period');
    }

    if (trialStatus.isTrial) {
      return trialStatus.daysRemaining?.toString() ??
          context.tr('saas_trial_active');
    }

    return context.tr('saas_active_plan');
  }

  String _formatExpiry(BuildContext context, DateTime? value) {
    if (value == null) {
      return context.tr('saas_expiry_unknown');
    }

    return DateFormat('dd MMM yyyy').format(value);
  }
}
