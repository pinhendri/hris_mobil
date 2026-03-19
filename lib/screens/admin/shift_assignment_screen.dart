import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/access_denied_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shift_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/department_provider.dart';
import '../../models/shift_assignment_model.dart';

class ShiftAssignmentScreen extends StatefulWidget {
  const ShiftAssignmentScreen({super.key});

  @override
  State<ShiftAssignmentScreen> createState() => _ShiftAssignmentScreenState();
}

class _ShiftAssignmentScreenState extends State<ShiftAssignmentScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final canAccessShiftAssignment =
        authProvider.canAccessShiftAssignmentModule;

    if (!canAccessShiftAssignment) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Shift Assignment',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const AccessDeniedState(permissionLabel: 'create/edit settings'),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Shift Assignment',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ShiftProvider>(
        builder: (context, shiftProvider, child) {
          final orders = shiftProvider.orders;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openAddOrderDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Shift Order'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: orders.isEmpty
                      ? _emptyState()
                      : ListView.builder(
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            return _buildOrderCard(context, order);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.assignment,
            color: AppColors.textSecondary,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No shift orders yet',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, ShiftAssignment order) {
    final provider = Provider.of<ShiftProvider>(context, listen: false);
    final shift = provider.getShiftById(order.shiftId);
    final start = DateTime.tryParse(order.startDate);
    final end = order.endDate != null
        ? DateTime.tryParse(order.endDate!)
        : null;
    final rangeStr =
        '${start != null ? DateFormat('MMM dd, yyyy').format(start) : order.startDate}'
        ' - '
        '${end != null ? DateFormat('MMM dd, yyyy').format(end) : 'No end'}';
    final created = DateTime.tryParse(order.createdAt);
    final createdStr = created != null
        ? DateFormat('MMM dd, yyyy HH:mm').format(created)
        : order.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                      shift?.name ?? 'Unknown Shift',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Range: $rangeStr • Created: $createdStr',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
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
                  color: (order.active ? Colors.green : Colors.grey).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  order.active ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: order.active ? Colors.green : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () {
                  Provider.of<ShiftProvider>(
                    context,
                    listen: false,
                  ).deleteShiftOrder(order.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Shift order deleted')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _chip('Employees: ${order.employeeIds.length}', Colors.blue),
              const SizedBox(width: 8),
              _chip(
                'Departments: ${order.departmentIds.length}',
                Colors.orange,
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () async {
                  final ok = await Provider.of<ShiftProvider>(
                    context,
                    listen: false,
                  ).toggleShiftOrderActive(order.id, !order.active);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? (order.active
                                  ? 'Order deactivated'
                                  : 'Order activated')
                            : 'Cannot activate: end date passed',
                      ),
                    ),
                  );
                },
                child: Text(order.active ? 'Deactivate' : 'Activate'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
    );
  }

  void _openAddOrderDialog(BuildContext context) {
    final shiftProvider = Provider.of<ShiftProvider>(context, listen: false);
    final empProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final deptProvider = Provider.of<DepartmentProvider>(
      context,
      listen: false,
    );
    final shifts = shiftProvider.shifts;
    final employees = empProvider.employees;
    final departments = deptProvider.departments;

    String? selectedShiftId = shifts.isNotEmpty ? shifts.first.id : null;
    DateTime startDate = DateTime.now();
    DateTime? endDate;
    bool active = true;
    final selectedEmployeeIds = <String>{};
    final selectedDepartmentIds = <String>{};
    final empQueryController = TextEditingController();
    final deptQueryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Shift Order'),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shift Selection
                      DropdownButtonFormField<String>(
                        value: selectedShiftId,
                        items: shifts
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => selectedShiftId = v),
                        decoration: const InputDecoration(labelText: 'Shift'),
                      ),
                      const SizedBox(height: 12),

                      // Start Date
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Start: ${DateFormat('MMM dd, yyyy').format(startDate)}',
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => startDate = picked);
                              }
                            },
                            child: const Text('Pick Start'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // End Date
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'End: ${endDate != null ? DateFormat('MMM dd, yyyy').format(endDate!) : 'No end'}',
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate ?? startDate,
                                firstDate: startDate,
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => endDate = picked);
                              }
                            },
                            child: const Text('Pick End'),
                          ),
                          if (endDate != null)
                            TextButton(
                              onPressed: () => setState(() => endDate = null),
                              child: const Text('Clear'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Active Switch
                      Row(
                        children: [
                          const Text(
                            'Active',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: active,
                            onChanged: (v) => setState(() => active = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Employee Selection
                      Text(
                        'Select Employees',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: empQueryController,
                        decoration: const InputDecoration(
                          labelText: 'Search name or NIP',
                        ),
                        onChanged: (v) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.inputBorder),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.builder(
                          itemCount: employees.where((e) {
                            final q = empQueryController.text.toLowerCase();
                            if (q.isEmpty) return true;
                            return e.name.toLowerCase().contains(q) ||
                                e.id.toLowerCase().contains(q) ||
                                e.uuid.toLowerCase().contains(q);
                          }).length,
                          itemBuilder: (context, index) {
                            final filtered = employees.where((e) {
                              final q = empQueryController.text.toLowerCase();
                              if (q.isEmpty) return true;
                              return e.name.toLowerCase().contains(q) ||
                                  e.id.toLowerCase().contains(q) ||
                                  e.uuid.toLowerCase().contains(q);
                            }).toList();
                            final e = filtered[index];
                            final checked = selectedEmployeeIds.contains(e.id);
                            return ListTile(
                              title: Text('${e.name} (${e.id})'),
                              subtitle: Text(e.position),
                              trailing: Checkbox(
                                value: checked,
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      selectedEmployeeIds.add(e.id);
                                    } else {
                                      selectedEmployeeIds.remove(e.id);
                                    }
                                  });
                                },
                              ),
                              onTap: () {
                                setState(() {
                                  if (checked) {
                                    selectedEmployeeIds.remove(e.id);
                                  } else {
                                    selectedEmployeeIds.add(e.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedEmployeeIds.map((id) {
                          final e = employees.firstWhere((x) => x.id == id);
                          return Chip(
                            label: Text('${e.name} (${e.id})'),
                            onDeleted: () {
                              setState(() {
                                selectedEmployeeIds.remove(id);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      // Department Selection
                      Text(
                        'Select Departments',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: deptQueryController,
                        decoration: const InputDecoration(
                          labelText: 'Search name or code',
                        ),
                        onChanged: (v) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.inputBorder),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.builder(
                          itemCount: departments.where((d) {
                            final q = deptQueryController.text.toLowerCase();
                            if (q.isEmpty) return true;
                            final nameMatch = d.name.toLowerCase().contains(q);
                            final codeMatch =
                                d.code?.toLowerCase().contains(q) ?? false;
                            return nameMatch || codeMatch;
                          }).length,
                          itemBuilder: (context, index) {
                            final filtered = departments.where((d) {
                              final q = deptQueryController.text.toLowerCase();
                              if (q.isEmpty) return true;
                              final nameMatch = d.name.toLowerCase().contains(
                                q,
                              );
                              final codeMatch =
                                  d.code?.toLowerCase().contains(q) ?? false;
                              return nameMatch || codeMatch;
                            }).toList();

                            final d = filtered[index];
                            final checked = selectedDepartmentIds.contains(
                              d.id.toString(),
                            );

                            return ListTile(
                              title: Text(d.name),
                              subtitle: Text('Code: ${d.code ?? 'N/A'}'),
                              trailing: Checkbox(
                                value: checked,
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      selectedDepartmentIds.add(
                                        d.id.toString(),
                                      );
                                    } else {
                                      selectedDepartmentIds.remove(
                                        d.id.toString(),
                                      );
                                    }
                                  });
                                },
                              ),
                              onTap: () {
                                setState(() {
                                  if (checked) {
                                    selectedDepartmentIds.remove(
                                      d.id.toString(),
                                    );
                                  } else {
                                    selectedDepartmentIds.add(d.id.toString());
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedDepartmentIds.map((id) {
                          final deptId = int.tryParse(id) ?? 0;
                          final d = departments.firstWhere(
                            (x) => x.id == deptId,
                            orElse: () => departments.first,
                          );
                          return Chip(
                            label: Text('${d.name} (${d.code ?? 'N/A'})'),
                            onDeleted: () {
                              setState(() {
                                selectedDepartmentIds.remove(id);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      selectedShiftId == null ||
                          (selectedEmployeeIds.isEmpty &&
                              selectedDepartmentIds.isEmpty)
                      ? null
                      : () {
                          Provider.of<ShiftProvider>(
                            context,
                            listen: false,
                          ).addShiftOrder(
                            shiftId: selectedShiftId!,
                            employeeIds: selectedEmployeeIds.toList(),
                            departmentIds: selectedDepartmentIds.toList(),
                            startDate: startDate,
                            endDate: endDate,
                            active: active,
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Shift order created'),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
