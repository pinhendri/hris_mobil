import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/access_denied_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employee_provider.dart';
import '../../models/employee_model.dart'; // PASTIKAN IMPORT INI ADA
import 'add_employee_screen.dart';
import 'employee_detail_screen.dart';
import '../../core/utils/image_helper.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key, this.selfOnly = false});

  final bool selfOnly;

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  Color get _screenBackgroundColor =>
      _isDarkMode ? const Color(0xFF020817) : AppColors.background;

  Color get _surfaceColor =>
      _isDarkMode ? const Color(0xFF111827) : Colors.white;

  Color get _surfaceMutedColor =>
      _isDarkMode ? const Color(0xFF0F172A) : AppColors.surface;

  Color get _surfaceBorderColor =>
      _isDarkMode ? const Color(0xFF253041) : AppColors.border;

  Color get _primaryTextColor =>
      _isDarkMode ? const Color(0xFFF8FAFC) : AppColors.textPrimary;

  Color get _secondaryTextColor =>
      _isDarkMode ? const Color(0xFFCBD5E1) : AppColors.textSecondary;

  List<BoxShadow> get _cardShadow => _isDarkMode
      ? const []
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<EmployeeProvider>(context, listen: false);
      if (widget.selfOnly) {
        provider.fetchCurrentUserEmployeeProfile();
      } else {
        provider.fetchEmployees();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final canViewEmployee = widget.selfOnly
        ? authProvider.hasPermission('view-employee-one') ||
              authProvider.canViewEmployeeScreen
        : authProvider.canViewEmployeeScreen;
    final canCreateEmployee =
        !widget.selfOnly && authProvider.hasPermission('create-employee');
    final title = widget.selfOnly
        ? context.tr('feature_label_employee_one')
        : context.tr('admin_master_employee');

    if (!canViewEmployee) {
      return Scaffold(
        backgroundColor: _screenBackgroundColor,
        appBar: AppBar(
          title: Text(
            title,
            style: GoogleFonts.poppins(
              color: _primaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: _surfaceColor,
          surfaceTintColor: _surfaceColor,
          elevation: 0,
          iconTheme: IconThemeData(color: _primaryTextColor),
        ),
        body: const AccessDeniedState(permissionLabel: 'view/manage employee'),
      );
    }

    return Scaffold(
      backgroundColor: _screenBackgroundColor,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: _primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _surfaceColor,
        surfaceTintColor: _surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: _primaryTextColor),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.selfOnly) _buildSearchBar(),
          Expanded(
            child: Consumer<EmployeeProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredEmployees = provider.employees.where((employee) {
                  final query = _searchQuery.toLowerCase();
                  return employee.name.toLowerCase().contains(query) ||
                      employee.position.toLowerCase().contains(query) ||
                      employee.department.toLowerCase().contains(query);
                }).toList();

                if (filteredEmployees.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredEmployees.length,
                  itemBuilder: (context, index) {
                    return _buildEmployeeCard(
                      context,
                      filteredEmployees[index],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: canCreateEmployee
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEmployeeScreen(),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: _surfaceColor,
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search employees...',
          hintStyle: GoogleFonts.poppins(color: _secondaryTextColor),
          prefixIcon: Icon(Icons.search, color: _secondaryTextColor),
          filled: true,
          fillColor: _surfaceMutedColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        style: GoogleFonts.poppins(color: _primaryTextColor),
      ),
    );
  }

  Widget _buildEmployeeCard(BuildContext context, Employee employee) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _surfaceBorderColor),
        boxShadow: _cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmployeeDetailScreen(employee: employee),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage:
                      employee.avatarUrl != null &&
                          employee.avatarUrl!.isNotEmpty
                      ? ImageHelper.avatar(employee.avatarUrl)
                      : null,
                  child:
                      (employee.avatarUrl == null ||
                          employee.avatarUrl!.isEmpty)
                      ? Text(
                          employee.name.substring(0, 2).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        employee.position,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: _secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _surfaceMutedColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          employee.department,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: _secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          employee.status,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        employee.status,
                        style: GoogleFonts.poppins(
                          color: _getStatusColor(employee.status),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: _secondaryTextColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No employees found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: _secondaryTextColor.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'on leave':
        return Colors.orange;
      case 'inactive':
      case 'deactive':
        return Colors.grey;
      case 'terminated':
      case 'resigned':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }
}
