import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/widgets/access_denied_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/broadcast_provider.dart';
import '../../providers/claim_provider.dart';
import '../../providers/department_provider.dart';
import '../../providers/employee_provider.dart';
import '../admin/broadcast_screen.dart';
import '../admin/claim_management_screen.dart';
import '../admin/claim_reports_screen.dart';
import '../admin/common_master_menu_screen.dart';
import '../admin/correction_management_screen.dart';
import '../admin/department_list_screen.dart';
import '../admin/event_management_screen.dart';
import '../admin/leave_management_enhanced_screen.dart';
import '../admin/master_shift_screen.dart';
import '../admin/org_structure_screen.dart';
import '../admin/shift_assignment_screen.dart';
import '../admin/user_management_menu_screen.dart';
import '../attendance/attendance_settings_screen.dart';
import '../employee/add_employee_screen.dart';
import '../employee/employee_list_screen.dart';

class AdminTab extends StatelessWidget {
  static const double _maxContentWidth = 840;
  static const Color _accentColor = Color(0xFFFF9628);
  static const Color _lightBackground = Color(0xFFF6F4F1);
  static const Color _darkBackground = Color(0xFF020817);

  const AdminTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quickActions = _buildQuickActions(context, authProvider);
    final sections = _buildSections(
      context,
      authProvider,
    ).where((section) => section.items.isNotEmpty).toList(growable: false);
    final availableModuleCount = sections.fold<int>(
      0,
      (sum, section) => sum + section.items.length,
    );
    final currentCompany = authProvider.selectedCompany;
    final companyName = currentCompany?.companyName.trim().isNotEmpty == true
        ? currentCompany!.companyName.trim()
        : 'Company Name';

