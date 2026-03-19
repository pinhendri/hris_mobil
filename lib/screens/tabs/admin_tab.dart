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
import '../admin/leave_management_screen.dart';
import '../admin/master_shift_screen.dart';
import '../admin/shift_assignment_screen.dart';
import '../attendance/attendance_settings_screen.dart';
import '../employee/add_employee_screen.dart';
import '../employee/employee_list_screen.dart';

class AdminTab extends StatelessWidget {
  const AdminTab({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isDark = themeProvider.isDarkMode;

    if (!authProvider.canAccessAdminPanel) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
        appBar: AppBar(
          title: Text(
            context.tr('admin_panel'),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            floating: false,
            backgroundColor: isDark
                ? const Color(0xFF1E1E1E)
                : Colors.blue.shade800,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1A237E), Color(0xFF4A148C)],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade800,
                            Colors.purple.shade700,
                          ],
                        ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr('admin_panel'),
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    context.tr('admin_header_subtitle'),
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _buildStatCard(
                              quickActions.length.toString(),
                              context.tr('admin_quick_actions'),
                              Icons.flash_on,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              availableModuleCount.toString(),
                              context.tr('admin_modules'),
                              Icons.dashboard_customize,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              authProvider.permissions.length.toString(),
                              context.tr('admin_permissions'),
                              Icons.verified_user,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (quickActions.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('admin_quick_actions'),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.spaceEvenly,
                      spacing: 12,
                      runSpacing: 16,
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
          for (final section in sections) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              sliver: SliverToBoxAdapter(
                child: _buildSectionHeader(
                  context: context,
                  title: section.title,
                  icon: section.icon,
                  color: section.color,
                  count: section.items.length,
                  isDark: isDark,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = section.items[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == section.items.length - 1 ? 0 : 12,
                    ),
                    child: _buildAdminMenuCard(
                      context,
                      title: item.title,
                      subtitle: item.subtitle,
                      icon: item.icon,
                      gradient: item.gradient,
                      badge: item.badge,
                      onTap: item.onTap,
                      isDark: isDark,
                    ),
                  );
                }, childCount: section.items.length),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
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
                builder: (context) => const LeaveManagementScreen(),
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
                    builder: (context) => const LeaveManagementScreen(),
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
          if (canAccessSettings)
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

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 20),
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
                fontSize: 10,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required _AdminQuickAction action,
    required bool isDark,
  }) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(action.icon, color: action.color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            context
                .tr('admin_menu_count')
                .replaceAll('{count}', count.toString()),
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
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
        borderRadius: BorderRadius.circular(20),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                badge,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
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
