import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/access_denied_state.dart';
import '../../models/broadcast_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/broadcast_provider.dart';

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
  late final TabController _tabController;

  _BroadcastRecipientType _recipientType = _BroadcastRecipientType.all;
  List<int> _selectedDepartmentIds = const [];
  List<int> _selectedEmployeeIds = const [];
  String _priority = 'medium';

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  Color get _screenBackgroundColor =>
      _isDarkMode ? const Color(0xFF020817) : AppColors.background;

  Color get _surfaceColor =>
      _isDarkMode ? const Color(0xFF111827) : Colors.white;

  Color get _surfaceMutedColor =>
      _isDarkMode ? const Color(0xFF0F172A) : Colors.grey.shade100;

  Color get _surfaceBorderColor =>
      _isDarkMode ? const Color(0xFF253041) : AppColors.border;

  Color get _primaryTextColor =>
      _isDarkMode ? const Color(0xFFF8FAFC) : AppColors.textPrimary;

  Color get _secondaryTextColor =>
      _isDarkMode ? const Color(0xFFCBD5E1) : AppColors.textSecondary;

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
        'Broadcast',
        style: TextStyle(color: _primaryTextColor, fontWeight: FontWeight.w700),
      ),
      backgroundColor: _surfaceColor,
      surfaceTintColor: _surfaceColor,
      iconTheme: IconThemeData(color: _primaryTextColor),
      elevation: 0,
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () =>
              context.read<BroadcastProvider>().initialize(showLoading: false),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      bottom: showTabs
          ? TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: _secondaryTextColor,
              tabs: const [
                Tab(text: 'Compose'),
                Tab(text: 'History'),
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
                'Pilih company terlebih dahulu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _primaryTextColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Broadcast membutuhkan company aktif agar data karyawan dan riwayat dapat dimuat dengan benar.',
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
            title: 'Broadcast Message',
            subtitle:
                'Kirim pengumuman dan notifikasi ke karyawan sesuai role.',
            badgeLabel: companyCode.isEmpty ? null : 'Company $companyCode',
            metricLabels: [
              '${provider.employees.length} karyawan',
              '${provider.departments.length} department',
              '${provider.history.length} riwayat',
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
          const SizedBox(height: 16),
          _buildSurfaceSection(
            title: 'Compose Message',
            subtitle: 'Tulis judul, isi pesan, dan prioritas broadcast.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  style: TextStyle(color: _primaryTextColor),
                  decoration: _inputDecoration(
                    hint: 'Masukkan judul broadcast',
                    prefixIcon: Icons.title_rounded,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _messageController,
                  maxLines: 7,
                  style: TextStyle(color: _primaryTextColor),
                  decoration: _inputDecoration(
                    hint: 'Tulis pesan yang ingin dikirim...',
                    prefixIcon: Icons.message_outlined,
                    helperText:
                        '${_messageController.text.trim().characters.length} karakter',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _priority,
                  dropdownColor: _surfaceColor,
                  decoration: _inputDecoration(
                    hint: 'Pilih prioritas',
                    prefixIcon: Icons.flag_outlined,
                  ),
                  style: TextStyle(color: _primaryTextColor),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low Priority')),
                    DropdownMenuItem(
                      value: 'medium',
                      child: Text('Medium Priority'),
                    ),
                    DropdownMenuItem(
                      value: 'high',
                      child: Text('High Priority'),
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
                  'Prioritas tinggi akan lebih mudah terlihat oleh penerima.',
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSurfaceSection(
            title: 'Select Recipients',
            subtitle: 'Tentukan siapa yang akan menerima broadcast ini.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AudienceOptionTile(
                  icon: Icons.groups_rounded,
                  title: 'All Employees',
                  subtitle:
                      'Kirim ke semua karyawan aktif yang tersedia di company.',
                  badgeLabel: '${provider.employees.length} penerima',
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
                  title: 'Specific Departments',
                  subtitle: 'Pilih satu atau beberapa department tertentu.',
                  badgeLabel: '${_selectedDepartmentIds.length} dipilih',
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
                    label: const Text('Pilih Department'),
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
                      message: 'Belum ada department yang dipilih.',
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
                  title: 'Specific Employees',
                  subtitle: 'Pilih karyawan satu per satu untuk broadcast.',
                  badgeLabel: '${_selectedEmployeeIds.length} dipilih',
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
                    label: const Text('Pilih Karyawan'),
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
                      message: 'Belum ada karyawan yang dipilih.',
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
            title: 'Recipient Summary',
            subtitle: 'Ringkasan penerima sebelum broadcast dikirim.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryMetric(
                        label: 'Audience',
                        value: _audienceLabel(_recipientType),
                        color: const Color(0xFF0EA5E9),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryMetric(
                        label: 'Priority',
                        value: _priorityLabel(_priority),
                        color: _priorityColor(_priority),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSummaryMetric(
                  label: 'Total Recipients',
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
                  label: const Text('Preview'),
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
                    provider.isSending ? 'Sending...' : 'Send Broadcast',
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
            title: 'Broadcast History',
            subtitle: 'Pantau pesan yang sudah pernah dikirim ke karyawan.',
            badgeLabel: provider.history.isEmpty
                ? null
                : '${provider.history.length} entries',
            metricLabels: [
              '${provider.history.where((item) => item.status == 'sent').length} sent',
              '${provider.history.where((item) => item.status == 'pending').length} pending',
              '${provider.history.where((item) => item.status == 'failed').length} failed',
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
          const SizedBox(height: 16),
          if (provider.history.isEmpty)
            _buildSurfaceSection(
              title: 'Belum ada riwayat',
              subtitle: 'Broadcast yang berhasil dikirim akan muncul di sini.',
              child: _buildEmptyInlineState(
                icon: Icons.notifications_none_rounded,
                message: 'Belum ada broadcast yang tercatat.',
              ),
            )
          else
            ...provider.history.map(_buildHistoryCard),
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
                label: item.status.toUpperCase(),
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
                label: '${item.recipientCount} recipients',
                color: const Color(0xFF0EA5E9),
              ),
              _buildTag(
                label: _historyTypeLabel(item.type),
                color: const Color(0xFF8B5CF6),
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

  Future<void> _handleSend(BroadcastProvider provider) async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    final recipientCount = _getRecipientCount(provider);

    if (title.isEmpty || message.isEmpty) {
      _showSnackBar('Judul dan pesan broadcast wajib diisi.', isError: true);
      return;
    }

    if (recipientCount == 0) {
      _showSnackBar('Pilih minimal satu penerima broadcast.', isError: true);
      return;
    }

    final success = await provider.sendBroadcast(
      title: title,
      message: message,
      type: _recipientType.apiValue,
      departmentIds: _selectedDepartmentIds,
      employeeIds: _selectedEmployeeIds,
      priority: _priority,
      recipientCount: recipientCount,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showSnackBar(
        provider.error ?? 'Broadcast gagal dikirim.',
        isError: true,
      );
      return;
    }

    setState(() {
      _titleController.clear();
      _messageController.clear();
      _priority = 'medium';
      _recipientType = _BroadcastRecipientType.all;
      _selectedDepartmentIds = const [];
      _selectedEmployeeIds = const [];
    });

    _tabController.animateTo(1);
    _showSnackBar('Broadcast berhasil dikirim.');
  }

  void _showPreviewDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        final provider = context.read<BroadcastProvider>();
        final recipientCount = _getRecipientCount(provider);

        return AlertDialog(
          backgroundColor: _surfaceColor,
          title: Text(
            'Preview Broadcast',
            style: TextStyle(color: _primaryTextColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _titleController.text.trim().isEmpty
                      ? '(Tanpa judul)'
                      : _titleController.text.trim(),
                  style: TextStyle(
                    color: _primaryTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _messageController.text.trim().isEmpty
                      ? '(Pesan masih kosong)'
                      : _messageController.text.trim(),
                  style: TextStyle(color: _secondaryTextColor, height: 1.5),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTag(
                      label: _audienceLabel(_recipientType),
                      color: const Color(0xFF0EA5E9),
                    ),
                    _buildTag(
                      label: _priorityLabel(_priority),
                      color: _priorityColor(_priority),
                    ),
                    _buildTag(
                      label: '$recipientCount recipients',
                      color: const Color(0xFF2F9D78),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
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
                      'Select Departments',
                      style: TextStyle(
                        color: _primaryTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pilih department yang akan menerima broadcast.',
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
                          child: const Text('Select All'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            setModalState(tempSelected.clear);
                          },
                          child: const Text('Clear'),
                        ),
                        const Spacer(),
                        Text(
                          '${tempSelected.length} dipilih',
                          style: TextStyle(color: _secondaryTextColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: provider.departments.isEmpty
                          ? _buildEmptyInlineState(
                              icon: Icons.domain_disabled_outlined,
                              message: 'Data department belum tersedia.',
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
                                  subtitle:
                                      '${employeeCount > 0 ? employeeCount : department.employeeCount} karyawan',
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
                        child: const Text('Terapkan Pilihan'),
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
                      'Select Employees',
                      style: TextStyle(
                        color: _primaryTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Cari dan pilih karyawan tertentu untuk menerima broadcast.',
                      style: TextStyle(color: _secondaryTextColor),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      style: TextStyle(color: _primaryTextColor),
                      decoration: _inputDecoration(
                        hint: 'Cari nama, email, NIK, atau department',
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
                          child: const Text('Select Result'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            setModalState(tempSelected.clear);
                          },
                          child: const Text('Clear'),
                        ),
                        const Spacer(),
                        Text(
                          '${tempSelected.length} dipilih',
                          style: TextStyle(color: _secondaryTextColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filteredEmployees.isEmpty
                          ? _buildEmptyInlineState(
                              icon: Icons.search_off_rounded,
                              message: 'Tidak ada karyawan yang cocok.',
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
                                      '${employee.employeeId.isEmpty ? '-' : employee.employeeId} • ${employee.departmentName.isEmpty ? 'Tanpa department' : employee.departmentName}',
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
                        child: const Text('Terapkan Pilihan'),
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
        return 'Specific Departments';
      case _BroadcastRecipientType.custom:
        return 'Specific Employees';
      case _BroadcastRecipientType.all:
        return 'All Employees';
    }
  }

  String _priorityLabel(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return 'Low';
      case 'high':
        return 'High';
      default:
        return 'Medium';
    }
  }

  String _historyTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'department':
        return 'Departments';
      case 'custom':
        return 'Custom Employees';
      default:
        return 'All Employees';
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
