import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/assignment_model.dart';
import '../../data/models/client_model.dart';
import '../../providers/client_provider.dart';
import 'vendor_palette.dart';

class AssignEmployeeScreen extends StatefulWidget {
  final Client client;

  const AssignEmployeeScreen({super.key, required this.client});

  @override
  State<AssignEmployeeScreen> createState() => _AssignEmployeeScreenState();
}

class _AssignEmployeeScreenState extends State<AssignEmployeeScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _selectedEmployeeUuids = [];
  final TextEditingController _roleController = TextEditingController();

  late final TabController _tabController;
  DateTime? _selectedDate;
  String? _selectedRole;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() => _currentTab = _tabController.index);
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    final clientProvider = context.read<ClientProvider>();
    await clientProvider.fetchAssignedEmployees(widget.client.id);
    if (mounted) {
      await clientProvider.fetchAvailableEmployees(widget.client.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorPalette.page(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: VendorPalette.surface(context),
        foregroundColor: VendorPalette.text(context),
        title: Text(
          'Assign - ${widget.client.name}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: VendorPalette.accent(context),
          labelColor: VendorPalette.accent(context),
          unselectedLabelColor: VendorPalette.mutedText(context),
          tabs: const [
            Tab(text: 'Assign', icon: Icon(Icons.person_add_alt_1_outlined)),
            Tab(text: 'Assigned', icon: Icon(Icons.people_alt_outlined)),
          ],
        ),
      ),
      body: Consumer<ClientProvider>(
        builder: (context, clientProvider, child) {
          if (clientProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: VendorPalette.accent(context),
              ),
            );
          }

          return IndexedStack(
            index: _currentTab,
            children: [
              _buildAssignTab(clientProvider),
              _buildAssignedListTab(clientProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAssignTab(ClientProvider clientProvider) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VendorPalette.surface(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: VendorPalette.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assignment Details',
                style: TextStyle(
                  color: VendorPalette.text(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickShiftDate,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: VendorPalette.inputDecoration(
                    context,
                    label: 'Shift Date *',
                    icon: Icons.calendar_today_outlined,
                  ),
                  child: Text(
                    _selectedDate != null
                        ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                        : 'Select date',
                    style: TextStyle(color: VendorPalette.text(context)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _roleController,
                style: TextStyle(color: VendorPalette.text(context)),
                decoration: VendorPalette.inputDecoration(
                  context,
                  label: 'Role (Optional)',
                  icon: Icons.work_outline,
                ),
                onChanged: (value) {
                  _selectedRole = value.isEmpty ? null : value;
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Employees',
                      style: TextStyle(
                        color: VendorPalette.text(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: VendorPalette.accentSoft(context),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_selectedEmployeeUuids.length} selected',
                        style: TextStyle(
                          color: VendorPalette.accent(context),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: clientProvider.availableEmployees.isEmpty
                      ? _buildEmptyState('No available employees')
                      : ListView.builder(
                          itemCount: clientProvider.availableEmployees.length,
                          itemBuilder: (context, index) {
                            final employee =
                                clientProvider.availableEmployees[index];
                            final isSelected = _selectedEmployeeUuids.contains(
                              employee.uuid,
                            );

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: VendorPalette.surface(context),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? VendorPalette.accent(context)
                                      : VendorPalette.border(context),
                                ),
                              ),
                              child: CheckboxListTile(
                                value: isSelected,
                                activeColor: VendorPalette.accent(context),
                                checkColor: Colors.white,
                                title: Text(
                                  employee.name,
                                  style: TextStyle(
                                    color: VendorPalette.text(context),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  employee.position ?? 'No position',
                                  style: TextStyle(
                                    color: VendorPalette.mutedText(context),
                                  ),
                                ),
                                secondary: CircleAvatar(
                                  backgroundColor: isSelected
                                      ? VendorPalette.accentSoft(context)
                                      : VendorPalette.mutedSurface(context),
                                  child: Icon(
                                    Icons.person_outline,
                                    color: isSelected
                                        ? VendorPalette.accent(context)
                                        : VendorPalette.mutedText(context),
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedEmployeeUuids.add(employee.uuid);
                                    } else {
                                      _selectedEmployeeUuids.remove(
                                        employee.uuid,
                                      );
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed:
                    _selectedDate == null || _selectedEmployeeUuids.isEmpty
                    ? null
                    : () => _assignSelectedEmployees(clientProvider),
                style: VendorPalette.primaryButton(context),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Assign Selected Employees'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignedListTab(ClientProvider clientProvider) {
    if (clientProvider.assignedEmployees.isEmpty) {
      return _buildEmptyState('No employees assigned yet');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: clientProvider.assignedEmployees.length,
      itemBuilder: (context, index) {
        final assignment = clientProvider.assignedEmployees[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: VendorPalette.surface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: VendorPalette.border(context)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: VendorPalette.accentSoft(context),
              child: Icon(
                Icons.person_outline,
                color: VendorPalette.accent(context),
              ),
            ),
            title: Text(
              assignment.name,
              style: TextStyle(
                color: VendorPalette.text(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (assignment.role != null)
                  Text(
                    'Role: ${assignment.role}',
                    style: TextStyle(color: VendorPalette.mutedText(context)),
                  ),
                if (assignment.shiftDate != null)
                  Text(
                    'Shift Date: ${assignment.shiftDate}',
                    style: TextStyle(color: VendorPalette.mutedText(context)),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: VendorPalette.danger(context),
              ),
              onPressed: () => _showRemoveDialog(clientProvider, assignment),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 52,
            color: VendorPalette.mutedText(context),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: TextStyle(color: VendorPalette.mutedText(context)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickShiftDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: VendorPalette.accent(context),
            surface: VendorPalette.surface(context),
            onSurface: VendorPalette.text(context),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _assignSelectedEmployees(ClientProvider clientProvider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(color: VendorPalette.accent(context)),
      ),
    );

    try {
      final success = await clientProvider.assignEmployees(
        widget.client.id,
        _selectedEmployeeUuids,
        DateFormat('yyyy-MM-dd').format(_selectedDate!),
        role: _selectedRole,
      );

      if (mounted) Navigator.pop(context);

      if (success && mounted) {
        setState(() {
          _selectedEmployeeUuids.clear();
          _selectedDate = null;
          _roleController.clear();
          _selectedRole = null;
        });
        await _loadData();
        _showSnack('Employees assigned successfully', success: true);
      } else if (mounted) {
        _showSnack('Failed: ${clientProvider.error ?? 'Unknown error'}');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnack('Error: $e');
      }
    }
  }

  Future<void> _showRemoveDialog(
    ClientProvider clientProvider,
    EmployeeAssignment assignment,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: VendorPalette.surface(dialogContext),
        title: Text(
          'Remove Assignment',
          style: TextStyle(color: VendorPalette.text(dialogContext)),
        ),
        content: Text(
          'Remove ${assignment.name} from this vendor?',
          style: TextStyle(color: VendorPalette.mutedText(dialogContext)),
        ),
        actions: [
          TextButton(
            style: VendorPalette.textButton(dialogContext),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: VendorPalette.dangerButton(dialogContext),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(color: VendorPalette.accent(context)),
      ),
    );

    try {
      final success = await clientProvider.removeAssignedEmployee(
        widget.client.id,
        assignment.uuid,
      );

      if (mounted) Navigator.pop(context);
      if (success && mounted) {
        await _loadData();
        _showSnack('Employee removed', success: true);
      }
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success
            ? VendorPalette.success(context)
            : VendorPalette.danger(context),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _roleController.dispose();
    super.dispose();
  }
}
