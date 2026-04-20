import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/access_denied_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/claim_provider.dart';
import '../../providers/department_provider.dart';
import '../../providers/theme_provider.dart';
import '../admin/claim_management_screen.dart';
import '../admin/claim_reports_screen.dart';
import '../admin/correction_management_screen.dart';
import '../admin/department_list_screen.dart';
import '../admin/event_management_screen.dart';
import '../admin/leave_management_enhanced_screen.dart';
import '../admin/master_shift_screen.dart';
import '../admin/shift_assignment_screen.dart';
import '../attendance/attendance_settings_screen.dart';
import '../employee/add_employee_screen.dart';
import '../employee/employee_list_screen.dart';

class AdminTab extends StatelessWidget {
  static const double _maxContentWidth = 520;

  const AdminTab({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isDark = themeProvider.isDarkMode;

    if (!authProvider.canAccessAdminPanel) {
      return Scaffold(
        backgroundColor: _pageBackground(isDark),
        appBar: AppBar(
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            context.tr('admin_panel'),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          backgroundColor: _surfaceColor(isDark),
        ),
        body: AccessDeniedState(
          title: context.tr('admin_panel'),
          message: context.tr('admin_no_access_message'),
        ),
      );
    }

    final quickActions = _buildQuickActions(context, authProvider);
    final sections = _buildSections(
      context,
      authProvider,
    ).where((section) => section.items.isNotEmpty).toList(growable: false);
    final availableModuleCount = sections.fold<int>(
      0,
      (sum, section) => sum + section.items.length,
    );

    return Scaffold(
      backgroundColor: _pageBackground(isDark),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            expandedHeight: 216,
            pinned: true,
            floating: false,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: isDark
                ? const Color(0xFF0F1A2C)
                : const Color(0xFF1D4ED8),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
                            )
                          : const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                            ),
                    ),
                  ),
                  Positioned(
                    top: -90,
                    right: -28,
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
                    left: -56,
                    bottom: -84,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                      child: _buildConstrainedContent(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.admin_panel_settings_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.tr('admin_panel'),
                                        style: GoogleFonts.poppins(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        context.tr('admin_header_subtitle'),
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          height: 1.45,
                                          color: Colors.white.withValues(
                                            alpha: 0.88,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildStatCard(
                                  quickActions.length.toString(),
                                  context.tr('admin_quick_actions'),
                                  Icons.flash_on_rounded,
                                ),
                                _buildStatCard(
                                  availableModuleCount.toString(),
                                  context.tr('admin_modules'),
                                  Icons.dashboard_customize_rounded,
                                ),
                                _buildStatCard(
                                  authProvider.permissions.length.toString(),
                                  context.tr('admin_permissions'),
                                  Icons.verified_user_rounded,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (quickActions.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _buildConstrainedContent(
                  _buildSurfaceCard(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              context.tr('admin_quick_actions'),
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : const Color(0xFFF3F7FC),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: _surfaceBorderColor(isDark),
                                ),
                              ),
                              child: Text(
                                context
                                    .tr('admin_menu_count')
                                    .replaceAll(
                                      '{count}',
                                      quickActions.length.toString(),
                                    ),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr('admin_header_subtitle'),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            height: 1.45,
                            color: isDark
                                ? Colors.white60
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: quickActions
                              .map(
                                (action) => _buildQuickAction(
                                  action: action,
                                  isDark: isDark,
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          for (final section in sections)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _buildConstrainedContent(
                  _buildSurfaceCard(
                    isDark: isDark,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          context: context,
                          title: section.title,
                          icon: section.icon,
                          color: section.color,
                          count: section.items.length,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        for (
                          var index = 0;
                          index < section.items.length;
                          index++
                        )
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: index == section.items.length - 1
                                  ? 0
                                  : 12,
                            ),
                            child: _buildAdminMenuCard(
                              context,
                              title: section.items[index].title,
                              subtitle: section.items[index].subtitle,
                              icon: section.items[index].icon,
                              gradient: section.items[index].gradient,
                              badge: section.items[index].badge,
                              onTap: section.items[index].onTap,
                              isDark: isDark,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 104 + MediaQuery.of(context).padding.bottom,
            ),
          ),
        ],
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

  Color _subtleSurfaceColor(bool isDark) {
    return isDark ? const Color(0xFF172235) : const Color(0xFFF7FAFD);
  }

  List<BoxShadow> _surfaceShadows(bool isDark) {
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.24)
            : const Color(0xFF8FA3BF).withValues(alpha: 0.12),
        blurRadius: 26,
        offset: const Offset(0, 12),
      ),
    ];
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _surfaceBorderColor(isDark)),
        boxShadow: _surfaceShadows(isDark),
      ),
      child: child,
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      constraints: const BoxConstraints(minWidth: 104),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<_AdminQuickAction> _buildQuickActions(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    final actions = <_AdminQuickAction>[];

    if (authProvider.hasPermission('create-employee')) {
      actions.add(
        _AdminQuickAction(
          icon: Icons.person_add_alt_1,
          label: context.tr('admin_quick_add_employee'),
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddEmployeeScreen(),
              ),
            );
          },
        ),
      );
    }

    if (authProvider.canAccessSettingsModule) {
      actions.add(
        _AdminQuickAction(
          icon: Icons.schedule,
          label: context.tr('admin_quick_shift'),
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MasterShiftScreen(),
              ),
            );
          },
        ),
      );
    }

    if (authProvider.canAccessLeaveModule) {
      actions.add(
        _AdminQuickAction(
          icon: Icons.beach_access,
          label: context.tr('admin_quick_leave'),
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LeaveManagementEnhancedScreen(),
              ),
            );
          },
        ),
      );
    }

    if (authProvider.canAccessReportsModule) {
      actions.add(
        _AdminQuickAction(
          icon: Icons.bar_chart,
          label: context.tr('admin_quick_reports'),
          color: Colors.purple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider(
                  create: (_) => ClaimProvider(),
                  child: const ClaimReportsScreen(),
                ),
              ),
            );
          },
        ),
      );
    }

    return actions;
  }

  List<_AdminSection> _buildSections(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    final canAccessSettings = authProvider.canAccessSettingsModule;
    final canAccessReports = authProvider.canAccessReportsModule;

    return [
      _AdminSection(
        title: context.tr('admin_section_master_data'),
        icon: Icons.storage,
        color: Colors.blue,
        items: [
          if (authProvider.canAccessDepartmentModule)
            _AdminMenuItem(
              title: context.tr('admin_master_department'),
              subtitle: context.tr('admin_master_department_subtitle'),
              icon: Icons.business,
              gradient: const LinearGradient(
                colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
              ),
              badge: context.tr('admin_badge_master'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider(
                      create: (_) => DepartmentProvider(),
                      child: const DepartmentListScreen(),
                    ),
                  ),
                );
              },
            ),
          if (authProvider.canAccessEmployeeMasterModule)
            _AdminMenuItem(
              title: context.tr('admin_master_employee'),
              subtitle: context.tr('admin_master_employee_subtitle'),
              icon: Icons.people_alt,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9966), Color(0xFFFF5E62)],
              ),
              badge: context.tr('admin_badge_active'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmployeeListScreen(),
                  ),
                );
              },
            ),
          if (canAccessSettings)
            _AdminMenuItem(
              title: context.tr('admin_master_shift'),
              subtitle: context.tr('admin_master_shift_subtitle'),
              icon: Icons.schedule,
              gradient: const LinearGradient(
                colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
              ),
              badge: context.tr('admin_badge_config'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MasterShiftScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      _AdminSection(
        title: context.tr('admin_section_configuration'),
        icon: Icons.settings_applications,
        color: Colors.purple,
        items: [
          if (canAccessSettings)
            _AdminMenuItem(
              title: context.tr('admin_attendance_settings'),
              subtitle: context.tr('admin_attendance_settings_subtitle'),
              icon: Icons.location_on,
              gradient: const LinearGradient(
                colors: [Color(0xFF3A1C71), Color(0xFFD76D77)],
              ),
              badge: context.tr('admin_badge_policy'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AttendanceSettingsScreen(),
                  ),
                );
              },
            ),
          if (authProvider.canAccessShiftAssignmentModule)
            _AdminMenuItem(
              title: context.tr('admin_shift_assignment'),
              subtitle: context.tr('admin_shift_assignment_subtitle'),
              icon: Icons.assignment_turned_in,
              gradient: const LinearGradient(
                colors: [Color(0xFFAA076B), Color(0xFF61045F)],
              ),
              badge: context.tr('admin_badge_schedule'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ShiftAssignmentScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      _AdminSection(
        title: context.tr('admin_section_management'),
        icon: Icons.manage_accounts,
        color: Colors.green,
        items: [
          if (authProvider.canAccessLeaveModule)
            _AdminMenuItem(
              title: context.tr('admin_leave_management'),
              subtitle: context.tr('admin_leave_management_subtitle'),
              icon: Icons.beach_access,
              gradient: const LinearGradient(
                colors: [Color(0xFF02AAB0), Color(0xFF00CDAC)],
              ),
              badge: context.tr('admin_badge_approval'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LeaveManagementEnhancedScreen(),
                  ),
                );
              },
            ),
          if (authProvider.canAccessCorrectionsModule)
            _AdminMenuItem(
              title: context.tr('admin_correction_management'),
              subtitle: context.tr('admin_correction_management_subtitle'),
              icon: Icons.edit_calendar,
              gradient: const LinearGradient(
                colors: [Color(0xFF4568DC), Color(0xFFB06AB3)],
              ),
              badge: context.tr('admin_badge_review'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CorrectionManagementScreen(),
                  ),
                );
              },
            ),
          if (authProvider.canAccessPayrollModule)
            _AdminMenuItem(
              title: context.tr('admin_claim_management'),
              subtitle: context.tr('admin_claim_management_subtitle'),
              icon: Icons.request_quote,
              gradient: const LinearGradient(
                colors: [Color(0xFF2193B0), Color(0xFF6DD5ED)],
              ),
              badge: context.tr('admin_badge_finance'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider(
                      create: (_) => ClaimProvider(),
                      child: const ClaimManagementScreen(),
                    ),
                  ),
                );
              },
            ),
          if (canAccessReports)
            _AdminMenuItem(
              title: context.tr('admin_claim_reports'),
              subtitle: context.tr('admin_claim_reports_subtitle'),
              icon: Icons.bar_chart,
              gradient: const LinearGradient(
                colors: [Color(0xFF834D9B), Color(0xFFD04ED6)],
              ),
              badge: context.tr('admin_badge_insight'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider(
                      create: (_) => ClaimProvider(),
                      child: const ClaimReportsScreen(),
                    ),
                  ),
                );
              },
            ),
          _AdminMenuItem(
            title: context.tr('admin_event_management'),
            subtitle: context.tr('admin_event_management_subtitle'),
            icon: Icons.event_available,
            gradient: const LinearGradient(
              colors: [Color(0xFF1D976C), Color(0xFF93F9B9)],
            ),
            badge: context.tr('admin_badge_calendar'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EventManagementScreen(),
                ),
              );
            },
          ),
        ],
      ),
    ];
  }

  Widget _buildQuickAction({
    required _AdminQuickAction action,
    required bool isDark,
  }) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 88,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: _subtleSurfaceColor(isDark),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _surfaceBorderColor(isDark)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(action.icon, color: action.color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required int count,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
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
            context
                .tr('admin_menu_count')
                .replaceAll('{count}', count.toString()),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    String? badge,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -16,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                right: 28,
                bottom: -26,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
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
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              height: 1.45,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.16),
                                ),
                              ),
                              child: Text(
                                badge,
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminQuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AdminQuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _AdminSection {
  final String title;
  final IconData icon;
  final Color color;
  final List<_AdminMenuItem> items;

  const _AdminSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });
}

class _AdminMenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final String? badge;
  final VoidCallback onTap;

  const _AdminMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.badge,
  });
}
