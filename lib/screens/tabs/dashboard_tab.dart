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
import '../../data/models/notification_model.dart';
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
  static const double _maxContentWidth = 520;

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
      backgroundColor: _pageBackground(isDark),
      body: dashboard.isLoading
          ? _buildLoadingState(isDark)
          : dashboard.error != null
          ? _buildErrorState(dashboard.error!, isDark)
          : RefreshIndicator(
              color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
              backgroundColor: _surfaceColor(isDark),
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
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  _buildHeader(firstName, isDark, notificationProvider),
                  if (_showNotifications)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: _buildConstrainedContent(
                          AnimatedBuilder(
                            animation: _notificationAnimationController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(
                                  0,
                                  _notificationSlideAnimation.value,
                                ),
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxHeight:
                                        MediaQuery.of(context).size.height *
                                        0.52,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _surfaceColor(isDark),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: _surfaceBorderColor(isDark),
                                    ),
                                    boxShadow: _surfaceShadows(isDark),
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
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        20,
                        20,
                        104 + MediaQuery.of(context).padding.bottom,
                      ),
                      child: _buildConstrainedContent(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAnimatedSection(
                              _buildWelcomeSection(
                                firstName,
                                isDark,
                                dashboard,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildAnimatedSection(
                              _buildSaasSummarySection(
                                isDark,
                                auth,
                                saasProvider,
                              ),
                            ),
                            if (dashboard.isUsingCachedData) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF3D2A16)
                                      : const Color(0xFFFFF4DE),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.28),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.16),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.cloud_off_outlined,
                                        color: Colors.orange,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        context.tr('dashboard_cached_banner'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.45,
                                          color: isDark
                                              ? Colors.orange.shade100
                                              : Colors.orange.shade900,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            _buildAnimatedSection(
                              _buildStatsSection(dashboard, isDark),
                            ),
                            const SizedBox(height: 24),
                            _buildAnimatedSection(
                              _buildQuickActionsSection(isDark, auth),
                            ),
                            const SizedBox(height: 24),
                            _buildAnimatedSection(
                              _buildRecentActivitiesSection(dashboard, isDark),
                            ),
                            const SizedBox(height: 24),
                            _buildAnimatedSection(
                              _buildUpcomingSection(isDark, eventProvider),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAnimatedSection(Widget child) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: child),
    );
  }

  Widget _buildConstrainedContent(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: child,
      ),
    );
  }

  Color _pageBackground(bool isDark) {
    return isDark ? const Color(0xFF081120) : const Color(0xFFF3F6FB);
  }

  Color _surfaceColor(bool isDark) {
    return isDark ? const Color(0xFF101A2B) : Colors.white;
  }

  Color _subtleSurfaceColor(bool isDark) {
    return isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF6F8FC);
  }

  Color _surfaceBorderColor(bool isDark) {
    return isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFDCE5F0);
  }

  List<BoxShadow> _surfaceShadows(bool isDark) {
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withOpacity(0.28)
            : const Color(0xFF0F172A).withOpacity(0.08),
        blurRadius: isDark ? 28 : 22,
        offset: const Offset(0, 12),
      ),
    ];
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final wideLayout = constraints.maxWidth >= 500;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: wideLayout ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: wideLayout ? 172 : 154,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 100)),
              tween: Tween(begin: 0, end: 1),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.92 + (0.08 * value),
                    child: child,
                  ),
                );
              },
              child: _buildStatCard(stats[index], isDark),
            );
          },
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
      expandedHeight: 202,
      floating: false,
      pinned: true,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: isDark
          ? const Color(0xFF0F1A2C)
          : const Color(0xFF2563EB),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: LayoutBuilder(
          builder: (context, constraints) {
            final isCompactHeader = constraints.maxHeight < 150;

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [Color(0xFF0F172A), Color(0xFF1D4ED8)]
                      : const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    top: -90,
                    right: -40,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.09),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -60,
                    bottom: -80,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        18,
                        isCompactHeader ? 12 : 16,
                        18,
                        isCompactHeader ? 12 : 20,
                      ),
                      child: _buildConstrainedContent(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: isCompactHeader ? 44 : 50,
                                  height: isCompactHeader ? 44 : 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.16),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.12),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.dashboard_customize_rounded,
                                    color: Colors.white,
                                    size: isCompactHeader ? 22 : 25,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        context.tr('dashboard_welcome_back'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: isCompactHeader ? 11 : 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withOpacity(0.82),
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        firstName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: isCompactHeader ? 20 : 26,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -0.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(18),
                                        onTap: () {
                                          setState(() {
                                            _showNotifications =
                                                !_showNotifications;
                                            if (_showNotifications) {
                                              _notificationAnimationController
                                                  .forward();
                                            } else {
                                              _notificationAnimationController
                                                  .reverse();
                                            }
                                          });
                                        },
                                        child: Ink(
                                          width: isCompactHeader ? 44 : 48,
                                          height: isCompactHeader ? 44 : 48,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.14,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.12,
                                              ),
                                            ),
                                          ),
                                          child: Icon(
                                            _showNotifications
                                                ? Icons.notifications_active
                                                : Icons.notifications_outlined,
                                            color: Colors.white,
                                            size: isCompactHeader ? 22 : 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (notificationProvider.unreadCount > 0)
                                      Positioned(
                                        right: -2,
                                        top: -2,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEF4444),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 1.5,
                                            ),
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 22,
                                            minHeight: 22,
                                          ),
                                          child: Center(
                                            child: Text(
                                              notificationProvider.unreadCount >
                                                      99
                                                  ? '99+'
                                                  : notificationProvider
                                                        .unreadCount
                                                        .toString(),
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
                                ),
                              ],
                            ),
                            if (!isCompactHeader) ...[
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildHeaderPill(
                                    icon: Icons.wb_sunny_outlined,
                                    label:
                                        '${context.tr('dashboard_good')} ${_getTimeGreeting()}',
                                  ),
                                  _buildDateChip(isDark),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDateChip(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 15,
            color: Colors.white.withOpacity(0.9),
          ),
          const SizedBox(width: 8),
          Text(
            _getFormattedDate(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.92),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white.withOpacity(0.92)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.92),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required bool isDark,
    Color? color,
    double maxWidth = 260,
  }) {
    final iconColor = color ?? (isDark ? Colors.white70 : Colors.blueGrey);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: color != null
                ? color.withOpacity(isDark ? 0.28 : 0.16)
                : _surfaceBorderColor(isDark),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF122033), Color(0xFF1D4ED8)]
              : const [Color(0xFFEAF2FF), Color(0xFFFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.white.withOpacity(0.72),
        ),
        boxShadow: _surfaceShadows(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${context.tr('dashboard_good')} ${_getTimeGreeting()},',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white.withOpacity(0.76)
                            : Colors.blueGrey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      firstName,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('dashboard_summary_today'),
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: isDark
                            ? Colors.white.withOpacity(0.68)
                            : Colors.blueGrey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.12) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : Colors.blue).withOpacity(
                        0.12,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.emoji_emotions_outlined,
                  size: 34,
                  color: isDark ? Colors.amber.shade300 : Colors.blue.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetaChip(
                icon: Icons.people_outline_rounded,
                label:
                    '${dashboard.totalEmployees} ${context.tr('dashboard_total_employees_short')}',
                isDark: isDark,
                color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
                maxWidth: 280,
              ),
              _buildMetaChip(
                icon: Icons.insights_outlined,
                label: context.tr('dashboard_summary_today'),
                isDark: isDark,
                color: isDark ? Colors.cyan.shade200 : Colors.indigo.shade600,
                maxWidth: 230,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(_StatItem stat, bool isDark) {
    final trendColor = stat.trendUp
        ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
        : (isDark ? Colors.orange.shade200 : Colors.orange.shade700);

    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor(isDark),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: stat.color.withOpacity(isDark ? 0.26 : 0.12)),
        boxShadow: _surfaceShadows(isDark),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -24,
            right: -12,
            child: IgnorePointer(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: stat.gradient
                        .map((color) => color.withOpacity(isDark ? 0.28 : 0.2))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: stat.color.withOpacity(isDark ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(stat.icon, color: stat.color, size: 20),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: trendColor.withOpacity(isDark ? 0.18 : 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Icon(
                            stat.trendUp
                                ? Icons.trending_up_rounded
                                : Icons.trending_flat_rounded,
                            color: trendColor,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      stat.value,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stat.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withOpacity(0.78)
                            : Colors.grey.shade800,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stat.trend,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: trendColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF0F172A), Color(0xFF1D4ED8)]
                  : const [Color(0xFFEAF2FF), Color(0xFFF7FAFF)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFFDCE7F5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isDark ? 0.12 : 0.86),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: isDark ? Colors.white : Colors.indigo.shade700,
                    ),
                  ),
                  const SizedBox(width: 14),
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
                            fontWeight: FontWeight.w800,
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
                            height: 1.4,
                            color: isDark
                                ? Colors.white70
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
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
              const SizedBox(height: 18),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactLayout = constraints.maxWidth < 500;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: compactLayout ? 2 : 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: compactLayout ? 132 : 112,
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
                child: _buildQuickActionItem(
                  actions[index],
                  isDark,
                  showPurpose: compactLayout,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildQuickActionItem(
    _QuickAction action,
    bool isDark, {
    required bool showPurpose,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _subtleSurfaceColor(isDark),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: action.color.withOpacity(isDark ? 0.22 : 0.14),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: action.color.withOpacity(isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(action.icon, color: action.color, size: 22),
              ),
              const Spacer(),
              Text(
                action.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.grey.shade900,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (showPurpose) ...[
                const SizedBox(height: 6),
                Text(
                  action.purpose,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.35,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
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
        color: Colors.white.withOpacity(isDark ? 0.1 : 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : const Color(0xFFD9E4F5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: isDark ? Colors.white70 : Colors.indigo.shade700,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 11,
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
      backgroundColor: _surfaceColor(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
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
        child: _buildSectionPlaceholder(
          icon: Icons.history_rounded,
          title: context.tr('dashboard_no_recent_activities'),
          isDark: isDark,
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
        separatorBuilder: (_, __) => const SizedBox(height: 12),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _subtleSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _surfaceBorderColor(isDark)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person_add_alt_1, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildMetaChip(
                      icon: Icons.badge_outlined,
                      label: item.positionName,
                      isDark: isDark,
                      maxWidth: 210,
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey.shade400,
                      ),
                    ),
                    _buildMetaChip(
                      icon: Icons.schedule_outlined,
                      label: _formatDate(item.createdAt),
                      isDark: isDark,
                      maxWidth: 170,
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
      ),
    );
  }

  Widget _buildSectionPlaceholder({
    required IconData icon,
    required String title,
    required bool isDark,
    String? message,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.blue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 14), action],
          ],
        ),
      ),
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
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.blue.shade200 : Colors.blue.shade700,
                  ),
                ),
              ),
            )
          : eventProvider.error != null && events.isEmpty
          ? _buildSectionPlaceholder(
              icon: Icons.event_busy_outlined,
              title: context.tr('dashboard_event_load_failed'),
              message: eventProvider.error!,
              isDark: isDark,
              action: OutlinedButton(
                onPressed: eventProvider.fetchUpcomingEvents,
                child: Text(context.tr('dashboard_retry')),
              ),
            )
          : events.isEmpty
          ? _buildSectionPlaceholder(
              icon: Icons.event_available_outlined,
              title: context.tr('dashboard_no_upcoming_events'),
              message: context.tr('dashboard_event_empty_hint'),
              isDark: isDark,
              action: ElevatedButton.icon(
                onPressed: _openEventManagement,
                icon: const Icon(Icons.add),
                label: Text(context.tr('dashboard_create_event')),
              ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _subtleSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accentColor.withOpacity(isDark ? 0.24 : 0.14),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isCompanyWide ? Icons.groups_2_outlined : Icons.mail_outline,
              color: accentColor,
              size: 18,
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
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatEventSchedule(event),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.location.isNotEmpty
                      ? '${_buildAudienceLabel(event)} • ${event.location}'
                      : _buildAudienceLabel(event),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
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
        child: _buildSectionPlaceholder(
          icon: Icons.notifications_none_outlined,
          title: context.tr('dashboard_no_notifications'),
          isDark: isDark,
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
                    backgroundColor: isDark
                        ? Colors.white.withOpacity(0.05)
                        : const Color(0xFFEFF4FF),
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
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

  Widget _buildNotificationItem(NotificationItem notification, bool isDark) {
    return InkWell(
      onTap: () {
        if (!notification.isRead) {
          context.read<NotificationProvider>().markAsRead(notification.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: !notification.isRead
              ? (isDark
                    ? notification.color.withOpacity(0.15)
                    : notification.color.withOpacity(0.05))
              : _subtleSurfaceColor(isDark),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _surfaceBorderColor(isDark)),
        boxShadow: _surfaceShadows(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (actionText != null)
                TextButton(
                  onPressed: onActionTap,
                  style: TextButton.styleFrom(
                    foregroundColor: isDark
                        ? Colors.blue.shade200
                        : Colors.blue.shade700,
                    backgroundColor: isDark
                        ? Colors.white.withOpacity(0.05)
                        : const Color(0xFFEFF4FF),
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
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
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _buildConstrainedContent(
          Center(
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _surfaceColor(isDark),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _surfaceBorderColor(isDark)),
                boxShadow: _surfaceShadows(isDark),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? Colors.blue.shade200 : Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    context.tr('dashboard_loading'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _buildConstrainedContent(
          Center(
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _surfaceColor(isDark),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _surfaceBorderColor(isDark)),
                boxShadow: _surfaceShadows(isDark),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
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
                      context.read<NotificationProvider>().fetchNotifications();
                      context.read<EventProvider>().fetchUpcomingEvents();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
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
          ),
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
