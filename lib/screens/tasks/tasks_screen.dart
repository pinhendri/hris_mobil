import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_strings.dart';
import '../../models/employee_model.dart';
import '../../models/task_model.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/task_provider.dart';
import '../../utils/task_visibility_utils.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _scopeFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final employeeProvider = context.read<EmployeeProvider>();
      if (employeeProvider.employees.isEmpty && !employeeProvider.isLoading) {
        employeeProvider.fetchAllEmployees();
      }
    });
  }

  Future<bool> _confirmToggleStatus(
    BuildContext context,
    TaskModel task,
  ) async {
    final isCompleting = !task.isCompleted;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: !isCompleting,
      builder: (dialogContext) =>
          _TaskStatusConfirmDialog(task: task, isCompleting: isCompleting),
    );

    return confirmed == true;
  }

  void _openTaskForm(BuildContext context, {TaskModel? task}) {
    final provider = context.read<TaskProvider>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider<TaskProvider>.value(
        value: provider,
        child: _TaskFormSheet(task: task),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TaskProvider provider,
    TaskModel task,
  ) async {
    if (provider.isDeleting(task.id)) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('task_delete_title')),
        content: Text(
          context.tr('task_delete_message').replaceAll('{title}', task.title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('task_action_cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.tr('task_action_delete')),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final success = await provider.deleteTask(task.id);
    if (!context.mounted) {
      return;
    }

    final message = success
        ? context.tr('task_delete_success')
        : (provider.error ?? context.tr('task_delete_failed'));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF101214)
            : const Color(0xFFF6F8FC),
        appBar: AppBar(
          title: Text(
            context.tr('task_page_title'),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              onPressed: () => context.read<TaskProvider>().refresh(),
              icon: const Icon(Icons.refresh),
              tooltip: context.tr('task_action_refresh'),
            ),
          ],
          bottom: TabBar(
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.poppins(),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: context.tr('task_status_pending')),
              Tab(text: context.tr('task_status_completed')),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openTaskForm(context),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: Text(context.tr('task_action_add')),
        ),
        body: Consumer<TaskProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.tasks.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final currentUser = context.read<AuthProvider>().user;
            final employeeProvider = context.watch<EmployeeProvider>();
            final subordinateAssigneeIds = employeeProvider.employees.isEmpty
                ? null
                : _subordinateAssigneeIds(
                    employeeProvider.employees,
                    currentUser,
                  );
            final visibleTasks = _filterTasksByScope(
              provider.tasks,
              currentUser,
              subordinateAssigneeIds,
            );
            final pendingTasks = visibleTasks
                .where((task) => !task.isCompleted)
                .toList();
            final completedTasks = visibleTasks
                .where((task) => task.isCompleted)
                .toList();

            return Column(
              children: [
                _buildOverview(
                  context,
                  provider.tasks,
                  currentUser,
                  subordinateAssigneeIds,
                ),
                _buildScopeFilter(
                  context,
                  provider.tasks,
                  currentUser,
                  subordinateAssigneeIds,
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildTaskList(context, provider, pendingTasks),
                      _buildTaskList(context, provider, completedTasks),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<TaskModel> _filterTasksByScope(
    List<TaskModel> tasks,
    User? user,
    Set<String>? subordinateAssigneeIds,
  ) {
    if (_scopeFilter == 'self') {
      return tasks.where((task) => taskBelongsToSelfView(task, user)).toList();
    }
    if (_scopeFilter == 'subordinate') {
      return tasks
          .where(
            (task) => taskBelongsToSubordinateView(
              task,
              user,
              subordinateAssigneeIds: subordinateAssigneeIds,
            ),
          )
          .toList();
    }
    return tasksForMyTaskCards(
      tasks,
      user,
      subordinateAssigneeIds: subordinateAssigneeIds,
    );
  }

  Widget _buildOverview(
    BuildContext context,
    List<TaskModel> tasks,
    User? user,
    Set<String>? subordinateAssigneeIds,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF151B23) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF293241)
        : const Color(0xFFE2E8F0);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF64748B);
    final visibleTasks = tasksForMyTaskCards(
      tasks,
      user,
      subordinateAssigneeIds: subordinateAssigneeIds,
    );
    final pending = visibleTasks.where((task) => !task.isCompleted).length;
    final subordinate = tasks
        .where(
          (task) => taskBelongsToSubordinateView(
            task,
            user,
            subordinateAssigneeIds: subordinateAssigneeIds,
          ),
        )
        .length;
    final overdue = visibleTasks.where((task) {
      return task.dueDate != null &&
          task.dueDate!.isBefore(DateTime.now()) &&
          !task.isCompleted;
    }).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('task_page_title'),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('task_page_subtitle'),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _TaskMetric(
                label: context.tr('task_status_pending'),
                value: pending.toString(),
                color: const Color(0xFF2563EB),
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _TaskMetric(
                label: context.tr('task_metric_subordinate'),
                value: subordinate.toString(),
                color: const Color(0xFF7C3AED),
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _TaskMetric(
                label: context.tr('task_metric_overdue'),
                value: overdue.toString(),
                color: const Color(0xFFEF4444),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScopeFilter(
    BuildContext context,
    List<TaskModel> tasks,
    User? user,
    Set<String>? subordinateAssigneeIds,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final labels = <String, String>{
      'all': context.tr('task_filter_all'),
      'self': context.tr('task_filter_mine'),
      'subordinate': context.tr('task_filter_subordinate'),
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: labels.entries.map((entry) {
          final selected = _scopeFilter == entry.key;
          final count = _filterCount(
            tasks,
            entry.key,
            user,
            subordinateAssigneeIds,
          );
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              label: Text('${entry.value} ($count)'),
              labelStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : (isDark
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF475569)),
              ),
              selectedColor: AppColors.primary,
              backgroundColor: isDark ? const Color(0xFF1B1F24) : Colors.white,
              side: BorderSide(
                color: selected ? AppColors.primary : borderColor,
              ),
              onSelected: (_) {
                setState(() {
                  _scopeFilter = entry.key;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  int _filterCount(
    List<TaskModel> tasks,
    String scope,
    User? user,
    Set<String>? subordinateAssigneeIds,
  ) {
    if (scope == 'self') {
      return tasks.where((task) => taskBelongsToSelfView(task, user)).length;
    }
    if (scope == 'subordinate') {
      return tasks
          .where(
            (task) => taskBelongsToSubordinateView(
              task,
              user,
              subordinateAssigneeIds: subordinateAssigneeIds,
            ),
          )
          .length;
    }
    return tasksForMyTaskCards(
      tasks,
      user,
      subordinateAssigneeIds: subordinateAssigneeIds,
    ).length;
  }

  Set<String> _subordinateAssigneeIds(List<Employee> employees, User? user) {
    if (user == null) {
      return const {};
    }

    final subordinates = EmployeeProvider.filterSubordinateTree(
      employees: employees,
      managerEmployeeId: user.employeeId,
    );

    return normalizeTaskIdentityValues(
      subordinates.expand((employee) => [employee.uuid, employee.id]),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    TaskProvider provider,
    List<TaskModel> tasks,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF111827);
    final secondaryTextColor = isDark
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF64748B);

    if (provider.error != null && provider.tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: secondaryTextColor),
              const SizedBox(height: 16),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => provider.refresh(),
                child: Text(context.tr('task_action_retry')),
              ),
            ],
          ),
        ),
      );
    }

    if (tasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: secondaryTextColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('task_empty_title'),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: primaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return _buildTaskCard(context, provider, task);
        },
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    TaskProvider provider,
    TaskModel task,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBusy = provider.isUpdating(task.id) || provider.isDeleting(task.id);
    final isOverdue =
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !task.isCompleted;
    final cardColor = isDark ? const Color(0xFF1B1F24) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF2F3844)
        : const Color(0xFFE2E8F0);
    final primaryTextColor = isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF1F2937);
    final secondaryTextColor = isDark
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF6B7280);
    final mutedTextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF6B7280);
    final chipColor = isDark
        ? const Color(0xFF27303B)
        : const Color(0xFFF3F4F6);
    final checkboxBorderColor = isDark
        ? const Color(0xFF93C5FD)
        : AppColors.primary;
    final currentUser = context.read<AuthProvider>().user;
    final employeeProvider = context.watch<EmployeeProvider>();
    final subordinateAssigneeIds = employeeProvider.employees.isEmpty
        ? null
        : _subordinateAssigneeIds(employeeProvider.employees, currentUser);
    final isSubordinateForCurrentUser = taskBelongsToSubordinateView(
      task,
      currentUser,
      subordinateAssigneeIds: subordinateAssigneeIds,
    );

    Color priorityColor;
    switch (task.priority) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      default:
        priorityColor = Colors.green;
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: provider.isDeleting(task.id) ? 0.5 : 1,
      child: IgnorePointer(
        ignoring: provider.isDeleting(task.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: task.isCompleted,
                        activeColor: AppColors.primary,
                        checkColor: Colors.white,
                        side: BorderSide(
                          color: checkboxBorderColor,
                          width: 1.8,
                        ),
                        fillColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.primary;
                          }
                          if (states.contains(WidgetState.disabled)) {
                            return isDark
                                ? const Color(0xFF27303B)
                                : const Color(0xFFF1F5F9);
                          }
                          return Colors.transparent;
                        }),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: isBusy || !task.canToggle
                            ? null
                            : (value) async {
                                final confirmed = await _confirmToggleStatus(
                                  context,
                                  task,
                                );
                                if (!confirmed || !context.mounted) {
                                  return;
                                }

                                final success = await provider.toggleTaskStatus(
                                  task.id,
                                );
                                if (!context.mounted) {
                                  return;
                                }

                                final message = success
                                    ? (task.isCompleted
                                          ? context.tr('task_status_to_pending')
                                          : context.tr(
                                              'task_status_to_completed',
                                            ))
                                    : (provider.error ??
                                          context.tr(
                                            'task_status_update_failed',
                                          ));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(message)),
                                );
                              },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: primaryTextColor,
                                    decoration: task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: secondaryTextColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: priorityColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _taskPriorityLabel(context, task.priority),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: priorityColor,
                                  ),
                                ),
                              ),
                              if (task.canEdit || task.canDelete) ...[
                                const SizedBox(width: 4),
                                PopupMenuButton<String>(
                                  tooltip: context.tr('task_actions_tooltip'),
                                  color: isDark
                                      ? const Color(0xFF1F2937)
                                      : Colors.white,
                                  iconColor: secondaryTextColor,
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _openTaskForm(context, task: task);
                                      return;
                                    }

                                    if (value == 'delete') {
                                      _confirmDelete(context, provider, task);
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    if (task.canEdit)
                                      PopupMenuItem<String>(
                                        value: 'edit',
                                        child: Text(
                                          context.tr('task_action_edit'),
                                        ),
                                      ),
                                    if (task.canDelete)
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Text(
                                          context.tr('task_action_delete'),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          if (task.description.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              task.description,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: isOverdue
                                ? Colors.red.shade400
                                : mutedTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.dueDate != null
                                ? '${context.tr('task_due_prefix')}: ${_formatTaskDate(task.dueDate!, pattern: 'MMM dd, yyyy')}'
                                : context.tr('task_no_due_date'),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isOverdue ? Colors.red : mutedTextColor,
                              fontWeight: isOverdue
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: chipColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          _taskTypeLabel(context, task.type),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSubordinateForCurrentUser
                              ? const Color(0xFF7C3AED).withValues(alpha: 0.10)
                              : AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSubordinateForCurrentUser
                                ? const Color(
                                    0xFF7C3AED,
                                  ).withValues(alpha: 0.24)
                                : AppColors.primary.withValues(alpha: 0.24),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSubordinateForCurrentUser
                                  ? Icons.groups_rounded
                                  : Icons.person_rounded,
                              size: 12,
                              color: isSubordinateForCurrentUser
                                  ? const Color(0xFF7C3AED)
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isSubordinateForCurrentUser
                                  ? context.tr('task_filter_subordinate')
                                  : context.tr('task_filter_mine'),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isSubordinateForCurrentUser
                                    ? const Color(0xFF7C3AED)
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if ((task.assigneeName ?? '').isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_circle_outlined,
                              size: 14,
                              color: mutedTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task.assigneeName!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: mutedTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      if (isBusy)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
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
}

String _taskPriorityLabel(BuildContext context, String priority) {
  switch (priority) {
    case 'high':
      return context.tr('task_priority_high');
    case 'low':
      return context.tr('task_priority_low');
    default:
      return context.tr('task_priority_medium');
  }
}

String _taskTypeLabel(BuildContext context, String type) {
  switch (type) {
    case 'onboarding':
      return context.tr('task_type_onboarding');
    case 'offboarding':
      return context.tr('task_type_offboarding');
    default:
      return context.tr('task_type_regular');
  }
}

String _formatTaskDate(DateTime date, {required String pattern}) {
  return DateFormat(pattern).format(date);
}

class _TaskMetric extends StatelessWidget {
  const _TaskMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskStatusConfirmDialog extends StatelessWidget {
  const _TaskStatusConfirmDialog({
    required this.task,
    required this.isCompleting,
  });

  final TaskModel task;
  final bool isCompleting;

  bool get _isHighPriority => task.priority == 'high';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF111827) : Colors.white;
    final mutedSurfaceColor = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF253041)
        : const Color(0xFFE2E8F0);
    final primaryTextColor = isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF0F172A);
    final secondaryTextColor = isDark
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF64748B);
    final accentColor = isCompleting
        ? const Color(0xFF2563EB)
        : const Color(0xFFF59E0B);
    final buttonLabel = isCompleting
        ? context.tr('task_toggle_complete_button')
        : context.tr('task_toggle_pending_button');
    final title = isCompleting
        ? context.tr('task_toggle_complete_title')
        : context.tr('task_toggle_pending_title');
    final subtitle = isCompleting
        ? context.tr('task_toggle_complete_subtitle')
        : context.tr('task_toggle_pending_subtitle');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor),
          boxShadow: isDark
              ? const []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor,
                        accentColor.withValues(alpha: 0.78),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    isCompleting
                        ? Icons.task_alt_rounded
                        : Icons.restart_alt_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          height: 1.5,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: mutedSurfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: primaryTextColor,
                    ),
                  ),
                  if (task.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      task.description.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        height: 1.45,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TaskDialogChip(
                        icon: Icons.flag_rounded,
                        label: _taskPriorityLabel(context, task.priority),
                        color: _priorityColor(task.priority),
                        isDark: isDark,
                      ),
                      _TaskDialogChip(
                        icon: Icons.category_rounded,
                        label: _taskTypeLabel(context, task.type),
                        color: const Color(0xFF8B5CF6),
                        isDark: isDark,
                      ),
                      if (task.dueDate != null)
                        _TaskDialogChip(
                          icon: Icons.event_rounded,
                          label: DateFormat(
                            'dd MMM yyyy',
                          ).format(task.dueDate!),
                          color: _isHighPriority
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF0EA5E9),
                          isDark: isDark,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: secondaryTextColor,
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      isCompleting
                          ? context.tr('task_toggle_cancel_complete')
                          : context.tr('task_action_cancel'),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      buttonLabel,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'low':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFFF59E0B);
    }
  }
}

