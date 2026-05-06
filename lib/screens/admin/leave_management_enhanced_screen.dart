import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/leave_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';

class LeaveManagementEnhancedScreen extends StatefulWidget {
  const LeaveManagementEnhancedScreen({super.key});

  @override
  State<LeaveManagementEnhancedScreen> createState() =>
      _LeaveManagementEnhancedScreenState();
}

class _LeaveManagementEnhancedScreenState
    extends State<LeaveManagementEnhancedScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  Color get _screenBackgroundColor =>
      _isDarkMode ? const Color(0xFF050914) : AppColors.background;

  Color get _surfaceColor =>
      _isDarkMode ? const Color(0xFF0B1220) : Colors.white;

  Color get _surfaceMutedColor =>
      _isDarkMode ? const Color(0xFF111A2C) : Colors.grey.shade100;

  Color get _surfaceBorderColor =>
      _isDarkMode ? const Color(0xFF1E293B) : AppColors.border;

  Color get _primarySoftColor =>
      AppColors.primary.withValues(alpha: _isDarkMode ? 0.13 : 0.1);

  Color get _primaryTextColor =>
      _isDarkMode ? const Color(0xFFE5EDF8) : AppColors.textPrimary;

  Color get _secondaryTextColor =>
      _isDarkMode ? const Color(0xFF94A3B8) : AppColors.textSecondary;

  BoxDecoration _surfaceDecoration() => BoxDecoration(
    color: _surfaceColor,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: _surfaceBorderColor),
    boxShadow: _isDarkMode
        ? const []
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
  );

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    final radius = BorderRadius.circular(14);

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _secondaryTextColor),
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: _secondaryTextColor, size: 20),
      filled: true,
      fillColor: _surfaceMutedColor,
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: _surfaceBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: _isDarkMode ? const Color(0xFF60A5FA) : AppColors.primary,
          width: 1.4,
        ),
      ),
      border: OutlineInputBorder(borderRadius: radius),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();
      final leaveProvider = context.read<LeaveProvider>();
      final companyCode = authProvider.getCompanyCode();

      if (companyCode.isNotEmpty) {
        leaveProvider.setCompanyCode(companyCode);
      }

      await leaveProvider.fetchLeaveData();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leaveProvider = context.watch<LeaveProvider>();
    final authProvider = context.watch<AuthProvider>();
    final companyCode = authProvider.getCompanyCode();
    final canManageCompanyLeave = leaveProvider.canManageCompanyLeave;

    return DefaultTabController(
      length: canManageCompanyLeave ? 2 : 1,
      child: Scaffold(
        backgroundColor: _screenBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Leave Management',
            style: TextStyle(
              color: _primaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: _surfaceColor,
          surfaceTintColor: _surfaceColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: _primaryTextColor),
          foregroundColor: _primaryTextColor,
          actions: [
            IconButton(
              onPressed: leaveProvider.isLoading
                  ? null
                  : () => leaveProvider.fetchLeaveData(),
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: TabBar(
            labelColor: _isDarkMode
                ? const Color(0xFFBFDBFE)
                : AppColors.primary,
            unselectedLabelColor: _secondaryTextColor,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: _surfaceBorderColor,
            indicator: BoxDecoration(
              color: _primarySoftColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDarkMode
                    ? const Color(0xFF1D4ED8).withValues(alpha: 0.28)
                    : AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            tabs: [
              const Tab(text: 'Requests'),
              if (canManageCompanyLeave) const Tab(text: 'Company Leave'),
            ],
          ),
        ),
        body: leaveProvider.isLoading && leaveProvider.leaveRequests.isEmpty
            ? Center(
                child: CircularProgressIndicator(
                  color: _isDarkMode ? Colors.white70 : AppColors.primary,
                ),
              )
            : TabBarView(
                children: [
                  _buildRequestsTab(leaveProvider, companyCode),
                  if (canManageCompanyLeave)
                    _buildCompanyLeaveTab(leaveProvider, companyCode),
                ],
              ),
      ),
    );
  }

  Widget _buildRequestsTab(LeaveProvider leaveProvider, String companyCode) {
    final requests = leaveProvider.leaveRequests;
    final companyLeaveCount = requests
        .where((request) => request.isCompanyLeave)
        .length;
    final pendingCount = requests
        .where((request) => request.status.toLowerCase() == 'pending')
        .length;

    return RefreshIndicator(
      onRefresh: leaveProvider.fetchLeaveData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _buildOverviewCard(
            companyCode: companyCode,
            requests: requests.length,
            companyLeave: companyLeaveCount,
            pending: pendingCount,
          ),
          const SizedBox(height: 16),
          if (requests.isEmpty)
            _buildEmptyState(
              icon: Icons.inbox_outlined,
              title: 'No leave requests found',
              message: companyCode.isEmpty
                  ? 'Select a company first to load leave requests.'
                  : 'Leave requests for $companyCode will appear here.',
            )
          else
            ...requests.map(
              (request) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LeaveRequestManagementCard(request: request),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard({
    required String companyCode,
    required int requests,
    required int companyLeave,
    required int pending,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _primarySoftColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.beach_access_outlined,
                  color: Color(0xFF60A5FA),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyCode.isEmpty ? 'No company selected' : companyCode,
                      style: TextStyle(
                        color: _primaryTextColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Leave request overview',
                      style: TextStyle(color: _secondaryTextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryPill(
                  label: 'Requests',
                  value: '$requests',
                  color: _isDarkMode
                      ? const Color(0xFF60A5FA)
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryPill(
                  label: 'Company',
                  value: '$companyLeave',
                  color: _isDarkMode ? const Color(0xFF38BDF8) : Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryPill(
                  label: 'Pending',
                  value: '$pending',
                  color: _isDarkMode ? const Color(0xFFFBBF24) : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      decoration: _surfaceDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 42),
      child: Column(
        children: [
          Icon(icon, size: 48, color: _secondaryTextColor),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _primaryTextColor,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: _secondaryTextColor, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyLeaveTab(
    LeaveProvider leaveProvider,
    String companyCode,
  ) {
    return RefreshIndicator(
      onRefresh: leaveProvider.fetchLeaveData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: _surfaceDecoration(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bulk Company Leave',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    companyCode.isEmpty
                        ? 'Select a company first before creating company leave.'
                        : 'HR/Admin can create company leave in bulk for all active employees in this company.',
                    style: TextStyle(color: _secondaryTextColor),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    style: TextStyle(color: _primaryTextColor),
                    decoration: _inputDecoration(
                      'Title',
                      icon: Icons.title_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: TextStyle(color: _primaryTextColor),
                    decoration: _inputDecoration(
                      'Description',
                      icon: Icons.notes_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DateTile(
                          label: 'Start Date',
                          value: _startDate,
                          onTap: () => _pickDate(isStartDate: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateTile(
                          label: 'End Date',
                          value: _endDate,
                          onTap: () => _pickDate(isStartDate: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(
                        alpha: _isDarkMode ? 0.16 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withValues(
                          alpha: _isDarkMode ? 0.24 : 0.15,
                        ),
                      ),
                    ),
                    child: Text(
                      _companyLeaveSummary(companyCode),
                      style: TextStyle(color: _secondaryTextColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: leaveProvider.isSubmittingCompanyLeaveBatch
                          ? null
                          : () => _submitCompanyLeaveBatch(
                              context,
                              leaveProvider,
                              companyCode,
                            ),
                      icon: leaveProvider.isSubmittingCompanyLeaveBatch
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.approval_outlined),
                      label: Text(
                        leaveProvider.isSubmittingCompanyLeaveBatch
                            ? 'Processing...'
                            : 'Create Company Leave',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Company Leave History',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _primaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          if (leaveProvider.companyLeaveBatches.isEmpty)
            _buildEmptyState(
              icon: Icons.event_busy_outlined,
              title: 'No company leave batches yet',
              message:
                  'Bulk company leave history will appear after you create a batch.',
            )
          else
            ...leaveProvider.companyLeaveBatches.map(
              (batch) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CompanyLeaveBatchCard(batch: batch),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isStartDate}) async {
    final initialDate = isStartDate
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      if (isStartDate) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submitCompanyLeaveBatch(
    BuildContext context,
    LeaveProvider leaveProvider,
    String companyCode,
  ) async {
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar(context, 'Title is required.', isError: true);
      return;
    }

    if (_startDate == null || _endDate == null) {
      _showSnackBar(
        context,
        'Start date and end date are required.',
        isError: true,
      );
      return;
    }

    if (companyCode.isEmpty) {
      _showSnackBar(context, 'Company code not found.', isError: true);
      return;
    }

    final success = await leaveProvider.createCompanyLeaveBatch(
      title: _titleController.text,
      description: _descriptionController.text,
      startDate: _startDate!,
      endDate: _endDate!,
      cCode: companyCode,
    );

    if (!context.mounted) {
      return;
    }

    if (success) {
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _startDate = null;
        _endDate = null;
      });

      _showSnackBar(
        context,
        leaveProvider.lastActionMessage ??
            'Company leave created successfully.',
      );
      return;
    }

    _showSnackBar(
      context,
      leaveProvider.error ?? 'Failed to create company leave.',
      isError: true,
    );
  }

  String _companyLeaveSummary(String companyCode) {
    if (companyCode.isEmpty) {
      return 'No company selected yet.';
    }

    if (_startDate == null || _endDate == null) {
      return 'This batch will be applied to all active employees in $companyCode once the dates are selected.';
    }

    final normalizedStartDate = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
    );
    final normalizedEndDate = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
    );
    final days = normalizedEndDate.difference(normalizedStartDate).inDays + 1;

    return 'This batch will create Company Leave entries for all active employees in $companyCode for $days day(s). Duplicate employees on the same date range will be skipped automatically.';
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}

class _LeaveRequestManagementCard extends StatelessWidget {
  const _LeaveRequestManagementCard({required this.request});

  final LeaveRequest request;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode ? const Color(0xFF0B1220) : Colors.white;
    final surfaceMutedColor = isDarkMode
        ? const Color(0xFF111A2C)
        : Colors.grey.shade100;
    final surfaceBorderColor = isDarkMode
        ? const Color(0xFF1E293B)
        : AppColors.border;
    final primaryTextColor = isDarkMode
        ? const Color(0xFFE5EDF8)
        : AppColors.textPrimary;
    final secondaryTextColor = isDarkMode
        ? const Color(0xFF94A3B8)
        : AppColors.textSecondary;
    final leaveProvider = context.read<LeaveProvider>();
    final canApprove =
        request.status.toLowerCase() == 'pending' && !request.isCompanyLeave;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: surfaceBorderColor),
        boxShadow: isDarkMode
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.employeeName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Text(
                            request.type,
                            style: TextStyle(color: secondaryTextColor),
                          ),
                          if (request.isCompanyLeave)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF2563EB,
                                ).withValues(alpha: isDarkMode ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Company Leave',
                                style: TextStyle(
                                  color: Color(0xFF60A5FA),
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
                _StatusChip(status: request.status),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _InfoBlock(
                    label: 'Start Date',
                    value: _formatDate(request.startDate),
                  ),
                ),
                Expanded(
                  child: _InfoBlock(
                    label: 'End Date',
                    value: _formatDate(request.endDate),
                  ),
                ),
                Expanded(
                  child: _InfoBlock(
                    label: 'Duration',
                    value: '${request.days} day(s)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surfaceMutedColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                request.reason.isEmpty
                    ? (request.isCompanyLeave
                          ? 'Company leave assigned in bulk by HR/Admin.'
                          : '-')
                    : request.reason,
                style: TextStyle(color: secondaryTextColor),
              ),
            ),
            if (canApprove) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleApproval(
                        context,
                        leaveProvider,
                        approved: false,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        backgroundColor: Colors.red.withValues(
                          alpha: isDarkMode ? 0.1 : 0.04,
                        ),
                        side: BorderSide(
                          color: Colors.red.withValues(
                            alpha: isDarkMode ? 0.5 : 0.3,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleApproval(
                        context,
                        leaveProvider,
                        approved: true,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleApproval(
    BuildContext context,
    LeaveProvider leaveProvider, {
    required bool approved,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final primaryTextColor = isDarkMode
            ? const Color(0xFFE5EDF8)
            : AppColors.textPrimary;
        final secondaryTextColor = isDarkMode
            ? const Color(0xFF94A3B8)
            : AppColors.textSecondary;
        final surfaceColor = isDarkMode
            ? const Color(0xFF0B1220)
            : Colors.white;

        return AlertDialog(
          backgroundColor: surfaceColor,
          surfaceTintColor: surfaceColor,
          title: Text(
            '${approved ? 'Approve' : 'Reject'} Leave Request',
            style: TextStyle(color: primaryTextColor),
          ),
          content: Text(
            'Are you sure you want to ${approved ? 'approve' : 'reject'} this leave request?',
            style: TextStyle(color: secondaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: approved ? Colors.green : Colors.red,
              ),
              child: Text(approved ? 'Approve' : 'Reject'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final success = approved
        ? await leaveProvider.approveRequest(request.id)
        : await leaveProvider.rejectRequest(request.id);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Leave request ${approved ? 'approved' : 'rejected'}.'
              : leaveProvider.error ?? 'Failed to update leave request.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) {
      return '-';
    }

    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}

class _CompanyLeaveBatchCard extends StatelessWidget {
  const _CompanyLeaveBatchCard({required this.batch});

  final CompanyLeaveBatch batch;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode ? const Color(0xFF0B1220) : Colors.white;
    final surfaceBorderColor = isDarkMode
        ? const Color(0xFF1E293B)
        : AppColors.border;
    final primaryTextColor = isDarkMode
        ? const Color(0xFFE5EDF8)
        : AppColors.textPrimary;
    final secondaryTextColor = isDarkMode
        ? const Color(0xFF94A3B8)
        : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: surfaceBorderColor),
        boxShadow: isDarkMode
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batch.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDate(batch.startDate)} - ${_formatDate(batch.endDate)} | ${batch.days} day(s)',
                        style: TextStyle(color: secondaryTextColor),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF2563EB,
                    ).withValues(alpha: isDarkMode ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    batch.leaveType,
                    style: const TextStyle(
                      color: Color(0xFF60A5FA),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (batch.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                batch.description,
                style: TextStyle(color: secondaryTextColor),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Employees',
                    value: batch.totalEmployees.toString(),
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    label: 'Processed',
                    value: batch.processedEmployees.toString(),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    label: 'Skipped',
                    value: batch.skippedEmployees.toString(),
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              batch.creatorName.isEmpty
                  ? 'Created ${_formatDate(batch.createdAt)}'
                  : 'Created ${_formatDate(batch.createdAt)} by ${batch.creatorName}',
              style: TextStyle(fontSize: 12, color: secondaryTextColor),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) {
      return '-';
    }

    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDarkMode
        ? const Color(0xFF94A3B8)
        : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDarkMode ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: isDarkMode ? 0.22 : 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: secondaryTextColor),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode ? const Color(0xFF111A2C) : Colors.white;
    final surfaceBorderColor = isDarkMode
        ? const Color(0xFF1E293B)
        : Colors.grey.shade300;
    final primaryTextColor = isDarkMode
        ? const Color(0xFFE5EDF8)
        : AppColors.textPrimary;
    final secondaryTextColor = isDarkMode
        ? const Color(0xFF94A3B8)
        : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: surfaceBorderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: secondaryTextColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value == null
                        ? 'Select date'
                        : DateFormat('dd MMM yyyy').format(value!),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode
        ? const Color(0xFFE5EDF8)
        : AppColors.textPrimary;
    final secondaryTextColor = isDarkMode
        ? const Color(0xFF94A3B8)
        : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: secondaryTextColor)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: primaryTextColor,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDarkMode
        ? const Color(0xFF94A3B8)
        : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDarkMode ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: secondaryTextColor),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;

    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
