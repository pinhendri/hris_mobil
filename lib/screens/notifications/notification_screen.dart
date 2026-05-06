import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_strings.dart';
import '../../data/models/notification_model.dart';
import '../../providers/claim_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/notification_provider.dart';
import '../claims/claims_screen.dart';
import '../leave/leave_screen.dart';
import '../overtime/overtime_screen.dart';
import '../tasks/tasks_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const Color _lightBackground = Color(0xFFF6F4F1);
  static const Color _darkBackground = Color(0xFF071B18);
  static const Color _darkSurface = Color(0xFF102824);
  static const Color _darkSurfaceMuted = Color(0xFF16322D);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? _darkBackground : _lightBackground,
      body: SafeArea(
        child: Consumer<NotificationProvider>(
          builder: (context, provider, child) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: provider.fetchNotifications,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  18,
                  12,
                  18,
                  28 + MediaQuery.of(context).padding.bottom,
                ),
                children: [
                  _buildTopBar(context, provider: provider, isDark: isDark),
                  const SizedBox(height: 18),
                  _buildSummaryCard(
                    context,
                    provider: provider,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 18),
                  if (provider.isLoading && provider.notifications.isEmpty)
                    _buildLoadingState(isDark)
                  else if (provider.notifications.isEmpty)
                    _buildEmptyState(context, isDark)
                  else
                    ...provider.notifications.map(
                      (notification) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildNotificationItem(
                          context,
                          notification,
                          provider,
                          isDark: isDark,
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

  Widget _buildTopBar(
    BuildContext context, {
    required NotificationProvider provider,
    required bool isDark,
  }) {
    final canMarkAll = provider.unreadCount > 0 && !provider.isLoading;

    return Row(
      children: [
        _buildIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          isDark: isDark,
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            context.tr('dashboard_notifications'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: _titleColor(isDark),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildIconButton(
          icon: Icons.done_all_rounded,
          isDark: isDark,
          isEnabled: canMarkAll,
          onTap: canMarkAll ? provider.markAllAsRead : null,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required NotificationProvider provider,
    required bool isDark,
  }) {
    final unreadCount = provider.unreadCount;
    final totalCount = provider.notifications.length;
    final tone = unreadCount > 0 ? const Color(0xFFFF8A3D) : AppColors.primary;
    final subtitle = unreadCount > 0
        ? context
              .tr('approval_notification_unread')
              .replaceAll('{count}', unreadCount.toString())
        : context
              .tr('approval_notification_summary')
              .replaceAll('{count}', totalCount.toString());

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF102824), Color(0xFF071B18)]
              : const [Color(0xFFFFFFFF), Color(0xFFFFF7ED)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor(isDark)),
        boxShadow: _surfaceShadows(isDark),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: isDark ? 0.20 : 0.12),
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
                  context.tr('dashboard_notifications'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: _titleColor(isDark),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: _bodyColor(isDark),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (provider.isLoading)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: tone),
            )
          else
            _buildCountPill(unreadCount, isDark: isDark, tone: tone),
        ],
      ),
    );
  }

  Widget _buildCountPill(
    int unreadCount, {
    required bool isDark,
    required Color tone,
  }) {
    final label = unreadCount > 99 ? '99+' : unreadCount.toString();

    return Container(
      constraints: const BoxConstraints(minWidth: 38),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: unreadCount > 0
            ? tone
            : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(999),
        border: unreadCount > 0
            ? null
            : Border.all(color: _borderColor(isDark)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          color: unreadCount > 0 ? Colors.white : _bodyColor(isDark),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Container(
      height: 220,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _surfaceColor(isDark),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor(isDark)),
      ),
      child: const CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
      decoration: BoxDecoration(
        color: _surfaceColor(isDark),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor(isDark)),
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 30,
              color: isDark ? Colors.white60 : AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('dashboard_no_notifications'),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: _titleColor(isDark),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Updates from approvals, broadcasts, and HR activity will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: _bodyColor(isDark),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationItem notification,
    NotificationProvider provider, {
    required bool isDark,
  }) {
    final tone = _getIconColor(notification.type);
    final surfaceColor = notification.isRead
        ? _surfaceColor(isDark)
        : (isDark ? _darkSurfaceMuted : const Color(0xFFEFF6FF));

    return Dismissible(
      key: Key(notification.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {},
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (!notification.isRead) {
              await provider.markAsRead(notification.id);
            }
            if (!context.mounted) {
              return;
            }
            _openNotificationTarget(context, notification);
          },
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: notification.isRead
                    ? _borderColor(isDark)
                    : AppColors.primary.withValues(alpha: isDark ? 0.34 : 0.22),
              ),
              boxShadow: notification.isRead ? null : _surfaceShadows(isDark),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _getIcon(notification.type),
                    color: tone,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.displayTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontWeight: notification.isRead
                                    ? FontWeight.w700
                                    : FontWeight.w800,
                                color: _titleColor(isDark),
                                fontSize: 14,
                                height: 1.25,
                              ),
                            ),
                          ),
                          if (!notification.isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 9,
                              height: 9,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.formattedMessage,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: _bodyColor(isDark),
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: _mutedColor(isDark),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _formatDate(notification.createdAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: _mutedColor(isDark),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildTypeChip(notification.type, tone, isDark),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openNotificationTarget(
    BuildContext context,
    NotificationItem notification,
  ) {
    final target = notification.targetModule;
    Widget? screen;

    switch (target) {
      case 'task':
      case 'tasks':
        screen = ChangeNotifierProvider(
          create: (_) => TaskProvider(),
          child: const TasksScreen(),
        );
        break;
      case 'leave':
      case 'cuti':
        screen = const LeaveScreen();
        break;
      case 'overtime':
      case 'lembur':
        screen = const OvertimeScreen();
        break;
      case 'claim':
      case 'claims':
      case 'expense_claim':
      case 'klaim':
        screen = ChangeNotifierProvider(
          create: (_) => ClaimProvider(),
          child: const ClaimsScreen(),
        );
        break;
    }

    if (screen == null) {
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
  }

  Widget _buildTypeChip(String type, Color tone, bool isDark) {
    final label = type.trim().isEmpty ? 'Info' : type.replaceAll('_', ' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          color: tone,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required bool isDark,
    required VoidCallback? onTap,
    bool isEnabled = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _borderColor(isDark)),
          ),
          child: Icon(
            icon,
            color: isEnabled ? _titleColor(isDark) : _mutedColor(isDark),
            size: 20,
          ),
        ),
      ),
    );
  }

  Color _surfaceColor(bool isDark) {
    return isDark ? _darkSurface : Colors.white;
  }

  Color _borderColor(bool isDark) {
    return isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFEAE7E2);
  }

  Color _titleColor(bool isDark) {
    return isDark ? Colors.white : const Color(0xFF111827);
  }

  Color _bodyColor(bool isDark) {
    return isDark ? Colors.white70 : const Color(0xFF667085);
  }

  Color _mutedColor(bool isDark) {
    return isDark
        ? Colors.white.withValues(alpha: 0.46)
        : const Color(0xFF94A3B8);
  }

  List<BoxShadow> _surfaceShadows(bool isDark) {
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.24),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ];
    }

    return const [
      BoxShadow(
        color: Color(0x17151B26),
        blurRadius: 18,
        offset: Offset(0, 10),
      ),
    ];
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'leave_request':
      case 'leave_status_update':
      case 'leave_approved':
      case 'leave_rejected':
        return Icons.event_available_outlined;
      case 'task_assigned':
      case 'task_completed':
      case 'task_status_update':
        return Icons.task_alt_rounded;
      case 'claim_request':
      case 'claim_status_update':
        return Icons.receipt_long_outlined;
      case 'overtime_request':
      case 'overtime_status_update':
        return Icons.more_time_rounded;
      case 'company_leave':
        return Icons.beach_access_outlined;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'success':
        return Icons.check_circle_outline;
      case 'announcement':
        return Icons.campaign_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'leave_request':
      case 'leave_status_update':
      case 'leave_approved':
      case 'leave_rejected':
        return const Color(0xFF22C55E);
      case 'task_assigned':
      case 'task_completed':
      case 'task_status_update':
        return const Color(0xFF4F46E5);
      case 'claim_request':
      case 'claim_status_update':
        return const Color(0xFFAA076B);
      case 'overtime_request':
      case 'overtime_status_update':
        return const Color(0xFFFF9628);
      case 'company_leave':
        return const Color(0xFF3698F5);
      case 'warning':
        return const Color(0xFFFFA726);
      case 'success':
        return const Color(0xFF22C55E);
      case 'announcement':
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes} mins ago';
    }
    if (difference.inDays == 0) {
      return '${difference.inHours} hours ago';
    }
    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    return DateFormat('MMM d, y').format(date);
  }
}
