import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_strings.dart';
import '../../models/claim_model.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/claim_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/leave_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/api_service.dart';
import '../../utils/leave_approval_utils.dart';
import '../../utils/task_approval_utils.dart';
import '../claims/claims_screen.dart';
import '../leave/leave_screen.dart';
import '../notifications/notification_screen.dart';
import '../overtime/overtime_screen.dart';
import '../tasks/tasks_screen.dart';

class ApprovalClaimsScreen extends StatelessWidget {
  const ApprovalClaimsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClaimProvider(),
      child: const ClaimsScreen(),
    );
  }
}

class ApprovalTasksScreen extends StatelessWidget {
  const ApprovalTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
      ],
      child: const TasksScreen(),
    );
  }
}

class ApprovalTab extends StatefulWidget {
  const ApprovalTab({super.key});

  @override
  State<ApprovalTab> createState() => _ApprovalTabState();
}

class _ApprovalTabState extends State<ApprovalTab> {
  static const double _maxContentWidth = 840;
  static const Color _accentColor = AppColors.primary;
  static const Color _lightBackground = Color(0xFFF6F4F1);
  static const Color _darkBackground = Color(0xFF121212);
  final ApiService _apiService = ApiService();
  int _claimApprovalCount = 0;
  int _overtimeApprovalCount = 0;
  int _taskApprovalCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshApprovalData());
    });
  }

  Future<void> _refreshApprovalData() async {
    final auth = context.read<AuthProvider>();
    final leave = context.read<LeaveProvider>();

    final companyCode = auth.getCompanyCode().trim();
    if (companyCode.isNotEmpty) {
      leave.setCompanyCode(companyCode);
    }

    await Future.wait([
      context.read<NotificationProvider>().fetchNotifications(),
      if (auth.hasAnyPermission([
        'view-leave',
        'create-leave',
        'edit-leave',
        'approve-leave',
        'reject-leave',
      ]))
        leave.fetchLeaveData(),
      if (auth.hasAnyPermission([
        'view-claims',
        'view-claims-management',
        'create-claims',
        'edit-claims',
        'approve-claims',
        'reject-claims',
      ]))
        _refreshClaimApprovalCount(auth),
      if (auth.hasAnyPermission([
        'view-overtime',
        'create-overtime',
        'edit-overtime',
        'approve-overtime',
        'reject-overtime',
      ]))
        _refreshOvertimeApprovalCount(auth),
      if (auth.hasAnyPermission(['view-tasks', 'create-tasks', 'edit-tasks']))
        _refreshTaskApprovalCount(),
    ]);
  }

  Future<void> _refreshClaimApprovalCount(AuthProvider auth) async {
    try {
      final response = await _apiService.get('/claims');
      final claims = _extractClaims(response);
      final count = pendingClaimApprovalsForUser(claims, auth.user).length;

      if (mounted && _claimApprovalCount != count) {
        setState(() => _claimApprovalCount = count);
      }
    } catch (_) {
      if (mounted && _claimApprovalCount != 0) {
        setState(() => _claimApprovalCount = 0);
      }
    }
  }

  Future<void> _refreshOvertimeApprovalCount(AuthProvider auth) async {
    try {
      final response = await _apiService.get('/overtime');
      final requests = _extractOvertimeRequests(response);
      final count = pendingOvertimeApprovalCountForUser(requests, auth.user);

      if (mounted && _overtimeApprovalCount != count) {
        setState(() => _overtimeApprovalCount = count);
      }
    } catch (_) {
      if (mounted && _overtimeApprovalCount != 0) {
        setState(() => _overtimeApprovalCount = 0);
      }
    }
  }

  Future<void> _refreshTaskApprovalCount() async {
    try {
      final response = await _apiService.get(
        ApiConstants.tasksEndpoint.replaceFirst('/api', ''),
      );
      final tasks = _extractTasks(response);
      final count = pendingAssignedTaskCountForApproval(tasks);

      if (mounted && _taskApprovalCount != count) {
        setState(() => _taskApprovalCount = count);
      }
    } catch (_) {
      if (mounted && _taskApprovalCount != 0) {
        setState(() => _taskApprovalCount = 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final leave = context.watch<LeaveProvider>();
    final notifications = context.watch<NotificationProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leaveApprovalCount = pendingLeaveApprovalsForUser(
      leave.leaveRequests,
      auth.user,
    ).length;
    final items = _buildApprovalItems(
      auth,
      leaveApprovalCount,
      _claimApprovalCount,
      _overtimeApprovalCount,
      _taskApprovalCount,
    );

    return Scaffold(
      backgroundColor: isDark ? _darkBackground : _lightBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: _accentColor,
          onRefresh: _refreshApprovalData,
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
                    _buildTopBar(context, isDark: isDark),
                    const SizedBox(height: 18),
                    _buildNotificationCard(
                      context,
                      isDark: isDark,
                      unreadCount: notifications.unreadCount,
                      totalCount: notifications.notifications.length,
                    ),
                    const SizedBox(height: 18),
                    _buildSectionTitle(
                      context.tr('approval_action_section'),
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    if (items.isEmpty)
                      _buildEmptyState(context, isDark: isDark)
                    else
                      ...items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildApprovalCard(
                            context,
                            item: item,
                            isDark: isDark,
                          ),
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

  Widget _buildConstrained(Widget child) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: child,
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, {required bool isDark}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('nav_approval'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _titleStyle(isDark, size: 22, weight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('approval_subtitle'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _bodyStyle(isDark, size: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildIconShell(Icons.fact_check_outlined, isDark),
      ],
    );
  }

  Widget _buildNotificationCard(
    BuildContext context, {
    required bool isDark,
    required int unreadCount,
    required int totalCount,
  }) {
    final tone = unreadCount > 0 ? const Color(0xFFE85D2A) : _accentColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _pushScreen(context, const NotificationScreen()),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF172033), Color(0xFF101827)]
                  : const [Color(0xFFFFF8F0), Colors.white],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _surfaceBorderColor(isDark)),
            boxShadow: _surfaceShadows(isDark),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.notifications_active_outlined, color: tone),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('approval_notification_title'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _titleStyle(isDark, size: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      unreadCount > 0
                          ? context
                                .tr('approval_notification_unread')
                                .replaceAll('{count}', unreadCount.toString())
                          : context
                                .tr('approval_notification_summary')
                                .replaceAll('{count}', totalCount.toString()),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _bodyStyle(isDark, size: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(title, style: _titleStyle(isDark, size: 18));
  }

  Widget _buildApprovalCard(
    BuildContext context, {
    required _ApprovalItem item,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _pushScreen(context, item.screen),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surfaceColor(isDark),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _surfaceBorderColor(isDark)),
            boxShadow: _surfaceShadows(isDark),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: isDark ? 0.20 : 0.11),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(item.icon, color: item.color),
                  ),
                  if (item.count > 0)
                    Positioned(
                      top: -7,
                      right: -7,
                      child: _buildCountBadge(item.count, isDark: isDark),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _titleStyle(isDark, size: 15),
                          ),
                        ),
                        const SizedBox(width: 8),
                        item.count > 0
                            ? _buildBadge(
                                '${item.count} pending',
                                color: const Color(0xFFEF4444),
                                isDark: isDark,
                              )
                            : _buildBadge(
                                item.badge,
                                color: item.color,
                                isDark: isDark,
                              ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _bodyStyle(isDark, size: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surfaceColor(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _surfaceBorderColor(isDark)),
        boxShadow: _surfaceShadows(isDark),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: isDark ? 0.20 : 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: _accentColor,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.tr('approval_empty_title'),
            textAlign: TextAlign.center,
            style: _titleStyle(isDark, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('approval_empty_message'),
            textAlign: TextAlign.center,
            style: _bodyStyle(isDark, size: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildIconShell(IconData icon, bool isDark) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _surfaceBorderColor(isDark)),
      ),
      child: Icon(icon, color: isDark ? Colors.white70 : _accentColor),
    );
  }

  Widget _buildBadge(
    String label, {
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
  }

  Widget _buildCountBadge(int count, {required bool isDark}) {
    return Container(
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }

  List<_ApprovalItem> _buildApprovalItems(
    AuthProvider auth,
    int leaveApprovalCount,
    int claimApprovalCount,
    int overtimeApprovalCount,
    int taskApprovalCount,
  ) {
    final items = <_ApprovalItem>[];

    if (auth.hasAnyPermission([
      'view-leave',
      'create-leave',
      'edit-leave',
      'approve-leave',
      'reject-leave',
    ])) {
      items.add(
        _ApprovalItem(
          title: context.tr('approval_leave_title'),
          subtitle: leaveApprovalCount > 0
              ? '$leaveApprovalCount leave request waiting for your approval'
              : context.tr('approval_leave_subtitle'),
          badge: auth.hasAnyPermission(['approve-leave', 'reject-leave'])
              ? context.tr('approval_badge_approve')
              : context.tr('approval_badge_status'),
          count: leaveApprovalCount,
          icon: Icons.event_available_outlined,
          color: const Color(0xFF2F9D78),
          screen: const LeaveScreen(),
        ),
      );
    }

    if (auth.hasAnyPermission([
      'view-claims',
      'view-claims-management',
      'create-claims',
      'edit-claims',
      'approve-claims',
      'reject-claims',
    ])) {
      items.add(
        _ApprovalItem(
          title: context.tr('approval_claims_title'),
          subtitle: claimApprovalCount > 0
              ? '$claimApprovalCount claim waiting for your approval'
              : context.tr('approval_claims_subtitle'),
          badge: auth.hasAnyPermission(['approve-claims', 'reject-claims'])
              ? context.tr('approval_badge_approve')
              : context.tr('approval_badge_status'),
          count: claimApprovalCount,
          icon: Icons.account_balance_wallet_outlined,
          color: const Color(0xFF3478F6),
          screen: const ApprovalClaimsScreen(),
        ),
      );
    }

    if (auth.hasAnyPermission([
      'view-overtime',
      'create-overtime',
      'edit-overtime',
      'approve-overtime',
      'reject-overtime',
    ])) {
      items.add(
        _ApprovalItem(
          title: context.tr('approval_overtime_title'),
          subtitle: overtimeApprovalCount > 0
              ? '$overtimeApprovalCount overtime request waiting for your approval'
              : context.tr('approval_overtime_subtitle'),
          badge: auth.hasAnyPermission(['approve-overtime', 'reject-overtime'])
              ? context.tr('approval_badge_approve')
              : context.tr('approval_badge_status'),
          count: overtimeApprovalCount,
          icon: Icons.schedule_outlined,
          color: const Color(0xFF7C3AED),
          screen: const OvertimeScreen(),
        ),
      );
    }

    if (auth.hasAnyPermission(['view-tasks', 'create-tasks', 'edit-tasks'])) {
      items.add(
        _ApprovalItem(
          title: context.tr('approval_tasks_title'),
          subtitle: taskApprovalCount > 0
              ? '$taskApprovalCount task assigned to you'
              : context.tr('approval_tasks_subtitle'),
          badge: context.tr('approval_badge_status'),
          count: taskApprovalCount,
          icon: Icons.task_alt_outlined,
          color: const Color(0xFFD5534F),
          screen: const ApprovalTasksScreen(),
        ),
      );
    }

    return items;
  }

  void _pushScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  List<ClaimModel> _extractClaims(dynamic response) {
    if (response is! Map<String, dynamic>) {
      return const [];
    }

    final data = response['data'];
    final rawClaims = data is Map<String, dynamic>
        ? data['claims']
        : response['claims'];
    if (rawClaims is! List) {
      return const [];
    }

    return rawClaims
        .whereType<Map>()
        .map((item) => ClaimModel.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _extractOvertimeRequests(dynamic response) {
    if (response is! Map<String, dynamic>) {
      return const [];
    }

    final data = response['data'];
    final rawRequests = data is Map<String, dynamic>
        ? data['requests']
        : response['requests'];
    if (rawRequests is! List) {
      return const [];
    }

    return rawRequests
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  List<TaskModel> _extractTasks(dynamic response) {
    if (response is! Map<String, dynamic>) {
      return const [];
    }

    final data = response['data'];
    final rawTasks = data is List
        ? data
        : data is Map<String, dynamic>
        ? data['tasks']
        : response['tasks'];

    if (rawTasks is! List) {
      return const [];
    }

    return rawTasks
        .whereType<Map>()
        .map((item) => TaskModel.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
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
  }) {
    return TextStyle(
      color: isDark ? Colors.white : const Color(0xFF1F2937),
      fontSize: size,
      fontWeight: weight,
      height: 1.2,
    );
  }

  TextStyle _bodyStyle(
    bool isDark, {
    double size = 13,
    FontWeight weight = FontWeight.w500,
  }) {
    return TextStyle(
      color: isDark ? Colors.white60 : const Color(0xFF6B7280),
      fontSize: size,
      fontWeight: weight,
      height: 1.4,
    );
  }
}

class _ApprovalItem {
  const _ApprovalItem({
    required this.title,
    required this.subtitle,
    required this.badge,
    this.count = 0,
    required this.icon,
    required this.color,
    required this.screen,
  });

  final String title;
  final String subtitle;
  final String badge;
  final int count;
  final IconData icon;
  final Color color;
  final Widget screen;
}
