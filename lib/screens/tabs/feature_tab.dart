import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../attendance/attendance_screen.dart';
import '../location/my_location_screen.dart';
import '../documents/document_screen.dart';
import '../clients/client_screen.dart';
import '../corrections/correction_screen.dart';
import '../leave/leave_screen.dart';
import '../payroll/payslip_screen.dart';
import '../performance/performance_screen.dart';
import '../recruitment/recruitment_screen.dart';
import '../inventory/inventory_screen.dart';
import '../training/training_screen.dart';
import '../tasks/tasks_screen.dart';
import '../claims/claims_screen.dart';

class FeatureTab extends StatefulWidget {
  const FeatureTab({super.key});

  @override
  State<FeatureTab> createState() => _FeatureTabState();
}

class _FeatureTabState extends State<FeatureTab> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Core HR',
    'Financial',
    'Operations',
    'Development',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // MARK: - Enhanced Header with Animation
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            floating: true,
            snap: true,
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.blue,
            flexibleSpace: FlexibleSpaceBar(
              background: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [Color(0xFF1A237E), Color(0xFF4A148C), Color(0xFF7B1FA2)]
                        : [Colors.blue.shade400, Colors.purple.shade400, Colors.pink.shade400],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 500),
                          tween: Tween(begin: 0, end: 1),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            'Explore Features',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 700),
                          tween: Tween(begin: 0, end: 1),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            'Everything you need to manage your work',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // MARK: - Enhanced Search Bar
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            sliver: SliverToBoxAdapter(
              child: Hero(
                tag: 'searchBar',
                child: Material(
                  elevation: 0,
                  color: Colors.transparent,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => _searchQuery = value.toLowerCase());
                      },
                      style: GoogleFonts.poppins(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search features...',
                        hintStyle: GoogleFonts.poppins(
                          color: isDark ? Colors.white38 : Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: isDark ? Colors.white38 : Colors.grey.shade400,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: isDark ? Colors.white38 : Colors.grey.shade400,
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // MARK: - Categories Filter
          SliverToBoxAdapter(
            child: Container(
              height: 50,
              margin: const EdgeInsets.only(left: 20),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(category),
                      onSelected: (selected) {
                        setState(() => _selectedCategory = category);
                      },
                      backgroundColor: isDark
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      selectedColor: isDark
                          ? Colors.blue.shade800
                          : Colors.blue,
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isSelected
                            ? Colors.white
                            : isDark
                            ? Colors.white70
                            : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // MARK: - Features Grid with Categories
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildListDelegate(
                _getFilteredFeatures().map((feature) =>
                    _buildFeatureCard(
                      context,
                      feature: feature,
                      isDark: isDark,
                    )
                ).toList(),
              ),
            ),
          ),

          // MARK: - Enhanced Footer
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF2C3E50), const Color(0xFF3498DB)]
                      : [Colors.blue.shade50, Colors.purple.shade50],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.lightbulb_outline_rounded,
                      color: isDark ? Colors.blue.shade300 : Colors.blue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need more features?',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contact your administrator to enable additional modules',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.blue.shade300 : Colors.blue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? Colors.blue.shade300 : Colors.blue).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_forward_rounded,
                        color: isDark ? Colors.black87 : Colors.white,
                        size: 18,
                      ),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Feature Model
  List<FeatureItem> _getAllFeatures() {
    return [
      FeatureItem(
        icon: Icons.receipt_long,
        label: 'Payslip',
        gradient: const [Color(0xFF4158D0), Color(0xFFC850C0)],
        screen: const PayslipScreen(),
        category: 'Financial',
        isPopular: false,
      ),
      FeatureItem(
        icon: Icons.calendar_today,
        label: 'Leave',
        gradient: const [Color(0xFFFF9966), Color(0xFFFF5E62)],
        screen: const LeaveScreen(),
        category: 'Core HR',
        isPopular: true,
      ),
      FeatureItem(
        icon: Icons.access_time,
        label: 'Attendance',
        gradient: const [Color(0xFF11998e), Color(0xFF38ef7d)],
        screen: const AttendanceScreen(),
        category: 'Core HR',
        isPopular: true,
      ),
      FeatureItem(
        icon: Icons.pin_drop,
        label: 'My Location',
        gradient: const [Color(0xFF3a1c71), Color(0xFFd76d77), Color(0xFFFFaf7b)],
        screen: const MyLocationScreen(),
        category: 'Operations',
        isPopular: false,
      ),
      FeatureItem(
        icon: Icons.monetization_on,
        label: 'Claims',
        gradient: const [Color(0xFFAA076B), Color(0xFF61045F)],
        screen: const ClaimsScreen(),
        category: 'Financial',
        isPopular: false,
      ),
      FeatureItem(
        icon: Icons.trending_up,
        label: 'Performance',
        gradient: const [Color(0xFF02AAB0), Color(0xFF00CDAC)],
        screen: const PerformanceScreen(),
        category: 'Core HR',
        isPopular: false,
      ),
      FeatureItem(
        icon: Icons.work_outline,
        label: 'Recruitment',
        gradient: const [Color(0xFF4568DC), Color(0xFFB06AB3)],
        screen: const RecruitmentScreen(),
        category: 'Core HR',
        isPopular: false,
      ),
      FeatureItem(
        icon: Icons.inventory_2_outlined,
        label: 'Inventory',
        gradient: const [Color(0xFF2193b0), Color(0xFF6dd5ed)],
        screen: const InventoryScreen(),
        category: 'Operations',
        isPopular: false,
      ),
      FeatureItem(
        icon: Icons.school_outlined,
        label: 'Training',
        gradient: const [Color(0xFF834d9b), Color(0xFFd04ed6)],
        screen: const TrainingScreen(),
        category: 'Development',
        isPopular: false,
      ),
      FeatureItem(
        icon: Icons.check_circle_outline,
        label: 'Tasks',
        gradient: const [Color(0xFFF09819), Color(0xFFEDDE5D)],
        screen: const TasksScreen(),
        category: 'Operations',
        isPopular: true,
      ),
      FeatureItem(
        icon: Icons.folder_open,
        label: 'Documents',
        gradient: const [Color(0xFF757F9A), Color(0xFFD7DDE8)],
        screen: const DocumentScreen(),
        category: 'Operations',
        isPopular: false,
      ),
      FeatureItem(
        icon: Icons.business,
        label: 'Clients',
        gradient: const [Color(0xFF5A3F37), Color(0xFF2C7744)],
        screen: const ClientScreen(),
        category: 'Operations',
        isPopular: false,
      ),
      FeatureItem(
        icon: Icons.build_circle_outlined,
        label: 'Corrections',
        gradient: const [Color(0xFFCB356B), Color(0xFFBD3F32)],
        screen: const CorrectionScreen(),
        category: 'Core HR',
        isPopular: false,
      ),
    ];
  }

  List<FeatureItem> _getFilteredFeatures() {
    var features = _getAllFeatures();

    // Filter by category
    if (_selectedCategory != 'All') {
      features = features.where((f) => f.category == _selectedCategory).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      features = features.where((f) =>
          f.label.toLowerCase().contains(_searchQuery)
      ).toList();
    }

    return features;
  }

  Widget _buildFeatureCard(
      BuildContext context, {
        required FeatureItem feature,
        required bool isDark,
      }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (feature.label.hashCode % 300)),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.9 + (0.1 * value),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _animationController.forward().then((_) {
              _animationController.reverse();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => feature.screen),
              );
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: feature.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background pattern
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Icon(
                    feature.icon,
                    size: 60,
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),

                // Popular badge
                if (feature.isPopular)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '🔥',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon container dengan efek glass morphism
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          feature.icon,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Label
                      Text(
                        feature.label,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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

// MARK: - Feature Model
class FeatureItem {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final Widget screen;
  final String category;
  final bool isPopular;

  FeatureItem({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.screen,
    required this.category,
    this.isPopular = false,
  });
}