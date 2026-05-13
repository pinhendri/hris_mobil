import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/access_denied_state.dart';
import '../../models/broadcast_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/broadcast_provider.dart';
import '../../providers/event_provider.dart';
import 'admin_palette.dart';

enum _BroadcastRecipientType { all, department, custom }

extension on _BroadcastRecipientType {
  String get apiValue {
    switch (this) {
      case _BroadcastRecipientType.department:
        return 'department';
      case _BroadcastRecipientType.custom:
        return 'custom';
      case _BroadcastRecipientType.all:
        return 'all';
    }
  }
}

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _eventLocationController =
      TextEditingController();
  late final TabController _tabController;

  _BroadcastRecipientType _recipientType = _BroadcastRecipientType.all;
  List<int> _selectedDepartmentIds = const [];
  List<int> _selectedEmployeeIds = const [];
  String _priority = 'medium';
  bool _isCalendarEvent = false;
  DateTime? _eventStartsAt;
  DateTime? _eventEndsAt;

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  Color get _screenBackgroundColor => AdminPalette.page(context);

  Color get _surfaceColor => AdminPalette.surface(context);

  Color get _surfaceMutedColor => AdminPalette.mutedSurface(context);

  Color get _surfaceBorderColor => AdminPalette.border(context);

  Color get _primaryTextColor => AdminPalette.text(context);

  Color get _secondaryTextColor => AdminPalette.mutedText(context);

  Color get _mutedTextColor =>
      _isDarkMode ? const Color(0xFF94A3B8) : AppColors.textMuted;

  List<BoxShadow> get _cardShadow => _isDarkMode
      ? const []
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ];

  BoxDecoration _surfaceDecoration({
    Color? color,
    bool highlightBorder = false,
  }) {
    return BoxDecoration(
      color: color ?? _surfaceColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: highlightBorder ? AppColors.primary : _surfaceBorderColor,
      ),
      boxShadow: _cardShadow,
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? prefixIcon,
    String? helperText,
  }) {
    return InputDecoration(
      hintText: hint,
      helperText: helperText,
      hintStyle: TextStyle(color: _mutedTextColor),
      helperStyle: TextStyle(color: _mutedTextColor),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: _secondaryTextColor, size: 20),
      filled: true,
      fillColor: _surfaceMutedColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _surfaceBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 1.2),
      ),
    );
  }

  String _tr(String key) => context.tr(key);

  String _trf(String key, Map<String, String> values) {
    var text = context.tr(key);
    for (final entry in values.entries) {
      text = text.replaceAll('{${entry.key}}', entry.value);
    }
    return text;
  }

  String _count(String key, int count) {
    return _trf(key, {'count': count.toString()});
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final companyCode = context.read<AuthProvider>().getCompanyCode();
      if (companyCode.isNotEmpty) {
        context.read<BroadcastProvider>().initialize();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    _eventLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final broadcastProvider = context.watch<BroadcastProvider>();
    final companyCode = authProvider.getCompanyCode();

    if (!authProvider.canAccessBroadcastModule) {
      return Scaffold(
        backgroundColor: _screenBackgroundColor,
        appBar: _buildAppBar(showTabs: false),
        body: const AccessDeniedState(permissionLabel: 'view-broadcast'),
      );
    }

    final showCompanyRequired =
        companyCode.isEmpty || broadcastProvider.companyRequired;
    final showInitialLoading =
        broadcastProvider.isLoading &&
        broadcastProvider.departments.isEmpty &&
        broadcastProvider.employees.isEmpty &&
        broadcastProvider.history.isEmpty;

    return Scaffold(
      backgroundColor: _screenBackgroundColor,
      appBar: _buildAppBar(showTabs: !showCompanyRequired),
      body: showCompanyRequired
          ? _buildCompanyRequiredState()
          : showInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildComposeTab(broadcastProvider, companyCode),
                _buildHistoryTab(broadcastProvider),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar({required bool showTabs}) {
    return AppBar(
      title: Text(
        _tr('broadcast_page_title'),
        style: TextStyle(color: _primaryTextColor, fontWeight: FontWeight.w700),
      ),
      backgroundColor: _surfaceColor,
      surfaceTintColor: _surfaceColor,
      iconTheme: IconThemeData(color: _primaryTextColor),
      elevation: 0,
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () {
            context.read<BroadcastProvider>().initialize(showLoading: false);
          },
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      bottom: showTabs
          ? TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: _secondaryTextColor,
              tabs: [
                Tab(text: _tr('broadcast_compose_tab')),
                Tab(text: _tr('broadcast_history_tab')),
              ],
            )
          : null,
    );
  }

  Widget _buildCompanyRequiredState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: _surfaceDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: AppColors.warning,
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _tr('broadcast_company_required_title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _primaryTextColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _tr('broadcast_company_required_message'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _secondaryTextColor,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComposeTab(BroadcastProvider provider, String companyCode) {
    final selectedDepartments = provider.departments
        .where((department) => _selectedDepartmentIds.contains(department.id))
        .toList(growable: false);
    final selectedEmployees = provider.employees
        .where((employee) => _selectedEmployeeIds.contains(employee.id))
        .toList(growable: false);
    final recipientCount = _getRecipientCount(provider);

    return RefreshIndicator(
      onRefresh: () => provider.initialize(showLoading: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildHeroCard(
            title: _tr('broadcast_message_title'),
            subtitle: _tr('broadcast_message_subtitle'),
            badgeLabel: companyCode.isEmpty
                ? null
                : _trf('broadcast_company_badge', {'code': companyCode}),
            metricLabels: [
              provider.employeeDirectoryRestricted
                  ? _tr('broadcast_employee_restricted')
                  : _count(
                      'broadcast_employee_count',
                      provider.employees.length,
                    ),
              provider.departmentDirectoryRestricted
                  ? _tr('broadcast_department_restricted')
                  : _count(
                      'broadcast_department_count',
                      provider.departments.length,
                    ),
              provider.historyRestricted
                  ? _tr('broadcast_history_restricted')
                  : _count('broadcast_history_count', provider.history.length),
            ],
          ),
          if (provider.error != null) ...[
            const SizedBox(height: 16),
            _buildBanner(
              color: AppColors.error,
              icon: Icons.error_outline_rounded,
              message: provider.error!,
            ),
          ],
          if (provider.employeeDirectoryRestricted ||
              provider.departmentDirectoryRestricted) ...[
            const SizedBox(height: 16),
            _buildBanner(
              color: AppColors.warning,
              icon: Icons.lock_outline_rounded,
              message: _tr('broadcast_recipients_restricted'),
            ),
          ],
          const SizedBox(height: 16),
          _buildSurfaceSection(
            title: _tr('broadcast_compose_title'),
            subtitle: _tr('broadcast_compose_subtitle'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  style: TextStyle(color: _primaryTextColor),
                  decoration: _inputDecoration(
                    hint: _tr('broadcast_title_hint'),
                    prefixIcon: Icons.title_rounded,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _messageController,
                  maxLines: 7,
                  style: TextStyle(color: _primaryTextColor),
                  decoration: _inputDecoration(
                    hint: _tr('broadcast_message_hint'),
                    prefixIcon: Icons.message_outlined,
                    helperText: _count(
                      'broadcast_character_count',
                      _messageController.text.trim().characters.length,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _priority,
                  dropdownColor: _surfaceColor,
                  decoration: _inputDecoration(
                    hint: _tr('broadcast_priority_hint'),
                    prefixIcon: Icons.flag_outlined,
                  ),
                  style: TextStyle(color: _primaryTextColor),
                  items: [
                    DropdownMenuItem(
                      value: 'low',
                      child: Text(_tr('broadcast_priority_low_full')),
                    ),
                    DropdownMenuItem(
                      value: 'medium',
                      child: Text(_tr('broadcast_priority_medium_full')),
                    ),
                    DropdownMenuItem(
                      value: 'high',
                      child: Text(_tr('broadcast_priority_high_full')),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _priority = value ?? 'medium';
                    });
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  _tr('broadcast_priority_help'),
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                _buildBroadcastTypePicker(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSurfaceSection(
            title: _tr('broadcast_select_recipients_title'),
            subtitle: _tr('broadcast_select_recipients_subtitle'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AudienceOptionTile(
                  icon: Icons.groups_rounded,
                  title: _tr('broadcast_all_employees'),
                  subtitle: _tr('broadcast_all_employees_subtitle'),
                  badgeLabel: provider.employeeDirectoryRestricted
                      ? _tr('broadcast_access_limited')
                      : _count(
                          'broadcast_recipient_count',
                          provider.employees.length,
                        ),
                  selected: _recipientType == _BroadcastRecipientType.all,
                  isDarkMode: _isDarkMode,
                  onTap: () {
                    setState(() {
                      _recipientType = _BroadcastRecipientType.all;
                      _selectedDepartmentIds = const [];
                      _selectedEmployeeIds = const [];
                    });
                  },
                ),
                const SizedBox(height: 12),
                _AudienceOptionTile(
                  icon: Icons.apartment_rounded,
                  title: _tr('broadcast_specific_departments'),
                  subtitle: _tr('broadcast_specific_departments_subtitle'),
                  badgeLabel: _count(
                    'broadcast_selected_count',
                    _selectedDepartmentIds.length,
                  ),
                  selected:
                      _recipientType == _BroadcastRecipientType.department,
                  isDarkMode: _isDarkMode,
                  onTap: () {
                    setState(() {
                      _recipientType = _BroadcastRecipientType.department;
                      _selectedEmployeeIds = const [];
                    });
                  },
                ),
                if (_recipientType == _BroadcastRecipientType.department) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: provider.departments.isEmpty
                        ? null
                        : () => _openDepartmentSelector(provider),
                    icon: const Icon(Icons.checklist_rounded),
                    label: Text(_tr('broadcast_choose_departments')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryTextColor,
                      side: BorderSide(color: _surfaceBorderColor),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (selectedDepartments.isEmpty)
                    _buildEmptyInlineState(
                      icon: Icons.domain_disabled_outlined,
                      message: _tr('broadcast_no_departments_selected'),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedDepartments
                          .map(
                            (department) => _buildTag(
                              label: department.name,
                              color: const Color(0xFF0EA5E9),
                            ),
                          )
                          .toList(growable: false),
                    ),
                ],
                const SizedBox(height: 12),
                _AudienceOptionTile(
                  icon: Icons.person_search_rounded,
                  title: _tr('broadcast_specific_employees'),
                  subtitle: _tr('broadcast_specific_employees_subtitle'),
                  badgeLabel: _count(
                    'broadcast_selected_count',
                    _selectedEmployeeIds.length,
                  ),
                  selected: _recipientType == _BroadcastRecipientType.custom,
                  isDarkMode: _isDarkMode,
                  onTap: () {
                    setState(() {
                      _recipientType = _BroadcastRecipientType.custom;
                      _selectedDepartmentIds = const [];
                    });
                  },
                ),
                if (_recipientType == _BroadcastRecipientType.custom) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: provider.employees.isEmpty
                        ? null
                        : () => _openEmployeeSelector(provider),
                    icon: const Icon(Icons.manage_accounts_outlined),
                    label: Text(_tr('broadcast_choose_employees')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryTextColor,
                      side: BorderSide(color: _surfaceBorderColor),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (selectedEmployees.isEmpty)
                    _buildEmptyInlineState(
                      icon: Icons.person_off_outlined,
                      message: _tr('broadcast_no_employees_selected'),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedEmployees
                          .take(8)
                          .map(
                            (employee) => _buildTag(
                              label: employee.name,
                              color: const Color(0xFF8B5CF6),
                            ),
                          )
                          .toList(growable: false),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSurfaceSection(
            title: _tr('broadcast_summary_title'),
            subtitle: _tr('broadcast_summary_subtitle'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryMetric(
                        label: _tr('broadcast_audience'),
                        value: _audienceLabel(_recipientType),
                        color: const Color(0xFF0EA5E9),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryMetric(
                        label: _tr('broadcast_priority'),
                        value: _priorityLabel(_priority),
                        color: _priorityColor(_priority),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSummaryMetric(
                  label: _tr('broadcast_total_recipients'),
                  value: recipientCount.toString(),
                  color: const Color(0xFF2F9D78),
                  fullWidth: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: recipientCount == 0 ? null : _showPreviewDialog,
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(_tr('broadcast_preview')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryTextColor,
                    side: BorderSide(color: _surfaceBorderColor),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: provider.isSending
                      ? null
                      : () => _handleSend(provider),
                  icon: provider.isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    provider.isSending
                        ? _tr('broadcast_sending')
                        : _tr('broadcast_send'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(BroadcastProvider provider) {
    return RefreshIndicator(
      onRefresh: provider.refreshHistory,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildHeroCard(
            title: _tr('broadcast_history_title'),
            subtitle: _tr('broadcast_history_subtitle'),
            badgeLabel: provider.history.isEmpty
                ? null
                : _count('broadcast_entry_count', provider.history.length),
            metricLabels: [
              _count(
                'broadcast_sent_count',
                provider.history.where((item) => item.status == 'sent').length,
              ),
              _count(
                'broadcast_pending_count',
                provider.history
                    .where((item) => item.status == 'pending')
                    .length,
              ),
              _count(
                'broadcast_failed_count',
                provider.history
                    .where((item) => item.status == 'failed')
                    .length,
              ),
            ],
          ),
          if (provider.error != null) ...[
            const SizedBox(height: 16),
            _buildBanner(
              color: AppColors.error,
              icon: Icons.error_outline_rounded,
              message: provider.error!,
            ),
          ],
          if (provider.historyRestricted) ...[
            const SizedBox(height: 16),
            _buildBanner(
              color: AppColors.warning,
              icon: Icons.lock_outline_rounded,
              message: _tr('broadcast_history_permission_message'),
            ),
          ],
          const SizedBox(height: 16),
          if (provider.history.isEmpty)
            _buildSurfaceSection(
              title: _tr('broadcast_no_history_title'),
              subtitle: _tr('broadcast_no_history_subtitle'),
              child: _buildEmptyInlineState(
                icon: Icons.notifications_none_rounded,
                message: _tr('broadcast_no_history_message'),
              ),
            )
          else
            ...provider.history.map(_buildHistoryCard),
        ],
      ),
    );
  }

  Widget _buildBroadcastTypePicker() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceMutedColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _surfaceBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr('broadcast_type_title'),
            style: TextStyle(
              color: _primaryTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _tr('broadcast_type_subtitle'),
            style: TextStyle(color: _secondaryTextColor, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ModeButton(
                  icon: Icons.notifications_active_outlined,
                  label: _tr('broadcast_type_message'),
                  selected: !_isCalendarEvent,
                  onTap: () {
                    setState(() {
                      _isCalendarEvent = false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ModeButton(
                  icon: Icons.event_available_outlined,
                  label: _tr('broadcast_type_event'),
                  selected: _isCalendarEvent,
                  onTap: () {
                    setState(() {
                      _isCalendarEvent = true;
                    });
                  },
                ),
              ),
            ],
          ),
          if (_isCalendarEvent) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _DateTimeTile(
                    label: _tr('broadcast_event_start'),
                    value: _eventStartsAt,
                    emptyLabel: _tr('broadcast_pick_time'),
                    isDarkMode: _isDarkMode,
                    onTap: () async {
                      final picked = await _pickDateTime(_eventStartsAt);
                      if (picked != null) {
                        setState(() => _eventStartsAt = picked);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateTimeTile(
                    label: _tr('broadcast_event_end'),
                    value: _eventEndsAt,
                    emptyLabel: _tr('broadcast_pick_time'),
                    isDarkMode: _isDarkMode,
                    onTap: () async {
                      final picked = await _pickDateTime(
                        _eventEndsAt ?? _eventStartsAt,
                      );
                      if (picked != null) {
                        setState(() => _eventEndsAt = picked);
                      }
                    },
                    onClear: _eventEndsAt == null
                        ? null
                        : () => setState(() => _eventEndsAt = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _eventLocationController,
              style: TextStyle(color: _primaryTextColor),
              decoration: _inputDecoration(
                hint: _tr('broadcast_event_location_hint'),
                prefixIcon: Icons.place_outlined,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroCard({
    required String title,
    required String subtitle,
    required List<String> metricLabels,
    String? badgeLabel,
  }) {
    final gradient = _isDarkMode
        ? const LinearGradient(
            colors: [Color(0xFF172554), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _surfaceBorderColor),
      ),
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
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: _primaryTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: _secondaryTextColor,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (badgeLabel != null && badgeLabel.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildTag(label: badgeLabel, color: AppColors.primary),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: metricLabels
                .map((label) => _buildTag(label: label, color: AppColors.info))
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _buildSurfaceSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _primaryTextColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildBanner({
    required Color color,
    required IconData icon,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: _isDarkMode ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: _isDarkMode
                    ? Colors.white
                    : color.withValues(alpha: 0.92),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: _isDarkMode ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _isDarkMode ? Colors.white : color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyInlineState({
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceMutedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _surfaceBorderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: _secondaryTextColor, size: 24),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: _secondaryTextColor, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric({
    required String label,
    required String value,
    required Color color,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: _isDarkMode ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: _isDarkMode ? Colors.white : color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BroadcastHistoryItem item) {
    final sentAt = item.sentAt == null
        ? '-'
        : DateFormat('dd MMM yyyy, HH:mm').format(item.sentAt!.toLocal());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: _surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                item.title,
                style: TextStyle(
                  color: _primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _buildTag(
                label: _priorityLabel(item.priority),
                color: _priorityColor(item.priority),
              ),
              _buildTag(
                label: _statusLabel(item.status),
                color: _statusColor(item.status),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.message,
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag(
                label: _count('broadcast_recipients', item.recipientCount),
                color: const Color(0xFF0EA5E9),
              ),
              _buildTag(
                label: _historyTypeLabel(item.type),
                color: const Color(0xFF8B5CF6),
              ),
              if (item.isCalendarEvent)
                _buildTag(
                  label: _tr('broadcast_calendar_event'),
                  color: const Color(0xFF2563EB),
                ),
              if (item.eventStartsAt != null)
                _buildTag(
                  label: DateFormat(
                    'dd MMM yyyy, HH:mm',
                  ).format(item.eventStartsAt!.toLocal()),
                  color: const Color(0xFF0EA5E9),
                ),
              if (item.eventLocation.isNotEmpty)
                _buildTag(
                  label: item.eventLocation,
                  color: const Color(0xFF14B8A6),
                ),
              if (item.sentBy.isNotEmpty)
                _buildTag(label: item.sentBy, color: const Color(0xFF2F9D78)),
              _buildTag(label: sentAt, color: const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  Future<DateTime?> _pickDateTime(DateTime? initialValue) async {
    final now = DateTime.now();
    final initial = initialValue ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );

    if (date == null || !mounted) {
      return null;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (time == null) {
      return null;
    }

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _handleSend(BroadcastProvider provider) async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    final recipientCount = _getRecipientCount(provider);

    if (title.isEmpty || message.isEmpty) {
      _showSnackBar(_tr('broadcast_title_message_required'), isError: true);
      return;
    }

    if (recipientCount == 0) {
      _showSnackBar(_tr('broadcast_recipient_required'), isError: true);
      return;
    }

    if (_isCalendarEvent && _eventStartsAt == null) {
      _showSnackBar(_tr('broadcast_event_start_required'), isError: true);
      return;
    }

    final wasCalendarEvent = _isCalendarEvent;
    final success = await provider.sendBroadcast(
      title: title,
      message: message,
      type: _recipientType.apiValue,
      departmentIds: _selectedDepartmentIds,
      employeeIds: _selectedEmployeeIds,
      priority: _priority,
      recipientCount: recipientCount,
      isCalendarEvent: _isCalendarEvent,
      eventStartsAt: _eventStartsAt,
      eventEndsAt: _eventEndsAt,
      eventLocation: _eventLocationController.text,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showSnackBar(
        provider.error ?? _tr('broadcast_send_failed'),
        isError: true,
      );
      return;
    }

    setState(() {
      _titleController.clear();
      _messageController.clear();
      _priority = 'medium';
      _isCalendarEvent = false;
      _eventStartsAt = null;
      _eventEndsAt = null;
      _eventLocationController.clear();
      _recipientType = _BroadcastRecipientType.all;
      _selectedDepartmentIds = const [];
      _selectedEmployeeIds = const [];
    });

    if (wasCalendarEvent) {
      context.read<EventProvider>().fetchUpcomingEvents();
    }

    _tabController.animateTo(1);
    _showSnackBar(
      wasCalendarEvent
          ? _tr('broadcast_calendar_success')
          : _tr('broadcast_success'),
    );
  }

  void _showPreviewDialog() {
    final provider = context.read<BroadcastProvider>();
    final recipientCount = _getRecipientCount(provider);
    final previewTitle = _titleController.text.trim().isEmpty
        ? _tr('broadcast_preview_no_title')
        : _titleController.text.trim();
    final previewMessage = _messageController.text.trim().isEmpty
        ? _tr('broadcast_preview_empty_message')
        : _messageController.text.trim();
    final audienceLabel = _audienceLabel(_recipientType);
    final priorityLabel = _priorityLabel(_priority);
    final priorityColor = _priorityColor(_priority);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surfaceColor,
          title: Text(
            _tr('broadcast_preview_title'),
            style: TextStyle(color: _primaryTextColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  previewTitle,
                  style: TextStyle(
                    color: _primaryTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  previewMessage,
                  style: TextStyle(color: _secondaryTextColor, height: 1.5),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTag(
                      label: audienceLabel,
                      color: const Color(0xFF0EA5E9),
                    ),
                    _buildTag(label: priorityLabel, color: priorityColor),
                    _buildTag(
                      label: _count('broadcast_recipients', recipientCount),
                      color: const Color(0xFF2F9D78),
                    ),
                    _buildTag(
                      label: _isCalendarEvent
                          ? _tr('broadcast_calendar_event')
                          : _tr('broadcast_type_message'),
                      color: _isCalendarEvent
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF64748B),
                    ),
                    if (_isCalendarEvent && _eventStartsAt != null)
                      _buildTag(
                        label: DateFormat(
                          'dd MMM yyyy, HH:mm',
                        ).format(_eventStartsAt!.toLocal()),
                        color: const Color(0xFF0EA5E9),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(_tr('broadcast_close')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openDepartmentSelector(BroadcastProvider provider) async {
    final result = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final tempSelected = {..._selectedDepartmentIds};

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.84,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _surfaceBorderColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _tr('broadcast_select_departments_title'),
                      style: TextStyle(
                        color: _primaryTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _tr('broadcast_select_departments_subtitle'),
                      style: TextStyle(color: _secondaryTextColor),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              tempSelected
                                ..clear()
                                ..addAll(
                                  provider.departments.map((item) => item.id),
                                );
                            });
                          },
                          child: Text(_tr('broadcast_select_all')),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            setModalState(tempSelected.clear);
                          },
                          child: Text(_tr('broadcast_clear')),
                        ),
                        const Spacer(),
                        Text(
                          _count(
                            'broadcast_selected_count',
                            tempSelected.length,
                          ),
                          style: TextStyle(color: _secondaryTextColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: provider.departments.isEmpty
                          ? _buildEmptyInlineState(
                              icon: Icons.domain_disabled_outlined,
                              message: _tr('broadcast_no_department_data'),
                            )
                          : ListView.separated(
                              itemCount: provider.departments.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final department = provider.departments[index];
                                final selected = tempSelected.contains(
                                  department.id,
                                );
                                final employeeCount = provider.employees
                                    .where(
                                      (employee) =>
                                          employee.departmentId ==
                                          department.id,
                                    )
                                    .length;

                                return _SelectorTile(
                                  title: department.name,
                                  subtitle: _count(
                                    'broadcast_employee_suffix',
                                    employeeCount > 0
                                        ? employeeCount
                                        : department.employeeCount,
                                  ),
                                  selected: selected,
                                  isDarkMode: _isDarkMode,
                                  onTap: () {
                                    setModalState(() {
                                      if (selected) {
                                        tempSelected.remove(department.id);
                                      } else {
                                        tempSelected.add(department.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, tempSelected.toList()..sort());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(_tr('broadcast_apply_selection')),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDepartmentIds = result;
      _selectedEmployeeIds = const [];
      _recipientType = result.isEmpty
          ? _BroadcastRecipientType.all
          : _BroadcastRecipientType.department;
    });
  }

  Future<void> _openEmployeeSelector(BroadcastProvider provider) async {
    final result = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final tempSelected = {..._selectedEmployeeIds};
        var searchQuery = '';

        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredEmployees = provider.employees
                .where((employee) {
                  if (searchQuery.trim().isEmpty) {
                    return true;
                  }

                  final normalizedQuery = searchQuery.toLowerCase();
                  return employee.name.toLowerCase().contains(
                        normalizedQuery,
                      ) ||
                      employee.email.toLowerCase().contains(normalizedQuery) ||
                      employee.employeeId.toLowerCase().contains(
                        normalizedQuery,
                      ) ||
                      employee.departmentName.toLowerCase().contains(
                        normalizedQuery,
                      );
                })
                .toList(growable: false);

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.88,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _surfaceBorderColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _tr('broadcast_select_employees_title'),
                      style: TextStyle(
                        color: _primaryTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _tr('broadcast_select_employees_subtitle'),
                      style: TextStyle(color: _secondaryTextColor),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      style: TextStyle(color: _primaryTextColor),
                      decoration: _inputDecoration(
                        hint: _tr('broadcast_employee_search_hint'),
                        prefixIcon: Icons.search_rounded,
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              tempSelected
                                ..clear()
                                ..addAll(
                                  filteredEmployees.map((item) => item.id),
                                );
                            });
                          },
                          child: Text(_tr('broadcast_select_result')),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            setModalState(tempSelected.clear);
                          },
                          child: Text(_tr('broadcast_clear')),
                        ),
                        const Spacer(),
                        Text(
                          _count(
                            'broadcast_selected_count',
                            tempSelected.length,
                          ),
                          style: TextStyle(color: _secondaryTextColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filteredEmployees.isEmpty
                          ? _buildEmptyInlineState(
                              icon: Icons.search_off_rounded,
                              message: _tr('broadcast_no_employee_match'),
                            )
                          : ListView.separated(
                              itemCount: filteredEmployees.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final employee = filteredEmployees[index];
                                final selected = tempSelected.contains(
                                  employee.id,
                                );

                                return _SelectorTile(
                                  title: employee.name,
                                  subtitle:
                                      '${employee.employeeId.isEmpty ? '-' : employee.employeeId} - ${employee.departmentName.isEmpty ? _tr('broadcast_no_department') : employee.departmentName}',
                                  selected: selected,
                                  isDarkMode: _isDarkMode,
                                  trailing: employee.email.isEmpty
                                      ? null
                                      : Text(
                                          employee.email,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: _mutedTextColor,
                                            fontSize: 11,
                                          ),
                                        ),
                                  onTap: () {
                                    setModalState(() {
                                      if (selected) {
                                        tempSelected.remove(employee.id);
                                      } else {
                                        tempSelected.add(employee.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, tempSelected.toList()..sort());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(_tr('broadcast_apply_selection')),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _selectedEmployeeIds = result;
      _selectedDepartmentIds = const [];
      _recipientType = result.isEmpty
          ? _BroadcastRecipientType.all
          : _BroadcastRecipientType.custom;
    });
  }

  int _getRecipientCount(BroadcastProvider provider) {
    switch (_recipientType) {
      case _BroadcastRecipientType.department:
        return provider.employees
            .where(
              (employee) =>
                  _selectedDepartmentIds.contains(employee.departmentId),
            )
            .length;
      case _BroadcastRecipientType.custom:
        return _selectedEmployeeIds.length;
      case _BroadcastRecipientType.all:
        return provider.employees.length;
    }
  }

  String _audienceLabel(_BroadcastRecipientType type) {
    switch (type) {
      case _BroadcastRecipientType.department:
        return _tr('broadcast_specific_departments');
      case _BroadcastRecipientType.custom:
        return _tr('broadcast_specific_employees');
      case _BroadcastRecipientType.all:
        return _tr('broadcast_all_employees');
    }
  }

  String _priorityLabel(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return _tr('broadcast_priority_low');
      case 'high':
        return _tr('broadcast_priority_high');
      default:
        return _tr('broadcast_priority_medium');
    }
  }

  String _historyTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'department':
        return _tr('broadcast_history_type_departments');
      case 'custom':
        return _tr('broadcast_history_type_custom');
      default:
        return _tr('broadcast_history_type_all');
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'failed':
        return _tr('broadcast_status_failed');
      case 'pending':
        return _tr('broadcast_status_pending');
      default:
        return _tr('broadcast_status_sent');
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return const Color(0xFF2F9D78);
      case 'high':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'failed':
        return const Color(0xFFEF4444);
      case 'pending':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF2F9D78);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : isDarkMode
              ? const Color(0xFF111827)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : isDarkMode
                ? const Color(0xFF253041)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? Colors.white
                  : isDarkMode
                  ? Colors.white70
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : isDarkMode
                      ? Colors.white
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  final String label;
  final DateTime? value;
  final String emptyLabel;
  final bool isDarkMode;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateTimeTile({
    required this.label,
    required this.value,
    required this.emptyLabel,
    required this.isDarkMode,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : AppColors.textPrimary;
    final subtitleColor = isDarkMode
        ? const Color(0xFFCBD5E1)
        : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? const Color(0xFF253041) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value == null
                        ? emptyLabel
                        : DateFormat('dd MMM, HH:mm').format(value!.toLocal()),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              InkWell(
                onTap: onClear,
                child: Icon(Icons.close, size: 16, color: subtitleColor),
              ),
          ],
        ),
      ),
    );
  }
}

class _AudienceOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badgeLabel;
  final bool selected;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _AudienceOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.selected,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: isDarkMode ? 0.18 : 0.10)
              : isDarkMode
              ? const Color(0xFF0F172A)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : isDarkMode
                ? const Color(0xFF253041)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDarkMode
                          ? const Color(0xFFCBD5E1)
                          : AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? AppColors.primary
                      : isDarkMode
                      ? const Color(0xFF64748B)
                      : AppColors.textMuted,
                ),
                const SizedBox(height: 8),
                Text(
                  badgeLabel,
                  style: TextStyle(
                    color: selected
                        ? AppColors.primary
                        : isDarkMode
                        ? const Color(0xFFCBD5E1)
                        : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectorTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final bool isDarkMode;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SelectorTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.isDarkMode,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: isDarkMode ? 0.18 : 0.10)
              : isDarkMode
              ? const Color(0xFF0F172A)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : isDarkMode
                ? const Color(0xFF253041)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? AppColors.primary
                  : isDarkMode
                  ? const Color(0xFF64748B)
                  : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDarkMode
                          ? const Color(0xFFCBD5E1)
                          : AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              Flexible(child: trailing!),
            ],
          ],
        ),
      ),
    );
  }
}
