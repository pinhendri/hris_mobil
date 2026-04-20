import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/localization/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/leave_provider.dart';
import '../../providers/saas_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/company.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';

import '../profile/personal_info_screen.dart';
import '../profile/employment_details_screen.dart';
import '../profile/change_password_screen.dart';
import '../saas/saas_workspace_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  static const double _maxContentWidth = 520;

  final ApiService _apiService = ApiService();

  String? _lastLoadedCompanyCode;
  double _overtimeHours = 0;
  bool _isLoadingStats = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final companyCode = context.read<AuthProvider>().getCompanyCode();
    if (_isLoadingStats || companyCode == _lastLoadedCompanyCode) {
      return;
    }

    _lastLoadedCompanyCode = companyCode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadProfileStats();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final leaveProvider = Provider.of<LeaveProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final saasProvider = Provider.of<SaasProvider>(context);
    final user = auth.user;
    final isDark = themeProvider.isDarkMode;
    final currentLanguageLabel = languageProvider.languageCode == 'id'
        ? context.tr('profile_language_indonesian')
        : context.tr('profile_language_english');
    final currentCompany = saasProvider.currentCompany ?? auth.selectedCompany;
    final trialSubtitle = _buildTrialSubtitle(context, saasProvider);
    final companySubtitle = _buildCompanySubtitle(
      context,
      currentCompany,
      auth.companyAssignments.length,
    );

    return Scaffold(
      backgroundColor: _pageBackground(isDark),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        child: Column(
          children: [
            _buildHeader(
              context,
              user,
              isDark,
              companySubtitle: companySubtitle,
              currentLanguageLabel: currentLanguageLabel,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                96 + MediaQuery.of(context).padding.bottom,
              ),
              child: _buildConstrainedContent(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatsCards(
                      context,
                      leaveDays: _getLeaveDays(leaveProvider),
                      overtimeHours: _overtimeHours,
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      context.tr('profile_saas_workspace'),
                      icon: Icons.shield_outlined,
                      children: [
                        _buildMenuItem(
                          Icons.shield_outlined,
                          context.tr('saas_workspace_title'),
                          subtitle: context.tr(
                            'profile_saas_workspace_subtitle',
                          ),
                          color: Colors.indigo,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SaasWorkspaceScreen(),
                              ),
                            );
                          },
                          isDark: isDark,
                        ),
                        _buildMenuItem(
                          Icons.apartment_outlined,
                          context.tr('saas_current_company'),
                          subtitle: companySubtitle,
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SaasWorkspaceScreen(),
                              ),
                            );
                          },
                          isDark: isDark,
                        ),
                        _buildMenuItem(
                          Icons.card_membership_outlined,
                          context.tr('saas_trial_status'),
                          subtitle: trialSubtitle,
                          color: Colors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SaasWorkspaceScreen(),
                              ),
                            );
                          },
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      context.tr('profile_account'),
                      icon: Icons.person_outline_rounded,
                      children: [
                        _buildMenuItem(
                          Icons.person_outline,
                          context.tr('profile_personal_information'),
                          subtitle: context.tr(
                            'profile_personal_information_subtitle',
                          ),
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PersonalInfoScreen(),
                              ),
                            );
                          },
                          isDark: isDark,
                        ),
                        _buildMenuItem(
                          Icons.work_outline,
                          context.tr('profile_employment_details'),
                          subtitle: context.tr(
                            'profile_employment_details_subtitle',
                          ),
                          color: Colors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const EmploymentDetailsScreen(),
                              ),
                            );
                          },
                          isDark: isDark,
                        ),
                        _buildMenuItem(
                          Icons.lock_outline,
                          context.tr('profile_change_password'),
                          subtitle: context.tr(
                            'profile_change_password_subtitle',
                          ),
                          color: Colors.purple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ChangePasswordScreen(),
                              ),
                            );
                          },
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      context.tr('profile_app_settings'),
                      icon: Icons.tune_rounded,
                      children: [
                        _buildMenuItem(
                          Icons.dark_mode_outlined,
                          context.tr('profile_dark_mode'),
                          subtitle: isDark
                              ? context.tr('profile_dark_mode_to_light')
                              : context.tr('profile_dark_mode_to_dark'),
                          color: isDark ? Colors.amber : Colors.indigo,
                          trailing: Switch(
                            value: isDark,
                            onChanged: (val) {
                              themeProvider.toggleTheme(val);
                            },
                            activeThumbColor: Colors.blue,
                            activeTrackColor: Colors.blue.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          isDark: isDark,
                        ),
                        _buildMenuItem(
                          Icons.notifications_none,
                          context.tr('profile_notifications'),
                          subtitle: context.tr(
                            'profile_notifications_subtitle',
                          ),
                          color: Colors.red,
                          trailing: Switch(
                            value: true,
                            onChanged: (val) {},
                            activeThumbColor: Colors.green,
                          ),
                          isDark: isDark,
                        ),
                        _buildMenuItem(
                          Icons.language,
                          context.tr('profile_language'),
                          subtitle: context.tr('profile_language_subtitle'),
                          color: Colors.teal,
                          onTap: () => _showLanguageSheet(context, isDark),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : const Color(0xFFF4F7FB),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: _surfaceBorderColor(isDark),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.public,
                                  size: 16,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  currentLanguageLabel,
                                  style: GoogleFonts.poppins(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      context.tr('profile_support'),
                      icon: Icons.help_outline_rounded,
                      children: [
                        _buildMenuItem(
                          Icons.help_outline,
                          context.tr('profile_help_center'),
                          subtitle: context.tr('profile_help_center_subtitle'),
                          color: Colors.blue,
                          onTap: () {},
                          isDark: isDark,
                        ),
                        _buildMenuItem(
                          Icons.info_outline,
                          context.tr('profile_about_app'),
                          subtitle: context.tr('generic_version'),
                          color: Colors.purple,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'v1.0.0',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          isDark: isDark,
                        ),
                        _buildMenuItem(
                          Icons.privacy_tip_outlined,
                          context.tr('profile_privacy_policy'),
                          subtitle: context.tr(
                            'profile_privacy_policy_subtitle',
                          ),
                          color: Colors.teal,
                          onTap: () {},
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          _showLogoutDialog(context, auth, isDark);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout_rounded, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              context.tr('profile_logout'),
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConstrainedContent(Widget child) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: child,
      ),
    );
  }

  Color _pageBackground(bool isDark) {
    return isDark ? const Color(0xFF0B1120) : const Color(0xFFF4F7FB);
  }

  Color _surfaceColor(bool isDark) {
    return isDark ? const Color(0xFF121B2B) : Colors.white;
  }

  Color _surfaceBorderColor(bool isDark) {
    return isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE1E9F3);
  }

  List<BoxShadow> _surfaceShadows(bool isDark) {
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.24)
            : const Color(0xFF8FA3BF).withValues(alpha: 0.12),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ];
  }

  Widget _buildHeaderChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    dynamic user,
    bool isDark, {
    required String companySubtitle,
    required String currentLanguageLabel,
  }) {
    final topPadding = MediaQuery.of(context).padding.top + 16;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, topPadding, 18, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0F172A), Color(0xFF1D4ED8)]
              : const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.24),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -92,
            right: -26,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: -70,
            bottom: -96,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          _buildConstrainedContent(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('nav_profile'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Text(
                          (user?.name.isNotEmpty ?? false)
                              ? user!.name.substring(0, 1).toUpperCase()
                              : 'U',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            color: isDark
                                ? const Color(0xFF1D4ED8)
                                : const Color(0xFF2563EB),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? context.tr('profile_user_fallback'),
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            companySubtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              height: 1.45,
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildHeaderChip(
                                icon: Icons.badge_outlined,
                                label:
                                    user?.position ??
                                    context.tr('profile_employee_fallback'),
                              ),
                              _buildHeaderChip(
                                icon: Icons.language_rounded,
                                label: currentLanguageLabel,
                              ),
                              _buildHeaderChip(
                                icon: Icons.verified_user_outlined,
                                label: 'ID: ${user?.uuid ?? "EMP-0000"}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(
    BuildContext context, {
    required int leaveDays,
    required double overtimeHours,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final cardWidth = availableWidth >= 520
            ? (availableWidth - 24) / 3
            : (availableWidth - 12) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildStatCard(
                icon: Icons.calendar_today_rounded,
                value: leaveDays.toString(),
                label: context.tr('profile_leave'),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildStatCard(
                icon: Icons.timer_rounded,
                value: _formatOvertimeHours(overtimeHours),
                label: context.tr('profile_overtime'),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9966), Color(0xFFFF5E62)],
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildStatCard(
                icon: Icons.star_rounded,
                value: '4.5',
                label: context.tr('profile_rating'),
                gradient: const LinearGradient(
                  colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLanguageSheet(BuildContext context, bool isDark) async {
    final languageProvider = context.read<LanguageProvider>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surfaceColor(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final currentCode = sheetContext.watch<LanguageProvider>().languageCode;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.14)
                          : const Color(0xFFD9E3EF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  sheetContext.tr('profile_select_language'),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  sheetContext.tr('profile_language_subtitle'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.45,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildLanguageOption(
                  isDark: isDark,
                  isSelected: currentCode == 'id',
                  label: sheetContext.tr('profile_language_indonesian'),
                  onTap: () async {
                    await languageProvider.setLanguageCode('id');
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildLanguageOption(
                  isDark: isDark,
                  isSelected: currentCode == 'en',
                  label: sheetContext.tr('profile_language_english'),
                  onTap: () async {
                    await languageProvider.setLanguageCode('en');
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required bool isDark,
    required bool isSelected,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blue.withValues(alpha: isDark ? 0.18 : 0.08)
                : (isDark ? const Color(0xFF172235) : const Color(0xFFF7FAFD)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.blue : _surfaceBorderColor(isDark),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: Colors.blue.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Gradient gradient,
  }) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            bottom: -14,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title, {
    required List<Widget> children,
    IconData? icon,
  }) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFEFF4FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isDark ? Colors.white70 : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFF4F7FB),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _surfaceBorderColor(isDark)),
              ),
              child: Text(
                children.length.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: _surfaceColor(isDark),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _surfaceBorderColor(isDark)),
            boxShadow: _surfaceShadows(isDark),
          ),
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: _surfaceBorderColor(isDark),
                    indent: 78,
                    endIndent: 18,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title, {
    String? subtitle,
    Color? color,
    Widget? trailing,
    VoidCallback? onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color ?? Colors.blue,
                      (color ?? Colors.blue).withValues(alpha: 0.72),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (color ?? Colors.blue).withValues(alpha: 0.26),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          height: 1.45,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (trailing != null)
                trailing
              else if (onTap != null)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFFF4F7FB),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth, bool isDark) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: _surfaceColor(isDark),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: _surfaceColor(isDark),
              border: Border.all(color: _surfaceBorderColor(isDark)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('profile_logout_title'),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('profile_logout_message'),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          foregroundColor: isDark
                              ? Colors.white70
                              : Colors.grey.shade700,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : const Color(0xFFF4F7FB),
                        ),
                        child: Text(
                          context.tr('profile_cancel'),
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          if (!context.mounted) return;

                          await auth.logout();

                          if (context.mounted) {
                            Navigator.of(
                              context,
                            ).pushNamedAndRemoveUntil('/', (route) => false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: Text(
                          context.tr('profile_logout'),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _buildCompanySubtitle(
    BuildContext context,
    Company? currentCompany,
    int companyCount,
  ) {
    final parts = <String>[];

    if (currentCompany?.companyName.isNotEmpty == true) {
      parts.add(currentCompany!.companyName);
    }

    if (currentCompany?.cCode.isNotEmpty == true) {
      parts.add(currentCompany!.cCode);
    }

    final summary = parts.isEmpty
        ? context.tr('saas_company_not_selected')
        : parts.join(' | ');

    return '$summary | $companyCount ${context.tr('profile_switch_company_count')}';
  }

  String _buildTrialSubtitle(BuildContext context, SaasProvider saasProvider) {
    final trialStatus = saasProvider.trialStatus;

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
            .tr('saas_trial_days_remaining')
            .replaceAll('{count}', trialStatus.daysRemaining.toString());
      }

      return context.tr('saas_trial_active');
    }

    return context.tr('saas_active_plan');
  }

  Future<void> _loadProfileStats() async {
    if (_isLoadingStats) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final leaveProvider = context.read<LeaveProvider>();
    final companyCode = authProvider.getCompanyCode();

    setState(() {
      _isLoadingStats = true;
    });

    leaveProvider.setCompanyCode(companyCode);

    try {
      await leaveProvider.fetchLeaveData();
    } catch (_) {
      // Leave provider already keeps its own error state; profile falls back to 0.
    }

    double overtimeHours = 0;

    try {
      final response = await _apiService.get('/overtime');
      if (response is Map<String, dynamic> && response['success'] == true) {
        final payload = response['data'];
        final requests = payload is Map<String, dynamic>
            ? payload['requests']
            : null;
        overtimeHours = _calculateOvertimeHours(
          requests is List ? requests : const [],
          authProvider.user,
        );
      }
    } catch (_) {
      overtimeHours = 0;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _overtimeHours = overtimeHours;
      _isLoadingStats = false;
    });
  }

  int _getLeaveDays(LeaveProvider leaveProvider) {
    final balance = leaveProvider.leaveBalance;
    if (balance == null) {
      return 0;
    }

    final remaining = balance.annualTotal - balance.annualUsed;
    return remaining > 0 ? remaining : 0;
  }

  double _calculateOvertimeHours(List<dynamic> rawRequests, User? user) {
    if (user == null) {
      return 0;
    }

    final identifiers = <String>{
      user.employeeUuid?.trim() ?? '',
      user.uuid.trim(),
    }..removeWhere((value) => value.isEmpty);

    if (identifiers.isEmpty) {
      return 0;
    }

    double totalHours = 0;

    for (final item in rawRequests) {
      if (item is! Map) {
        continue;
      }

      final request = Map<String, dynamic>.from(item);
      final employee = request['employee'];
      final employeeUuid = employee is Map<String, dynamic>
          ? employee['uuid']?.toString().trim() ?? ''
          : '';
      final status = request['status']?.toString().trim().toLowerCase() ?? '';

      if (!identifiers.contains(employeeUuid) || status != 'approved') {
        continue;
      }

      totalHours += double.tryParse(request['hours']?.toString() ?? '0') ?? 0;
    }

    return totalHours;
  }

  String _formatOvertimeHours(double value) {
    if (value <= 0) {
      return '0h';
    }

    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.01) {
      return '${rounded.toInt()}h';
    }

    return '${value.toStringAsFixed(1)}h';
  }
}

// HAPUS BAGIAN INI:
// class LoginScreen extends StatelessWidget {
//   const LoginScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Text('Login Screen'),
//       ),
//     );
//   }
// }
