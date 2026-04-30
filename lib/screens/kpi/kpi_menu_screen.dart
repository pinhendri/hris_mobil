import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/widgets/access_denied_state.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

enum KpiMenuType {
  overview,
  master,
  evaluation,
  departmentGoals,
  employeeGoals,
}

class KpiMenuScreen extends StatefulWidget {
  final String titleKey;
  final String requiredPermission;
  final IconData icon;
  final KpiMenuType type;

  const KpiMenuScreen({
    super.key,
    required this.titleKey,
    required this.requiredPermission,
    required this.icon,
    this.type = KpiMenuType.overview,
  });

  @override
  State<KpiMenuScreen> createState() => _KpiMenuScreenState();
}

class _KpiMenuScreenState extends State<KpiMenuScreen> {
  static const int _assignPageSize = 20;
  static const int _recordPageSize = 20;

  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, TextEditingController>> _kpiRows = [];

  bool _isLoading = true;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _departmentGoals = [];
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _evaluationDetails = [];
  final Map<String, String> _evaluationActualValues = {};
  final Map<String, String> _evaluationNotesValues = {};
  bool _isLoadingEvaluationDetails = false;
  bool _isLoadingAssignments = false;
  bool _isAssigning = false;
  final Set<int> _selectedAssignEmployeeIds = {};
  final Set<int> _assignedEmployeeIds = {};
  final Map<int, String> _assignConflictLabels = {};

  String? _departmentId;
  String? _employeeId;
  String? _departmentGoalId;
  String? _assignMasterKpiId;
  String _assignDepartmentFilter = 'all';
  String _assignStatusFilter = 'unassigned';
  int _assignVisibleCount = _assignPageSize;
  String _recordDepartmentFilter = 'all';
  String _recordStatusFilter = 'all';
  String _recordPeriodFilter = 'all';
  String _recordYearFilter = 'all';
  int _recordVisibleCount = _recordPageSize;
  String _period = 'monthly';
  String _year = DateTime.now().year.toString();
  String? _month;
  String? _quarter;
  String? _semester;
  String _status = 'pending';

