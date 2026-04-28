import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class OvertimeScreen extends StatefulWidget {
  const OvertimeScreen({super.key});

  @override
  State<OvertimeScreen> createState() => _OvertimeScreenState();
}

class _OvertimeScreenState extends State<OvertimeScreen> {
  static const Color _accentColor = Color(0xFFFF9628);
  static const Color _lightBackground = Color(0xFFF6F4F1);
  static const Color _darkBackground = Color(0xFF121212);
  static const List<String> _adminRoles = [
    'administrator',
    'admin',
    'hrd',
    'hr-admin',
    'superadmin',
    'super-admin',
  ];

  final ApiService _apiService = ApiService();
  final TextEditingController _projectCodeController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isAdminUser = false;
  String? _errorMessage;
  List<_OvertimeEmployeeOption> _employees = const [];
  List<_OvertimeRequestItem> _requests = const [];
  _OvertimeEmployeeOption? _currentEmployee;
  int? _selectedEmployeeId;
  int? _editingId;
  DateTime? _requestDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _projectCodeController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accessLabel = _resolveAccessLabel(authProvider);

    return Scaffold(
      backgroundColor: isDark ? _darkBackground : _lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Overtime Requests', style: _titleStyle(isDark, size: 18)),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: _accentColor,
                onRefresh: _loadData,
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
                    _buildSummaryCard(isDark, accessLabel: accessLabel),
                    const SizedBox(height: 16),
                    _buildFormCard(isDark),
                    const SizedBox(height: 16),
                    _buildRequestsCard(isDark),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark, {required String accessLabel}) {
    return _buildSurfaceCard(
      isDark: isDark,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: _accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submit Overtime',
                      style: _titleStyle(isDark, size: 17),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isAdminUser
                          ? 'Create, review, and approve overtime requests.'
                          : 'Create and track your overtime requests.',
                      style: _bodyStyle(isDark, size: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                label: 'Requests: ${_requests.length}',
                color: const Color(0xFF3478F6),
                isDark: isDark,
              ),
              _buildInfoChip(
                label: accessLabel,
                color: accessLabel == 'Admin access'
                    ? const Color(0xFF2F9D78)
                    : accessLabel == 'Approver access'
                    ? const Color(0xFF8B5CF6)
                    : _accentColor,
                isDark: isDark,
              ),
              if (_currentEmployee != null)
                _buildInfoChip(
                  label: _currentEmployee!.name,
                  color: _accentColor,
                  isDark: isDark,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(bool isDark) {
    return _buildSurfaceCard(
      isDark: isDark,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _editingId == null
                      ? 'Create Overtime Request'
                      : 'Edit Overtime Request',
                  style: _titleStyle(isDark, size: 17),
                ),
              ),
              if (_editingId != null)
                TextButton(
                  onPressed: _isSubmitting ? null : _resetForm,
                  child: const Text('Cancel'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (_errorMessage != null) ...[
            _buildInlineMessage(
              isDark: isDark,
              message: _errorMessage!,
              tone: const Color(0xFFD5534F),
            ),
            const SizedBox(height: 14),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 620;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isAdminUser)
                    DropdownButtonFormField<int>(
                      key: ValueKey<int?>(_selectedEmployeeId),
                      initialValue:
                          _employees.any(
                            (employee) => employee.id == _selectedEmployeeId,
                          )
                          ? _selectedEmployeeId
                          : null,
                      decoration: _inputDecoration(
                        isDark,
                        label: 'Employee',
                        hint: 'Select employee',
                      ),
                      items: _employees
                          .map(
                            (employee) => DropdownMenuItem<int>(
                              value: employee.id,
                              child: Text(employee.name),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              setState(() {
                                _selectedEmployeeId = value;
                              });
                            },
                    )
                  else
                    _buildReadOnlyField(
                      isDark,
                      label: 'Employee',
                      value:
                          _currentEmployee?.name ?? 'Employee login not found',
                      helperText: _currentEmployee == null
                          ? 'Your employee profile was not found in the overtime endpoint yet.'
                          : 'Employee follows the user who is currently logged in.',
                    ),
                  const SizedBox(height: 12),
                  if (isCompact) ...[
                    _buildDatePickerField(isDark),
                    const SizedBox(height: 12),
                    _buildTimePickerField(
                      isDark,
                      label: 'Start Time',
                      value: _startTime,
                      onTap: _pickStartTime,
                    ),
                    const SizedBox(height: 12),
                    _buildTimePickerField(
                      isDark,
                      label: 'End Time',
                      value: _endTime,
                      onTap: _pickEndTime,
                    ),
                  ] else
                    Row(
                      children: [
                        Expanded(child: _buildDatePickerField(isDark)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTimePickerField(
                            isDark,
                            label: 'Start Time',
                            value: _startTime,
                            onTap: _pickStartTime,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTimePickerField(
                            isDark,
                            label: 'End Time',
                            value: _endTime,
                            onTap: _pickEndTime,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _projectCodeController,
                    enabled: !_isSubmitting,
                    decoration: _inputDecoration(
                      isDark,
                      label: 'Project Code',
                      hint: 'Optional project code',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reasonController,
                    enabled: !_isSubmitting,
                    minLines: 3,
                    maxLines: 4,
                    decoration: _inputDecoration(
                      isDark,
                      label: 'Reason',
                      hint: 'Tell why overtime is needed',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    enabled: !_isSubmitting,
                    minLines: 2,
                    maxLines: 3,
                    decoration: _inputDecoration(
                      isDark,
                      label: 'Notes',
                      hint: 'Optional notes',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            _isSubmitting
                                ? 'Saving...'
                                : _editingId == null
                                ? 'Submit Request'
                                : 'Update Request',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsCard(bool isDark) {
    return _buildSurfaceCard(
      isDark: isDark,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overtime Register', style: _titleStyle(isDark, size: 17)),
          const SizedBox(height: 6),
          Text(
            'Track submitted overtime requests and approval status.',
            style: _bodyStyle(isDark, size: 13),
          ),
          const SizedBox(height: 14),
          if (_requests.isEmpty)
            _buildInlineMessage(
              isDark: isDark,
              message: 'No overtime requests found.',
              tone: const Color(0xFF6B7280),
            )
          else
            Column(
              children: [
                for (var index = 0; index < _requests.length; index++) ...[
                  _buildRequestItem(isDark, _requests[index]),
                  if (index != _requests.length - 1) ...[
                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: _surfaceBorderColor(isDark),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRequestItem(bool isDark, _OvertimeRequestItem request) {
    final statusColor = _statusColor(request.status);
    final authProvider = context.read<AuthProvider>();
    final canEdit = _canEditRequest(authProvider, request);
    final canApprove = _canApproveRequest(authProvider, request);
    final canReject = canApprove;
    final canDelete = canEdit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: isDark ? 0.20 : 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.av_timer_rounded,
                color: _accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.employeeName,
                    style: _titleStyle(isDark, size: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy').format(request.requestDate),
                    style: _bodyStyle(isDark, size: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: isDark ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                request.displayStatus,
                style: _bodyStyle(
                  isDark,
                  size: 11,
                  weight: FontWeight.w700,
                  color: statusColor,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildMetaChip(
              isDark: isDark,
              icon: Icons.schedule_outlined,
              label: '${request.startTimeLabel} - ${request.endTimeLabel}',
            ),
            _buildMetaChip(
              isDark: isDark,
              icon: Icons.hourglass_bottom_rounded,
              label: request.hoursLabel,
            ),
            if (request.projectCode?.trim().isNotEmpty == true)
              _buildMetaChip(
                isDark: isDark,
                icon: Icons.confirmation_number_outlined,
                label: request.projectCode!,
              ),
            if (request.approverName?.trim().isNotEmpty == true)
              _buildMetaChip(
                isDark: isDark,
                icon: Icons.verified_user_outlined,
                label: request.approverName!,
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(request.reason, style: _bodyStyle(isDark, size: 13, height: 1.45)),
        if (request.notes?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 6),
          Text(
            request.notes!,
            style: _bodyStyle(isDark, size: 12, color: statusColor),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (canEdit)
              OutlinedButton(
                onPressed: _isSubmitting ? null : () => _startEditing(request),
                child: const Text('Edit'),
              ),
            if (canApprove)
              OutlinedButton(
                onPressed: _isSubmitting
                    ? null
                    : () => _approveRequest(request.id),
                child: const Text('Approve'),
              ),
            if (canReject)
              OutlinedButton(
                onPressed: _isSubmitting
                    ? null
                    : () => _rejectRequest(request.id),
                child: const Text('Reject'),
              ),
            if (canDelete)
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => _deleteRequest(request.id),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFD5534F),
                ),
                child: const Text('Delete'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePickerField(bool isDark) {
    return InkWell(
      onTap: _isSubmitting ? null : _pickDate,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _inputDecoration(
          isDark,
          label: 'Request Date',
          hint: 'Select date',
        ),
        child: Text(
          _requestDate == null
              ? 'Select date'
              : DateFormat('yyyy-MM-dd').format(_requestDate!),
          style: _bodyStyle(
            isDark,
            size: 13,
            color: _requestDate == null
                ? (isDark ? Colors.white54 : const Color(0xFF9CA3AF))
                : (isDark ? Colors.white : const Color(0xFF1F2937)),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePickerField(
    bool isDark, {
    required String label,
    required TimeOfDay? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isSubmitting ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _inputDecoration(isDark, label: label, hint: 'Select time'),
        child: Text(
          value == null ? 'Select time' : _formatTimeOfDay(value),
          style: _bodyStyle(
            isDark,
            size: 13,
            color: value == null
                ? (isDark ? Colors.white54 : const Color(0xFF9CA3AF))
                : (isDark ? Colors.white : const Color(0xFF1F2937)),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(
    bool isDark, {
    required String label,
    required String value,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InputDecorator(
          decoration: _inputDecoration(isDark, label: label),
          child: Text(
            value,
            style: _bodyStyle(
              isDark,
              size: 13,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(helperText, style: _bodyStyle(isDark, size: 12)),
        ],
      ],
    );
  }

  Widget _buildInlineMessage({
    required bool isDark,
    required String message,
    required Color tone,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: _bodyStyle(
          isDark,
          size: 13,
          weight: FontWeight.w600,
          color: tone,
        ),
      ),
    );
  }

  Widget _buildMetaChip({
    required bool isDark,
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF8F6F2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? Colors.white70 : const Color(0xFF6B7280),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: _bodyStyle(isDark, size: 11, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildSurfaceCard({
    required bool isDark,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _surfaceColor(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _surfaceBorderColor(isDark)),
        boxShadow: _surfaceShadows(isDark),
      ),
      child: child,
    );
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.get('/overtime');
      final payload = response is Map<String, dynamic>
          ? (response['data'] is Map<String, dynamic>
                ? response['data'] as Map<String, dynamic>
                : response)
          : const <String, dynamic>{};

      final employees = _extractEmployees(payload['employees']);
      final requests = _extractRequests(payload['requests']);
      final isAdminUser = _hasAdminRole(authProvider);
      final currentEmployee = _resolveCurrentEmployee(
        authProvider,
        employees,
        requests,
      );
      final visibleEmployees = isAdminUser
          ? employees
          : currentEmployee != null
          ? <_OvertimeEmployeeOption>[currentEmployee]
          : employees;

      if (!mounted) {
        return;
      }

      setState(() {
        _isAdminUser = isAdminUser;
        _employees = visibleEmployees;
        _requests = requests;
        _currentEmployee = currentEmployee;
        _selectedEmployeeId = isAdminUser
            ? _selectedEmployeeId
            : currentEmployee?.id;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _submitRequest() async {
    final employeeId = _isAdminUser
        ? _selectedEmployeeId
        : _currentEmployee?.id;

    if (employeeId == null ||
        _requestDate == null ||
        _startTime == null ||
        _endTime == null ||
        _reasonController.text.trim().isEmpty) {
      setState(() {
        _errorMessage =
            'Employee, request date, time, and reason are required.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final payload = <String, dynamic>{
      'employee_id': employeeId,
      'request_date': DateFormat('yyyy-MM-dd').format(_requestDate!),
      'start_time': _formatTimeOfDay(_startTime!),
      'end_time': _formatTimeOfDay(_endTime!),
      'project_code': _projectCodeController.text.trim(),
      'reason': _reasonController.text.trim(),
      'notes': _notesController.text.trim(),
    };

    try {
      if (_editingId == null) {
        await _apiService.post('/overtime', payload);
      } else {
        await _apiService.put('/overtime/$_editingId', payload);
      }

      if (!mounted) {
        return;
      }

      _resetForm();
      await _loadData();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isSubmitting = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _approveRequest(int requestId) async {
    try {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });
      await _apiService.post('/overtime/$requestId/approve', {});
      await _loadData();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _rejectRequest(int requestId) async {
    final note = await _showRejectDialog();
    if (note == null) {
      return;
    }

    try {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });
      await _apiService.post('/overtime/$requestId/reject', {'notes': note});
      await _loadData();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _deleteRequest(int requestId) async {
    try {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });
      await _apiService.delete('/overtime/$requestId');
      await _loadData();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _requestDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _requestDate = pickedDate;
    });
  }

  Future<void> _pickStartTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 18, minute: 0),
    );

    if (pickedTime == null) {
      return;
    }

    setState(() {
      _startTime = pickedTime;
    });
  }

  Future<void> _pickEndTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 20, minute: 0),
    );

    if (pickedTime == null) {
      return;
    }

    setState(() {
      _endTime = pickedTime;
    });
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: _surfaceColor(isDark),
          title: Text(
            'Reject Overtime Request',
            style: _titleStyle(isDark, size: 17),
          ),
          content: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 4,
            decoration: _inputDecoration(
              isDark,
              label: 'Reason',
              hint: 'Enter rejection notes',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, controller.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD5534F),
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  void _startEditing(_OvertimeRequestItem request) {
    setState(() {
      _editingId = request.id;
      _selectedEmployeeId = _isAdminUser
          ? request.employeeId
          : _currentEmployee?.id;
      _requestDate = request.requestDate;
      _startTime = _parseTime(request.startTimeRaw);
      _endTime = _parseTime(request.endTimeRaw);
      _projectCodeController.text = request.projectCode ?? '';
      _reasonController.text = request.reason;
      _notesController.text = request.notes ?? '';
      _errorMessage = null;
    });
  }

  void _resetForm() {
    setState(() {
      _editingId = null;
      _requestDate = null;
      _startTime = null;
      _endTime = null;
      _selectedEmployeeId = _isAdminUser ? null : _currentEmployee?.id;
      _projectCodeController.clear();
      _reasonController.clear();
      _notesController.clear();
      _errorMessage = null;
    });
  }

  List<_OvertimeEmployeeOption> _extractEmployees(dynamic rawEmployees) {
    if (rawEmployees is! List) {
      return const [];
    }

    return rawEmployees
        .whereType<Map>()
        .map(
          (item) =>
              _OvertimeEmployeeOption.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.id > 0)
        .toList(growable: false);
  }

  List<_OvertimeRequestItem> _extractRequests(dynamic rawRequests) {
    if (rawRequests is! List) {
      return const [];
    }

    return rawRequests
        .whereType<Map>()
        .map(
          (item) =>
              _OvertimeRequestItem.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  bool _hasAdminRole(AuthProvider authProvider) {
    final normalizedRoles = <String>{
      ...authProvider.roles.map(_normalizeRole),
      _normalizeRole(authProvider.user?.role ?? ''),
    }..removeWhere((role) => role.isEmpty);

    return normalizedRoles.any(_adminRoles.contains);
  }

  String _resolveAccessLabel(AuthProvider authProvider) {
    if (_isAdminUser) {
      return 'Admin access';
    }

    if (_requests.any((request) => _canApproveRequest(authProvider, request))) {
      return 'Approver access';
    }

    if (_requests.any((request) => _canEditRequest(authProvider, request))) {
      return 'Member access';
    }

    return 'Viewer access';
  }

  bool _canEditRequest(
    AuthProvider authProvider,
    _OvertimeRequestItem request,
  ) {
    final normalizedStatus = request.status.trim().toLowerCase();
    final isEditableStatus =
        normalizedStatus == 'pending' || normalizedStatus == 'rejected';

    return isEditableStatus &&
        (_isAdminUser || _isOwnRequest(authProvider, request));
  }

  bool _canApproveRequest(
    AuthProvider authProvider,
    _OvertimeRequestItem request,
  ) {
    if (!request.isPending) {
      return false;
    }

    final currentUserId = authProvider.user?.id;
    final currentUserUuid = _normalizeValue(authProvider.user?.uuid);

    return _isAdminUser ||
        (currentUserId != null && request.approverId == currentUserId) ||
        (currentUserUuid.isNotEmpty &&
            request.employeeImmediateSupervisor == currentUserUuid);
  }

  bool _isOwnRequest(AuthProvider authProvider, _OvertimeRequestItem request) {
    final currentEmployeeUuid = _normalizeValue(
      authProvider.user?.employeeUuid ?? authProvider.user?.uuid,
    );
    final matchesById =
        _currentEmployee != null &&
        _currentEmployee!.id > 0 &&
        request.employeeId == _currentEmployee!.id;
    final matchesByUuid =
        currentEmployeeUuid.isNotEmpty &&
        _normalizeValue(request.employeeUuid) == currentEmployeeUuid;
    return matchesById || matchesByUuid;
  }

  _OvertimeEmployeeOption? _resolveCurrentEmployee(
    AuthProvider authProvider,
    List<_OvertimeEmployeeOption> employees,
    List<_OvertimeRequestItem> requests,
  ) {
    final employeeUuid = _normalizeValue(
      authProvider.user?.employeeUuid ?? authProvider.user?.uuid,
    );

    if (employeeUuid.isNotEmpty) {
      for (final employee in employees) {
        if (_normalizeValue(employee.uuid) == employeeUuid) {
          return employee;
        }
      }

      for (final request in requests) {
        if (_normalizeValue(request.employeeUuid) == employeeUuid &&
            request.employeeId > 0) {
          return _OvertimeEmployeeOption(
            id: request.employeeId,
            uuid: request.employeeUuid ?? '',
            name: request.employeeName,
          );
        }
      }
    }

    return null;
  }

  String _normalizeRole(String value) {
    return value.trim().toLowerCase().replaceAll('_', '-');
  }

  String _normalizeValue(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  TimeOfDay _parseTime(String rawValue) {
    final normalizedValue = rawValue.trim();
    final parts = normalizedValue.split(':');
    if (parts.length < 2) {
      return const TimeOfDay(hour: 0, minute: 0);
    }

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTimeOfDay(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return const Color(0xFF2F9D78);
      case 'rejected':
        return const Color(0xFFD5534F);
      default:
        return _accentColor;
    }
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
    Color? color,
    double height = 1.2,
  }) {
    return TextStyle(
      color: color ?? (isDark ? Colors.white : const Color(0xFF1F2937)),
      fontSize: size,
      fontWeight: weight,
      height: height,
    );
  }

  TextStyle _bodyStyle(
    bool isDark, {
    double size = 13,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double height = 1.4,
  }) {
    return TextStyle(
      color: color ?? (isDark ? Colors.white60 : const Color(0xFF6B7280)),
      fontSize: size,
      fontWeight: weight,
      height: height,
    );
  }

  Widget _buildInfoChip({
    required String label,
    required bool isDark,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: _bodyStyle(
          isDark,
          size: 11,
          weight: FontWeight.w700,
          color: color,
          height: 1.2,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    bool isDark, {
    required String label,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : const Color(0xFFF8F6F2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _surfaceBorderColor(isDark)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _surfaceBorderColor(isDark)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accentColor),
      ),
    );
  }
}

class _OvertimeEmployeeOption {
  const _OvertimeEmployeeOption({
    required this.id,
    required this.uuid,
    required this.name,
  });

  final int id;
  final String uuid;
  final String name;

  factory _OvertimeEmployeeOption.fromJson(Map<String, dynamic> json) {
    return _OvertimeEmployeeOption(
      id: _parseInt(json['id'] ?? json['employee_id']),
      uuid: (json['uuid'] ?? json['employee_uuid'] ?? '').toString().trim(),
      name: (json['name'] ?? '').toString().trim(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _OvertimeRequestItem {
  const _OvertimeRequestItem({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.requestDate,
    required this.startTimeRaw,
    required this.endTimeRaw,
    required this.hours,
    required this.reason,
    required this.status,
    this.employeeUuid,
    this.employeeImmediateSupervisor,
    this.projectCode,
    this.notes,
    this.approverId,
    this.approverName,
  });

  final int id;
  final int employeeId;
  final String? employeeUuid;
  final String? employeeImmediateSupervisor;
  final String employeeName;
  final DateTime requestDate;
  final String startTimeRaw;
  final String endTimeRaw;
  final double hours;
  final String? projectCode;
  final String reason;
  final String status;
  final String? notes;
  final int? approverId;
  final String? approverName;

  factory _OvertimeRequestItem.fromJson(Map<String, dynamic> json) {
    final employeeRaw = json['employee'];
    final employee = employeeRaw is Map<String, dynamic> ? employeeRaw : null;
    final approverRaw = json['approver'];
    final approver = approverRaw is Map<String, dynamic> ? approverRaw : null;

    return _OvertimeRequestItem(
      id: _parseInt(json['id']),
      employeeId: _parseInt(
        json['employee_id'] ?? (employee != null ? employee['id'] : null),
      ),
      employeeUuid:
          (employee != null ? employee['uuid'] : json['employee_uuid'])
              ?.toString()
              .trim(),
      employeeImmediateSupervisor: _normalizeValue(
        employee != null
            ? employee['immediate_supervisor']
            : json['employee_immediate_supervisor'],
      ),
      employeeName:
          (employee != null ? employee['name'] : json['employee_name'])
              ?.toString()
              .trim() ??
          '-',
      requestDate: _parseDate(json['request_date']),
      startTimeRaw: (json['start_time'] ?? '').toString().trim(),
      endTimeRaw: (json['end_time'] ?? '').toString().trim(),
      hours: _parseDouble(json['hours']),
      projectCode: json['project_code']?.toString().trim(),
      reason: (json['reason'] ?? '').toString().trim(),
      status: (json['status'] ?? 'pending').toString().trim(),
      notes: json['notes']?.toString().trim(),
      approverId: _parseInt(
        approver != null ? approver['id'] : json['approver_id'],
      ),
      approverName: (approver != null ? approver['name'] : null)
          ?.toString()
          .trim(),
    );
  }

  String get displayStatus {
    final normalizedStatus = status.trim().toLowerCase();
    if (normalizedStatus == 'approved') {
      return 'Approved';
    }
    if (normalizedStatus == 'rejected') {
      return 'Rejected';
    }
    return 'Pending';
  }

  bool get isPending {
    final normalizedStatus = status.trim().toLowerCase();
    return normalizedStatus == 'pending' || normalizedStatus == 'submitted';
  }

  String get startTimeLabel => _normalizeTimeLabel(startTimeRaw);

  String get endTimeLabel => _normalizeTimeLabel(endTimeRaw);

  String get hoursLabel {
    if (hours <= 0) {
      return '0h';
    }

    final roundedHours = hours.roundToDouble();
    if ((hours - roundedHours).abs() < 0.01) {
      return '${roundedHours.toInt()}h';
    }

    return '${hours.toStringAsFixed(1)}h';
  }

  bool matchesEmployee(_OvertimeEmployeeOption employee) {
    return employeeId == employee.id ||
        (employeeUuid?.isNotEmpty == true && employeeUuid == employee.uuid);
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _parseDate(dynamic value) {
    final rawValue = value?.toString() ?? '';
    return DateTime.tryParse(rawValue) ?? DateTime.now();
  }

  static String _normalizeTimeLabel(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      return '-';
    }

    final parts = value.split(':');
    if (parts.length < 2) {
      return value;
    }

    final hour = parts[0].padLeft(2, '0');
    final minute = parts[1].padLeft(2, '0');
    return '$hour:$minute';
  }

  static String? _normalizeValue(dynamic value) {
    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }
}
