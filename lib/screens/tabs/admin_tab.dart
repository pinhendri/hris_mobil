import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/department_provider.dart'; // Add this import
import '../attendance/attendance_settings_screen.dart';
import '../admin/department_list_screen.dart';
import '../employee/employee_list_screen.dart';
import '../admin/master_shift_screen.dart';
import '../admin/shift_assignment_screen.dart';
import '../admin/leave_management_screen.dart';
import '../admin/correction_management_screen.dart';
import '../admin/claim_management_screen.dart';
import '../admin/claim_reports_screen.dart';

class AdminTab extends StatelessWidget {
  const AdminTab({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Header dengan gradient dan statistik
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            floating: false,
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.blue.shade800,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1A237E),
                            Color(0xFF4A148C),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade800,
                            Colors.purple.shade700,
                          ],
                        ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Admin Panel',
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Manage your organization',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Statistik cards
                        Row(
                          children: [
                            _buildStatCard('25', 'Departments', Icons.business, isDark),
                            const SizedBox(width: 12),
                            _buildStatCard('128', 'Employees', Icons.people, isDark),
                            const SizedBox(width: 12),
                            _buildStatCard('12', 'Pending', Icons.pending_actions, isDark),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Quick Actions Section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quick Actions',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Online',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickAction(
                        icon: Icons.person_add_alt_1,
                        label: 'Add Emp',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChangeNotifierProvider(
                                create: (_) => DepartmentProvider(),
                                child: const DepartmentListScreen(),
                              ),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                      _buildQuickAction(
                        icon: Icons.schedule,
                        label: 'Shift',
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MasterShiftScreen(),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                      _buildQuickAction(
                        icon: Icons.beach_access,
                        label: 'Leave',
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LeaveManagementScreen(),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                      _buildQuickAction(
                        icon: Icons.bar_chart,
                        label: 'Reports',
                        color: Colors.purple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ClaimReportsScreen(),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Master Data Section
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: _buildSectionHeader(
                title: 'Master Data',
                icon: Icons.storage,
                color: Colors.blue,
                isDark: isDark,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildAdminMenuCard(
                  context,
                  title: 'Master Department',
                  subtitle: 'Manage company departments',
                  icon: Icons.business,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                  ),
                  badge: '3 new',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeNotifierProvider(
                          create: (_) => DepartmentProvider(),
                          child: const DepartmentListScreen(),
                        ),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildAdminMenuCard(
                  context,
                  title: 'Master Employee',
                  subtitle: 'Manage employees and roles',
                  icon: Icons.people_alt,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9966), Color(0xFFFF5E62)],
                  ),
                  badge: '12 active',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmployeeListScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildAdminMenuCard(
                  context,
                  title: 'Master Shift',
                  subtitle: 'Create and edit shifts',
                  icon: Icons.schedule,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                  ),
                  badge: '5 shifts',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MasterShiftScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
              ]),
            ),
          ),

          // Configuration Section
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
            sliver: SliverToBoxAdapter(
              child: _buildSectionHeader(
                title: 'Configuration',
                icon: Icons.settings_applications,
                color: Colors.purple,
                isDark: isDark,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildAdminMenuCard(
                  context,
                  title: 'Attendance Settings',
                  subtitle: 'Configure radius and locations',
                  icon: Icons.location_on,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3a1c71), Color(0xFFd76d77)],
                  ),
                  badge: 'Active',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AttendanceSettingsScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildAdminMenuCard(
                  context,
                  title: 'Shift Assignment',
                  subtitle: 'Create and track shift orders',
                  icon: Icons.assignment_turned_in,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFAA076B), Color(0xFF61045F)],
                  ),
                  badge: '2 pending',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ShiftAssignmentScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
              ]),
            ),
          ),

          // Management Section
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
            sliver: SliverToBoxAdapter(
              child: _buildSectionHeader(
                title: 'Management',
                icon: Icons.manage_accounts,
                color: Colors.green,
                isDark: isDark,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildAdminMenuCard(
                  context,
                  title: 'Leave Management',
                  subtitle: 'Review and approve leave requests',
                  icon: Icons.beach_access,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF02AAB0), Color(0xFF00CDAC)],
                  ),
                  badge: '8 requests',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LeaveManagementScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildAdminMenuCard(
                  context,
                  title: 'Correction Management',
                  subtitle: 'Review attendance correction requests',
                  icon: Icons.edit_calendar,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4568DC), Color(0xFFB06AB3)],
                  ),
                  badge: '3 pending',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CorrectionManagementScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildAdminMenuCard(
                  context,
                  title: 'Claim Management',
                  subtitle: 'Review and approve employee claims',
                  icon: Icons.request_quote,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
                  ),
                  badge: '5 claims',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ClaimManagementScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildAdminMenuCard(
                  context,
                  title: 'Claim Reports',
                  subtitle: 'Analytics for claims and reimbursements',
                  icon: Icons.bar_chart,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF834d9b), Color(0xFFd04ed6)],
                  ),
                  badge: 'Reports',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ClaimReportsScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'View All',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminMenuCard(
    BuildContext context, {
      required String title,
      required String subtitle,
      required IconData icon,
      required Gradient gradient,
      String? badge,
      required VoidCallback onTap,
      required bool isDark,
    }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon dengan efek glass morphism
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                badge,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow dengan efek glass
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}