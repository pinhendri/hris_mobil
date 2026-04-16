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
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context, user, isDark),
            const SizedBox(height: 20),

            // Stats Cards
            _buildStatsCards(
              context,
              isDark,
              leaveDays: _getLeaveDays(leaveProvider),
              overtimeHours: _overtimeHours,
            ),
            const SizedBox(height: 20),

            _buildSection(context, context.tr('profile_saas_workspace'), [
              _buildMenuItem(
                Icons.shield_outlined,
                context.tr('saas_workspace_title'),
                subtitle: context.tr('profile_saas_workspace_subtitle'),
                color: Colors.indigo,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SaasWorkspaceScreen(),
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
                      builder: (context) => const SaasWorkspaceScreen(),
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
                      builder: (context) => const SaasWorkspaceScreen(),
                    ),
                  );
                },
                isDark: isDark,
              ),
            ]),

            const SizedBox(height: 20),

            // Account Section
            _buildSection(context, context.tr('profile_account'), [
              _buildMenuItem(
                Icons.person_outline,
                context.tr('profile_personal_information'),
                subtitle: context.tr('profile_personal_information_subtitle'),
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PersonalInfoScreen(),
                    ),
                  );
                },
                isDark: isDark,
              ),
              _buildMenuItem(
                Icons.work_outline,
                context.tr('profile_employment_details'),
                subtitle: context.tr('profile_employment_details_subtitle'),
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EmploymentDetailsScreen(),
                    ),
                  );
                },
                isDark: isDark,
              ),
              _buildMenuItem(
                Icons.lock_outline,
                context.tr('profile_change_password'),
                subtitle: context.tr('profile_change_password_subtitle'),
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  );
                },
                isDark: isDark,
              ),
            ]),

            const SizedBox(height: 20),

            // App Settings Section with Dark Mode Toggle
            _buildSection(context, context.tr('profile_app_settings'), [
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
                  activeColor: Colors.blue,
                  activeTrackColor: Colors.blue.withOpacity(0.3),
                ),
                isDark: isDark,
              ),
              _buildMenuItem(
                Icons.notifications_none,
                context.tr('profile_notifications'),
                subtitle: context.tr('profile_notifications_subtitle'),
                color: Colors.red,
                trailing: Switch(
                  value: true,
                  onChanged: (val) {},
                  activeColor: Colors.green,
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
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.public,
                        size: 16,
                        color: isDark ? Colors.white70 : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currentLanguageLabel,
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                isDark: isDark,
              ),
            ]),

            const SizedBox(height: 20),

            // Support Section
            _buildSection(context, context.tr('profile_support'), [
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
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.blue],
                    ),
                    borderRadius: BorderRadius.circular(20),
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
                subtitle: context.tr('profile_privacy_policy_subtitle'),
                color: Colors.teal,
                onTap: () {},
                isDark: isDark,
              ),
            ]),

            const SizedBox(height: 30),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    _showLogoutDialog(context, auth, isDark);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: Colors.red.withOpacity(0.3),
                  ),
                  child: Text(
                    context.tr('profile_logout'),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A237E), const Color(0xFF4A148C)]
              : [Colors.blue, Colors.purple],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.purple : Colors.blue).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Text(
                (user?.name.isNotEmpty ?? false)
                    ? user!.name.substring(0, 1).toUpperCase()
                    : 'U',
                style: GoogleFonts.poppins(
                  fontSize: 42,
                  color: isDark ? const Color(0xFF1A237E) : Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? context.tr('profile_user_fallback'),
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.badge_outlined, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  user?.position ?? context.tr('profile_employee_fallback'),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'ID: ${user?.uuid ?? "EMP-0000"}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(
    BuildContext context,
    bool isDark, {
    required int leaveDays,
    required double overtimeHours,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStatCard(
            icon: Icons.calendar_today_rounded,
            value: leaveDays.toString(),
            label: context.tr('profile_leave'),
            gradient: const LinearGradient(
              colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
            ),
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.timer_rounded,
            value: _formatOvertimeHours(overtimeHours),
            label: context.tr('profile_overtime'),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9966), Color(0xFFFF5E62)],
            ),
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.star_rounded,
            value: '4.5',
            label: context.tr('profile_rating'),
            gradient: const LinearGradient(
              colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
            ),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Future<void> _showLanguageSheet(BuildContext context, bool isDark) async {
    final languageProvider = context.read<LanguageProvider>();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final currentCode = sheetContext.watch<LanguageProvider>().languageCode;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sheetContext.tr('profile_select_language'),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildLanguageOption(
                  context: sheetContext,
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
                  context: sheetContext,
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
    required BuildContext context,
    required bool isDark,
    required bool isSelected,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blue.withOpacity(isDark ? 0.18 : 0.08)
                : (isDark ? const Color(0xFF262626) : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Colors.blue
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
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
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(children: children),
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
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color ?? Colors.blue,
                      (color ?? Colors.blue).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (color ?? Colors.blue).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else if (onTap != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
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
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: isDark
                              ? Colors.white70
                              : Colors.grey.shade700,
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
        : parts.join(' • ');

    return '$summary • $companyCount ${context.tr('profile_switch_company_count')}';
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
