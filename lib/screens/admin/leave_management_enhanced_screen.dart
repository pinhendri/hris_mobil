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

  BoxDecoration _surfaceDecoration() => BoxDecoration(
    color: _surfaceColor,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: _surfaceBorderColor),
    boxShadow: _isDarkMode
        ? const []
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
  );

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
          actions: [
            IconButton(
              onPressed: leaveProvider.isLoading
                  ? null
                  : () => leaveProvider.fetchLeaveData(),
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: _secondaryTextColor,
            indicatorColor: AppColors.primary,
            tabs: [
              const Tab(text: 'Requests'),
              if (canManageCompanyLeave) const Tab(text: 'Company Leave'),
            ],
          ),
        ),
        body: leaveProvider.isLoading && leaveProvider.leaveRequests.isEmpty
            ? const Center(child: CircularProgressIndicator())
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

    return RefreshIndicator(
      onRefresh: leaveProvider.fetchLeaveData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (companyCode.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: _isDarkMode ? 0.16 : 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.withValues(
                    alpha: _isDarkMode ? 0.24 : 0.15,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Company: $companyCode',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Requests: ${requests.length} | Company leave: ${requests.where((request) => request.isCompanyLeave).length}',
                    style: TextStyle(color: _secondaryTextColor),
                  ),
                ],
              ),
            ),
          if (requests.isEmpty) ...[
            const SizedBox(height: 140),
            Icon(
              Icons.inbox_outlined,
              size: 56,
              color: _secondaryTextColor.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'No leave requests found',
                style: TextStyle(color: _secondaryTextColor, fontSize: 16),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            ...requests.map(
              (request) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LeaveRequestManagementCard(request: request),
              ),
            ),
          ],
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
                    decoration: InputDecoration(
                      labelText: 'Title',
                      labelStyle: TextStyle(color: _secondaryTextColor),
                      filled: true,
                      fillColor: _surfaceMutedColor,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: TextStyle(color: _primaryTextColor),
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: _secondaryTextColor),
                      filled: true,
                      fillColor: _surfaceMutedColor,
                      border: const OutlineInputBorder(),
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
            Container(
              decoration: _surfaceDecoration(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy_outlined,
                      size: 40,
                      color: _secondaryTextColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No company leave batches yet',
                      style: TextStyle(color: _secondaryTextColor),
                    ),
                  ],
                ),
              ),
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
    final surfaceColor = isDarkMode ? const Color(0xFF111827) : Colors.white;
    final surfaceMutedColor = isDarkMode
        ? const Color(0xFF0F172A)
        : Colors.grey.shade100;
    final surfaceBorderColor = isDarkMode
        ? const Color(0xFF253041)
        : AppColors.border;
    final primaryTextColor = isDarkMode
        ? const Color(0xFFF8FAFC)
        : AppColors.textPrimary;
    final secondaryTextColor = isDarkMode
        ? const Color(0xFFCBD5E1)
        : AppColors.textSecondary;
    final leaveProvider = context.read<LeaveProvider>();
    final canApprove =
        request.status.toLowerCase() == 'pending' && !request.isCompanyLeave;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: surfaceBorderColor),
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
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Company Leave',
                                style: TextStyle(
                                  color: Colors.blue,
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
                        side: BorderSide(color: surfaceBorderColor),
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
      builder: (context) => AlertDialog(
        title: Text('${approved ? 'Approve' : 'Reject'} Leave Request'),
        content: Text(
          'Are you sure you want to ${approved ? 'approve' : 'reject'} this leave request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(approved ? 'Approve' : 'Reject'),
          ),
        ],
      ),
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
    final surfaceColor = isDarkMode ? const Color(0xFF111827) : Colors.white;
    final surfaceBorderColor = isDarkMode
        ? const Color(0xFF253041)
        : AppColors.border;
    final primaryTextColor = isDarkMode
        ? const Color(0xFFF8FAFC)
        : AppColors.textPrimary;
    final secondaryTextColor = isDarkMode
        ? const Color(0xFFCBD5E1)
        : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: surfaceBorderColor),
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
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    batch.leaveType,
                    style: const TextStyle(
                      color: Colors.blue,
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
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
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
    final surfaceColor = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final surfaceBorderColor = isDarkMode
        ? const Color(0xFF253041)
        : Colors.grey.shade300;
    final primaryTextColor = isDarkMode
        ? const Color(0xFFF8FAFC)
        : AppColors.textPrimary;
    final secondaryTextColor = isDarkMode
        ? const Color(0xFFCBD5E1)
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
        ? const Color(0xFFF8FAFC)
        : AppColors.textPrimary;
    final secondaryTextColor = isDarkMode
        ? const Color(0xFFCBD5E1)
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
        ? const Color(0xFFCBD5E1)
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
