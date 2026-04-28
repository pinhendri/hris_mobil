// lib/screens/admin/department_list_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/access_denied_state.dart';
import '../../providers/department_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/department_model.dart';
import 'add_edit_department_screen.dart';
import 'department_detail_screen.dart';

class DepartmentListScreen extends StatefulWidget {
  const DepartmentListScreen({super.key});

  @override
  State<DepartmentListScreen> createState() => _DepartmentListScreenState();
}

class _DepartmentListScreenState extends State<DepartmentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
      _isDarkMode ? const Color(0xFFF8FAFC) : Colors.black87;

  Color get _secondaryTextColor =>
      _isDarkMode ? const Color(0xFFCBD5E1) : Colors.grey.shade600;

  List<BoxShadow> get _cardShadow => _isDarkMode
      ? const []
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeData();
      }
    });
  }

  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final deptProvider = Provider.of<DepartmentProvider>(
      context,
      listen: false,
    );

    // Get company code from auth provider
    final companyCode = authProvider.getCompanyCode();
    print('📱 Company code from AuthProvider: $companyCode');

    // Set company code in department provider
    if (companyCode.isNotEmpty) {
      deptProvider.setCurrentCcode(companyCode);
    }

    // Fetch departments
    await deptProvider.fetchDepartments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final companyCode = authProvider.getCompanyCode();
    final canViewDepartment = authProvider.hasPermission('view-department');
    final canCreateDepartment = authProvider.hasPermission('create-department');

    if (!canViewDepartment) {
      return Scaffold(
        backgroundColor: _screenBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Master Departments',
            style: GoogleFonts.poppins(
              color: _primaryTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          backgroundColor: _surfaceColor,
          surfaceTintColor: _surfaceColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: _primaryTextColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const AccessDeniedState(permissionLabel: 'view-department'),
      );
    }

    return Scaffold(
      backgroundColor: _screenBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Master Departments',
              style: GoogleFonts.poppins(
                color: _primaryTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (companyCode.isNotEmpty)
              Text(
                'Company: $companyCode',
                style: GoogleFonts.poppins(
                  color: _secondaryTextColor,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        backgroundColor: _surfaceColor,
        surfaceTintColor: _surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: _primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (canCreateDepartment)
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.primary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddEditDepartmentScreen(),
                  ),
                ).then((_) {
                  Provider.of<DepartmentProvider>(
                    context,
                    listen: false,
                  ).fetchDepartments();
                });
              },
            ),
          IconButton(
            icon: Icon(Icons.refresh, color: _secondaryTextColor),
            onPressed: () {
              Provider.of<DepartmentProvider>(
                context,
                listen: false,
              ).fetchDepartments();
            },
          ),
        ],
      ),
      body: Consumer<DepartmentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.departments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading departments',
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _secondaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchDepartments(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildSearchBar()),
              // Show filter info if company code exists
              if (companyCode.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildFilterInfo(
                    companyCode,
                    provider.departments.length,
                  ),
                ),
              SliverToBoxAdapter(child: _buildSummaryCards(context, provider)),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: _buildDepartmentList(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterInfo(String companyCode, int totalDepartments) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue.withValues(alpha: _isDarkMode ? 0.16 : 0.08),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            size: 16,
            color: _isDarkMode ? const Color(0xFFBFDBFE) : Colors.blue[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing departments for company: $companyCode',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: _isDarkMode ? const Color(0xFFE0F2FE) : Colors.blue[900],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: _isDarkMode ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$totalDepartments departments',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: _isDarkMode ? const Color(0xFFDBEAFE) : Colors.blue[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: _surfaceColor,
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search by name or department code...',
          hintStyle: GoogleFonts.poppins(color: _secondaryTextColor),
          prefixIcon: Icon(Icons.search, color: _secondaryTextColor),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: _surfaceMutedColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: GoogleFonts.poppins(color: _primaryTextColor),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, DepartmentProvider provider) {
    final totalDepts = provider.departments.length;
    final totalEmployees = provider.getTotalEmployees();
    final totalBudget = provider.getTotalBudget();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      color: _surfaceColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildSummaryCard(
              'Total Departments',
              totalDepts.toString(),
              Icons.apartment,
              Colors.blue,
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              'Total Headcount',
              totalEmployees.toString(),
              Icons.people,
              Colors.orange,
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              'Total Budget',
              '\$${(totalBudget / 1000).toStringAsFixed(0)}k',
              Icons.attach_money,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _surfaceBorderColor),
        boxShadow: _cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: _secondaryTextColor,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _primaryTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentList(DepartmentProvider provider) {
    final departments = provider.departments.where((d) {
      final nameMatch = d.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final codeMatch =
          d.code?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      final idMatch = d.id.toString().contains(_searchQuery);
      // Also search by company code if available
      final cCodeMatch =
          d.cCode?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      return nameMatch || codeMatch || idMatch || cCodeMatch;
    }).toList();

    if (departments.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.business_center,
                size: 64,
                color: _secondaryTextColor.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty
                    ? 'No departments found'
                    : 'No matching departments',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: _secondaryTextColor,
                ),
              ),
              if (_searchQuery.isNotEmpty) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Text('Clear search'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final department = departments[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildDepartmentCard(context, department),
        );
      }, childCount: departments.length),
    );
  }

  Widget _buildDepartmentCard(BuildContext context, Department department) {
    final displayCode =
        department.code ?? 'DEPT-${department.id.toString().padLeft(3, '0')}';
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentCompanyCode = authProvider.getCompanyCode();

    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _surfaceBorderColor),
        boxShadow: _cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DepartmentDetailScreen(
                  departmentId: department.id.toString(),
                ),
              ),
            ).then((_) {
              // Refresh when returning from detail screen
              Provider.of<DepartmentProvider>(
                context,
                listen: false,
              ).fetchDepartments();
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      displayCode.split('-').last,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              department.name,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: _primaryTextColor,
                              ),
                            ),
                          ),
                          // Show company code badge if it exists and is different from current
                          if (department.cCode != null &&
                              department.cCode != currentCompanyCode) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                department.cCode!,
                                style: GoogleFonts.poppins(
                                  fontSize: 8,
                                  color: Colors.orange[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: department.growth > 0
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${department.growth.toStringAsFixed(1)}% growth',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: department.growth > 0
                                    ? Colors.green[800]
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Dept',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.blue[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          // Show department code if available
                          if (department.code != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                department.code!,
                                style: GoogleFonts.poppins(
                                  fontSize: 8,
                                  color: Colors.purple[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 14,
                            color: _secondaryTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${department.employees} Employees',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: _secondaryTextColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (department.head != null) ...[
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: _secondaryTextColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                department.head!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: _secondaryTextColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: _secondaryTextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