  final _goalNameController = TextEditingController();
  final _targetValueController = TextEditingController();
  final _achievedValueController = TextEditingController();
  final _progressController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _evaluationPeriodController = TextEditingController();
  final _assignSearchController = TextEditingController();
  final _recordSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _evaluationPeriodController.text = _defaultMonthValue();
    _dueDateController.text = _defaultDateValue();
    _addKpiRow();
    _loadReferences();
  }

  @override
  void dispose() {
    for (final row in _kpiRows) {
      for (final controller in row.values) {
        controller.dispose();
      }
    }
    _goalNameController.dispose();
    _targetValueController.dispose();
    _achievedValueController.dispose();
    _progressController.dispose();
    _dueDateController.dispose();
    _evaluationPeriodController.dispose();
    _assignSearchController.dispose();
    _recordSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadReferences() async {
    setState(() => _isLoading = true);
    try {
      final responses = await Future.wait<dynamic>([
        _safeGet('/departments'),
        _safeGet(
          widget.type == KpiMenuType.evaluation ||
                  widget.type == KpiMenuType.master
              ? '/kpi/employee-kpi/data'
              : '/employees/list',
        ),
        _safeGet('/kpi/department-goals'),
        _safeGet(_listEndpoint),
      ]);

      if (!mounted) return;
      setState(() {
        _departments = _extractRecords(responses[0]);
        _employees = _extractRecords(responses[1]);
        _departmentGoals = _extractRecords(responses[2]);
        _records = _extractRecords(responses[3]);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Gagal memuat data referensi: $error');
    }
  }

  Future<dynamic> _safeGet(String endpoint) async {
    try {
      return await _apiService.get(endpoint);
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = context.tr(widget.titleKey);

    if (!authProvider.hasPermission(widget.requiredPermission)) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: AccessDeniedState(permissionLabel: widget.requiredPermission),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF6F4F1),
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1F2937),
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReferences,
              child: Form(
                key: _formKey,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(18),
                  children: [
                    _HeaderCard(
                      title: title,
                      icon: widget.icon,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildCurrentForm(isDark),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_isSubmitting ? 'Menyimpan...' : 'Simpan'),
                    ),
                    const SizedBox(height: 18),
                    _buildRecordList(isDark),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentForm(bool isDark) {
    switch (widget.type) {
      case KpiMenuType.master:
        return _buildMasterKpiForm(isDark);
      case KpiMenuType.evaluation:
        return _buildEvaluationForm(isDark);
      case KpiMenuType.departmentGoals:
        return _buildDepartmentGoalForm(isDark);
      case KpiMenuType.employeeGoals:
        return _buildEmployeeGoalForm(isDark);
      case KpiMenuType.overview:
        return _SectionCard(
          isDark: isDark,
          children: const [Text('Pilih submenu KPI untuk membuka form input.')],
        );
    }
  }

  Widget _buildMasterKpiForm(bool isDark) {
    return _SectionCard(
      isDark: isDark,
      children: [
        _dropdown(
          label: 'Department',
          value: _departmentId,
          items: _departments,
          labelFor: _departmentLabel,
          onChanged: (value) => setState(() => _departmentId = value),
        ),
        _textField(
          label: 'Year',
          initialController: null,
          keyboardType: TextInputType.number,
          initialValue: _year,
          onChanged: (value) => _year = value,
          required: true,
        ),
        _periodDropdown(includeSemester: true),
        if (_period == 'monthly') _monthDropdown(),
        if (_period == 'quarterly') _quarterDropdown(),
        if (_period == 'semester') _semesterDropdown(),
        const SizedBox(height: 8),
        Text(
          'Detail KPI',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < _kpiRows.length; index++)
          _buildKpiRow(index, isDark),
        OutlinedButton.icon(
          onPressed: _addKpiRow,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Tambah KPI'),
        ),
        const Divider(height: 28),
        _buildAssignSection(isDark),
      ],
    );
  }

  Widget _buildAssignSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assign Employee ke KPI',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue:
              _records.any((item) => _recordId(item) == _assignMasterKpiId)
              ? _assignMasterKpiId
              : null,
          decoration: const InputDecoration(labelText: 'Pilih Master KPI'),
          items: _records
              .where((item) => _recordId(item).isNotEmpty)
              .map(
                (item) => DropdownMenuItem(
                  value: _recordId(item),
                  child: Text(
                    _masterKpiLabel(item),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _assignMasterKpiId = value;
              _selectedAssignEmployeeIds.clear();
              _assignedEmployeeIds.clear();
              _assignConflictLabels.clear();
              _assignDepartmentFilter = 'all';
              _assignStatusFilter = 'unassigned';
              _assignVisibleCount = _assignPageSize;
              _assignSearchController.clear();
            });
            if (value != null && value.isNotEmpty) {
              _loadAssignmentState(value);
            }
          },
        ),
        if (_assignMasterKpiId == null)
          const Text('Pilih Master KPI dari data tersimpan untuk mulai assign.')
        else if (_isLoadingAssignments)
          const Center(child: CircularProgressIndicator())
        else ...[
          _buildAssignFilters(isDark),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_selectedAssignEmployeeIds.length} dipilih',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: _toggleSelectAllAssignableEmployees,
                child: const Text('Pilih yang tampil'),
              ),
              TextButton(
                onPressed: _selectedAssignEmployeeIds.isEmpty
                    ? null
                    : () => setState(_selectedAssignEmployeeIds.clear),
                child: const Text('Clear'),
              ),
            ],
          ),
          Builder(
            builder: (context) {
              final filteredEmployees = _filteredAssignEmployees();
              final visibleEmployees = filteredEmployees
                  .take(_assignVisibleCount)
                  .toList();
              final hiddenCount =
                  filteredEmployees.length - visibleEmployees.length;

              if (filteredEmployees.isEmpty) {
                return Text(
                  'Tidak ada employee yang cocok dengan filter.',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Menampilkan ${visibleEmployees.length} dari ${filteredEmployees.length} employee',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 420),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: visibleEmployees.length,
                      itemBuilder: (context, index) {
                        final employee = visibleEmployees[index];
                        final id = int.tryParse(_recordId(employee));
                        if (id == null) return const SizedBox.shrink();

                        return _buildAssignEmployeeTile(
                          employee: employee,
                          id: id,
                          isDark: isDark,
                        );
                      },
                    ),
                  ),
                  if (hiddenCount > 0)
                    Center(
                      child: TextButton.icon(
                        onPressed: () => setState(
                          () => _assignVisibleCount += _assignPageSize,
                        ),
                        icon: const Icon(Icons.expand_more_rounded),
                        label: Text('Muat 20 lagi ($hiddenCount tersisa)'),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: double.infinity),
            child: FilledButton.icon(
              onPressed: _isAssigning ? null : _assignSelectedEmployees,
              icon: _isAssigning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.group_add_outlined),
              label: Text(_isAssigning ? 'Assigning...' : 'Assign KPI'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAssignFilters(bool isDark) {
    final departments = _assignDepartmentOptions();

    return Column(
      children: [
        TextField(
          controller: _assignSearchController,
          decoration: const InputDecoration(
            labelText: 'Cari employee',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (_) => setState(() {
            _assignVisibleCount = _assignPageSize;
          }),
        ),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue:
                    departments.any(
                      (item) => item['value'] == _assignDepartmentFilter,
                    )
                    ? _assignDepartmentFilter
                    : 'all',
                decoration: const InputDecoration(labelText: 'Department'),
                items: departments
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item['value']!,
                        child: Text(
                          item['label']!,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _assignDepartmentFilter = value ?? 'all';
                  _assignVisibleCount = _assignPageSize;
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _assignStatusFilter,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(
                    value: 'unassigned',
                    child: Text('Belum assigned'),
                  ),
                  DropdownMenuItem(
                    value: 'assigned',
                    child: Text('Sudah assigned'),
                  ),
                  DropdownMenuItem(value: 'conflict', child: Text('Konflik')),
                ],
                onChanged: (value) => setState(() {
                  _assignStatusFilter = value ?? 'unassigned';
                  _assignVisibleCount = _assignPageSize;
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAssignEmployeeTile({
    required Map<String, dynamic> employee,
    required int id,
    required bool isDark,
  }) {
    final assigned = _assignedEmployeeIds.contains(id);
    final conflict = _assignConflictLabels[id];
    final disabled = conflict != null;
    final selected = _selectedAssignEmployeeIds.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? const Color(0xFF02AAB0)
              : isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: CheckboxListTile(
        value: selected,
        onChanged: disabled
            ? null
            : (_) {
                setState(() {
                  if (selected) {
                    _selectedAssignEmployeeIds.remove(id);
                  } else {
                    _selectedAssignEmployeeIds.add(id);
                  }
                });
              },
        title: Text(
          _employeeLabel(employee),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          conflict ??
              (assigned
                  ? 'Sudah memiliki KPI ini, assign akan update'
                  : _employeeDepartmentLabel(employee)),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        secondary: Icon(
          conflict != null
              ? Icons.block_rounded
              : assigned
              ? Icons.update_rounded
              : Icons.person_add_alt_1_rounded,
          color: conflict != null
              ? Colors.red
              : assigned
              ? Colors.amber
              : const Color(0xFF028A91),
        ),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }

  Widget _buildDepartmentGoalForm(bool isDark) {
    return _SectionCard(
      isDark: isDark,
      children: [
        _dropdown(
          label: 'Department',
          value: _departmentId,
          items: _departments,
          labelFor: _departmentLabel,
          onChanged: (value) => setState(() => _departmentId = value),
        ),
        _textField(label: 'Goal Name', initialController: _goalNameController),
        _textField(
          label: 'Target Value',
          initialController: _targetValueController,
          keyboardType: TextInputType.number,
        ),
        _periodDropdown(includeSemester: false),
        _textField(
          label: 'Year',
          initialController: null,
          keyboardType: TextInputType.number,
          initialValue: _year,
          onChanged: (value) => _year = value,
          required: true,
        ),
        if (_period == 'monthly') _monthDropdown(),
      ],
    );
  }

  Widget _buildEmployeeGoalForm(bool isDark) {
    final filteredGoals = _filteredDepartmentGoalsForEmployee();

    return _SectionCard(
      isDark: isDark,
      children: [
        _dropdown(
          label: 'Employee',
          value: _employeeId,
          items: _employees,
          labelFor: _employeeLabel,
          onChanged: (value) {
            setState(() {
              _employeeId = value;
              _departmentGoalId = null;
            });
          },
        ),
        _dropdown(
          label: 'Department Goal (Optional)',
          value: _departmentGoalId,
          items: filteredGoals,
          labelFor: (item) => _readString(item, const ['goal_name', 'name']),
          onChanged: (value) => setState(() => _departmentGoalId = value),
          required: false,
        ),
        _textField(label: 'Goal Name', initialController: _goalNameController),
        _statusDropdown(),
        _textField(
          label: 'Due Date (YYYY-MM-DD)',
          initialController: _dueDateController,
        ),
        _textField(
          label: 'Target Value',
          initialController: _targetValueController,
          keyboardType: TextInputType.number,
          required: false,
        ),
        _textField(
          label: 'Achieved Value',
          initialController: _achievedValueController,
          keyboardType: TextInputType.number,
          required: false,
        ),
        _textField(
          label: 'Progress (%)',
          initialController: _progressController,
          keyboardType: TextInputType.number,
          required: false,
        ),
      ],
    );
  }

  Widget _buildEvaluationForm(bool isDark) {
    final totalScore = _calculateEvaluationTotalScore();

    return _SectionCard(
      isDark: isDark,
      children: [
        _dropdown(
          label: 'Employee',
          value: _employeeId,
          items: _employees,
          labelFor: _employeeLabel,
          onChanged: (value) {
            setState(() {
              _employeeId = value;
              _evaluationDetails = [];
              _evaluationActualValues.clear();
              _evaluationNotesValues.clear();
            });
            if (value != null && value.isNotEmpty) {
              _loadEmployeeEvaluationDetails(value);
            }
          },
        ),
        _textField(
          label: 'Periode Penilaian (YYYY-MM)',
          initialController: _evaluationPeriodController,
          onChanged: (_) {
            if (_employeeId != null && _evaluationDetails.isNotEmpty) {
              _checkExistingEvaluation();
            }
          },
        ),
        if (_isLoadingEvaluationDetails)
          const Center(child: CircularProgressIndicator())
        else if (_employeeId == null)
          const Text('Pilih employee untuk memuat KPI yang sudah di-assign.')
        else if (_evaluationDetails.isEmpty)
          const Text(
            'Employee ini belum memiliki KPI yang di-assign. Assign Master KPI terlebih dahulu dari web/frontend.',
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_evaluationDetails.length} KPI detail siap dinilai',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Chip(label: Text('Score ${totalScore.toStringAsFixed(2)}')),
            ],
          ),
          for (var index = 0; index < _evaluationDetails.length; index++)
            _buildEvaluationDetailCard(index, isDark),
        ],
      ],
    );
  }

  Widget _buildEvaluationDetailCard(int index, bool isDark) {
    final detail = _evaluationDetails[index];
    final detailKey = _evaluationDetailKey(detail, index);
    final target = _readDouble(detail, const ['target', 'target_value']);
    final weight = _readDouble(detail, const ['weight']);
    final actual =
        double.tryParse(_evaluationActualValues[detailKey] ?? '') ?? 0;
    final score = target <= 0 ? 0 : (actual / target * weight);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _readString(detail, const ['goal_name', 'name', 'title']),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                score.toStringAsFixed(2),
                style: const TextStyle(
                  color: Color(0xFF028A91),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniBadge(
                _readString(detail, const ['category']).isEmpty
                    ? 'General'
                    : _readString(detail, const ['category']),
              ),
              _MiniBadge('Target ${_formatNumber(target)}'),
              _MiniBadge('Weight ${_formatNumber(weight)}%'),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            key: ValueKey('actual-$detailKey'),
            initialValue: _evaluationActualValues[detailKey],
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Actual'),
            validator: (value) {
              if (_evaluationActualValues.values.any(
                (item) => item.trim().isNotEmpty,
              )) {
                return null;
              }
              return index == 0 ? 'Isi minimal satu nilai actual' : null;
            },
            onChanged: (value) {
              setState(() => _evaluationActualValues[detailKey] = value);
            },
          ),
          TextFormField(
            key: ValueKey('notes-$detailKey'),
            initialValue: _evaluationNotesValues[detailKey],
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Notes'),
            onChanged: (value) => _evaluationNotesValues[detailKey] = value,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(int index, bool isDark) {
    final row = _kpiRows[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'KPI #${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: _kpiRows.length == 1
                    ? null
                    : () => _removeKpiRow(index),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          DropdownButtonFormField<String>(
            initialValue: row['category']!.text.isEmpty
                ? null
                : row['category']!.text,
            decoration: const InputDecoration(labelText: 'Category'),
            items: const [
              DropdownMenuItem(value: 'Quality', child: Text('Quality')),
              DropdownMenuItem(
                value: 'Productivity',
                child: Text('Productivity'),
              ),
              DropdownMenuItem(value: 'Discipline', child: Text('Discipline')),
            ],
            validator: (value) =>
                value == null || value.isEmpty ? 'Wajib diisi' : null,
            onChanged: (value) => row['category']!.text = value ?? '',
          ),
          _textField(label: 'Goal Name', initialController: row['goal_name']),
          _textField(
            label: 'Target Value',
            initialController: row['target_value'],
            keyboardType: TextInputType.number,
          ),
          _textField(
            label: 'Weight (%)',
            initialController: row['weight'],
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<Map<String, dynamic>> items,
    required String Function(Map<String, dynamic>) labelFor,
    required ValueChanged<String?> onChanged,
    bool required = true,
  }) {
    final currentValue = items.any((item) => _recordId(item) == value)
        ? value
        : null;

    return DropdownButtonFormField<String>(
      initialValue: currentValue,
      decoration: InputDecoration(labelText: label),
      items: items
          .where((item) => _recordId(item).isNotEmpty)
          .map(
            (item) => DropdownMenuItem(
              value: _recordId(item),
              child: Text(labelFor(item), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      validator: required
          ? (value) => value == null || value.isEmpty ? 'Wajib dipilih' : null
          : null,
      onChanged: onChanged,
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController? initialController,
    TextInputType? keyboardType,
    String? initialValue,
    ValueChanged<String>? onChanged,
    int maxLines = 1,
    bool required = true,
  }) {
    return TextFormField(
      controller: initialController,
      initialValue: initialController == null ? initialValue : null,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (value) =>
                value == null || value.trim().isEmpty ? 'Wajib diisi' : null
          : null,
      onChanged: onChanged,
    );
  }

  Widget _periodDropdown({required bool includeSemester}) {
    final options = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
      const DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
      if (includeSemester)
        const DropdownMenuItem(value: 'semester', child: Text('Semester')),
      const DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
    ];

    return DropdownButtonFormField<String>(
      initialValue: _period,
      decoration: const InputDecoration(labelText: 'Period'),
      items: options,
      onChanged: (value) {
        setState(() {
          _period = value ?? 'monthly';
          _month = null;
          _quarter = null;
          _semester = null;
        });
      },
    );
  }

  Widget _monthDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _month,
      decoration: const InputDecoration(labelText: 'Month'),
      validator: (value) =>
          value == null || value.isEmpty ? 'Wajib dipilih' : null,
      items: List.generate(12, (index) {
        final value = (index + 1).toString().padLeft(2, '0');
        return DropdownMenuItem(value: value, child: Text(value));
      }),
      onChanged: (value) => setState(() => _month = value),
    );
  }

  Widget _quarterDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _quarter,
      decoration: const InputDecoration(labelText: 'Quarter'),
      validator: (value) =>
          value == null || value.isEmpty ? 'Wajib dipilih' : null,
      items: const [
        DropdownMenuItem(value: 'Q1', child: Text('Q1 (Jan - Mar)')),
        DropdownMenuItem(value: 'Q2', child: Text('Q2 (Apr - Jun)')),
        DropdownMenuItem(value: 'Q3', child: Text('Q3 (Jul - Sep)')),
        DropdownMenuItem(value: 'Q4', child: Text('Q4 (Oct - Dec)')),
      ],
      onChanged: (value) => setState(() => _quarter = value),
    );
  }

  Widget _semesterDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _semester,
      decoration: const InputDecoration(labelText: 'Semester'),
      validator: (value) =>
          value == null || value.isEmpty ? 'Wajib dipilih' : null,
      items: const [
        DropdownMenuItem(value: 'S1', child: Text('Semester 1')),
        DropdownMenuItem(value: 'S2', child: Text('Semester 2')),
      ],
      onChanged: (value) => setState(() => _semester = value),
    );
  }

  Widget _statusDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _status,
      decoration: const InputDecoration(labelText: 'Status'),
      items: const [
        DropdownMenuItem(value: 'pending', child: Text('Pending')),
        DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
        DropdownMenuItem(value: 'completed', child: Text('Completed')),
        DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
      ],
      onChanged: (value) => setState(() => _status = value ?? 'pending'),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      switch (widget.type) {
        case KpiMenuType.master:
          await _apiService.post('/kpi/master-kpi', _masterPayload());
          break;
        case KpiMenuType.evaluation:
          await _apiService.post('/kpi/evaluation/save', _evaluationPayload());
          break;
        case KpiMenuType.departmentGoals:
          await _apiService.post(
            '/kpi/department-goals',
            _departmentGoalPayload(),
          );
          break;
        case KpiMenuType.employeeGoals:
          await _apiService.post('/kpi/employee-goals', _employeeGoalPayload());
          break;
        case KpiMenuType.overview:
          break;
      }

      if (!mounted) return;
      _showSnack('Data berhasil disimpan');
      await _refreshRecords();
    } catch (error) {
      if (!mounted) return;
      _showSnack('Gagal menyimpan data: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _refreshRecords() async {
    final response = await _safeGet(_listEndpoint);
    if (!mounted) return;
    setState(() {
      _records = _extractRecords(response);
      _recordVisibleCount = _recordPageSize;
    });
  }

  Future<void> _loadAssignmentState(String masterKpiId) async {
    setState(() => _isLoadingAssignments = true);
    try {
      final responses = await Future.wait<dynamic>([
        _safeGet('/kpi/master-kpi/$masterKpiId/assignments'),
        _safePost('/kpi/employee-kpi/assignment-conflicts', {
          'master_kpi_id': int.tryParse(masterKpiId),
          'employee_ids': _employees
              .map((item) => int.tryParse(_recordId(item)))
              .whereType<int>()
              .toList(),
        }),
      ]);

      final assignments = _extractRecords(responses[0]);
      final assignedIds = assignments
          .map((item) => _readInt(item, const ['employee_id', 'id']))
          .whereType<int>()
          .toSet();

      final conflictResponse = responses[1];
      final conflicts = <int, String>{};
      if (conflictResponse is Map) {
        final periodLabel = (conflictResponse['period_label'] ?? '').toString();
        final blocked = conflictResponse['blocked_employees'];
        if (blocked is List) {
          for (final item in blocked.whereType<Map>()) {
            final map = Map<String, dynamic>.from(item);
            final employeeId = _readInt(map, const ['employee_id']);
            if (employeeId == null) continue;
            final name = _readString(map, const ['employee_name']);
            conflicts[employeeId] = name.isEmpty
                ? 'Sudah memiliki KPI pada periode ${periodLabel.isEmpty ? 'yang sama' : periodLabel}'
                : '$name sudah memiliki KPI pada periode ${periodLabel.isEmpty ? 'yang sama' : periodLabel}';
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _assignedEmployeeIds
          ..clear()
          ..addAll(assignedIds);
        _assignConflictLabels
          ..clear()
          ..addAll(conflicts);
        _selectedAssignEmployeeIds.removeWhere(conflicts.containsKey);
        _isLoadingAssignments = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingAssignments = false);
      _showSnack('Gagal memuat assignment: $error');
    }
  }

  Future<dynamic> _safePost(
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    try {
      return await _apiService.post(endpoint, payload);
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  void _toggleSelectAllAssignableEmployees() {
    final selectableIds = _filteredAssignEmployees()
        .take(_assignVisibleCount)
        .map((item) => int.tryParse(_recordId(item)))
        .whereType<int>()
        .where((id) => !_assignConflictLabels.containsKey(id))
        .toList();

    setState(() {
      final allSelected = selectableIds.every(
        _selectedAssignEmployeeIds.contains,
      );
      if (allSelected) {
        _selectedAssignEmployeeIds.clear();
      } else {
        _selectedAssignEmployeeIds.addAll(selectableIds);
      }
    });
  }

  List<Map<String, dynamic>> _filteredAssignEmployees() {
    final query = _assignSearchController.text.trim().toLowerCase();

    return _employees.where((employee) {
      final id = int.tryParse(_recordId(employee));
      if (id == null) return false;

      if (_assignDepartmentFilter != 'all' &&
          _employeeDepartmentFilterValue(employee) != _assignDepartmentFilter) {
        return false;
      }

      final assigned = _assignedEmployeeIds.contains(id);
      final conflict = _assignConflictLabels.containsKey(id);
      switch (_assignStatusFilter) {
        case 'unassigned':
          if (assigned || conflict) return false;
          break;
        case 'assigned':
          if (!assigned || conflict) return false;
          break;
        case 'conflict':
          if (!conflict) return false;
          break;
        case 'all':
        default:
          break;
      }

      if (query.isEmpty) return true;
      final haystack = [
        _employeeLabel(employee),
        _employeeDepartmentLabel(employee),
        _readString(employee, const ['email', 'employee', 'employee_email']),
        _readString(employee, const [
          'employee_number',
          'employee_code',
          'nik',
        ]),
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  List<Map<String, String>> _assignDepartmentOptions() {
    final options = <String, String>{'all': 'All'};
    for (final employee in _employees) {
      final value = _employeeDepartmentFilterValue(employee);
      if (value.isEmpty) continue;
      options[value] = _employeeDepartmentLabel(employee);
    }
    final sorted = options.entries.toList()
      ..sort((a, b) {
        if (a.key == 'all') return -1;
        if (b.key == 'all') return 1;
        return a.value.toLowerCase().compareTo(b.value.toLowerCase());
      });
    return sorted
        .map((entry) => {'value': entry.key, 'label': entry.value})
        .toList();
  }

  String _employeeDepartmentFilterValue(Map<String, dynamic> employee) {
    final nestedId = _nestedString(employee, 'department', const [
      'id',
      'uuid',
    ]);
    if (nestedId.isNotEmpty) return nestedId;
    final id = _readString(employee, const [
      'department_id',
      'department_uuid',
      'departmentId',
    ]);
    if (id.isNotEmpty) return id;
    return _employeeDepartmentLabel(employee).toLowerCase();
  }

  Future<void> _assignSelectedEmployees() async {
    final masterKpiId = _assignMasterKpiId;
    if (masterKpiId == null || masterKpiId.isEmpty) {
      _showSnack('Pilih Master KPI terlebih dahulu');
      return;
    }
    if (_selectedAssignEmployeeIds.isEmpty) {
      _showSnack('Pilih minimal satu employee');
      return;
    }

    setState(() => _isAssigning = true);
    try {
      await _apiService.post('/kpi/employee-kpi/assign', {
        'master_kpi_id': int.tryParse(masterKpiId),
        'employee_ids': _selectedAssignEmployeeIds.toList(),
      });

      if (!mounted) return;
      _showSnack('KPI berhasil di-assign');
      _selectedAssignEmployeeIds.clear();
      await _loadAssignmentState(masterKpiId);
    } catch (error) {
      if (!mounted) return;
      _showSnack('Gagal assign KPI: $error');
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  String get _listEndpoint {
    switch (widget.type) {
      case KpiMenuType.master:
        return '/kpi/master-kpi';
      case KpiMenuType.evaluation:
        return '/kpi/evaluation/list';
      case KpiMenuType.departmentGoals:
        return '/kpi/department-goals';
      case KpiMenuType.employeeGoals:
        return '/kpi/employee-goals';
      case KpiMenuType.overview:
        return '/kpi/master-kpi';
    }
  }

  Widget _buildRecordList(bool isDark) {
    final title = widget.type == KpiMenuType.evaluation
        ? 'Data Evaluasi'
        : 'Data Tersimpan';
    final filteredRecords = _filteredRecords();
    final visibleRecords = filteredRecords.take(_recordVisibleCount).toList();
    final hiddenCount = filteredRecords.length - visibleRecords.length;

    return _SectionCard(
      isDark: isDark,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _refreshRecords,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        if (widget.type == KpiMenuType.evaluation)
          _buildEvaluationListFilters(),
        if (_records.isEmpty)
          Text(
            'Belum ada data yang bisa ditampilkan.',
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF6B7280),
            ),
          )
        else if (filteredRecords.isEmpty)
          Text(
            'Tidak ada evaluasi yang cocok dengan filter.',
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF6B7280),
            ),
          )
        else ...[
          Text(
            'Menampilkan ${visibleRecords.length} dari ${filteredRecords.length} data',
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          for (final record in visibleRecords)
            _RecordTile(
              title: _recordTitle(record),
              subtitle: _recordSubtitle(record),
              trailing: _recordTrailing(record),
              isDark: isDark,
            ),
          if (hiddenCount > 0)
            Center(
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => _recordVisibleCount += _recordPageSize),
                icon: const Icon(Icons.expand_more_rounded),
                label: Text('Muat 20 lagi ($hiddenCount tersisa)'),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildEvaluationListFilters() {
    final departments = _recordDepartmentOptions();
    final statuses = _recordValueOptions(
      label: 'All',
      values: _records.map((record) => _readString(record, const ['status'])),
    );
    final periods = _recordValueOptions(
      label: 'All',
      values: _records.map((record) => _readString(record, const ['period'])),
    );
    final years = _recordValueOptions(
      label: 'All',
      values: _records.map((record) => _readString(record, const ['year'])),
    );

    return Column(
      children: [
        TextField(
          controller: _recordSearchController,
          decoration: const InputDecoration(
            labelText: 'Cari evaluasi',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (_) => setState(() {
            _recordVisibleCount = _recordPageSize;
          }),
        ),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue:
                    departments.any(
                      (item) => item['value'] == _recordDepartmentFilter,
                    )
                    ? _recordDepartmentFilter
                    : 'all',
                decoration: const InputDecoration(labelText: 'Department'),
                items: departments
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item['value']!,
                        child: Text(
                          item['label']!,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _recordDepartmentFilter = value ?? 'all';
                  _recordVisibleCount = _recordPageSize;
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue:
                    statuses.any((item) => item['value'] == _recordStatusFilter)
                    ? _recordStatusFilter
                    : 'all',
                decoration: const InputDecoration(labelText: 'Status'),
                items: statuses
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item['value']!,
                        child: Text(item['label']!),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _recordStatusFilter = value ?? 'all';
                  _recordVisibleCount = _recordPageSize;
                }),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue:
                    periods.any((item) => item['value'] == _recordPeriodFilter)
                    ? _recordPeriodFilter
                    : 'all',
                decoration: const InputDecoration(labelText: 'Periode'),
                items: periods
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item['value']!,
                        child: Text(item['label']!),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _recordPeriodFilter = value ?? 'all';
                  _recordVisibleCount = _recordPageSize;
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue:
                    years.any((item) => item['value'] == _recordYearFilter)
                    ? _recordYearFilter
                    : 'all',
                decoration: const InputDecoration(labelText: 'Tahun'),
                items: years
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item['value']!,
                        child: Text(item['label']!),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _recordYearFilter = value ?? 'all';
                  _recordVisibleCount = _recordPageSize;
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _filteredRecords() {
    if (widget.type != KpiMenuType.evaluation) {
      return _records.take(_recordVisibleCount).toList();
    }

    final query = _recordSearchController.text.trim().toLowerCase();
    return _records.where((record) {
      if (_recordDepartmentFilter != 'all' &&
          _recordDepartmentFilterValue(record) != _recordDepartmentFilter) {
        return false;
      }
      if (_recordStatusFilter != 'all' &&
          _readString(record, const ['status']).toLowerCase() !=
              _recordStatusFilter) {
        return false;
      }
      if (_recordPeriodFilter != 'all' &&
          _readString(record, const ['period']).toLowerCase() !=
              _recordPeriodFilter) {
        return false;
      }
      if (_recordYearFilter != 'all' &&
          _readString(record, const ['year']) != _recordYearFilter) {
        return false;
      }

      if (query.isEmpty) return true;
      final haystack = [
        _recordTitle(record),
        _recordSubtitle(record),
        _readString(record, const ['employee_name', 'name']),
        _nestedString(record, 'employee', const ['name', 'employee_name']),
        _readString(record, const ['employee_number', 'employee_code', 'nik']),
        _readString(record, const ['grade', 'final_score']),
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  List<Map<String, String>> _recordDepartmentOptions() {
    final options = <String, String>{'all': 'All'};
    for (final record in _records) {
      final value = _recordDepartmentFilterValue(record);
      if (value.isEmpty) continue;
      options[value] = _recordDepartmentLabel(record);
    }
    final sorted = options.entries.toList()
      ..sort((a, b) {
        if (a.key == 'all') return -1;
        if (b.key == 'all') return 1;
        return a.value.toLowerCase().compareTo(b.value.toLowerCase());
      });
    return sorted
        .map((entry) => {'value': entry.key, 'label': entry.value})
        .toList();
  }

  List<Map<String, String>> _recordValueOptions({
    required String label,
    required Iterable<String> values,
  }) {
    final normalized = <String, String>{'all': label};
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      normalized[trimmed.toLowerCase()] = trimmed;
    }
    final sorted = normalized.entries.toList()
      ..sort((a, b) {
        if (a.key == 'all') return -1;
        if (b.key == 'all') return 1;
        return a.value.toLowerCase().compareTo(b.value.toLowerCase());
      });
    return sorted
        .map((entry) => {'value': entry.key, 'label': entry.value})
        .toList();
  }

  String _recordDepartmentFilterValue(Map<String, dynamic> record) {
    final nestedId = _nestedString(record, 'department', const ['id', 'uuid']);
    if (nestedId.isNotEmpty) return nestedId;
    final employeeDepartmentId = _nestedString(record, 'employee', const [
      'department_id',
      'department_uuid',
    ]);
    if (employeeDepartmentId.isNotEmpty) return employeeDepartmentId;
    final id = _readString(record, const [
      'department_id',
      'department_uuid',
      'departmentId',
    ]);
    if (id.isNotEmpty) return id;
    return _recordDepartmentLabel(record).toLowerCase();
  }

  String _recordDepartmentLabel(Map<String, dynamic> record) {
    final nestedDepartment = _nestedString(record, 'department', const [
      'name',
      'department_name',
    ]);
    if (nestedDepartment.isNotEmpty) return nestedDepartment;
    final employeeDepartment = _nestedString(record, 'employee', const [
      'department_name',
      'department',
    ]);
    if (employeeDepartment.isNotEmpty) return employeeDepartment;
    return _readString(record, const ['department_name', 'department']);
  }

  String _recordTitle(Map<String, dynamic> record) {
    switch (widget.type) {
      case KpiMenuType.master:
        return _readString(record, const [
              'name',
              'goal_name',
              'department_name',
              'period',
            ]).isNotEmpty
            ? _readString(record, const [
                'name',
                'goal_name',
                'department_name',
                'period',
              ])
            : 'Master KPI #${_recordId(record)}';
      case KpiMenuType.evaluation:
        return _readString(record, const ['employee_name', 'name']).isNotEmpty
            ? _readString(record, const ['employee_name', 'name'])
            : 'Evaluasi #${_recordId(record)}';
      case KpiMenuType.departmentGoals:
      case KpiMenuType.employeeGoals:
        return _readString(record, const [
              'goal_name',
              'name',
              'title',
            ]).isNotEmpty
            ? _readString(record, const ['goal_name', 'name', 'title'])
            : 'Goal #${_recordId(record)}';
      case KpiMenuType.overview:
        return _readString(record, const ['name', 'goal_name']);
    }
  }

  String _recordSubtitle(Map<String, dynamic> record) {
    final parts = <String>[
      _readString(record, const ['period']),
      _readString(record, const ['year']),
      _readString(record, const ['status']),
      _nestedString(record, 'department', const ['name', 'department_name']),
      _nestedString(record, 'employee', const ['name', 'employee_name']),
    ]..removeWhere((part) => part.isEmpty);

    return parts.isEmpty ? 'ID: ${_recordId(record)}' : parts.join(' • ');
  }

  String _recordTrailing(Map<String, dynamic> record) {
    final values = [
      _readString(record, const ['target_value', 'target']),
      _readString(record, const ['progress']),
      _readString(record, const ['final_score']),
      _readString(record, const ['grade']),
    ]..removeWhere((value) => value.isEmpty);

    if (values.isEmpty) return '';
    return values.first;
  }

  Map<String, dynamic> _masterPayload() {
    return {
      'department_id': int.tryParse(_departmentId ?? ''),
      'year': int.tryParse(_year) ?? DateTime.now().year,
      'period': _period,
      'month': _month,
      'quarter': _quarter,
      'semester': _semester,
      'details': _kpiRows
          .map(
            (row) => {
              'category': row['category']!.text.trim(),
              'goal_name': row['goal_name']!.text.trim(),
              'target_value': row['target_value']!.text.trim(),
              'weight': double.tryParse(row['weight']!.text.trim()) ?? 0,
            },
          )
          .toList(),
    };
  }

  Map<String, dynamic> _departmentGoalPayload() {
    return {
      'department_id': _departmentId,
      'goal_name': _goalNameController.text.trim(),
      'target_value': _targetValueController.text.trim(),
      'period': _period,
      'year': _year,
      'month': _month,
    };
  }

  Map<String, dynamic> _employeeGoalPayload() {
    return {
      'goal_name': _goalNameController.text.trim(),
      'status': _status,
      'due_date': _dueDateController.text.trim(),
      'target_value': double.tryParse(_targetValueController.text.trim()) ?? 0,
      'achieved_value':
          double.tryParse(_achievedValueController.text.trim()) ?? 0,
      'progress': double.tryParse(_progressController.text.trim()) ?? 0,
      'employee_id': int.tryParse(_employeeId ?? ''),
      'department_goal_id': int.tryParse(_departmentGoalId ?? ''),
    };
  }

  Map<String, dynamic> _evaluationPayload() {
    final scores = <Map<String, dynamic>>[];

    for (var index = 0; index < _evaluationDetails.length; index++) {
      final detail = _evaluationDetails[index];
      final detailKey = _evaluationDetailKey(detail, index);
      final actualText = _evaluationActualValues[detailKey]?.trim() ?? '';
      if (actualText.isEmpty) continue;

      final target = _readDouble(detail, const ['target', 'target_value']);
      final weight = _readDouble(detail, const ['weight']);
      final actual = double.tryParse(actualText) ?? 0;
      final score = target <= 0 ? 0 : (actual / target * weight);

      scores.add({
        'employee_kpi_id': _readInt(detail, const ['employee_kpi_id', 'id']),
        'master_kpi_detail_id': _readInt(detail, const [
          'master_kpi_detail_id',
          'id',
        ]),
        'goal_name': _readString(detail, const ['goal_name', 'name']),
        'category': _readString(detail, const ['category']).isEmpty
            ? 'General'
            : _readString(detail, const ['category']),
        'target': target,
        'weight': weight,
        'actual': actual,
        'score': score,
        'achievement_notes': _evaluationNotesValues[detailKey]?.trim() ?? '',
        'notes': _evaluationNotesValues[detailKey]?.trim() ?? '',
      });
    }

    return {
      'employee_id': int.tryParse(_employeeId ?? ''),
      'period': _evaluationPeriodController.text.trim(),
      'scores': scores,
    };
  }

  Future<void> _loadEmployeeEvaluationDetails(String employeeId) async {
    setState(() => _isLoadingEvaluationDetails = true);
    try {
      var response = await _safeGet('/kpi/evaluation/employee/$employeeId/kpi');
      var details = _normalizeEmployeeKpiResponse(response);

      if (details.isEmpty) {
        response = await _safeGet('/kpi/employee-kpi/$employeeId');
        details = _normalizeEmployeeKpiResponse(response);
      }

      if (!mounted) return;
      setState(() {
        _evaluationDetails = details;
        _evaluationActualValues.clear();
        _evaluationNotesValues.clear();
        for (var index = 0; index < details.length; index++) {
          final key = _evaluationDetailKey(details[index], index);
          _evaluationActualValues[key] = '';
          _evaluationNotesValues[key] = '';
        }
        _isLoadingEvaluationDetails = false;
      });

      await _checkExistingEvaluation();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingEvaluationDetails = false);
      _showSnack('Gagal memuat KPI employee: $error');
    }
  }

  Future<void> _checkExistingEvaluation() async {
    final employeeId = _employeeId;
    final period = _evaluationPeriodController.text.trim();
    if (employeeId == null || employeeId.isEmpty || period.isEmpty) return;

    try {
      final response = await _apiService.post(
        '/kpi/evaluation/check-existing',
        {'employee_id': employeeId, 'period': period},
      );
      final existing = _extractRecords(response);
      if (existing.isEmpty || !mounted) return;

      setState(() {
        for (final item in existing) {
          for (var index = 0; index < _evaluationDetails.length; index++) {
            final detail = _evaluationDetails[index];
            final sameDetail =
                _readString(detail, const ['master_kpi_detail_id', 'id']) ==
                _readString(item, const ['master_kpi_detail_id']);
            final sameEmployeeKpi =
                _readString(detail, const ['employee_kpi_id']) ==
                _readString(item, const ['employee_kpi_id']);

            if (sameDetail || sameEmployeeKpi) {
              final key = _evaluationDetailKey(detail, index);
              _evaluationActualValues[key] = _readString(item, const [
                'actual',
                'actual_value',
              ]);
              _evaluationNotesValues[key] = _readString(item, const [
                'achievement_notes',
                'notes',
              ]);
            }
          }
        }
      });
    } catch (_) {
      // Existing evaluation is optional; new entries simply start blank.
    }
  }

  List<Map<String, dynamic>> _normalizeEmployeeKpiResponse(dynamic response) {
    final rawItems = _extractRecords(response);
    final normalized = <Map<String, dynamic>>[];

    for (final item in rawItems) {
      final detailsValue = item['details'];
      final details = detailsValue is List ? detailsValue : const [];
      final employeeKpiId = _readString(item, const ['employee_kpi_id', 'id']);
      final masterKpiId = _readString(item, const ['master_kpi_id']);
      final masterKpi = item['master_kpi'] is Map
          ? Map<String, dynamic>.from(item['master_kpi'] as Map)
          : const <String, dynamic>{};

      if (details.isNotEmpty) {
        for (final rawDetail in details.whereType<Map>()) {
          final detail = Map<String, dynamic>.from(rawDetail);
          normalized.add({
            'employee_kpi_id': employeeKpiId,
            'master_kpi_id': masterKpiId,
            'master_kpi_detail_id':
                detail['id'] ?? detail['master_kpi_detail_id'],
            'goal_name': detail['goal_name'] ?? item['goal_name'],
            'category': detail['category'] ?? item['category'],
            'target':
                detail['target_value'] ?? detail['target'] ?? item['target'],
            'weight': detail['weight'] ?? item['weight'],
            'period': item['period'] ?? masterKpi['period'],
            'year': item['year'] ?? masterKpi['year'],
            'master_kpi_name':
                masterKpi['name'] ?? item['master_kpi_name'] ?? 'KPI',
          });
        }
      } else {
        normalized.add({
          'employee_kpi_id': employeeKpiId,
          'master_kpi_id': masterKpiId.isNotEmpty
              ? masterKpiId
              : _readString(masterKpi, const ['id']),
          'master_kpi_detail_id': _readString(item, const [
            'master_kpi_detail_id',
            'id',
          ]),
          'goal_name': item['goal_name'],
          'category': item['category'],
          'target': item['target'] ?? item['target_value'],
          'weight': item['weight'],
          'period': item['period'] ?? masterKpi['period'],
          'year': item['year'] ?? masterKpi['year'],
          'master_kpi_name':
              masterKpi['name'] ?? item['master_kpi_name'] ?? 'KPI',
        });
      }
    }

    return normalized
        .where((item) => _readString(item, const ['goal_name']).isNotEmpty)
        .toList();
  }

  void _addKpiRow() {
    setState(() {
      _kpiRows.add({
        'category': TextEditingController(),
        'goal_name': TextEditingController(),
        'target_value': TextEditingController(),
        'weight': TextEditingController(),
      });
    });
  }

  void _removeKpiRow(int index) {
    final row = _kpiRows.removeAt(index);
    for (final controller in row.values) {
      controller.dispose();
    }
    setState(() {});
  }

  List<Map<String, dynamic>> _filteredDepartmentGoalsForEmployee() {
    if (_employeeId == null) return _departmentGoals;
    final employee = _employees.firstWhere(
      (item) => _recordId(item) == _employeeId,
      orElse: () => const <String, dynamic>{},
    );
    final departmentId = _readString(employee, const [
      'department_id',
      'department',
    ]);
    if (departmentId.isEmpty) return _departmentGoals;
    return _departmentGoals
        .where(
          (goal) => _readString(goal, const ['department_id']) == departmentId,
        )
        .toList();
  }

  List<Map<String, dynamic>> _extractRecords(dynamic response) {
    if (response is List) {
      return response
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (response is Map) {
      for (final key in const [
        'data',
        'items',
        'departments',
        'employees',
        'goals',
        'department_goals',
        'employee_goals',
        'evaluations',
        'master_kpis',
        'masterKpis',
        'assignments',
      ]) {
        final value = response[key];
        if (value is List) {
          return value
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
        if (value is Map && value['data'] is List) {
          return (value['data'] as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }
    }
    return const [];
  }

  String _departmentLabel(Map<String, dynamic> item) {
    return _readString(item, const [
          'name',
          'department_name',
          'label',
          'nama_department',
        ]).isNotEmpty
        ? _readString(item, const [
            'name',
            'department_name',
            'label',
            'nama_department',
          ])
        : 'Department #${_recordId(item)}';
  }

  String _employeeLabel(Map<String, dynamic> item) {
    final name = _readString(item, const [
      'name',
      'employee_name',
      'full_name',
    ]);
    final position = _readString(item, const ['position_name', 'position']);
    return position.isEmpty ? name : '$name ($position)';
  }

  String _employeeDepartmentLabel(Map<String, dynamic> item) {
    final department = _nestedString(item, 'department', const [
      'name',
      'department_name',
    ]);
    if (department.isNotEmpty) return department;
    return _readString(item, const ['department_name', 'department']);
  }

  String _masterKpiLabel(Map<String, dynamic> item) {
    final department = _nestedString(item, 'department', const ['name']);
    final departmentName = department.isNotEmpty
        ? department
        : _readString(item, const ['department_name', 'name']);
    final period = _readString(item, const ['period']);
    final year = _readString(item, const ['year']);
    final id = _recordId(item);

    final parts = [departmentName, period, year]
      ..removeWhere((value) => value.isEmpty);
    return parts.isEmpty ? 'Master KPI #$id' : parts.join(' - ');
  }

  String _recordId(Map<String, dynamic> item) =>
      _readString(item, const ['id', 'uuid']);

  String _evaluationDetailKey(Map<String, dynamic> detail, int index) {
    final employeeKpiId = _readString(detail, const ['employee_kpi_id']);
    final masterDetailId = _readString(detail, const ['master_kpi_detail_id']);
    if (employeeKpiId.isNotEmpty || masterDetailId.isNotEmpty) {
      return '$employeeKpiId-$masterDetailId';
    }
    return 'detail-$index';
  }

  double _calculateEvaluationTotalScore() {
    var total = 0.0;
    for (var index = 0; index < _evaluationDetails.length; index++) {
      final detail = _evaluationDetails[index];
      final key = _evaluationDetailKey(detail, index);
      final target = _readDouble(detail, const ['target', 'target_value']);
      final weight = _readDouble(detail, const ['weight']);
      final actual = double.tryParse(_evaluationActualValues[key] ?? '') ?? 0;
      if (target > 0 && actual > 0) {
        total += actual / target * weight;
      }
    }
    return total;
  }

  int? _readInt(Map<String, dynamic> item, List<String> keys) {
    final value = _readString(item, keys);
    return int.tryParse(value);
  }

  double _readDouble(Map<String, dynamic> item, List<String> keys) {
    final value = _readString(item, keys);
    return double.tryParse(value) ?? 0;
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  String _readString(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  String _nestedString(
    Map<String, dynamic> item,
    String key,
    List<String> nestedKeys,
  ) {
    final value = item[key];
    if (value is Map<String, dynamic>) {
      return _readString(value, nestedKeys);
    }
    if (value is Map) {
      return _readString(Map<String, dynamic>.from(value), nestedKeys);
    }
    return '';
  }

  String _defaultMonthValue() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  String _defaultDateValue() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;

  const _HeaderCard({
    required this.title,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      isDark: isDark,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF02AAB0).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: const Color(0xFF028A91)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _SectionCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  final bool isDark;

  const _RecordTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? '-' : title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (trailing.isNotEmpty) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF02AAB0).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                trailing,
                style: const TextStyle(
                  color: Color(0xFF028A91),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;

  const _MiniBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF02AAB0).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF028A91),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