class _TaskDialogChip extends StatelessWidget {
  const _TaskDialogChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isDark ? Colors.white : color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskFormSheet extends StatefulWidget {
  const _TaskFormSheet({this.task});

  final TaskModel? task;

  @override
  State<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<_TaskFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _priority;
  late String _type;
  late String _assignmentScope;
  String? _selectedAssigneeEmployeeId;
  DateTime? _dueDate;
  bool _isSubmitting = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _priority = widget.task?.priority ?? 'medium';
    _type = widget.task?.type ?? 'regular';
    _assignmentScope = widget.task?.assignmentScope ?? 'self';
    _selectedAssigneeEmployeeId = widget.task?.assigneeEmployeeId;
    _dueDate = widget.task?.dueDate;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final employeeProvider = context.read<EmployeeProvider>();
      if (employeeProvider.employees.isEmpty && !employeeProvider.isLoading) {
        employeeProvider.fetchAllEmployees();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
      builder: (context, child) {
        final baseTheme = Theme.of(context);
        return Theme(
          data: baseTheme.copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: Color(0xFF1B1F24),
                    onSurface: Color(0xFFF8FAFC),
                  )
                : const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF111827),
                  ),
            dialogTheme: DialogThemeData(
              backgroundColor: isDark ? const Color(0xFF1B1F24) : Colors.white,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _dueDate = DateTime(picked.year, picked.month, picked.day, 9);
    });
  }

  Future<void> _submit() async {
    final provider = context.read<TaskProvider>();
    final title = _titleController.text.trim();
    final selectedAssignee = _selectedAssignee();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('task_title_required'))),
      );
      return;
    }

    if (_assignmentScope == 'subordinate' && selectedAssignee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('task_assignee_required'))),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    provider.clearError();

    final success = _isEditing
        ? await provider.updateTask(
            id: widget.task!.id,
            title: title,
            description: _descriptionController.text,
            dueDate: _dueDate,
            priority: _priority,
            type: _type,
            assigneeEmployeeId: _assignmentScope == 'subordinate'
                ? _employeeValue(selectedAssignee!)
                : null,
            assigneeName: _assignmentScope == 'subordinate'
                ? selectedAssignee!.name
                : null,
            assigneeEmployeeRecordId: _assignmentScope == 'subordinate'
                ? selectedAssignee!.id
                : null,
            assignmentScope: _assignmentScope,
          )
        : await provider.createTask(
            title: title,
            description: _descriptionController.text,
            dueDate: _dueDate,
            priority: _priority,
            type: _type,
            assigneeEmployeeId: _assignmentScope == 'subordinate'
                ? _employeeValue(selectedAssignee!)
                : null,
            assigneeName: _assignmentScope == 'subordinate'
                ? selectedAssignee!.name
                : null,
            assigneeEmployeeRecordId: _assignmentScope == 'subordinate'
                ? selectedAssignee!.id
                : null,
            assignmentScope: _assignmentScope,
          );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? context.tr('task_save_failed')),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing
              ? context.tr('task_update_success')
              : context.tr('task_create_success'),
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  InputDecoration _inputDecoration({
    required bool isDark,
    required Color fieldColor,
    required Color borderColor,
  }) {
    final labelColor = isDark
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF475569);

    return InputDecoration(
      filled: true,
      fillColor: fieldColor,
      labelStyle: GoogleFonts.poppins(
        color: labelColor,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: GoogleFonts.poppins(
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF9CA3AF),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor.withValues(alpha: 0.55)),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
    );
  }

  Widget _buildAssignmentSection({
    required bool isDark,
    required Color fieldColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required InputDecoration inputDecoration,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fieldColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('task_assignment_for'),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                selected: _assignmentScope == 'self',
                label: Text(context.tr('task_assignment_self')),
                avatar: Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: _assignmentScope == 'self'
                      ? Colors.white
                      : AppColors.primary,
                ),
                selectedColor: AppColors.primary,
                backgroundColor: isDark
                    ? const Color(0xFF111827)
                    : Colors.white,
                labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: _assignmentScope == 'self'
                      ? Colors.white
                      : secondaryTextColor,
                ),
                side: BorderSide(color: borderColor),
                onSelected: _isSubmitting
                    ? null
                    : (_) {
                        setState(() {
                          _assignmentScope = 'self';
                          _selectedAssigneeEmployeeId = null;
                        });
                      },
              ),
              ChoiceChip(
                selected: _assignmentScope == 'subordinate',
                label: Text(context.tr('task_filter_subordinate')),
                avatar: Icon(
                  Icons.groups_rounded,
                  size: 18,
                  color: _assignmentScope == 'subordinate'
                      ? Colors.white
                      : const Color(0xFF7C3AED),
                ),
                selectedColor: const Color(0xFF7C3AED),
                backgroundColor: isDark
                    ? const Color(0xFF111827)
                    : Colors.white,
                labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: _assignmentScope == 'subordinate'
                      ? Colors.white
                      : secondaryTextColor,
                ),
                side: BorderSide(color: borderColor),
                onSelected: _isSubmitting
                    ? null
                    : (_) {
                        setState(() {
                          _assignmentScope = 'subordinate';
                        });
                      },
              ),
            ],
          ),
          if (_assignmentScope == 'subordinate') ...[
            const SizedBox(height: 14),
            Consumer<EmployeeProvider>(
              builder: (context, employeeProvider, _) {
                final authProvider = context.read<AuthProvider>();
                final currentEmployeeId = authProvider.user?.employeeId ?? '';
                final employees = EmployeeProvider.filterSubordinateTree(
                  employees: employeeProvider.employees,
                  managerEmployeeId: currentEmployeeId,
                );
                final values = employees.map(_employeeValue).toSet();
                final selectedValue =
                    values.contains(_selectedAssigneeEmployeeId)
                    ? _selectedAssigneeEmployeeId
                    : null;

                if (employeeProvider.isLoading && employees.isEmpty) {
                  return Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        context.tr('task_assignee_loading'),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  );
                }

                if (employees.isEmpty) {
                  return OutlinedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => employeeProvider.fetchAllEmployees(),
                    icon: const Icon(Icons.account_tree_outlined),
                    label: Text(context.tr('task_assignee_empty')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: borderColor),
                    ),
                  );
                }

                return DropdownButtonFormField<String>(
                  initialValue: selectedValue,
                  dropdownColor: isDark
                      ? const Color(0xFF1B1F24)
                      : Colors.white,
                  style: GoogleFonts.poppins(color: primaryTextColor),
                  iconEnabledColor: secondaryTextColor,
                  decoration: inputDecoration.copyWith(
                    labelText: context.tr('task_assignee_label'),
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  items: employees.map((employee) {
                    return DropdownMenuItem<String>(
                      value: _employeeValue(employee),
                      child: Text(
                        employee.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            _selectedAssigneeEmployeeId = value;
                          });
                        },
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('task_assignee_note'),
              style: GoogleFonts.poppins(
                fontSize: 11,
                height: 1.4,
                color: secondaryTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _employeeValue(Employee employee) {
    return employee.uuid.isNotEmpty ? employee.uuid : employee.id;
  }

  Employee? _selectedAssignee() {
    final selectedValue = _selectedAssigneeEmployeeId?.trim();
    if (selectedValue == null || selectedValue.isEmpty) {
      return null;
    }

    final authProvider = context.read<AuthProvider>();
    final employeeProvider = context.read<EmployeeProvider>();
    final currentEmployeeId = authProvider.user?.employeeId ?? '';
    final subordinates = EmployeeProvider.filterSubordinateTree(
      employees: employeeProvider.employees,
      managerEmployeeId: currentEmployeeId,
    );

    for (final employee in subordinates) {
      if (_employeeValue(employee) == selectedValue ||
          employee.id == selectedValue) {
        return employee;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1B1F24) : Colors.white;
    final fieldColor = isDark
        ? const Color(0xFF111827)
        : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFD1D5DB);
    final primaryTextColor = isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF1F2937);
    final secondaryTextColor = isDark
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF4B5563);
    final mutedTextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF6B7280);
    final inputDecoration = _inputDecoration(
      isDark: isDark,
      fieldColor: fieldColor,
      borderColor: borderColor,
    );

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF475569)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isEditing
                    ? context.tr('task_form_edit_title')
                    : context.tr('task_form_create_title'),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                style: GoogleFonts.poppins(color: primaryTextColor),
                cursorColor: AppColors.primary,
                decoration: inputDecoration.copyWith(
                  labelText: context.tr('task_title_label'),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                style: GoogleFonts.poppins(color: primaryTextColor),
                cursorColor: AppColors.primary,
                decoration: inputDecoration.copyWith(
                  labelText: context.tr('task_description_label'),
                ),
              ),
              const SizedBox(height: 16),
              _buildAssignmentSection(
                isDark: isDark,
                fieldColor: fieldColor,
                borderColor: borderColor,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                inputDecoration: inputDecoration,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _priority,
                      dropdownColor: surfaceColor,
                      style: GoogleFonts.poppins(color: primaryTextColor),
                      iconEnabledColor: secondaryTextColor,
                      decoration: inputDecoration.copyWith(
                        labelText: context.tr('task_priority_label'),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'high',
                          child: Text(context.tr('task_priority_high')),
                        ),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Text(context.tr('task_priority_medium')),
                        ),
                        DropdownMenuItem(
                          value: 'low',
                          child: Text(context.tr('task_priority_low')),
                        ),
                      ],
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              if (value == null) {
                                return;
                              }

                              setState(() {
                                _priority = value;
                              });
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _type,
                      dropdownColor: surfaceColor,
                      style: GoogleFonts.poppins(color: primaryTextColor),
                      iconEnabledColor: secondaryTextColor,
                      decoration: inputDecoration.copyWith(
                        labelText: context.tr('task_type_label'),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'regular',
                          child: Text(context.tr('task_type_regular')),
                        ),
                        DropdownMenuItem(
                          value: 'onboarding',
                          child: Text(context.tr('task_type_onboarding')),
                        ),
                        DropdownMenuItem(
                          value: 'offboarding',
                          child: Text(context.tr('task_type_offboarding')),
                        ),
                      ],
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              if (value == null) {
                                return;
                              }

                              setState(() {
                                _type = value;
                              });
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: fieldColor,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('task_due_date_label'),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _dueDate != null
                          ? _formatTaskDate(
                              _dueDate!,
                              pattern: 'EEEE, dd MMM yyyy',
                            )
                          : context.tr('task_due_not_set'),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: mutedTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isSubmitting ? null : _pickDueDate,
                          icon: const Icon(Icons.date_range),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark
                                ? const Color(0xFF93C5FD)
                                : AppColors.primary,
                            side: BorderSide(color: borderColor),
                          ),
                          label: Text(
                            _dueDate == null
                                ? context.tr('task_due_pick_date')
                                : context.tr('task_due_change_date'),
                          ),
                        ),
                        if (_dueDate != null)
                          TextButton(
                            onPressed: _isSubmitting
                                ? null
                                : () {
                                    setState(() {
                                      _dueDate = null;
                                    });
                                  },
                            style: TextButton.styleFrom(
                              foregroundColor: isDark
                                  ? const Color(0xFFFCA5A5)
                                  : Colors.red.shade600,
                            ),
                            child: Text(context.tr('task_due_clear')),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: secondaryTextColor,
                        side: BorderSide(color: borderColor),
                      ),
                      child: Text(context.tr('task_action_cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isEditing
                                  ? context.tr('task_action_save')
                                  : context.tr('task_action_create'),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
