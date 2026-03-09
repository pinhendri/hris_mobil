import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/notification_provider.dart';
import '../../data/models/notification_model.dart'; // TAMBAHKAN IMPORT INI

// ================= DASHBOARD TAB =================
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> with TickerProviderStateMixin {
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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _notificationAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _notificationSlideAnimation = Tween<double>(begin: -100, end: 0).animate(
      CurvedAnimation(parent: _notificationAnimationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final companyCode = authProvider.getCompanyCode();
      
      print('🏢 Initializing Dashboard with company code: $companyCode');
      
      context.read<DashboardProvider>().fetchDashboardData(companyCode: companyCode);
      context.read<NotificationProvider>().fetchNotifications();
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
    final isDark = themeProvider.isDarkMode;

    final firstName = (auth.user?.name ?? 'User').split(' ').first;
    final companyCode = auth.getCompanyCode();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      body: dashboard.isLoading
          ? _buildLoadingState(isDark)
          : dashboard.error != null
          ? _buildErrorState(dashboard.error!, isDark)
          : RefreshIndicator(
              onRefresh: () async {
                final authProvider = context.read<AuthProvider>();
                final newCompanyCode = authProvider.getCompanyCode();
                await context.read<DashboardProvider>().fetchDashboardData(companyCode: newCompanyCode);
                await context.read<NotificationProvider>().fetchNotifications(); // TAMBAHKAN REFRESH NOTIFIKASI
              },
              child: CustomScrollView(
                slivers: [
                  _buildHeader(firstName, isDark, notificationProvider, companyCode, dashboard),
                  if (_showNotifications)
                    SliverToBoxAdapter(
                      child: AnimatedBuilder(
                        animation: _notificationAnimationController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _notificationSlideAnimation.value),
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              constraints: BoxConstraints(
                                maxHeight: MediaQuery.of(context).size.height * 0.5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: _buildNotificationPanel(isDark, notificationProvider),
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
                            child: _buildWelcomeSection(firstName, isDark, dashboard),
                          ),
                        ),
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
                            child: _buildQuickActionsSection(isDark),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: _buildRecentActivitiesSection(dashboard, isDark),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: _buildUpcomingSection(isDark),
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
    print('📊 Building stats - Total: ${dashboard.totalEmployees}, Active: ${dashboard.activeEmployees}');
    
    final stats = [
      _StatItem(
        title: 'Total Employees',
        value: dashboard.totalEmployees.toString(),
        icon: Icons.people_alt,
        color: Colors.blue,
        gradient: const [Color(0xFF4158D0), Color(0xFFC850C0)],
        trend: 'Active: ${dashboard.activeEmployees}',
        trendUp: true,
      ),
      _StatItem(
        title: 'Today\'s Attendance',
        value: dashboard.attendanceToday.toString(),
        icon: Icons.check_circle,
        color: Colors.green,
        gradient: const [Color(0xFF0093E9), Color(0xFF80D0C7)],
        trend: 'Present today',
        trendUp: dashboard.attendanceToday > 0,
      ),
      _StatItem(
        title: 'On Leave Today',
        value: dashboard.onLeave.toString(),
        icon: Icons.event_note,
        color: Colors.orange,
        gradient: const [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
        trend: 'Leave today',
        trendUp: false,
      ),
      _StatItem(
        title: 'New Hires',
        value: dashboard.newHires.toString(),
        icon: Icons.person_add,
        color: Colors.purple,
        gradient: const [Color(0xFF00B4DB), Color(0xFF0083B0)],
        trend: 'This month',
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
              child: Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: child,
              ),
            );
          },
          child: _buildStatCard(stats[index], isDark),
        );
      },
    );
  }

  // MARK: - Header Section
  Widget _buildHeader(String firstName, bool isDark, NotificationProvider notificationProvider, String? companyCode, DashboardProvider dashboard) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.blue,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
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
              padding: const EdgeInsets.all(24.0),
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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.dashboard_customize, color: Colors.white, size: 28),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                'Welcome back,',
                                style: TextStyle(
                                  fontSize: 14,
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
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (companyCode != null && companyCode.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Text(
                            companyCode,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: Icon(
                              _showNotifications ? Icons.notifications_active : Icons.notifications_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () {
                              setState(() {
                                _showNotifications = !_showNotifications;
                                if (_showNotifications) {
                                  _notificationAnimationController.forward();
                                } else {
                                  _notificationAnimationController.reverse();
                                }
                              });
                            },
                          ),
                          if (notificationProvider.unreadCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                child: Center(
                                  child: Text(
                                    notificationProvider.unreadCount > 99 ? '99+' : notificationProvider.unreadCount.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      TweenAnimationBuilder<double>(
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
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.people, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        'Total Employees: ${dashboard.totalEmployees}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
          Icon(Icons.calendar_today, size: 14, color: Colors.white.withOpacity(0.9)),
          const SizedBox(width: 8),
          Text(
            _getFormattedDate(),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }

  // MARK: - Welcome Section
  Widget _buildWelcomeSection(String firstName, bool isDark, DashboardProvider dashboard) {
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
                Text('Good ${_getTimeGreeting()},', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey.shade700)),
                const SizedBox(height: 4),
                Text(firstName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade800)),
                const SizedBox(height: 8),
                Text('Here\'s your summary for today', style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 14, color: isDark ? Colors.white54 : Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text('${dashboard.totalEmployees} total employees', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600)),
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
            child: Icon(Icons.emoji_emotions, size: 40, color: isDark ? Colors.amber : Colors.blue.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(_StatItem stat, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: stat.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: stat.color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
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
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: Icon(stat.icon, color: Colors.white, size: 20),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (stat.trendUp ? Colors.green : Colors.red).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(stat.trendUp ? Icons.arrow_upward : Icons.arrow_downward,
                              color: stat.trendUp ? Colors.green : Colors.red, size: 12),
                          const SizedBox(width: 2),
                          Text(stat.trend, style: TextStyle(color: stat.trendUp ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(stat.value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(stat.title, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // MARK: - Quick Actions Section
  Widget _buildQuickActionsSection(bool isDark) {
    final actions = [
      _QuickAction(icon: Icons.qr_code_scanner, label: 'Scan', color: Colors.purple, route: '/scan'),
      _QuickAction(icon: Icons.person_add, label: 'Add Employee', color: Colors.blue, route: '/add-employee'),
      _QuickAction(icon: Icons.event, label: 'Leave', color: Colors.orange, route: '/leave'),
      _QuickAction(icon: Icons.assessment, label: 'Reports', color: Colors.green, route: '/reports'),
    ];

    return _buildSectionCard(
      title: 'Quick Actions',
      isDark: isDark,
      actionText: 'More',
      onActionTap: () {},
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.8),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 400 + (index * 50)),
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
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
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: action.color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(action.icon, color: action.color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.grey.shade700),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // MARK: - Recent Activities Section
  Widget _buildRecentActivitiesSection(DashboardProvider dashboard, bool isDark) {
    final activities = dashboard.recentActivities;
    
    if (activities.isEmpty) {
      return _buildSectionCard(
        title: 'Recent Activities',
        isDark: isDark,
        actionText: 'View All',
        onActionTap: () {},
        child: const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No recent activities'))),
      );
    }

    return _buildSectionCard(
      title: 'Recent Activities',
      isDark: isDark,
      actionText: 'View All',
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
                child: Transform.translate(offset: Offset(20 * (1 - value), 0), child: child),
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
          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.person_add, color: Colors.blue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87, fontSize: 14)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(item.positionName, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade600)),
                  Text(' • ', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400)),
                  Text(_formatDate(item.createdAt), style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade500)),
                ],
              ),
            ],
          ),
        ),
        Icon(Icons.more_horiz, color: isDark ? Colors.white38 : Colors.grey.shade400, size: 20),
      ],
    );
  }

  // MARK: - Upcoming Section
  Widget _buildUpcomingSection(bool isDark) {
    return _buildSectionCard(
      title: 'Upcoming Events',
      isDark: isDark,
      actionText: 'Calendar',
      onActionTap: () {},
      child: Column(
        children: [
          _buildEventItem('Team Meeting', '10:00 AM • Today', Icons.group, Colors.blue, isDark),
          const SizedBox(height: 12),
          _buildEventItem('Project Deadline', 'Tomorrow • 5:00 PM', Icons.event, Colors.red, isDark),
          const SizedBox(height: 12),
          _buildEventItem('Training Session', 'Wed • 2:00 PM', Icons.school, Colors.green, isDark),
        ],
      ),
    );
  }

  Widget _buildEventItem(String title, String time, IconData icon, Color color, bool isDark) {
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
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87, fontSize: 13)),
                const SizedBox(height: 2),
                Text(time, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600)),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.notifications_none, color: color, size: 18),
          ),
        ],
      ),
    );
  }

  // MARK: - Notification Panel
  Widget _buildNotificationPanel(bool isDark, NotificationProvider notificationProvider) {
    if (notificationProvider.isLoading) {
      return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
    }

    if (notificationProvider.notifications.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none, size: 50, color: isDark ? Colors.white38 : Colors.grey.shade400),
              const SizedBox(height: 8),
              Text('Tidak ada notifikasi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.white60 : Colors.grey.shade600)),
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
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_active, size: 20, color: isDark ? Colors.blue.shade300 : Colors.blue),
                  const SizedBox(width: 8),
                  Text('Notifikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                  if (notificationProvider.unreadCount > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                      child: Text(notificationProvider.unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              if (notificationProvider.unreadCount > 0)
                TextButton(
                  onPressed: () => notificationProvider.markAllAsRead(),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? Colors.blue.shade300 : Colors.blue,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Tandai semua sudah dibaca', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: notificationProvider.notifications.length > 5 ? 5 : notificationProvider.notifications.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),
            itemBuilder: (context, index) {
              final notification = notificationProvider.notifications[index];
              return _buildNotificationItem(notification, isDark);
            },
          ),
        ),
        if (notificationProvider.notifications.length > 5)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200))),
            child: Center(
              child: TextButton(
                onPressed: () {
                  // TODO: Navigasi ke halaman semua notifikasi
                },
                child: Text('Lihat semua notifikasi (${notificationProvider.notifications.length})',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.blue.shade300 : Colors.blue)),
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
              ? (isDark ? notification.color.withOpacity(0.15) : notification.color.withOpacity(0.05))
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
              child: Icon(notification.icon, color: notification.color, size: 20),
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
                      fontWeight: !notification.isRead ? FontWeight.w600 : FontWeight.normal,
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
                  if (notification.type == 'leave_request' && notification.days != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Duration: ${notification.days} ${notification.days == 1 ? 'day' : 'days'}',
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

    if (difference.inMinutes < 1) return 'Baru saja';
    if (difference.inMinutes < 60) return '${difference.inMinutes} menit yang lalu';
    if (difference.inHours < 24) return '${difference.inHours} jam yang lalu';
    if (difference.inDays < 7) return '${difference.inDays} hari yang lalu';
    return DateFormat('dd MMM yyyy').format(time);
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.grey.shade800, letterSpacing: -0.3)),
              if (actionText != null)
                TextButton(
                  onPressed: onActionTap,
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? Colors.blue.shade300 : Colors.blue,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(actionText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.blue.shade300 : Colors.blue)),
          const SizedBox(height: 16),
          Text('Loading your dashboard...', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600)),
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Oops! Something went wrong', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade800)),
            const SizedBox(height: 8),
            Text(error, style: TextStyle(color: Colors.red.shade400, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final authProvider = context.read<AuthProvider>();
                final companyCode = authProvider.getCompanyCode();
                context.read<DashboardProvider>().fetchDashboardData(companyCode: companyCode);
                context.read<NotificationProvider>().fetchNotifications(); // TAMBAHKAN REFRESH NOTIFIKASI
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // MARK: - Utility Methods
  String _getFormattedDate() {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
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
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });
}