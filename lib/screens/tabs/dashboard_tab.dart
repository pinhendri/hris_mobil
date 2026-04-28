import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../data/models/attendance_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/payroll_provider.dart';
import '../../providers/saas_provider.dart';
import '../attendance/clock_in_screen.dart';
import '../leave/leave_screen.dart';
import '../notifications/notification_screen.dart';
import '../payroll/payslip_screen.dart';
import '../saas/saas_workspace_screen.dart';
import 'feature_tab.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  static const double _maxContentWidth = 520;
  static const Color _accentColor = Color(0xFFFF9628);
  static const Color _lightBackground = Color(0xFFF6F4F1);
  static const Color _darkBackground = Color(0xFF121212);

  bool _showAttendanceDetails = true;
  Future<void>? _homeRefreshInFlight;
  Future<void>? _secondaryLoadInFlight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshHome(backgroundSecondary: true));
    });
  }

  Future<void> _refreshHome({
    bool forceWorkspace = false,
    bool backgroundSecondary = false,
  }) async {
    final currentRefresh = _homeRefreshInFlight;
    if (currentRefresh != null) {
      return currentRefresh;
    }

    final refreshFuture = _performHomeRefresh(
      forceWorkspace: forceWorkspace,
      backgroundSecondary: backgroundSecondary,
    );
    _homeRefreshInFlight = refreshFuture;

    try {
      await refreshFuture;
    } finally {
      if (identical(_homeRefreshInFlight, refreshFuture)) {
        _homeRefreshInFlight = null;
      }
    }
  }

  Future<void> _performHomeRefresh({
    required bool forceWorkspace,
    required bool backgroundSecondary,
  }) async {
    final auth = context.read<AuthProvider>();
    final attendance = context.read<AttendanceProvider>();
    final leave = context.read<LeaveProvider>();
    final notifications = context.read<NotificationProvider>();
    final saas = context.read<SaasProvider>();
    final companyCode = auth.getCompanyCode().trim();

    await Future.wait([
      _runSafely(() async {
        if (auth.canAccessAttendanceModule) {
          await attendance.fetchTodayAttendance();
          await attendance.getAttendanceSummary();
        }
      }),
      _runSafely(() async {
        await notifications.fetchNotifications();
      }),
    ]);

    if (backgroundSecondary) {
      unawaited(
        _loadSecondaryHomeData(
          auth: auth,
          leave: leave,
          saas: saas,
          companyCode: companyCode,
          forceWorkspace: forceWorkspace,
          delay: const Duration(milliseconds: 250),
        ),
      );
      return;
    }

    await _loadSecondaryHomeData(
      auth: auth,
      leave: leave,
      saas: saas,
      companyCode: companyCode,
      forceWorkspace: forceWorkspace,
    );
  }

  Future<void> _loadSecondaryHomeData({
    required AuthProvider auth,
    required LeaveProvider leave,
    required SaasProvider saas,
    required String companyCode,
    required bool forceWorkspace,
    Duration delay = Duration.zero,
  }) async {
    final currentLoad = _secondaryLoadInFlight;
    if (currentLoad != null && !forceWorkspace) {
      return currentLoad;
    }

    final loadFuture = _performSecondaryHomeDataLoad(
      auth: auth,
      leave: leave,
      saas: saas,
      companyCode: companyCode,
      forceWorkspace: forceWorkspace,
      delay: delay,
    );
    _secondaryLoadInFlight = loadFuture;

    try {
      await loadFuture;
    } finally {
      if (identical(_secondaryLoadInFlight, loadFuture)) {
        _secondaryLoadInFlight = null;
      }
    }
  }

  Future<void> _performSecondaryHomeDataLoad({
    required AuthProvider auth,
    required LeaveProvider leave,
    required SaasProvider saas,
    required String companyCode,
    required bool forceWorkspace,
    required Duration delay,
  }) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    if (!mounted) {
      return;
    }

    await Future.wait([
      _runSafely(() async {
        if (auth.canAccessLeaveModule && companyCode.isNotEmpty) {
          leave.setCompanyCode(companyCode);
          await leave.fetchLeaveData();
        }
      }),
      _runSafely(() async {
        if (forceWorkspace || !saas.hasLoadedData) {
          await saas.loadWorkspace(
            includeAdminOverview: auth.canAccessPlatformAdmin,
            force: forceWorkspace,
          );
        }
      }),
    ]);
  }

  Future<void> _runSafely(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Each provider already exposes its own fallback/error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final attendance = context.watch<AttendanceProvider>();
    final leave = context.watch<LeaveProvider>();
    final notifications = context.watch<NotificationProvider>();
    final saas = context.watch<SaasProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentCompany = saas.currentCompany ?? auth.selectedCompany;
    final companyName = currentCompany?.companyName.trim().isNotEmpty == true
        ? currentCompany!.companyName.trim()
        : 'Company Name';
    final userName = auth.user?.name.trim().isNotEmpty == true
        ? auth.user!.name.trim()
        : '-';
    final position = auth.user?.position.trim().isNotEmpty == true
        ? auth.user!.position.trim()
        : auth.user?.email.trim().isNotEmpty == true
        ? auth.user!.email.trim()
        : '-';
    final favoriteActions = _buildFavoriteActions(auth, attendance);

    return Scaffold(
      backgroundColor: isDark ? _darkBackground : _lightBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: _accentColor,
          onRefresh: () => _refreshHome(forceWorkspace: true),
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
              _buildConstrained(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(
                      companyName: companyName,
                      unreadCount: notifications.unreadCount,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 18),
                    _buildProfileCard(
                      userName: userName,
                      position: position,
                      unreadCount: notifications.unreadCount,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildAttendanceCard(
                      attendance: attendance.todayAttendance,
                      attendanceProvider: attendance,
                      companyCode: auth.getCompanyCode().trim(),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle(
                      context.tr('dashboard_favorite_menu'),
                      isDark,
                    ),
                    const SizedBox(height: 14),
                    _buildFavoriteMenu(
                      actions: favoriteActions,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 28),
                    _buildSectionTitle(
                      context.tr('dashboard_company_information'),
                      isDark,
                    ),
                    const SizedBox(height: 14),
                    _buildCompanyInformation(
                      auth: auth,
                      leave: leave,
                      saas: saas,
                      companyName: companyName,
                      isDark: isDark,
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

  Widget _buildConstrained(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: child,
      ),
    );
  }

  Widget _buildTopBar({
    required String companyName,
    required int unreadCount,
    required bool isDark,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            companyName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1E1E1E),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildIconShell(
          icon: Icons.search_rounded,
          isDark: isDark,
          onTap: () => _pushScreen(const FeatureTab()),
        ),
      ],
    );
  }

  Widget _buildProfileCard({
    required String userName,
    required String position,
    required int unreadCount,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 2),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : const Color(0xFFE8E8E8),
            child: Text(
              _initialsFromName(userName),
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  position,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildIconShell(
            icon: Icons.notifications_none_rounded,
            isDark: isDark,
            badgeCount: unreadCount > 0 ? unreadCount : null,
            onTap: () => _pushScreen(const NotificationScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard({
    required Attendance? attendance,
    required AttendanceProvider attendanceProvider,
    required String companyCode,
    required bool isDark,
  }) {
    final hasClockIn = attendance?.hasClockIn ?? false;
    final hasClockOut = attendance?.hasClockOut ?? false;
    final shouldClockOut = hasClockIn && !hasClockOut;
    final startTime = _displayTime(attendance?.clockInTimeFormatted);
    final endTime = _displayTime(attendance?.clockOutTimeFormatted);
    final badgeLabel = _attendanceBadgeLabel(
      hasClockIn: hasClockIn,
      hasClockOut: hasClockOut,
      isPendingSync:
          attendance?.isPendingSync == true ||
          attendanceProvider.pendingSyncCount > 0,
    );
    final localeCode = _localeCode(context);
    final formattedDate = DateFormat(
      'EEE, d MMM yyyy',
      localeCode,
    ).format(DateTime.now());
    final summary = attendanceProvider.summary ?? const <String, dynamic>{};

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFEAE7E2),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.24)
                : const Color(0x22151B26),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.tr('dashboard_today_label')} ($formattedDate)',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF303030),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${context.tr('dashboard_shift_label')}: [-]',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : const Color(0xFF7C7C7C),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFF0EEEA),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildAttendanceTimeBlock(
                    label: context.tr('dashboard_start_time'),
                    time: startTime,
                    initials: _initialsFromName(
                      context.read<AuthProvider>().user?.name ?? '',
                    ),
                    isActive: hasClockIn,
                    accent: const Color(0xFF4CB87B),
                    isDark: isDark,
                  ),
                ),
                Container(
                  width: 1,
                  height: 68,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFEEEAE5),
                ),
                Expanded(
                  child: _buildAttendanceTimeBlock(
                    label: context.tr('dashboard_end_time'),
                    time: endTime,
                    initials: _initialsFromName(
                      context.read<AuthProvider>().user?.name ?? '',
                    ),
                    isActive: hasClockOut,
                    accent: const Color(0xFFE58E7C),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            child: SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () {
                    _pushScreen(ClockInScreen(isClockOut: shouldClockOut));
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: Text(
                          context.tr('dashboard_record_time'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          InkWell(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(18),
            ),
            onTap: () {
              setState(() {
                _showAttendanceDetails = !_showAttendanceDetails;
              });
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 12),
              child: Column(
                children: [
                  Text(
                    _showAttendanceDetails
                        ? context.tr('dashboard_hide_detail')
                        : context.tr('dashboard_view_more'),
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF666666),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 220),
                    crossFadeState: _showAttendanceDetails
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        children: [
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildInfoChip(
                                label: badgeLabel,
                                isDark: isDark,
                                color: _statusColor(
                                  hasClockIn: hasClockIn,
                                  hasClockOut: hasClockOut,
                                  isPendingSync:
                                      attendance?.isPendingSync == true ||
                                      attendanceProvider.pendingSyncCount > 0,
                                ),
                              ),
                              if (companyCode.isNotEmpty)
                                _buildInfoChip(
                                  label:
                                      '${context.tr('saas_company_code')}: $companyCode',
                                  isDark: isDark,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMiniStat(
                                  label: context.tr('dashboard_start_time'),
                                  value: startTime,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildMiniStat(
                                  label: context.tr('dashboard_end_time'),
                                  value: endTime,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildMiniStat(
                                  label: 'Sync',
                                  value: (summary['pending_sync'] ?? 0)
                                      .toString(),
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    secondChild: const SizedBox.shrink(),
                  ),
                  if (_showAttendanceDetails) ...[
                    const SizedBox(height: 10),
                    Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: isDark ? Colors.white54 : const Color(0xFF8A8A8A),
                    ),
                  ] else ...[
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDark ? Colors.white54 : const Color(0xFF8A8A8A),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTimeBlock({
    required String label,
    required String time,
    required String initials,
    required bool isActive,
    required Color accent,
    required bool isDark,
  }) {
    final inactiveColor = isDark ? Colors.white38 : const Color(0xFFC0C0C0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white54 : const Color(0xFFB0B0B0),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFF0F0F0),
                child: Text(
                  initials,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : const Color(0xFFA8A8A8),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      time,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isActive ? accent : inactiveColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: isActive ? accent : inactiveColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            isActive ? badgeDotText(time) : '--',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isActive ? accent : inactiveColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
    );
  }

  Widget _buildFavoriteMenu({
    required List<_HomeShortcut> actions,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFEAE7E2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions
            .map(
              (action) => Expanded(child: _buildFavoriteItem(action, isDark)),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _buildFavoriteItem(_HomeShortcut action, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: action.backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(action.icon, color: action.iconColor, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF3A3A3A),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyInformation({
    required AuthProvider auth,
    required LeaveProvider leave,
    required SaasProvider saas,
    required String companyName,
    required bool isDark,
  }) {
    final currentCompany = saas.currentCompany ?? auth.selectedCompany;
    final companyCode = currentCompany?.cCode.trim().isNotEmpty == true
        ? currentCompany!.cCode.trim()
        : auth.getCompanyCode().trim();
    final accessibleCompanies = saas.companies.isNotEmpty
        ? saas.companies.length
        : auth.companyAssignments.length;
    final leaveBalance = leave.leaveBalance;
    final remainingLeave = leaveBalance == null
        ? 0
        : (leaveBalance.annualTotal - leaveBalance.annualUsed).clamp(0, 999);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFEAE7E2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.orange.withValues(alpha: 0.14)
                      : const Color(0xFFFFF1E3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.business_center_outlined,
                  color: _accentColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      companyCode.isNotEmpty
                          ? '${context.tr('saas_company_code')}: $companyCode'
                          : context.tr('saas_company_not_selected'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white60
                            : const Color(0xFF667085),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _openWorkspace,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _accentColor,
                  side: const BorderSide(color: Color(0xFFFFC78C)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                child: Text(context.tr('saas_open_workspace')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                label: context.tr('saas_accessible_companies'),
                value: accessibleCompanies.toString(),
                icon: Icons.apartment_rounded,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                label: context.tr('profile_leave'),
                value: '$remainingLeave',
                icon: Icons.event_available_outlined,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFEAE7E2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.orange.withValues(alpha: 0.14)
                  : const Color(0xFFFFF1E3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _accentColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1F2937),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white60 : const Color(0xFF667085),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF2A2A2A),
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF8F6F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF263238),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white54 : const Color(0xFF7B7B7B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
        style: TextStyle(
          color: resolvedColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildIconShell({
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white,
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
            ),
          ),
        ),
        if ((badgeCount ?? 0) > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.circular(999),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Center(
                child: Text(
                  badgeCount! > 9 ? '9+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<_HomeShortcut> _buildFavoriteActions(
    AuthProvider auth,
    AttendanceProvider attendance,
  ) {
    final actions = <_HomeShortcut>[];

    if (auth.canAccessAttendanceModule) {
      final shouldClockOut =
          attendance.todayAttendance?.hasClockIn == true &&
          attendance.todayAttendance?.hasClockOut != true;

      actions.add(
        _HomeShortcut(
          label: context.tr('feature_label_attendance'),
          icon: shouldClockOut
              ? Icons.logout_rounded
              : Icons.access_time_rounded,
          iconColor: const Color(0xFF3698F5),
          backgroundColor: const Color(0xFFEAF6FF),
          onTap: () {
            _pushScreen(ClockInScreen(isClockOut: shouldClockOut));
          },
        ),
      );
    }

    if (auth.canAccessLeaveModule) {
      actions.add(
        _HomeShortcut(
          label: context.tr('feature_label_leave'),
          icon: Icons.assignment_turned_in_outlined,
          iconColor: const Color(0xFF4AA8B0),
          backgroundColor: const Color(0xFFE7F8F8),
          onTap: () => _pushScreen(const LeaveScreen()),
        ),
      );
    }

    if (auth.canAccessPayrollModule) {
      actions.add(
        _HomeShortcut(
          label: context.tr('feature_label_payslip'),
          icon: Icons.receipt_long_outlined,
          iconColor: const Color(0xFFE69448),
          backgroundColor: const Color(0xFFFFF1E5),
          onTap: () => _pushScreen(
            ChangeNotifierProvider(
              create: (_) => PayrollProvider(),
              child: const PayslipScreen(),
            ),
          ),
        ),
      );
    }

    if (actions.isEmpty) {
      actions.addAll([
        _HomeShortcut(
          label: context.tr('dashboard_record_time'),
          icon: Icons.access_time_rounded,
          iconColor: const Color(0xFF3698F5),
          backgroundColor: const Color(0xFFEAF6FF),
          onTap: () => _pushScreen(const ClockInScreen()),
        ),
        _HomeShortcut(
          label: context.tr('dashboard_company_information'),
          icon: Icons.business_center_outlined,
          iconColor: const Color(0xFFE69448),
          backgroundColor: const Color(0xFFFFF1E5),
          onTap: _openWorkspace,
        ),
      ]);
    }

    while (actions.length < 3) {
      actions.add(
        _HomeShortcut(
          label: context.tr('saas_workspace_title'),
          icon: Icons.apartment_rounded,
          iconColor: const Color(0xFF6F63E9),
          backgroundColor: const Color(0xFFF0EEFF),
          onTap: _openWorkspace,
        ),
      );
    }

    return actions.take(3).toList(growable: false);
  }

  Future<void> _pushScreen(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _openWorkspace() {
    _pushScreen(const SaasWorkspaceScreen());
  }

  String _initialsFromName(String rawName) {
    final parts = rawName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) {
      return 'HR';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'
        .toUpperCase();
  }

  String _localeCode(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'id' ? 'id_ID' : 'en_US';
  }

  String _displayTime(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty || normalized == '-') {
      return '--:--';
    }
    return normalized;
  }

  String badgeDotText(String time) {
    return time == '--:--' ? '--' : 'Recorded';
  }

  String _attendanceBadgeLabel({
    required bool hasClockIn,
    required bool hasClockOut,
    required bool isPendingSync,
  }) {
    if (isPendingSync) {
      return context.tr('dashboard_attendance_pending_sync');
    }
    if (hasClockIn && hasClockOut) {
      return context.tr('dashboard_attendance_complete');
    }
    if (hasClockIn) {
      return context.tr('dashboard_attendance_active');
    }
    return context.tr('dashboard_attendance_ready');
  }

  Color _statusColor({
    required bool hasClockIn,
    required bool hasClockOut,
    required bool isPendingSync,
  }) {
    if (isPendingSync) {
      return const Color(0xFFE69B2E);
    }
    if (hasClockIn && hasClockOut) {
      return const Color(0xFF2E9F5F);
    }
    if (hasClockIn) {
      return const Color(0xFF3478F6);
    }
    return const Color(0xFF7A7A7A);
  }
}

class _HomeShortcut {
  const _HomeShortcut({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;
}
