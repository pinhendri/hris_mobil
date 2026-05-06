import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/claim_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/claim_provider.dart';

class ClaimsScreen extends StatefulWidget {
  const ClaimsScreen({super.key});

  @override
  State<ClaimsScreen> createState() => _ClaimsScreenState();
}

class _ClaimsScreenState extends State<ClaimsScreen> {
  static const Color _accentColor = Color(0xFFAA076B);
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

  final NumberFormat _idrFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final TextEditingController _categoryController = TextEditingController(
    text: 'general',
  );
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController(
    text: 'IDR',
  );
  final TextEditingController _notesController = TextEditingController();

  DateTime? _expenseDate;
  String _selectedClaimType = 'reimbursement';
  String _statusFilter = 'all';
  String? _editingId;
  int? _selectedEmployeeId;

  @override
  void dispose() {
    _categoryController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _currencyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final claimProvider = context.watch<ClaimProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBootstrapping =
        !claimProvider.isInitialized &&
        !claimProvider.isLoading &&
        claimProvider.claims.isEmpty;
    final isAdminUser = _hasAdminRole(authProvider);
    final currentUserId = authProvider.user?.id;
    final currentUserUuid = _normalizeKey(authProvider.user?.uuid);
    final currentEmployee = _resolveCurrentEmployee(
      authProvider,
      claimProvider,
    );
    final accessLabel = _resolveAccessLabel(
      claimProvider.claims,
      currentEmployee: currentEmployee,
      currentUserId: currentUserId,
      currentUserUuid: currentUserUuid,
      isAdminUser: isAdminUser,
    );

    return Scaffold(
      backgroundColor: isDark ? _darkBackground : _lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Expense Claims', style: _titleStyle(isDark, size: 18)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: claimProvider.isSubmitting
            ? null
            : () {
                _resetForm(
                  claimProvider,
                  currentEmployee: currentEmployee,
                  isAdminUser: isAdminUser,
                );
                _openClaimForm(
                  claimProvider: claimProvider,
                  authProvider: authProvider,
                  currentEmployee: currentEmployee,
                  isAdminUser: isAdminUser,
                );
              },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Claim'),
      ),
      body: SafeArea(
        child:
            (isBootstrapping ||
                (claimProvider.isLoading && claimProvider.claims.isEmpty))
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: _accentColor,
                onRefresh: claimProvider.refresh,
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
                    _buildSummaryCard(
                      isDark,
                      claimCount: claimProvider.claims.length,
                      filteredCount: _filteredClaims(
                        claimProvider.claims,
                      ).length,
                      accessLabel: accessLabel,
                      currentEmployee: currentEmployee,
                      syncNotice: claimProvider.syncNotice,
                    ),
                    const SizedBox(height: 16),
                    _buildStatusFilters(isDark, claimProvider.claims),
                    const SizedBox(height: 12),
                    _buildRegisterCard(
                      isDark,
                      claimProvider: claimProvider,
                      claims: _filteredClaims(claimProvider.claims),
                      currentEmployee: currentEmployee,
                      currentUserId: currentUserId,
                      currentUserUuid: currentUserUuid,
                      isAdminUser: isAdminUser,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryCard(
    bool isDark, {
    required int claimCount,
    required int filteredCount,
    required String accessLabel,
    required ClaimEmployeeOption? currentEmployee,
    required String? syncNotice,
  }) {
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
                  Icons.receipt_long_rounded,
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
                      'Expense Claims',
                      style: _titleStyle(isDark, size: 17),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage reimbursement, expense, and travel claims with formal approval states.',
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
                label: 'Claims: $claimCount',
                color: const Color(0xFF3478F6),
                isDark: isDark,
              ),
              _buildInfoChip(
                label: 'Shown: $filteredCount',
                color: const Color(0xFF7C3AED),
                isDark: isDark,
              ),
              _buildInfoChip(
                label: accessLabel,
                color: accessLabel == 'Admin access'
                    ? const Color(0xFF2F9D78)
                    : accessLabel == 'Approver access'
                    ? const Color(0xFF7C3AED)
                    : _accentColor,
                isDark: isDark,
              ),
              if (currentEmployee != null && currentEmployee.name.isNotEmpty)
                _buildInfoChip(
                  label: currentEmployee.name,
                  color: _accentColor,
                  isDark: isDark,
                ),
            ],
          ),
          if (syncNotice?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _buildInlineMessage(
              isDark: isDark,
              message: syncNotice!,
              tone: _accentColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormCard(
    bool isDark, {
    required ClaimProvider claimProvider,
    required AuthProvider authProvider,
    required ClaimEmployeeOption? currentEmployee,
    required bool isAdminUser,
  }) {
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
                  _editingId == null ? 'Create Claim' : 'Edit Claim',
                  style: _titleStyle(isDark, size: 17),
                ),
              ),
              if (_editingId != null)
                TextButton(
                  onPressed: claimProvider.isSubmitting
                      ? null
                      : () => _resetForm(
                          claimProvider,
                          currentEmployee: currentEmployee,
                          isAdminUser: isAdminUser,
                        ),
                  child: const Text('Cancel'),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'New submissions automatically route approval to the employee\'s direct supervisor.',
            style: _bodyStyle(isDark, size: 13),
          ),
          const SizedBox(height: 14),
          if (claimProvider.error?.trim().isNotEmpty == true) ...[
            _buildInlineMessage(
              isDark: isDark,
              message: claimProvider.error!,
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
                  if (isAdminUser)
                    DropdownButtonFormField<int>(
                      key: ValueKey<String?>(_editingId),
                      initialValue:
                          claimProvider.employees.any(
                            (employee) => employee.id == _selectedEmployeeId,
                          )
                          ? _selectedEmployeeId
                          : null,
                      decoration: _inputDecoration(
                        isDark,
                        label: 'Employee',
                        hint: 'Select employee',
                      ),
                      items: claimProvider.employees
                          .map(
                            (employee) => DropdownMenuItem<int>(
                              value: employee.id,
                              child: Text(employee.name),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: claimProvider.isSubmitting
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
                      value: currentEmployee?.name.isNotEmpty == true
                          ? currentEmployee!.name
                          : authProvider.user?.name ??
                                'Employee login not found',
                      helperText: currentEmployee == null
                          ? 'Your employee profile was not found in the claims endpoint yet.'
                          : 'Employee follows the user who is currently logged in.',
                    ),
                  const SizedBox(height: 12),
                  if (isCompact) ...[
                    _buildClaimTypeField(isDark, claimProvider.isSubmitting),
                    const SizedBox(height: 12),
                    _buildExpenseDateField(isDark, claimProvider.isSubmitting),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: _buildClaimTypeField(
                            isDark,
                            claimProvider.isSubmitting,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildExpenseDateField(
                            isDark,
                            claimProvider.isSubmitting,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  if (isCompact) ...[
                    TextField(
                      controller: _categoryController,
                      enabled: !claimProvider.isSubmitting,
                      decoration: _inputDecoration(
                        isDark,
                        label: 'Category',
                        hint: 'General, travel, meals, etc.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      enabled: !claimProvider.isSubmitting,
                      decoration: _inputDecoration(
                        isDark,
                        label: 'Title',
                        hint: 'Claim title',
                      ),
                    ),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _categoryController,
                            enabled: !claimProvider.isSubmitting,
                            decoration: _inputDecoration(
                              isDark,
                              label: 'Category',
                              hint: 'General, travel, meals, etc.',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _titleController,
                            enabled: !claimProvider.isSubmitting,
                            decoration: _inputDecoration(
                              isDark,
                              label: 'Title',
                              hint: 'Claim title',
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  if (isCompact) ...[
                    TextField(
                      controller: _amountController,
                      enabled: !claimProvider.isSubmitting,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _inputDecoration(
                        isDark,
                        label: 'Amount',
                        hint: '0',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _currencyController,
                      enabled: !claimProvider.isSubmitting,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _inputDecoration(
                        isDark,
                        label: 'Currency',
                        hint: 'IDR',
                      ),
                    ),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            enabled: !claimProvider.isSubmitting,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _inputDecoration(
                              isDark,
                              label: 'Amount',
                              hint: '0',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _currencyController,
                            enabled: !claimProvider.isSubmitting,
                            textCapitalization: TextCapitalization.characters,
                            decoration: _inputDecoration(
                              isDark,
                              label: 'Currency',
                              hint: 'IDR',
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    enabled: !claimProvider.isSubmitting,
                    minLines: 3,
                    maxLines: 4,
                    decoration: _inputDecoration(
                      isDark,
                      label: 'Notes',
                      hint: 'Notes for this claim',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: claimProvider.isSubmitting
                          ? null
                          : () => _submitClaim(
                              claimProvider: claimProvider,
                              currentEmployee: currentEmployee,
                              isAdminUser: isAdminUser,
                            ),
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
                        claimProvider.isSubmitting
                            ? 'Saving...'
                            : _editingId == null
                            ? 'Submit Claim'
                            : 'Update Claim',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openClaimForm({
    required ClaimProvider claimProvider,
    required AuthProvider authProvider,
    required ClaimEmployeeOption? currentEmployee,
    required bool isAdminUser,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 12,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 12,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.88,
            ),
            child: SingleChildScrollView(
              child: _buildFormCard(
                isDark,
                claimProvider: claimProvider,
                authProvider: authProvider,
                currentEmployee: currentEmployee,
                isAdminUser: isAdminUser,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusFilters(bool isDark, List<ClaimModel> claims) {
    final filters = <String, String>{
      'all': 'Semua',
      'submitted': 'Pending',
      'approved': 'Approved',
      'paid': 'Paid',
      'rejected': 'Rejected',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries.map((entry) {
          final selected = _statusFilter == entry.key;
          final count = _filteredClaims(claims, filter: entry.key).length;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              label: Text('${entry.value} ($count)'),
              selectedColor: _accentColor,
              backgroundColor: _surfaceColor(isDark),
              side: BorderSide(color: _surfaceBorderColor(isDark)),
              labelStyle: _bodyStyle(
                isDark,
                size: 12,
                weight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
              onSelected: (_) {
                setState(() {
                  _statusFilter = entry.key;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  List<ClaimModel> _filteredClaims(List<ClaimModel> claims, {String? filter}) {
    final activeFilter = filter ?? _statusFilter;
    if (activeFilter == 'all') {
      return claims;
    }

    return claims
        .where((claim) {
          final status = claim.status.trim().toLowerCase();
          if (activeFilter == 'submitted') {
            return status == 'submitted' || status == 'pending';
          }
          return status == activeFilter;
        })
        .toList(growable: false);
  }

  Widget _buildRegisterCard(
    bool isDark, {
    required ClaimProvider claimProvider,
    required List<ClaimModel> claims,
    required ClaimEmployeeOption? currentEmployee,
    required int? currentUserId,
    required String currentUserUuid,
    required bool isAdminUser,
  }) {
    return _buildSurfaceCard(
      isDark: isDark,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Claims Register', style: _titleStyle(isDark, size: 17)),
          const SizedBox(height: 6),
          Text(
            'Track submitted claims, approvers, and payment status.',
            style: _bodyStyle(isDark, size: 13),
          ),
          const SizedBox(height: 14),
          if (claims.isEmpty)
            _buildInlineMessage(
              isDark: isDark,
              message: 'No claims recorded.',
              tone: const Color(0xFF6B7280),
            )
          else
            Column(
              children: [
                for (var index = 0; index < claims.length; index++) ...[
                  _buildClaimItem(
                    isDark,
                    claims[index],
                    claimProvider: claimProvider,
                    currentEmployee: currentEmployee,
                    currentUserId: currentUserId,
                    currentUserUuid: currentUserUuid,
                    isAdminUser: isAdminUser,
                  ),
                  if (index != claims.length - 1) ...[
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

  Widget _buildClaimItem(
    bool isDark,
    ClaimModel claim, {
    required ClaimProvider claimProvider,
    required ClaimEmployeeOption? currentEmployee,
    required int? currentUserId,
    required String currentUserUuid,
    required bool isAdminUser,
  }) {
    final statusColor = _statusColor(claim.status, claim.isPendingSync);
    final canEdit = _canEditClaim(
      claim,
      currentEmployee: currentEmployee,
      isAdminUser: isAdminUser,
    );
    final canApprove = _canApproveClaim(
      claim,
      currentUserId: currentUserId,
      currentUserUuid: currentUserUuid,
      isAdminUser: isAdminUser,
    );
    final canReject = canApprove;
    final canMarkPaid =
        isAdminUser && claim.status.trim().toLowerCase() == 'approved';
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
                Icons.request_quote_rounded,
                color: _accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(claim.title, style: _titleStyle(isDark, size: 14)),
                  const SizedBox(height: 4),
                  Text(
                    claim.employeeName?.trim().isNotEmpty == true
                        ? claim.employeeName!
                        : 'Unknown employee',
                    style: _bodyStyle(isDark, size: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('yyyy-MM-dd').format(claim.date),
                    style: _bodyStyle(isDark, size: 12),
                  ),
                  if (claim.claimNumber?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      claim.claimNumber!,
                      style: _bodyStyle(isDark, size: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(claim.amount, claim.currency),
                  style: _titleStyle(
                    isDark,
                    size: 14,
                    weight: FontWeight.w800,
                    color: _accentColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: isDark ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    claim.displayStatus,
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
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildMetaChip(
              isDark: isDark,
              icon: Icons.account_tree_outlined,
              label: claim.displayClaimType,
            ),
            _buildMetaChip(
              isDark: isDark,
              icon: _claimCategoryIcon(claim.type),
              label: claim.displayCategory,
            ),
            if (claim.approverName?.trim().isNotEmpty == true)
              _buildMetaChip(
                isDark: isDark,
                icon: Icons.verified_user_outlined,
                label: claim.approverName!,
              ),
          ],
        ),
        if (claim.description.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            claim.description,
            style: _bodyStyle(isDark, size: 13, height: 1.45),
          ),
        ],
        const SizedBox(height: 12),
        if (canEdit || canApprove || canReject || canMarkPaid || canDelete)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (canEdit)
                OutlinedButton(
                  onPressed: claimProvider.isSubmitting
                      ? null
                      : () {
                          final authProvider = context.read<AuthProvider>();
                          _startEditing(
                            claim,
                            claimProvider,
                            currentEmployee: currentEmployee,
                            isAdminUser: isAdminUser,
                          );
                          _openClaimForm(
                            claimProvider: claimProvider,
                            authProvider: authProvider,
                            currentEmployee: currentEmployee,
                            isAdminUser: isAdminUser,
                          );
                        },
                  child: const Text('Edit'),
                ),
              if (canApprove)
                OutlinedButton(
                  onPressed: claimProvider.isSubmitting
                      ? null
                      : () => _approveClaim(claimProvider, claim),
                  child: const Text('Approve'),
                ),
              if (canReject)
                OutlinedButton(
                  onPressed: claimProvider.isSubmitting
                      ? null
                      : () => _rejectClaim(claimProvider, claim),
                  child: const Text('Reject'),
                ),
              if (canMarkPaid)
                OutlinedButton(
                  onPressed: claimProvider.isSubmitting
                      ? null
                      : () => _markClaimPaid(claimProvider, claim),
                  child: const Text('Paid'),
                ),
              if (canDelete)
                TextButton(
                  onPressed: claimProvider.isSubmitting
                      ? null
                      : () => _deleteClaim(claimProvider, claim),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFD5534F),
                  ),
                  child: const Text('Delete'),
                ),
            ],
          )
        else
          Text('No actions', style: _bodyStyle(isDark, size: 12)),
      ],
    );
  }

  Widget _buildClaimTypeField(bool isDark, bool isSubmitting) {
    return DropdownButtonFormField<String>(
      key: ValueKey<String>('${_editingId ?? 'new'}::$_selectedClaimType'),
      initialValue: _selectedClaimType,
      decoration: _inputDecoration(isDark, label: 'Claim Type'),
      items: const [
        DropdownMenuItem(value: 'reimbursement', child: Text('Reimbursement')),
        DropdownMenuItem(value: 'expense', child: Text('Expense Claim')),
        DropdownMenuItem(value: 'travel', child: Text('Travel Claim')),
      ],
      onChanged: isSubmitting
          ? null
          : (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _selectedClaimType = value;
              });
            },
    );
  }

  Widget _buildExpenseDateField(bool isDark, bool isSubmitting) {
    return InkWell(
      onTap: isSubmitting ? null : _pickExpenseDate,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _inputDecoration(
          isDark,
          label: 'Expense Date',
          hint: 'Select date',
        ),
        child: Text(
          _expenseDate == null
              ? 'Select date'
              : DateFormat('yyyy-MM-dd').format(_expenseDate!),
          style: _bodyStyle(
            isDark,
            size: 13,
            color: _expenseDate == null
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
    required String helperText,
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
        const SizedBox(height: 6),
        Text(helperText, style: _bodyStyle(isDark, size: 12)),
      ],
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

  Widget _buildInlineMessage({
    required bool isDark,
    required String message,
    required Color tone,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: isDark ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: _bodyStyle(
          isDark,
          size: 12,
          weight: FontWeight.w600,
          color: tone,
        ),
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

  Future<void> _pickExpenseDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _expenseDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _expenseDate = pickedDate;
    });
  }

  Future<void> _submitClaim({
    required ClaimProvider claimProvider,
    required ClaimEmployeeOption? currentEmployee,
    required bool isAdminUser,
  }) async {
    claimProvider.clearError();
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    final currency = _currencyController.text.trim().isEmpty
        ? 'IDR'
        : _currencyController.text.trim().toUpperCase();
    final category = _categoryController.text.trim().isEmpty
        ? 'general'
        : _categoryController.text.trim();
    final employeeId = isAdminUser
        ? _selectedEmployeeId
        : (currentEmployee?.id ?? claimProvider.currentEmployeeId);

    if (title.isEmpty ||
        amount == null ||
        amount <= 0 ||
        _expenseDate == null) {
      _showSnackBar(
        'Employee, title, amount, and expense date are required.',
        isError: true,
      );
      return;
    }

    if (isAdminUser && employeeId == null) {
      _showSnackBar('Please select employee first.', isError: true);
      return;
    }

    final wasEditing = _editingId != null;
    final existingClaim = _editingId == null
        ? null
        : _findClaimById(claimProvider.claims, _editingId!);
    final claim = ClaimModel(
      id: existingClaim?.id ?? '',
      employeeId: employeeId,
      employeeUuid: existingClaim?.employeeUuid ?? currentEmployee?.uuid,
      employeeName: existingClaim?.employeeName ?? currentEmployee?.name,
      employeeImmediateSupervisor:
          existingClaim?.employeeImmediateSupervisor ??
          currentEmployee?.immediateSupervisor,
      claimNumber: existingClaim?.claimNumber,
      title: title,
      amount: amount,
      date: _expenseDate!,
      status: existingClaim?.status ?? 'submitted',
      type: category,
      claimType: _selectedClaimType,
      description: _notesController.text.trim(),
      currency: currency,
      attachmentUrl: existingClaim?.attachmentUrl,
      approverId: existingClaim?.approverId,
      approverName: existingClaim?.approverName,
    );

    final success = _editingId == null
        ? await claimProvider.submitClaim(claim)
        : await claimProvider.updateClaim(claim);

    if (!mounted) {
      return;
    }

    if (!success) {
      _showSnackBar(
        claimProvider.error ?? 'Failed to save claim.',
        isError: true,
      );
      return;
    }

    _resetForm(
      claimProvider,
      currentEmployee: currentEmployee,
      isAdminUser: isAdminUser,
    );
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    _showSnackBar(
      claimProvider.lastActionMessage ??
          (wasEditing ? 'Claim updated.' : 'Claim submitted.'),
      highlight: claimProvider.lastActionQueued,
    );
  }

  Future<void> _approveClaim(
    ClaimProvider claimProvider,
    ClaimModel claim,
  ) async {
    final success = await claimProvider.approveClaim(claim.id);
    if (!mounted) {
      return;
    }

    _showSnackBar(
      success
          ? 'Claim approved.'
          : claimProvider.error ?? 'Failed to approve claim.',
      isError: !success,
    );
  }

  Future<void> _rejectClaim(
    ClaimProvider claimProvider,
    ClaimModel claim,
  ) async {
    final note = await _showRejectDialog();
    if (note == null) {
      return;
    }

    final success = await claimProvider.rejectClaim(claim.id, notes: note);
    if (!mounted) {
      return;
    }

    _showSnackBar(
      success
          ? 'Claim rejected.'
          : claimProvider.error ?? 'Failed to reject claim.',
      isError: !success,
    );
  }

  Future<void> _markClaimPaid(
    ClaimProvider claimProvider,
    ClaimModel claim,
  ) async {
    final success = await claimProvider.markClaimPaid(claim.id);
    if (!mounted) {
      return;
    }

    _showSnackBar(
      success
          ? 'Claim marked as paid.'
          : claimProvider.error ?? 'Failed to mark claim paid.',
      isError: !success,
    );
  }

  Future<void> _deleteClaim(
    ClaimProvider claimProvider,
    ClaimModel claim,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: _surfaceColor(isDark),
          title: Text('Delete Claim', style: _titleStyle(isDark, size: 17)),
          content: Text(
            'Delete this claim from the register?',
            style: _bodyStyle(isDark, size: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD5534F),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    final success = await claimProvider.deleteClaim(claim.id);
    if (!mounted) {
      return;
    }

    _showSnackBar(
      success
          ? 'Claim deleted.'
          : claimProvider.error ?? 'Failed to delete claim.',
      isError: !success,
    );
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: _surfaceColor(isDark),
          title: Text('Reject Claim', style: _titleStyle(isDark, size: 17)),
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
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
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

  void _startEditing(
    ClaimModel claim,
    ClaimProvider claimProvider, {
    required ClaimEmployeeOption? currentEmployee,
    required bool isAdminUser,
  }) {
    claimProvider.clearError();
    setState(() {
      _editingId = claim.id;
      _selectedEmployeeId = isAdminUser
          ? claim.employeeId
          : currentEmployee?.id;
      _selectedClaimType = claim.claimType.isEmpty
          ? 'reimbursement'
          : claim.claimType;
      _categoryController.text = claim.type.trim().isEmpty
          ? 'general'
          : claim.type;
      _titleController.text = claim.title;
      _amountController.text = claim.amount.toStringAsFixed(0);
      _currencyController.text = claim.currency.trim().isEmpty
          ? 'IDR'
          : claim.currency;
      _notesController.text = claim.description;
      _expenseDate = claim.date;
    });
  }

  void _resetForm(
    ClaimProvider claimProvider, {
    required ClaimEmployeeOption? currentEmployee,
    required bool isAdminUser,
  }) {
    claimProvider.clearError();
    setState(() {
      _editingId = null;
      _selectedEmployeeId = isAdminUser ? null : currentEmployee?.id;
      _selectedClaimType = 'reimbursement';
      _categoryController.text = 'general';
      _titleController.clear();
      _amountController.clear();
      _currencyController.text = 'IDR';
      _notesController.clear();
      _expenseDate = null;
    });
  }

  bool _hasAdminRole(AuthProvider authProvider) {
    final normalizedRoles = <String>{
      ...authProvider.roles.map(_normalizeKey),
      _normalizeKey(authProvider.user?.role),
    }..removeWhere((role) => role.isEmpty);

    return normalizedRoles.any(_adminRoles.contains);
  }

  ClaimEmployeeOption? _resolveCurrentEmployee(
    AuthProvider authProvider,
    ClaimProvider claimProvider,
  ) {
    final employeeUuid = _normalizeKey(
      authProvider.user?.employeeUuid ?? authProvider.user?.uuid,
    );
    final currentEmployeeId = claimProvider.currentEmployeeId;

    for (final employee in claimProvider.employees) {
      final matchesById =
          currentEmployeeId != null && employee.id == currentEmployeeId;
      final matchesByUuid =
          employeeUuid.isNotEmpty &&
          _normalizeKey(employee.uuid) == employeeUuid;
      if (matchesById || matchesByUuid) {
        return employee;
      }
    }

    for (final claim in claimProvider.claims) {
      final matchesById =
          currentEmployeeId != null && claim.employeeId == currentEmployeeId;
      final matchesByUuid =
          employeeUuid.isNotEmpty &&
          _normalizeKey(claim.employeeUuid) == employeeUuid;
      if (!matchesById && !matchesByUuid) {
        continue;
      }

      final fallbackId = claim.employeeId ?? currentEmployeeId;
      if (fallbackId == null || fallbackId <= 0) {
        continue;
      }

      return ClaimEmployeeOption(
        id: fallbackId,
        uuid: claim.employeeUuid ?? employeeUuid,
        name: claim.employeeName?.trim().isNotEmpty == true
            ? claim.employeeName!
            : authProvider.user?.name ?? 'Current User',
        immediateSupervisor: claim.employeeImmediateSupervisor,
      );
    }

    if (currentEmployeeId != null && currentEmployeeId > 0) {
      return ClaimEmployeeOption(
        id: currentEmployeeId,
        uuid: authProvider.user?.employeeUuid ?? authProvider.user?.uuid ?? '',
        name: authProvider.user?.name ?? 'Current User',
      );
    }

    return null;
  }

  String _resolveAccessLabel(
    List<ClaimModel> claims, {
    required ClaimEmployeeOption? currentEmployee,
    required int? currentUserId,
    required String currentUserUuid,
    required bool isAdminUser,
  }) {
    if (isAdminUser) {
      return 'Admin access';
    }

    final canApproveAny = claims.any(
      (claim) => _canApproveClaim(
        claim,
        currentUserId: currentUserId,
        currentUserUuid: currentUserUuid,
        isAdminUser: isAdminUser,
      ),
    );
    if (canApproveAny) {
      return 'Approver access';
    }

    final ownsClaim = claims.any(
      (claim) => _isOwnClaim(claim, currentEmployee: currentEmployee),
    );
    return ownsClaim ? 'Member access' : 'Viewer access';
  }

  bool _isOwnClaim(
    ClaimModel claim, {
    required ClaimEmployeeOption? currentEmployee,
  }) {
    if (currentEmployee == null) {
      return false;
    }

    final matchesById =
        currentEmployee.id > 0 && claim.employeeId == currentEmployee.id;
    final matchesByUuid =
        currentEmployee.uuid.trim().isNotEmpty &&
        _normalizeKey(claim.employeeUuid) ==
            _normalizeKey(currentEmployee.uuid);
    return matchesById || matchesByUuid;
  }

  bool _canEditClaim(
    ClaimModel claim, {
    required ClaimEmployeeOption? currentEmployee,
    required bool isAdminUser,
  }) {
    final normalizedStatus = claim.status.trim().toLowerCase();
    final isEditableStatus =
        normalizedStatus == 'draft' ||
        normalizedStatus == 'submitted' ||
        normalizedStatus == 'rejected';

    return isEditableStatus &&
        (isAdminUser || _isOwnClaim(claim, currentEmployee: currentEmployee));
  }

  bool _canApproveClaim(
    ClaimModel claim, {
    required int? currentUserId,
    required String currentUserUuid,
    required bool isAdminUser,
  }) {
    if (claim.status.trim().toLowerCase() != 'submitted') {
      return false;
    }

    return isAdminUser ||
        (currentUserId != null && claim.approverId == currentUserId) ||
        (currentUserUuid.isNotEmpty &&
            claim.employeeImmediateSupervisor == currentUserUuid);
  }

  ClaimModel? _findClaimById(List<ClaimModel> claims, String id) {
    for (final claim in claims) {
      if (claim.id == id) {
        return claim;
      }
    }

    return null;
  }

  String _normalizeKey(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  IconData _claimCategoryIcon(String type) {
    final normalized = type.trim().toLowerCase();
    if (normalized.contains('travel') || normalized.contains('transport')) {
      return Icons.directions_car_outlined;
    }
    if (normalized.contains('meal') || normalized.contains('food')) {
      return Icons.restaurant_outlined;
    }
    if (normalized.contains('medical')) {
      return Icons.medical_services_outlined;
    }
    return Icons.category_outlined;
  }

  String _formatCurrency(double amount, String currency) {
    if (currency.toUpperCase() == 'IDR') {
      return _idrFormat.format(amount);
    }

    return NumberFormat.currency(symbol: '$currency ').format(amount);
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    bool highlight = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFD5534F)
            : highlight
            ? Colors.orange
            : null,
      ),
    );
  }

  Color _statusColor(String status, bool isPendingSync) {
    if (isPendingSync) {
      return const Color(0xFF7C3AED);
    }

    switch (status.trim().toLowerCase()) {
      case 'approved':
        return const Color(0xFF2F9D78);
      case 'rejected':
        return const Color(0xFFD5534F);
      case 'paid':
        return const Color(0xFF2563EB);
      case 'draft':
        return const Color(0xFF6B7280);
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