    return Scaffold(
      backgroundColor: _pageBackground(isDark),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
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
                  if (!authProvider.canAccessAdminPanel) ...[
                    _buildIntroCard(
                      context: context,
                      isDark: isDark,
                      quickActionsCount: 0,
                      availableModuleCount: 0,
                      permissionCount: authProvider.permissions.length,
                    ),
                    const SizedBox(height: 16),
                    _buildSurfaceCard(
                      isDark: isDark,
                      child: AccessDeniedState(
                        title: context.tr('admin_panel'),
                        message: context.tr('admin_no_access_message'),
                      ),
                    ),
                  ] else ...[
                    _buildIntroCard(
                      context: context,
                      isDark: isDark,
                      quickActionsCount: quickActions.length,
                      availableModuleCount: availableModuleCount,
                      permissionCount: authProvider.permissions.length,
                    ),
                    if (quickActions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildQuickActionsSection(
                        context: context,
                        actions: quickActions,
                        isDark: isDark,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildSectionsGrid(
                      context: context,
                      sections: sections,
                      isDark: isDark,
                    ),
                  ],
                ],
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
        _buildIconShell(
          icon: Icons.admin_panel_settings_outlined,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildIntroCard({
    required BuildContext context,
    required bool isDark,
    required int quickActionsCount,
    required int availableModuleCount,
    required int permissionCount,
  }) {
    return _buildSurfaceCard(
      isDark: isDark,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isDark
                      ? _accentColor.withValues(alpha: 0.18)
                      : const Color(0xFFFFF1E3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: _accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('admin_panel'),
                      style: _titleStyle(isDark, size: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('admin_header_subtitle'),
                      style: _bodyStyle(isDark),
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
              _buildInfoChip(
                label:
                    '${context.tr('admin_quick_actions')}: $quickActionsCount',
                isDark: isDark,
              ),
              _buildInfoChip(
                label: '${context.tr('admin_modules')}: $availableModuleCount',
                isDark: isDark,
                color: const Color(0xFF3478F6),
              ),
              _buildInfoChip(
                label: '${context.tr('admin_permissions')}: $permissionCount',
                isDark: isDark,
                color: const Color(0xFF2F9D78),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection({
    required BuildContext context,
    required List<_AdminQuickAction> actions,
    required bool isDark,
  }) {
    return _buildSurfaceCard(
      isDark: isDark,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context: context,
            title: context.tr('admin_quick_actions'),
            icon: Icons.flash_on_rounded,
            color: _accentColor,
            count: actions.length,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 720
                  ? 4
                  : width >= 480
                  ? 3
                  : 2;
              final itemWidth = (width - ((columns - 1) * 12)) / columns;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: actions
                    .map(
                      (action) => SizedBox(
                        width: itemWidth,
                        child: _buildQuickAction(
                          action: action,
                          isDark: isDark,
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsGrid({
    required BuildContext context,
    required List<_AdminSection> sections,
    required bool isDark,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 720 ? 2 : 1;
        final cardWidth = columns == 2 ? (width - 16) / 2 : width;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: sections
              .map(
                (section) => SizedBox(
                  width: cardWidth,
                  child: _buildSectionCard(
                    context: context,
                    section: section,
                    isDark: isDark,
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required _AdminSection section,
    required bool isDark,
  }) {
    return _buildSurfaceCard(
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
          const SizedBox(height: 14),
          for (var index = 0; index < section.items.length; index++) ...[
            _buildAdminMenuCard(
              context,
              item: section.items[index],
              isDark: isDark,
            ),
            if (index != section.items.length - 1) ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: _surfaceBorderColor(isDark)),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }

  Color _pageBackground(bool isDark) {
    return isDark ? _darkBackground : _lightBackground;
  }

  Color _surfaceColor(bool isDark) {
    return isDark ? const Color(0xFF111827) : Colors.white;
  }

  Color _surfaceBorderColor(bool isDark) {
    return isDark ? const Color(0xFF253041) : const Color(0xFFEAE7E2);
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

  Widget _buildInfoChip({
    required String label,
    required bool isDark,
    Color? color,
  }) {
    final resolvedColor =
        color ?? (isDark ? Colors.white70 : const Color(0xFF5E6470));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: _bodyStyle(
          isDark,
          size: 12,
          weight: FontWeight.w700,
          color: resolvedColor,
          height: 1.2,
        ),
      ),
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
          color: const Color(0xFF3478F6),
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
          color: _accentColor,
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
          color: const Color(0xFF2F9D78),
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
          color: const Color(0xFF8B5CF6),
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
        color: const Color(0xFF3478F6),
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
          if (authProvider.hasPermission('view-struktur-organisasi') ||
              authProvider.canAccessEmployeeMasterModule)
            _AdminMenuItem(
              title: context.tr('admin_org_structure'),
              subtitle: context.tr('admin_org_structure_subtitle'),
              icon: Icons.account_tree_outlined,
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
              ),
              badge: context.tr('admin_badge_master'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider(
                      create: (_) => EmployeeProvider(),
                      child: const OrgStructureScreen(),
                    ),
                  ),
                );
              },
            ),
          if (authProvider.hasAnyPermission([
            'view-settings',
            'assign-roles',
            'view-roles',
          ]))
            _AdminMenuItem(
              title: context.tr('admin_common_master'),
              subtitle: context.tr('admin_common_master_subtitle'),
              icon: Icons.dataset_outlined,
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
              ),
              badge: context.tr('admin_badge_master'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CommonMasterMenuScreen(),
                  ),
                );
              },
            ),
          if (authProvider.hasAnyPermission([
            'assign-roles',
            'view-roles',
            'view-permissions',
          ]))
            _AdminMenuItem(
              title: context.tr('admin_user_management'),
              subtitle: context.tr('admin_user_management_subtitle'),
              icon: Icons.manage_accounts_outlined,
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF8B5CF6)],
              ),
              badge: context.tr('admin_badge_master'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserManagementMenuScreen(),
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
        color: const Color(0xFF8B5CF6),
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
        color: const Color(0xFF2F9D78),
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
          if (authProvider.canAccessBroadcastModule)
            _AdminMenuItem(
              title: context.tr('admin_broadcast'),
              subtitle: context.tr('admin_broadcast_subtitle'),
              icon: Icons.campaign_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFFACC15)],
              ),
              badge: context.tr('admin_badge_broadcast'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider(
                      create: (_) => BroadcastProvider(),
                      child: const BroadcastScreen(),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : const Color(0xFFF8F6F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _surfaceBorderColor(isDark)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(action.icon, color: action.color, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                action.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _titleStyle(isDark, size: 13, height: 1.25),
              ),
            ],
          ),
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
        Expanded(child: Text(title, style: _titleStyle(isDark, size: 17))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF8F6F2),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            context
                .tr('admin_menu_count')
                .replaceAll('{count}', count.toString()),
            style: _bodyStyle(
              isDark,
              size: 11,
              weight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminMenuCard(
    BuildContext context, {
    required _AdminMenuItem item,
    required bool isDark,
  }) {
    final tone = _toneFromGradient(item.gradient);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: tone, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _titleStyle(isDark, size: 14, height: 1.25),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _bodyStyle(isDark, size: 12, height: 1.4),
                    ),
                    if (item.badge != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: tone.withValues(alpha: isDark ? 0.18 : 0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.badge!,
                          style: _bodyStyle(
                            isDark,
                            size: 10,
                            weight: FontWeight.w700,
                            color: tone,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF8F6F2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_rounded, color: tone, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _toneFromGradient(Gradient gradient) {
    if (gradient is LinearGradient && gradient.colors.isNotEmpty) {
      return gradient.colors.first;
    }

    return _accentColor;
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
