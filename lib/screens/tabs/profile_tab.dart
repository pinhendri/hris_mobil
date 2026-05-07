import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_strings.dart';
import '../../models/company.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/leave_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../profile/change_password_screen.dart';
import '../profile/employment_details_screen.dart';
import '../profile/personal_info_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  static const double _maxContentWidth = 840;
  static const Color _accentColor = AppColors.primary;
  static const Color _lightBackground = Color(0xFFF6F4F1);
  static const Color _darkBackground = Color(0xFF121212);

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
    final auth = context.watch<AuthProvider>();
    final leaveProvider = context.watch<LeaveProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final user = auth.user;
    final isDark = themeProvider.isDarkMode;
    final currentLanguageLabel = languageProvider.languageCode == 'id'
        ? context.tr('profile_language_indonesian')
        : context.tr('profile_language_english');
    final currentCompany = auth.selectedCompany;
    final companyName = (currentCompany?.companyName ?? '').trim().isNotEmpty
        ? currentCompany!.companyName.trim()
        : 'Company Name';
    final workspaceCount = auth.companyAssignments.length;
    final companySubtitle = _buildCompanySubtitle(
      context,
      currentCompany,
      workspaceCount,
    );
    final sections = [
      _buildSection(
        context,
        title: context.tr('profile_account'),
        icon: Icons.person_outline_rounded,
        count: 3,
        tone: AppColors.secondary,
        isDark: isDark,
        children: [
          _buildMenuItem(
            icon: Icons.person_outline,
            title: context.tr('profile_personal_information'),
            subtitle: context.tr('profile_personal_information_subtitle'),
            color: const Color(0xFF3478F6),
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
            icon: Icons.work_outline,
            title: context.tr('profile_employment_details'),
            subtitle: context.tr('profile_employment_details_subtitle'),
            color: AppColors.secondary,
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
            icon: Icons.lock_outline,
            title: context.tr('profile_change_password'),
            subtitle: context.tr('profile_change_password_subtitle'),
            color: const Color(0xFF8B5CF6),
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
        ],
      ),
      _buildSection(
        context,
        title: context.tr('profile_app_settings'),
        icon: Icons.tune_rounded,
        count: 3,
        tone: const Color(0xFF0F766E),
        isDark: isDark,
        children: [
          _buildMenuItem(
            icon: Icons.dark_mode_outlined,
            title: context.tr('profile_dark_mode'),
            subtitle: isDark
                ? context.tr('profile_dark_mode_to_light')
                : context.tr('profile_dark_mode_to_dark'),
            color: isDark ? const Color(0xFFF5B942) : const Color(0xFF475569),
            onTap: () => themeProvider.toggleTheme(!isDark),
            trailing: Switch.adaptive(
              value: isDark,
              onChanged: themeProvider.toggleTheme,
              activeThumbColor: _accentColor,
              activeTrackColor: _accentColor.withValues(alpha: 0.35),
            ),
            isDark: isDark,
          ),
          _buildMenuItem(
            icon: Icons.notifications_none,
            title: context.tr('profile_notifications'),
            subtitle: context.tr('profile_notifications_subtitle'),
            color: const Color(0xFFD5534F),
            trailing: Switch.adaptive(
              value: true,
              onChanged: (_) {},
              activeThumbColor: _accentColor,
              activeTrackColor: _accentColor.withValues(alpha: 0.35),
            ),
            isDark: isDark,
          ),
          _buildMenuItem(
            icon: Icons.language,
            title: context.tr('profile_language'),
            subtitle: context.tr('profile_language_subtitle'),
            color: const Color(0xFF2F9D78),
            onTap: () => _showLanguageSheet(context, isDark),
            trailing: _buildTag(
              label: currentLanguageLabel,
              isDark: isDark,
              color: const Color(0xFF2F9D78),
            ),
            isDark: isDark,
          ),
        ],
      ),
      _buildSection(
        context,
        title: context.tr('profile_support'),
        icon: Icons.help_outline_rounded,
        count: 3,
        tone: const Color(0xFF7C3AED),
        isDark: isDark,
        children: [
          _buildMenuItem(
            icon: Icons.help_outline,
            title: context.tr('profile_help_center'),
            subtitle: context.tr('profile_help_center_subtitle'),
            color: const Color(0xFF3478F6),
            onTap: () {},
            isDark: isDark,
          ),
          _buildMenuItem(
            icon: Icons.info_outline,
            title: context.tr('profile_about_app'),
            subtitle: context.tr('generic_version'),
            color: const Color(0xFF8B5CF6),
            trailing: _buildTag(
              label: 'v1.0.0',
              isDark: isDark,
              color: const Color(0xFF8B5CF6),
            ),
            isDark: isDark,
          ),
          _buildMenuItem(
            icon: Icons.privacy_tip_outlined,
            title: context.tr('profile_privacy_policy'),
            subtitle: context.tr('profile_privacy_policy_subtitle'),
            color: const Color(0xFF2F9D78),
            onTap: () {},
            isDark: isDark,
          ),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: _pageBackground(isDark),
      body: SafeArea(
        child: RefreshIndicator(
          color: _accentColor,
          onRefresh: _loadProfileStats,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              18,
              14,
              18,
              28 + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              _buildConstrainedContent(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(companyName: companyName, isDark: isDark),
                    const SizedBox(height: 18),
                    _buildProfileSummaryCard(
                      context,
                      user: user,
                      currentCompany: currentCompany,
                      companySubtitle: companySubtitle,
                      currentLanguageLabel: currentLanguageLabel,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildStatsCards(
                      context,
                      isDark: isDark,
                      isLoading: _isLoadingStats,
                      leaveDays: _getLeaveDays(leaveProvider),
                      overtimeHours: _overtimeHours,
                    ),
                    const SizedBox(height: 16),
                    _buildSectionsGrid(sections: sections),
                    const SizedBox(height: 16),
                    _buildLogoutCard(context, auth: auth, isDark: isDark),
                  ],
                ),
              ),
            ],
          ),
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

  Widget _buildTopBar({required String companyName, required bool isDark}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            companyName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _titleStyle(
              isDark,
              size: 18,
              color: isDark ? Colors.white : const Color(0xFF1E1E1E),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildIconShell(icon: Icons.person_outline_rounded, isDark: isDark),
      ],
    );
  }

  Widget _buildProfileSummaryCard(
    BuildContext context, {
    required User? user,
    required Company? currentCompany,
    required String companySubtitle,
    required String currentLanguageLabel,
    required bool isDark,
  }) {
    final rawUserName = (user?.name ?? '').trim();
    final rawRole = (user?.position ?? '').trim();
    final userName = rawUserName.isNotEmpty
        ? rawUserName
        : context.tr('profile_user_fallback');
    final role = rawRole.isNotEmpty
        ? rawRole
        : context.tr('profile_employee_fallback');
    final companyCode = (currentCompany?.cCode ?? '').trim();
    final roles = _buildRolesLabel(user);

    return _buildSurfaceCard(
      isDark: isDark,
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 480;
          final heroDetails = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Text(
                  context.tr('nav_profile'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                userName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                role,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFDCE7FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (companyCode.isNotEmpty)
                    _buildHeroPill(
                      icon: Icons.apartment_rounded,
                      label: companyCode,
                    ),
                  _buildHeroPill(
                    icon: Icons.language_rounded,
                    label: currentLanguageLabel,
                  ),
                ],
              ),
            ],
          );

          final factWidth = isCompact
              ? constraints.maxWidth - 36
              : (constraints.maxWidth - 60) / 3;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF151A23), Color(0xFF1B2330)]
                    : const [Color(0xFFF8FBFF), Colors.white],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -44,
                  right: -28,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : _accentColor.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? const [Color(0xFF1E3A8A), Color(0xFF0F172A)]
                                : const [
                                    AppColors.primary,
                                    AppColors.primaryHover,
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: _accentColor.withValues(
                                alpha: isDark ? 0.18 : 0.22,
                              ),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: isCompact
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildAvatar(
                                    userName: userName,
                                    isDark: isDark,
                                    size: 70,
                                    isProminent: true,
                                  ),
                                  const SizedBox(height: 16),
                                  heroDetails,
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildAvatar(
                                    userName: userName,
                                    isDark: isDark,
                                    size: 70,
                                    isProminent: true,
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(child: heroDetails),
                                ],
                              ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        context.tr('saas_current_company'),
                        style: _bodyStyle(
                          isDark,
                          size: 11,
                          weight: FontWeight.w700,
                          color: _accentColor,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        companySubtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: _bodyStyle(isDark, size: 13, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: factWidth,
                            child: _buildProfileFactCard(
                              label: 'Roles',
                              value: roles,
                              icon: Icons.admin_panel_settings_outlined,
                              tone: AppColors.secondary,
                              isDark: isDark,
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
        },
      ),
    );
  }

  Widget _buildAvatar({
    required String userName,
    required bool isDark,
    double size = 60,
    bool isProminent = false,
  }) {
    final decoration = isProminent
        ? BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.20),
                Colors.white.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.4,
            ),
          )
        : BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE9E5DE),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0),
            ),
          );

    return Container(
      width: size,
      height: size,
      decoration: decoration,
      alignment: Alignment.center,
      child: Text(
        _initialsFromName(userName),
        style: _titleStyle(
          isDark,
          size: size * 0.32,
          color: isProminent
              ? Colors.white
              : (isDark ? Colors.white70 : const Color(0xFF666666)),
        ),
      ),
    );
  }

  Widget _buildStatsCards(
    BuildContext context, {
    required bool isDark,
    required bool isLoading,
    required int leaveDays,
    required double overtimeHours,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 640;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.calendar_today_rounded,
                value: leaveDays.toString(),
                label: context.tr('profile_leave'),
                tone: const Color(0xFF3478F6),
                isDark: isDark,
                isLoading: isLoading,
                isCompact: isCompact,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.timer_rounded,
                value: _formatOvertimeHours(overtimeHours),
                label: context.tr('profile_overtime'),
                tone: const Color(0xFF4F46E5),
                isDark: isDark,
                isLoading: isLoading,
                isCompact: isCompact,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color tone,
    required bool isDark,
    bool isLoading = false,
    bool isCompact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 16,
        vertical: isCompact ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: _surfaceColor(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _surfaceBorderColor(isDark)),
        boxShadow: _surfaceShadows(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isCompact ? 36 : 44,
                height: isCompact ? 36 : 44,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
                ),
                child: Icon(icon, color: tone, size: isCompact ? 18 : 20),
              ),
              SizedBox(width: isCompact ? 8 : 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _bodyStyle(
                    isDark,
                    size: isCompact ? 10 : 12,
                    weight: FontWeight.w700,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    height: 1.3,
                  ),
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: isCompact ? 16 : 18,
                  height: isCompact ? 16 : 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(tone),
                  ),
                ),
            ],
          ),
          SizedBox(height: isCompact ? 14 : 18),
          Text(
            isLoading ? '--' : value,
            style: _titleStyle(isDark, size: isCompact ? 20 : 24, height: 1.05),
          ),
          SizedBox(height: isCompact ? 5 : 6),
          Container(
            width: isCompact ? 38 : 48,
            height: 4,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: isDark ? 0.32 : 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsGrid({required List<Widget> sections}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 760 ? 2 : 1;
        final itemWidth = columns == 1 ? width : (width - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: sections
              .map((section) => SizedBox(width: itemWidth, child: section))
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
    required IconData icon,
    required int count,
    required Color tone,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _surfaceBorderColor(isDark)),
        boxShadow: _surfaceShadows(isDark),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: isDark ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: tone, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: _titleStyle(isDark, size: 17)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: isDark ? 0.16 : 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    count.toString(),
                    style: _bodyStyle(
                      isDark,
                      size: 11,
                      weight: FontWeight.w700,
                      color: tone,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index != children.length - 1) ...[
                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: _surfaceBorderColor(isDark),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isDark,
    String? subtitle,
    Color? color,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final resolvedColor = color ?? _accentColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: resolvedColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: resolvedColor, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _titleStyle(isDark, size: 14, height: 1.25),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: _bodyStyle(isDark, size: 12, height: 1.45),
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
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: resolvedColor.withValues(
                      alpha: isDark ? 0.18 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: resolvedColor,
                    size: 17,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutCard(
    BuildContext context, {
    required AuthProvider auth,
    required bool isDark,
  }) {
    return _buildSurfaceCard(
      isDark: isDark,
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 560;
          final message = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(
                        alpha: isDark ? 0.22 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('profile_logout_title'),
                      style: _titleStyle(isDark, size: 17),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                context.tr('profile_logout_message'),
                style: _bodyStyle(isDark, size: 13, height: 1.45),
              ),
            ],
          );

          final actionButton = SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () => _showLogoutDialog(context, auth, isDark),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                context.tr('profile_logout'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [message, const SizedBox(height: 14), actionButton],
            );
          }

          return Row(
            children: [
              Expanded(child: message),
              const SizedBox(width: 16),
              SizedBox(width: 160, child: actionButton),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSurfaceCard({
    required bool isDark,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _surfaceColor(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _surfaceBorderColor(isDark)),
        boxShadow: _surfaceShadows(isDark),
      ),
      child: child,
    );
  }

  Widget _buildIconShell({required IconData icon, required bool isDark}) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFFE5E5E5),
        ),
      ),
      child: Icon(
        icon,
        color: isDark ? Colors.white70 : const Color(0xFF444444),
      ),
    );
  }

  Widget _buildTag({
    required String label,
    required bool isDark,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _bodyStyle(
                isDark,
                size: 11,
                weight: FontWeight.w700,
                color: color,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileFactCard({
    required String label,
    required String value,
    required IconData icon,
    required Color tone,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFDCE7FF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: tone),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _bodyStyle(
              isDark,
              size: 11,
              weight: FontWeight.w700,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _titleStyle(isDark, size: 14, height: 1.25),
          ),
        ],
      ),
    );
  }

  String _buildRolesLabel(User? user) {
    final roles = <String>{
      ...(user?.roles ?? const <String>[]).map((role) => role.trim()),
      if ((user?.role ?? '').trim().isNotEmpty) (user?.role ?? '').trim(),
    }..removeWhere((role) => role.isEmpty);

    if (roles.isNotEmpty) {
      return roles.join(', ');
    }

    final position = (user?.position ?? '').trim();
    return position.isNotEmpty ? position : 'Role belum tersedia';
  }

  Color _pageBackground(bool isDark) {
    return isDark ? _darkBackground : _lightBackground;
  }

  Color _surfaceColor(bool isDark) {
    return isDark ? const Color(0xFF1C1C1C) : Colors.white;
  }

  Color _surfaceBorderColor(bool isDark) {
    return isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFEAE7E2);
  }

  List<BoxShadow> _surfaceShadows(bool isDark) {
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.18)
            : const Color(0x140F172A),
        blurRadius: isDark ? 18 : 14,
        offset: const Offset(0, 8),
      ),
    ];
  }

  TextStyle _titleStyle(
    bool isDark, {
    double size = 17,
    FontWeight weight = FontWeight.w700,
    Color? color,
    double height = 1.2,
  }) {
    return TextStyle(
      color: color ?? (isDark ? Colors.white : const Color(0xFF1F2937)),
      fontSize: size,
      fontWeight: weight,
      height: height,
    );
  }

  TextStyle _bodyStyle(
    bool isDark, {
    double size = 13,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double height = 1.4,
  }) {
    return TextStyle(
      color: color ?? (isDark ? Colors.white60 : const Color(0xFF6B7280)),
      fontSize: size,
      fontWeight: weight,
      height: height,
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
                          : const Color(0xFFD9D4CB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  sheetContext.tr('profile_select_language'),
                  style: _titleStyle(isDark, size: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  sheetContext.tr('profile_language_subtitle'),
                  style: _bodyStyle(isDark, size: 13, height: 1.45),
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
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? _accentColor.withValues(alpha: isDark ? 0.18 : 0.10)
                : (isDark ? const Color(0xFF202020) : const Color(0xFFF8F6F2)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? _accentColor : _surfaceBorderColor(isDark),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: _bodyStyle(
                    isDark,
                    size: 13,
                    weight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: _accentColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth, bool isDark) {
    showDialog(
      context: context,
      builder: (dialogContext) {
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
                    color: _accentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('profile_logout_title'),
                  style: _titleStyle(isDark, size: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('profile_logout_message'),
                  style: _bodyStyle(isDark, size: 14),
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
                              : const Color(0xFF555555),
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : const Color(0xFFF8F6F2),
                        ),
                        child: Text(
                          context.tr('profile_cancel'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          if (!context.mounted) {
                            return;
                          }

                          await auth.logout();

                          if (context.mounted) {
                            Navigator.of(
                              context,
                            ).pushNamedAndRemoveUntil('/', (route) => false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          context.tr('profile_logout'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
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

  String _initialsFromName(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) {
      return 'U';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
