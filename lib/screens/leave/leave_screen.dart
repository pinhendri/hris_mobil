import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/leave_provider.dart';
import '../../models/leave_model.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/image_helper.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  String _selectedType = 'Annual Leave';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isSubmitting = false;

  String? _employeeName;
  String? _companyCode;
  Map<String, dynamic>? _userBalance;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  int _calculateDays(DateTime start, DateTime end) {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    return endDate.difference(startDate).inDays + 1;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final leaveProvider = Provider.of<LeaveProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final cCode = authProvider.getCompanyCode();
    if (cCode.isNotEmpty) {
      leaveProvider.setCompanyCode(cCode);
    }

    setState(() {
      _employeeName = authProvider.user?.name ?? 'User';
      _companyCode = cCode;
    });

    await leaveProvider.fetchLeaveData();

    if (leaveProvider.leaveBalance != null) {
      setState(() {
        _userBalance = {
          'annual': {
            'used': leaveProvider.leaveBalance?.annualUsed ?? 0,
            'total': leaveProvider.leaveBalance?.annualTotal ?? 25,
          },
          'sick': {
            'used': leaveProvider.leaveBalance?.sickUsed ?? 0,
            'total': leaveProvider.leaveBalance?.sickTotal ?? 10,
          },
          'personal': {
            'used': leaveProvider.leaveBalance?.personalUsed ?? 0,
            'total': leaveProvider.leaveBalance?.personalTotal ?? 5,
          },
        };
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    String displayStatus = status;

    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case 'pending sync':
        color = Colors.orange;
        icon = Icons.cloud_upload_outlined;
        displayStatus = 'Pending Sync';
        break;
      case 'pending':
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
        displayStatus = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            displayStatus,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  int? _getRemainingDays(String type) {
    if (_userBalance == null) return null;

    try {
      switch (type) {
        case 'Annual Leave':
          final used = _userBalance!['annual']['used'] as int;
          final total = _userBalance!['annual']['total'] as int;
          return total - used;
        case 'Sick Leave':
          final used = _userBalance!['sick']['used'] as int;
          final total = _userBalance!['sick']['total'] as int;
          return total - used;
        case 'Personal Leave':
          final used = _userBalance!['personal']['used'] as int;
          final total = _userBalance!['personal']['total'] as int;
          return total - used;
        default:
          return null;
      }
    } catch (e) {
      print('Error calculating remaining days: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Leave Management',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Requests'),
            Tab(text: 'Apply'),
            Tab(text: 'Balance'),
          ],
        ),
      ),
      body: Consumer<LeaveProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${provider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearError();
                      _loadInitialData();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildRequestsList(provider.leaveRequests),
              _buildApplyForm(context, provider),
              _buildBalanceView(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequestsList(List<LeaveRequest> requests) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    if (currentUser == null) {
      return const Center(child: Text('User not logged in'));
    }

    if (requests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No leave requests found',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];

        final bool isMyRequest =
            request.uuid == (currentUser.employeeUuid ?? currentUser.uuid);
        final bool isImmediateSupervisor =
            currentUser.uuid == request.immediateSupervisor;

        final bool showApproveRejectButtons =
            request.status.toLowerCase() == 'pending' &&
            !isMyRequest &&
            !request.isCompanyLeave;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header dengan Avatar dan Nama
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            backgroundImage: ImageHelper.avatar(
                              request.avatarUrl,
                            ),
                            child:
                                (request.avatarUrl == null ||
                                    request.avatarUrl!.isEmpty)
                                ? Text(
                                    request.employeeName
                                        .substring(0, 2)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.employeeName.isNotEmpty
                                      ? request.employeeName
                                      : 'Unknown Employee',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  request.type,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (request.isCompanyLeave)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Company Leave',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                if (isMyRequest)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Your Request',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                if (isImmediateSupervisor &&
                                    !isMyRequest &&
                                    request.status.toLowerCase() == 'pending')
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Need Your Approval',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(request.status),
                  ],
                ),

                const SizedBox(height: 16),

                // Date and Duration Info
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoColumn(
                        'Start Date',
                        _formatDate(request.startDate),
                      ),
                    ),
                    Expanded(
                      child: _buildInfoColumn(
                        'End Date',
                        _formatDate(request.endDate),
                      ),
                    ),
                    Expanded(
                      child: _buildInfoColumn(
                        'Duration',
                        '${request.days} ${request.days == 1 ? 'day' : 'days'}',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Reason
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reason',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.reason.isNotEmpty
                            ? request.reason
                            : (request.isCompanyLeave
                                  ? 'Company leave assigned by HR/Admin.'
                                  : '-'),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // 🔴 BUTTON APPROVE/REJECT - HANYA UNTUK ATASAN (immediateSupervisor)
                if (showApproveRejectButtons) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleApproveReject(
                            context,
                            request,
                            'Approved',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Approve'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleApproveReject(
                            context,
                            request,
                            'Rejected',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                    ],
                  ),
                ],

                // 🔴 INFO UNTUK USER YANG MENGAJUKAN REQUEST (bukan atasan)
                if (isMyRequest) ...[
                  if (request.status.toLowerCase() == 'pending')
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your request is waiting for approval from your manager.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (request.status.toLowerCase() == 'approved')
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your request has been approved.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (request.status.toLowerCase() == 'rejected')
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.cancel,
                              size: 16,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your request has been rejected.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // 🔴 METHOD UNTUK HANDLE APPROVE/REJECT
  Future<void> _handleApproveReject(
    BuildContext context,
    LeaveRequest request,
    String status,
  ) async {
    final provider = Provider.of<LeaveProvider>(context, listen: false);

    try {
      bool success;
      if (status == 'Approved') {
        success = await provider.approveRequest(request.id);
      } else {
        success = await provider.rejectRequest(request.id);
      }

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request ${status.toLowerCase()} successfully'),
            backgroundColor: status == 'Approved' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error $status: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to $status request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildApplyForm(BuildContext context, LeaveProvider provider) {
    // Ambil authProvider untuk validasi
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    // Validasi user login
    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            const Text(
              'User not logged in',
              style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
    }

    // 🔴 CEK COMPANY CODE DARI STATE
    if (_companyCode == null || _companyCode!.isEmpty) {
      // Coba ambil lagi dari AuthProvider
      final freshCode = authProvider.getCompanyCode();
      if (freshCode.isNotEmpty) {
        // Update state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _companyCode = freshCode;
          });
        });
      } else {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Company code not found',
                style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Please contact HR or try again later',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadInitialData,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
    }

    final remainingDays = _getRemainingDays(_selectedType) ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Request Leave',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Employee: $_employeeName',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Company: $_companyCode',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Leave Type Dropdown
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: 'Leave Type',
                  ),
                  value: _selectedType,
                  items: ['Annual Leave', 'Sick Leave', 'Personal Leave'].map((
                    type,
                  ) {
                    final remaining = _getRemainingDays(type) ?? 0;
                    return DropdownMenuItem(
                      value: type,
                      child: Text('$type ($remaining days left)'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Start Date
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: InkWell(
                onTap: () => _selectDate(context, true),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Start Date'),
                      Row(
                        children: [
                          Text(
                            DateFormat('dd MMM yyyy').format(_startDate),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.calendar_today, size: 18),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // End Date
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: InkWell(
                onTap: () => _selectDate(context, false),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('End Date'),
                      Row(
                        children: [
                          Text(
                            DateFormat('dd MMM yyyy').format(_endDate),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.calendar_today, size: 18),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Duration
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Duration:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_calculateDays(_startDate, _endDate)} days',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Reason Field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Reason is required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),

            // Balance Info
            if (_userBalance != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Leave Balance:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildBalanceInfo(
                          'Annual',
                          (_userBalance!['annual']['total'] as int) -
                              (_userBalance!['annual']['used'] as int),
                        ),
                        _buildBalanceInfo(
                          'Sick',
                          (_userBalance!['sick']['total'] as int) -
                              (_userBalance!['sick']['used'] as int),
                        ),
                        _buildBalanceInfo(
                          'Personal',
                          (_userBalance!['personal']['total'] as int) -
                              (_userBalance!['personal']['used'] as int),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    _isSubmitting ||
                        remainingDays < _calculateDays(_startDate, _endDate)
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          await _submitLeaveRequest(context, provider);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Request ${_calculateDays(_startDate, _endDate)} ${_calculateDays(_startDate, _endDate) == 1 ? 'day' : 'days'} Leave',
                      ),
              ),
            ),

            if (remainingDays < _calculateDays(_startDate, _endDate))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Insufficient balance. You only have $remainingDays days left.',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceInfo(String label, int days) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          '$days days',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Future<void> _submitLeaveRequest(
    BuildContext context,
    LeaveProvider provider,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Validasi user login
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 🔴 CEK APAKAH PROVIDER SUDAH PUNYA NUMERIC EMPLOYEE_ID
    if (provider.correctEmployeeId == null) {
      // Tampilkan loading dan fetch data dulu
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading employee data...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Fetch leave data untuk mendapatkan employee_id yang benar
      await provider.fetchLeaveData();

      if (provider.correctEmployeeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get employee ID. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // 🔴 CEK COMPANY CODE
    String companyCode = _companyCode ?? '';
    if (companyCode.isEmpty) {
      companyCode = authProvider.getCompanyCode();
      if (companyCode.isNotEmpty) {
        setState(() {
          _companyCode = companyCode;
        });
      }
    }

    if (companyCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company code not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final days = _calculateDays(_startDate, _endDate);
    final remaining = _getRemainingDays(_selectedType) ?? 0;

    if (days > remaining) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient balance. You only have $remaining days left.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // PANGGIL METHOD DENGAN COMPANY CODE
      final success = await provider.submitLeaveRequest(
        type: _selectedType,
        startDate: _startDate,
        endDate: _endDate,
        days: days,
        reason: _reasonController.text,
        cCode: companyCode,
      );

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.lastActionMessage ??
                  'Leave requested successfully for $days days',
            ),
            backgroundColor: provider.lastActionQueued
                ? Colors.orange
                : Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Reset form
        _reasonController.clear();
        setState(() {
          _startDate = DateTime.now();
          _endDate = DateTime.now();
          _selectedType = 'Annual Leave';
          _isSubmitting = false;
        });

        // Switch to Requests tab
        _tabController.animateTo(0);

        // Refresh data
        await provider.fetchLeaveData();

        // Update balance
        if (provider.leaveBalance != null) {
          setState(() {
            _userBalance = {
              'annual': {
                'used': provider.leaveBalance?.annualUsed ?? 0,
                'total': provider.leaveBalance?.annualTotal ?? 25,
              },
              'sick': {
                'used': provider.leaveBalance?.sickUsed ?? 0,
                'total': provider.leaveBalance?.sickTotal ?? 10,
              },
              'personal': {
                'used': provider.leaveBalance?.personalUsed ?? 0,
                'total': provider.leaveBalance?.personalTotal ?? 5,
              },
            };
          });
        }

        // 🔴 HAPUS BAGIAN NOTIFIKASI INI KARENA SUDAH DITANGANI BACKEND
        // Notifikasi akan dibuat otomatis oleh backend (Laravel)
        // Ke atasan: "Staff {$employee->name} mengajukan {$leaveRequest->type}..."
      } else if (context.mounted) {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to submit request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildBalanceView() {
    if (_userBalance == null) {
      return const Center(child: Text('No balance data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildBalanceCard(
            'Annual Leave',
            _userBalance!['annual']['used'] as int,
            _userBalance!['annual']['total'] as int,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildBalanceCard(
            'Sick Leave',
            _userBalance!['sick']['used'] as int,
            _userBalance!['sick']['total'] as int,
            Colors.red,
          ),
          const SizedBox(height: 16),
          _buildBalanceCard(
            'Personal Leave',
            _userBalance!['personal']['used'] as int,
            _userBalance!['personal']['total'] as int,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(String title, int used, int total, Color color) {
    final remaining = total - used;
    double percentage = 0.0;
    if (total > 0) {
      percentage = (used / total).clamp(0.0, 1.0);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$remaining days left',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: percentage,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Used: $used days',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Total: $total days',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
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
