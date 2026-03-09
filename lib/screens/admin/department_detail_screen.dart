// lib/screens/admin/department_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/department_model.dart';
import '../../models/employee_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/department_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/notification_provider.dart';
import 'add_edit_department_screen.dart';
import 'package:hris_mobile/core/utils/image_helper.dart';

class DepartmentDetailScreen extends StatefulWidget {
  final String departmentId;

  const DepartmentDetailScreen({super.key, required this.departmentId});

  @override
  State<DepartmentDetailScreen> createState() => _DepartmentDetailScreenState();
}

class _DepartmentDetailScreenState extends State<DepartmentDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load department data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final deptProvider = Provider.of<DepartmentProvider>(context, listen: false);
      // Refresh to ensure we have latest data
      deptProvider.fetchDepartments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    // Perbaikan: Cek permissions untuk menentukan admin
    final isAdmin = user != null && (user.permissions.contains('all') || user.permissions.contains('admin'));

    return Consumer2<DepartmentProvider, EmployeeProvider>(
      builder: (context, deptProvider, empProvider, child) {
        // Parse ID dengan aman
        final deptId = int.tryParse(widget.departmentId) ?? 0;
        final department = deptProvider.getDepartmentById(deptId);

        // Show loading state if department not found but still loading
        if (department == null && deptProvider.isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Department Details',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Show error if department not found
        if (department == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Error',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Department not found',
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: ${widget.departmentId}',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        // Get children departments
        final children = deptProvider.getChildrenDepartments(deptId);

        // Find employees in this department
        final departmentEmployees = empProvider.employees
            .where(
              (e) =>
                  e.department?.toString() == department.name ||
                  e.department?.toString() == department.id.toString(),
            )
            .toList();

        final userIdStr = authProvider.user?.id.toString();
        final isDeptHead = userIdStr == department.employeeId; // Use employeeId instead of headId
        final canManage = isAdmin || isDeptHead;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(
              department.name,
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (isAdmin) ...[
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditDepartmentScreen(department: department),
                      ),
                    ).then((_) {
                      // Refresh after editing
                      deptProvider.fetchDepartments();
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(context, deptProvider, department),
                ),
              ],
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => deptProvider.fetchDepartments(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(department),
                  const SizedBox(height: 20),
                  _buildStatsGrid(department, departmentEmployees),
                  const SizedBox(height: 20),

                  // Employees Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader(
                        'Employees (${departmentEmployees.length})',
                      ),
                      if (canManage)
                        TextButton(
                          onPressed: () => _showManageEmployeesDialog(
                            context,
                            department,
                            empProvider,
                            deptProvider,
                          ),
                          child: Text(
                            'Manage',
                            style: GoogleFonts.poppins(color: AppColors.primary),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (departmentEmployees.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'No employees assigned',
                              style: GoogleFonts.poppins(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    _buildEmployeeList(departmentEmployees),

                  const SizedBox(height: 20),

                  // Role Distribution Analysis
                  if (departmentEmployees.isNotEmpty) ...[
                    _buildSectionHeader('Role Distribution'),
                    const SizedBox(height: 12),
                    _buildRoleDistribution(departmentEmployees),
                    const SizedBox(height: 20),
                  ],

                  // Sub-Departments Section
                  _buildSectionHeader('Sub-Departments'),
                  const SizedBox(height: 12),
                  if (children.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.subdirectory_arrow_right, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'No sub-departments',
                              style: GoogleFonts.poppins(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: children.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildChildDepartmentCard(
                          context,
                          children[index],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showManageEmployeesDialog(
    BuildContext context,
    Department department,
    EmployeeProvider empProvider,
    DepartmentProvider deptProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setState) {
            return Consumer<EmployeeProvider>(
              builder: (context, empProvider, child) {
                // Ensure employees are loaded
                if (empProvider.employees.isEmpty && !empProvider.isLoading) {
                  empProvider.fetchEmployees();
                }

                final filteredEmployees = empProvider.employees.where((e) {
                  return e.name.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      ) ||
                      e.position.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      );
                }).toList();

                return DraggableScrollableSheet(
                  initialChildSize: 0.7,
                  minChildSize: 0.5,
                  maxChildSize: 0.9,
                  expand: false,
                  builder: (context, scrollController) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                'Manage Employees',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (empProvider.isLoading)
                                const LinearProgressIndicator(
                                  color: AppColors.primary,
                                  backgroundColor: AppColors.inputBackground,
                                ),
                              if (empProvider.isLoading)
                                const SizedBox(height: 16),
                              TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search employees...',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    searchQuery = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: filteredEmployees.length,
                            itemBuilder: (context, index) {
                              final employee = filteredEmployees[index];
                              final isInDepartment =
                                  employee.department?.toString() == department.name ||
                                  employee.department?.toString() == department.id.toString();

                              return CheckboxListTile(
                                value: isInDepartment,
                                title: Text(
                                  employee.name,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  employee.position,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                secondary: CircleAvatar(
                                  backgroundImage: ImageHelper.avatar(employee.avatarUrl),
                                  child: employee.avatarUrl == null || employee.avatarUrl!.isEmpty
                                      ? const Icon(Icons.person, size: 20)
                                      : null,
                                ),
                                onChanged: (bool? value) async {
                                  try {
                                    if (value == true) {
                                      // Assign to department
                                      await empProvider.updateEmployeeDepartment(
                                        employee.id,
                                        department.name,
                                      );
                                      
                                      // Refresh data
                                      await deptProvider.fetchDepartments();
                                      
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${employee.name} assigned to ${department.name}',
                                              style: GoogleFonts.poppins(),
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } else {
                                      // Remove from department
                                      await empProvider.updateEmployeeDepartment(
                                        employee.id,
                                        'Unassigned',
                                      );
                                      
                                      // Refresh data
                                      await deptProvider.fetchDepartments();
                                      
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${employee.name} removed from ${department.name}',
                                              style: GoogleFonts.poppins(),
                                            ),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    debugPrint('Error updating employee: $e');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error: $e',
                                            style: GoogleFonts.poppins(),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmployeeList(List<Employee> employees) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: employees.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final employee = employees[index];
          return Container(
            width: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: ImageHelper.avatar(employee.avatarUrl),
                  child: employee.avatarUrl == null || employee.avatarUrl!.isEmpty
                      ? const Icon(Icons.person, size: 24)
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  employee.name.split(' ').first,
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                Text(
                  employee.position.split(' ').last,
                  style: GoogleFonts.poppins(fontSize: 8, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    DepartmentProvider provider,
    Department department,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Department',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete ${department.name}? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final success = await provider.deleteDepartment(department.id);
              if (context.mounted) {
                if (success) {
                  Navigator.pop(context); // Go back to list
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Department deleted successfully',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.error ?? 'Failed to delete department',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildInfoCard(Department department) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (department.code != null)
                Chip(
                  label: Text(
                    department.code!,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                )
              else
                Chip(
                  label: Text(
                    'Dept #${department.id}',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: AppColors.primary.withOpacity(0.7),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Active',
                  style: GoogleFonts.poppins(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.description,
            'Description',
            department.description ?? 'No description',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.person,
            'Head',
            department.head ?? 'Not assigned',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.attach_money,
            'Budget',
            department.budget != null
                ? NumberFormat.currency(locale: 'id', symbol: 'Rp ').format(department.budget)
                : 'No budget',
          ),
          const SizedBox(height: 12),
          if (department.cCode != null)
            _buildInfoRow(
              Icons.business,
              'Company Code',
              department.cCode!,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(Department department, List<Employee> employees) {
    final count = employees.isNotEmpty ? employees.length : (department.employees ?? 0);

    // Calculate total salary
    final totalSalary = employees.fold<double>(0.0, (sum, e) => sum + (e.salary ?? 0));

    // Calculate Budget Utilization if budget is available
    String utilization = 'N/A';
    double utilizationValue = 0.0;
    if (department.budget != null && department.budget! > 0) {
      utilizationValue = (totalSalary / department.budget!) * 100;
      utilization = '${utilizationValue.toStringAsFixed(1)}%';
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Employees',
                count.toString(),
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Budget',
                department.budget != null
                    ? NumberFormat.compact().format(department.budget)
                    : 'N/A',
                Icons.account_balance_wallet,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Payroll Cost',
                totalSalary > 0 ? NumberFormat.compact().format(totalSalary) : 'Rp 0',
                Icons.money_off,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Utilization',
                utilization,
                Icons.pie_chart,
                utilizationValue > 100 ? Colors.red : Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDistribution(List<Employee> employees) {
    final Map<String, int> distribution = {};
    for (var e in employees) {
      distribution[e.position] = (distribution[e.position] ?? 0) + 1;
    }

    // Sort by count descending
    final sortedEntries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: sortedEntries.map((e) {
          final percentage = (e.value / employees.length * 100).toStringAsFixed(1);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    e.key,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: e.value / employees.length,
                          backgroundColor: Colors.grey[100],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary.withOpacity(0.7),
                          ),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${e.value} ($percentage%)',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChildDepartmentCard(BuildContext context, Department child) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DepartmentDetailScreen(departmentId: child.id.toString())
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.subdirectory_arrow_right,
                color: Colors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Head: ${child.head ?? "N/A"}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${child.employees ?? 0} employees',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}