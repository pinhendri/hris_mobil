import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/localization/app_strings.dart';
import '../../models/calendar_event_model.dart';
import '../../models/saas_models.dart';
import '../../providers/claim_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/saas_provider.dart';
import '../../data/models/notification_model.dart'; // TAMBAHKAN IMPORT INI
import '../admin/claim_reports_screen.dart';
import '../admin/event_management_screen.dart';
import '../attendance/clock_in_screen.dart';
import '../employee/add_employee_screen.dart';
import '../leave/leave_screen.dart';
import '../notifications/notification_screen.dart';
import '../saas/saas_workspace_screen.dart';

// ================= DASHBOARD TAB =================
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _notificationAnimationController;
  late Animation<double> _notificationSlideAnimation;
  bool _showNotifications = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _notificationAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _notificationSlideAnimation = Tween<double>(begin: -100, end: 0).animate(
      CurvedAnimation(
        parent: _notificationAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final companyCode = authProvider.getCompanyCode();

      context.read<DashboardProvider>().fetchDashboardData(
        companyCode: companyCode,
      );
      context.read<SaasProvider>().loadWorkspace(
        includeAdminOverview: authProvider.canAccessPlatformAdmin,
      );
      context.read<NotificationProvider>().fetchNotifications();
      context.read<EventProvider>().fetchUpcomingEvents();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _notificationAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final eventProvider = context.watch<EventProvider>();
    final saasProvider = context.watch<SaasProvider>();
    final isDark = themeProvider.isDarkMode;

    final firstName = (auth.user?.name ?? context.tr('profile_user_fallback'))
        .split(' ')
        .first;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF8F9FA),
      body: dashboard.isLoading
          ? _buildLoadingState(isDark)
          : dashboard.error != null
          ? _buildErrorState(dashboard.error!, isDark)
          : RefreshIndicator(
              onRefresh: () async {
                final authProvider = context.read<AuthProvider>();
                final newCompanyCode = authProvider.getCompanyCode();
                await Future.wait([
                  context.read<DashboardProvider>().fetchDashboardData(
                    companyCode: newCompanyCode,
                  ),
                  context.read<SaasProvider>().loadWorkspace(
                    includeAdminOverview: authProvider.canAccessPlatformAdmin,
                    force: true,
                  ),
                  context.read<NotificationProvider>().fetchNotifications(),
                  context.read<EventProvider>().fetchUpcomingEvents(),
                ]);
              },
              child: CustomScrollView(
                slivers: [
                  _buildHeader(firstName, isDark, notificationProvider),
                  if (_showNotifications)
                    SliverToBoxAdapter(
                      child: AnimatedBuilder(
                        animation: _notificationAnimationController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              0,
                              _notificationSlideAnimation.value,
                            ),
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.of(context).size.height * 0.5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E1E1E)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: _buildNotificationPanel(
                                isDark,
                                notificationProvider,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: _buildWelcomeSection(
                              firstName,
                              isDark,
                              dashboard,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: _buildSaasSummarySection(
                              isDark,
                              auth,
                              saasProvider,
                            ),
                          ),
                        ),
                        if (dashboard.isUsingCachedData) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.orange.withOpacity(0.12)
                                  : const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.cloud_off_outlined,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    context.tr('dashboard_cached_banner'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.orange.shade100
                                          : Colors.orange.shade900,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: _buildStatsSection(dashboard, isDark),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: _buildQuickActionsSection(isDark, auth),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: _buildRecentActivitiesSection(
                              dashboard,
                              isDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: _buildUpcomingSection(isDark, eventProvider),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // MARK: - Stats Section
  Widget _buildStatsSection(DashboardProvider dashboard, bool isDark) {
    final stats = [
      _StatItem(
        title: context.tr('dashboard_stat_total_employees'),
        value: dashboard.totalEmployees.toString(),
        icon: Icons.people_alt,
        color: Colors.blue,
        gradient: const [Color(0xFF4158D0), Color(0xFFC850C0)],
        trend:
            '${context.tr('dashboard_stat_active')}: ${dashboard.activeEmployees}',
        trendUp: true,
      ),
      _StatItem(
        title: context.tr('dashboard_stat_attendance_today'),
        value: dashboard.attendanceToday.toString(),
        icon: Icons.check_circle,
        color: Colors.green,
        gradient: const [Color(0xFF0093E9), Color(0xFF80D0C7)],
        trend: context.tr('dashboard_stat_present_today'),
        trendUp: dashboard.attendanceToday > 0,
      ),
      _StatItem(
        title: context.tr('dashboard_stat_on_leave_today'),
        value: dashboard.onLeave.toString(),
        icon: Icons.event_note,
        color: Colors.orange,
        gradient: const [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
        trend: context.tr('dashboard_stat_leave_today'),
        trendUp: false,
      ),
      _StatItem(
        title: context.tr('dashboard_stat_new_hires'),
        value: dashboard.newHires.toString(),
        icon: Icons.person_add,
        color: Colors.purple,
        gradient: const [Color(0xFF00B4DB), Color(0xFF0083B0)],
        trend: context.tr('dashboard_stat_this_month'),
        trendUp: dashboard.newHires > 0,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100)),
          tween: Tween(begin: 0, end: 1),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
            );
          },
          child: _buildStatCard(stats[index], isDark),
        );
      },
    );
  }

  // MARK: - Header Section
  Widget _buildHeader(
    String firstName,
    bool isDark,
    NotificationProvider notificationProvider,
  ) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.blue,
      flexibleSpace: FlexibleSpaceBar(
        background: LayoutBuilder(
          builder: (context, constraints) {
            final isCompactHeader = constraints.maxHeight < 150;

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [Color(0xFF1A237E), Color(0xFF311B92)]
                      : [Colors.blue.shade400, Colors.blue.shade700],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    isCompactHeader ? 12 : 24,
                    20,
                    isCompactHeader ? 12 : 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 500),
                            tween: Tween(begin: 0, end: 1),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: child,
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.all(
                                isCompactHeader ? 10 : 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.dashboard_customize,
                                color: Colors.white,
                                size: isCompactHeader ? 24 : 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 600),
                                  tween: Tween(begin: 0, end: 1),
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 10 * (1 - value)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    context.tr('dashboard_welcome_back'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: isCompactHeader ? 12 : 14,
                                      color: Colors.white.withOpacity(0.9),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 700),
                                  tween: Tween(begin: 0, end: 1),
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 10 * (1 - value)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    firstName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: isCompactHeader ? 22 : 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: isCompactHeader ? 4 : 8),
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints.tight(
                                  Size.square(isCompactHeader ? 36 : 44),
                                ),
                                icon: Icon(
                                  _showNotifications
                                      ? Icons.notifications_active
                                      : Icons.notifications_outlined,
                                  color: Colors.white,
                                  size: isCompactHeader ? 24 : 28,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showNotifications = !_showNotifications;
                                    if (_showNotifications) {
                                      _notificationAnimationController
                                          .forward();
                                    } else {
                                      _notificationAnimationController
                                          .reverse();
                                    }
                                  });
                                },
                              ),
                              if (notificationProvider.unreadCount > 0)
                                Positioned(
                                  right: 2,
                                  top: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Center(
                                      child: Text(
                                        notificationProvider.unreadCount > 99
                                            ? '99+'
                                            : notificationProvider.unreadCount
                                                  .toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (!isCompactHeader) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 800),
                                tween: Tween(begin: 0, end: 1),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(20 * (1 - value), 0),
                                      child: child,
                                    ),
                                  );
                                },
                                child: _buildDateChip(isDark),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDateChip(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: 14,
            color: Colors.white.withOpacity(0.9),
          ),
          const SizedBox(width: 8),
          Text(
            _getFormattedDate(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Welcome Section
  Widget _buildWelcomeSection(
    String firstName,
    bool isDark,
    DashboardProvider dashboard,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2C3E50), const Color(0xFF3498DB)]
              : [Colors.blue.shade50, Colors.blue.shade100],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.tr('dashboard_good')} ${_getTimeGreeting()},',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  firstName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('dashboard_summary_today'),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 14,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${dashboard.totalEmployees} ${context.tr('dashboard_total_employees_short')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_emotions,
              size: 40,
              color: isDark ? Colors.amber : Colors.blue.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(_StatItem stat, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: stat.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: stat.color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(stat.icon, color: Colors.white, size: 20),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (stat.trendUp ? Colors.green : Colors.red)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            stat.trendUp
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: stat.trendUp ? Colors.green : Colors.red,
                            size: 12,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            stat.trend,
                            style: TextStyle(
                              color: stat.trendUp ? Colors.green : Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  stat.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat.title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaasSummarySection(
    bool isDark,
    AuthProvider auth,
    SaasProvider saasProvider,
  ) {
    final currentCompany = saasProvider.currentCompany ?? auth.selectedCompany;
    final trialStatus = saasProvider.trialStatus;
    final trialColor = _trialTone(trialStatus);

    return _buildSectionCard(
      title: context.tr('saas_workspace_title'),
      isDark: isDark,
      actionText: context.tr('saas_open_workspace'),
      onActionTap: _openSaasWorkspace,
      child: InkWell(
        onTap: _openSaasWorkspace,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0F172A), const Color(0xFF1D4ED8)]
                  : [Colors.blue.shade50, Colors.indigo.shade50],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isDark ? 0.12 : 0.8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: isDark ? Colors.white : Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentCompany?.companyName.isNotEmpty == true
                              ? currentCompany!.companyName
                              : context.tr('saas_company_not_selected'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.grey.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentCompany?.cCode.isNotEmpty == true
                              ? '${context.tr('saas_company_code')}: ${currentCompany!.cCode}'
                              : context.tr('saas_workspace_subtitle'),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white70
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: trialColor.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _trialLabel(trialStatus),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: trialColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildSaasMetricChip(
                    icon: Icons.timelapse_outlined,
                    label: context.tr('saas_days_remaining'),
                    value: trialStatus?.daysRemaining?.toString() ?? '-',
                    isDark: isDark,
                  ),
                  _buildSaasMetricChip(
                    icon: Icons.business_outlined,
                    label: context.tr('saas_accessible_companies'),
                    value:
                        '${saasProvider.companies.isNotEmpty ? saasProvider.companies.length : auth.companyAssignments.length}',
                    isDark: isDark,
                  ),
                  _buildSaasMetricChip(
                    icon: Icons.mark_email_unread_outlined,
                    label: context.tr('saas_pending_invitations'),
                    value: '${saasProvider.pendingInvitationsCount}',
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // MARK: - Quick Actions Section
  Widget _buildQuickActionsSection(bool isDark, AuthProvider auth) {
    final actions = <_QuickAction>[
      _QuickAction(
        id: 'scan',
        icon: Icons.qr_code_scanner,
        label: context.tr('dashboard_action_scan'),
        color: Colors.purple,
        purpose: context.tr('dashboard_action_scan_purpose'),
        onTap: () => _pushScreen(const ClockInScreen()),
      ),
      _QuickAction(
        id: 'leave',
        icon: Icons.event,
        label: context.tr('dashboard_action_leave'),
        color: Colors.orange,
        purpose: context.tr('dashboard_action_leave_purpose'),
        onTap: () => _pushScreen(const LeaveScreen()),
      ),
      _QuickAction(
        id: 'reports',
        icon: Icons.assessment,
        label: context.tr('dashboard_action_reports'),
        color: Colors.green,
        purpose: context.tr('dashboard_action_reports_purpose'),
        onTap: () => _pushScreen(
          ChangeNotifierProvider(
            create: (_) => ClaimProvider(),
            child: const ClaimReportsScreen(),
          ),
        ),
      ),
    ];

    if (auth.hasPermission('create-employee')) {
      actions.insert(
        1,
        _QuickAction(
          id: 'add_employee',
          icon: Icons.person_add,
          label: context.tr('dashboard_action_add_employee'),
          color: Colors.blue,
          purpose: context.tr('dashboard_action_add_employee_purpose'),
          onTap: () => _pushScreen(const AddEmployeeScreen()),
        ),
      );
    }

    if (!auth.hasAnyPermission(['view-reports', 'view-payroll'])) {
      actions.removeWhere((action) => action.id == 'reports');
    }

    return _buildSectionCard(
      title: context.tr('dashboard_quick_actions'),
      isDark: isDark,
      actionText: context.tr('dashboard_guide'),
      onActionTap: () => _showQuickActionGuide(actions, isDark),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.8,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 400 + (index * 50)),
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: _buildQuickActionItem(actions[index], isDark),
          );
        },
      ),
    );
  }

  Widget _buildQuickActionItem(_QuickAction action, bool isDark) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pushScreen(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _openSaasWorkspace() {
    _pushScreen(const SaasWorkspaceScreen());
  }

  Widget _buildSaasMetricChip({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isDark ? 0.1 : 0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isDark ? Colors.white70 : Colors.indigo),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.grey.shade900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

  String _trialLabel(TrialStatus? trialStatus) {
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

  void _showQuickActionGuide(List<_QuickAction> actions, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('dashboard_quick_action_guide_title'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('dashboard_quick_action_guide_message'),
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                ...actions.map(
                  (action) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: action.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            action.icon,
                            color: action.color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                action.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                action.purpose,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.45,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
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
      },
    );
  }

  // MARK: - Recent Activities Section
  Widget _buildRecentActivitiesSection(
    DashboardProvider dashboard,
    bool isDark,
  ) {
    final activities = dashboard.recentActivities;

    if (activities.isEmpty) {
      return _buildSectionCard(
        title: context.tr('dashboard_recent_activities'),
        isDark: isDark,
        actionText: context.tr('dashboard_view_all'),
        onActionTap: () {},
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(context.tr('dashboard_no_recent_activities')),
          ),
        ),
      );
    }

    return _buildSectionCard(
      title: context.tr('dashboard_recent_activities'),
      isDark: isDark,
      actionText: context.tr('dashboard_view_all'),
      onActionTap: () {},
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length > 4 ? 4 : activities.length,
        separatorBuilder: (_, __) => const Divider(height: 24),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (index * 100)),
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(20 * (1 - value), 0),
                  child: child,
                ),
              );
            },
            child: _buildActivityItem(activity, isDark),
          );
        },
      ),
    );
  }

  Widget _buildActivityItem(RecentActivity item, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.person_add, color: Colors.blue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    item.positionName,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    ' • ',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                    ),
                  ),
                  Text(
                    _formatDate(item.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Icon(
          Icons.more_horiz,
          color: isDark ? Colors.white38 : Colors.grey.shade400,
          size: 20,
        ),
      ],
    );
  }

  // MARK: - Upcoming Section
  Widget _buildUpcomingSection(bool isDark, EventProvider eventProvider) {
    return _buildDynamicUpcomingSection(isDark, eventProvider);
  }

  Widget _buildDynamicUpcomingSection(
    bool isDark,
    EventProvider eventProvider,
  ) {
    final events = eventProvider.upcomingEvents.take(3).toList(growable: false);

    return _buildSectionCard(
      title: context.tr('dashboard_upcoming_events'),
      isDark: isDark,
      actionText: context.tr('dashboard_manage'),
      onActionTap: _openEventManagement,
      child: eventProvider.isLoading && events.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          : eventProvider.error != null && events.isEmpty
          ? Column(
              children: [
                Text(
                  context.tr('dashboard_event_load_failed'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  eventProvider.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: eventProvider.fetchUpcomingEvents,
                  child: Text(context.tr('dashboard_retry')),
                ),
              ],
            )
          : events.isEmpty
          ? Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.blue.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.event_available_outlined,
                    color: isDark ? Colors.blue.shade200 : Colors.blue,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr('dashboard_no_upcoming_events'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr('dashboard_event_empty_hint'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _openEventManagement,
                  icon: const Icon(Icons.add),
                  label: Text(context.tr('dashboard_create_event')),
                ),
              ],
            )
          : Column(
              children: [
                for (var index = 0; index < events.length; index++) ...[
                  _buildUpcomingEventItem(events[index], isDark),
                  if (index != events.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }

  Widget _buildUpcomingEventItem(CalendarEvent event, bool isDark) {
    final isCompanyWide = event.isCompanyWide;
    final accentColor = isCompanyWide ? Colors.green : Colors.blue;
    final subtitleColor = isDark ? Colors.white60 : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompanyWide ? Icons.groups_2_outlined : Icons.mail_outline,
              color: accentColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatEventSchedule(event),
                  style: TextStyle(fontSize: 11, color: subtitleColor),
                ),
                const SizedBox(height: 2),
                Text(
                  event.location.isNotEmpty
                      ? '${_buildAudienceLabel(event)} • ${event.location}'
                      : _buildAudienceLabel(event),
                  style: TextStyle(fontSize: 11, color: subtitleColor),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isCompanyWide
                  ? context.tr('feature_category_all')
                  : '${event.inviteCount}',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openEventManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EventManagementScreen()),
    );
  }

  String _formatEventSchedule(CalendarEvent event) {
    final localeCode = _currentLocaleCode();
    final startLabel = DateFormat(
      'EEE, dd MMM • HH:mm',
      localeCode,
    ).format(event.startsAt);

    if (event.endsAt == null) {
      return startLabel;
    }

    final sameDay =
        event.startsAt.year == event.endsAt!.year &&
        event.startsAt.month == event.endsAt!.month &&
        event.startsAt.day == event.endsAt!.day;

    if (sameDay) {
      return '$startLabel - ${DateFormat('HH:mm', localeCode).format(event.endsAt!)}';
    }

    return '$startLabel - ${DateFormat('dd MMM • HH:mm', localeCode).format(event.endsAt!)}';
  }

  String _buildAudienceLabel(CalendarEvent event) {
    if (event.isCompanyWide) {
      return context.tr('dashboard_all_employees');
    }

    if (event.isUserInvited) {
      return context.tr('dashboard_you_are_invited');
    }

    return _inviteeLabel(event.inviteCount);
  }

  // MARK: - Notification Panel
  Widget _buildNotificationPanel(
    bool isDark,
    NotificationProvider notificationProvider,
  ) {
    if (notificationProvider.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (notificationProvider.notifications.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none,
                size: 50,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('dashboard_no_notifications'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notifications_active,
                    size: 20,
                    color: isDark ? Colors.blue.shade300 : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('dashboard_notifications'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (notificationProvider.unreadCount > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        notificationProvider.unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              if (notificationProvider.unreadCount > 0)
                TextButton(
                  onPressed: () => notificationProvider.markAllAsRead(),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark
                        ? Colors.blue.shade300
                        : Colors.blue,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    context.tr('dashboard_mark_all_read'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: notificationProvider.notifications.length > 5
                ? 5
                : notificationProvider.notifications.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
            itemBuilder: (context, index) {
              final notification = notificationProvider.notifications[index];
              return _buildNotificationItem(notification, isDark);
            },
          ),
        ),
        if (notificationProvider.notifications.length > 5)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
              ),
            ),
            child: Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationScreen(),
                    ),
                  );
                },
                child: Text(
                  context
                      .tr('dashboard_view_all_notifications')
                      .replaceAll(
                        '{count}',
                        notificationProvider.notifications.length.toString(),
                      ),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.blue.shade300 : Colors.blue,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // PERBAIKAN: Gunakan NotificationItem dari model, bukan dynamic
  Widget _buildNotificationItem(NotificationItem notification, bool isDark) {
    return InkWell(
      onTap: () {
        if (!notification.isRead) {
          context.read<NotificationProvider>().markAsRead(notification.id);
        }

        // TODO: Navigasi ke halaman terkait berdasarkan type
        // if (notification.type == 'leave_request') {
        //   // Navigasi ke halaman detail leave request
        // }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: !notification.isRead
              ? (isDark
                    ? notification.color.withOpacity(0.15)
                    : notification.color.withOpacity(0.05))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon dengan background
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: notification.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                notification.icon,
                color: notification.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    notification.displayTitle,
                    style: TextStyle(
                      fontWeight: !notification.isRead
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Message (dari backend)
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Tampilkan informasi tambahan untuk leave request
                  if (notification.type == 'leave_request' &&
                      notification.days != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${context.tr('dashboard_duration_label')}: ${notification.days} ${notification.days == 1 ? context.tr('dashboard_duration_day') : context.tr('dashboard_duration_days')}',
                        style: TextStyle(
                          fontSize: 11,
                          color: notification.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  const SizedBox(height: 4),

                  // Time
                  Text(
                    _formatNotificationTime(notification.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),

            // Unread indicator
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: notification.color,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatNotificationTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return context.tr('dashboard_just_now');
    if (difference.inMinutes < 60)
      return context
          .tr('dashboard_minutes_ago')
          .replaceAll('{count}', difference.inMinutes.toString());
    if (difference.inHours < 24) {
      return context
          .tr('dashboard_hours_ago')
          .replaceAll('{count}', difference.inHours.toString());
    }
    if (difference.inDays < 7) {
      return context
          .tr('dashboard_days_ago')
          .replaceAll('{count}', difference.inDays.toString());
    }
    return DateFormat('dd MMM yyyy', _currentLocaleCode()).format(time);
  }

  // MARK: - Helper Widgets
  Widget _buildSectionCard({
    required String title,
    required bool isDark,
    required Widget child,
    String? actionText,
    VoidCallback? onActionTap,
  }) {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                  letterSpacing: -0.3,
                ),
              ),
              if (actionText != null)
                TextButton(
                  onPressed: onActionTap,
                  style: TextButton.styleFrom(
                    foregroundColor: isDark
                        ? Colors.blue.shade300
                        : Colors.blue,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    actionText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? Colors.blue.shade300 : Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('dashboard_loading'),
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              context.tr('dashboard_error_title'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.red.shade400, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final authProvider = context.read<AuthProvider>();
                final companyCode = authProvider.getCompanyCode();
                context.read<DashboardProvider>().fetchDashboardData(
                  companyCode: companyCode,
                );
                context
                    .read<NotificationProvider>()
                    .fetchNotifications(); // TAMBAHKAN REFRESH NOTIFIKASI
                context.read<EventProvider>().fetchUpcomingEvents();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(context.tr('dashboard_try_again')),
            ),
          ],
        ),
      ),
    );
  }

  // MARK: - Utility Methods
  String _getFormattedDate() {
    final now = DateTime.now();
    return DateFormat('dd MMM yyyy', _currentLocaleCode()).format(now);
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return context.tr('dashboard_morning');
    if (hour < 17) return context.tr('dashboard_afternoon');
    return context.tr('dashboard_evening');
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy', _currentLocaleCode()).format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _currentLocaleCode() {
    final locale = Localizations.localeOf(context);
    final countryCode = locale.countryCode;

    if (countryCode == null || countryCode.isEmpty) {
      return locale.languageCode;
    }

    return '${locale.languageCode}_$countryCode';
  }

  String _inviteeLabel(int count) {
    if (_currentLocaleCode().startsWith('id')) {
      return '$count undangan';
    }

    return '$count invitee${count == 1 ? '' : 's'}';
  }
}

// MARK: - Models
class _StatItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  final String trend;
  final bool trendUp;

  _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.trend,
    required this.trendUp,
  });
}

class _QuickAction {
  final String id;
  final IconData icon;
  final String label;
  final Color color;
  final String purpose;
  final VoidCallback onTap;

  _QuickAction({
    required this.id,
    required this.icon,
    required this.label,
    required this.color,
    required this.purpose,
    required this.onTap,
  });
}
