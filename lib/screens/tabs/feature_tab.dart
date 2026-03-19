import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/access_denied_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/claim_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/payroll_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/training_provider.dart';
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

class _FeatureTabState extends State<FeatureTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'feature_category_all';

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
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final availableFeatures = _getAllFeatures(authProvider);
    final categories = _buildAvailableCategories(availableFeatures);
    final selectedCategory = categories.contains(_selectedCategory)
        ? _selectedCategory
        : 'feature_category_all';
    final filteredFeatures = _getFilteredFeatures(
      context,
      availableFeatures,
      selectedCategory,
    );

    if (availableFeatures.isEmpty) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0A0A0A)
            : const Color(0xFFF8F9FA),
        body: AccessDeniedState(
          title: context.tr('feature_no_active_title'),
          message: context.tr('feature_no_active_message'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF8F9FA),
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
                        ? const [
                            Color(0xFF1A237E),
                            Color(0xFF4A148C),
                            Color(0xFF7B1FA2),
                          ]
                        : [
                            Colors.blue.shade400,
                            Colors.purple.shade400,
                            Colors.pink.shade400,
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
                            context.tr('feature_header_title'),
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
                            context.tr('feature_header_subtitle'),
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
                        hintText: context.tr('feature_search_hint'),
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
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.grey.shade400,
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
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = selectedCategory == category;

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(_featureCategoryLabel(context, category)),
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
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
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
          if (filteredFeatures.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildEmptyFeatureState(isDark, selectedCategory),
              ),
            )
          else
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
                  filteredFeatures
                      .map(
                        (feature) => _buildFeatureCard(
                          context,
                          feature: feature,
                          isDark: isDark,
                        ),
                      )
                      .toList(),
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
                          context
                              .tr('feature_footer_count')
                              .replaceAll(
                                '{count}',
                                availableFeatures.length.toString(),
                              ),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('feature_footer_subtitle'),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white60
                                : Colors.grey.shade600,
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
                          color: (isDark ? Colors.blue.shade300 : Colors.blue)
                              .withOpacity(0.3),
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
  List<FeatureItem> _getAllFeatures(AuthProvider authProvider) {
    return [
      if (authProvider.canAccessPayrollModule)
        FeatureItem(
          icon: Icons.receipt_long,
          labelKey: 'feature_label_payslip',
          gradient: const [Color(0xFF4158D0), Color(0xFFC850C0)],
          screenBuilder: (_) => ChangeNotifierProvider(
            create: (_) => PayrollProvider(),
            child: const PayslipScreen(),
          ),
          categoryKey: 'feature_category_financial',
          isPopular: false,
        ),
      if (authProvider.canAccessLeaveModule)
        FeatureItem(
          icon: Icons.calendar_today,
          labelKey: 'feature_label_leave',
          gradient: const [Color(0xFFFF9966), Color(0xFFFF5E62)],
          screenBuilder: (_) => const LeaveScreen(),
          categoryKey: 'feature_category_core_hr',
          isPopular: true,
        ),
      if (authProvider.canAccessAttendanceModule)
        FeatureItem(
          icon: Icons.access_time,
          labelKey: 'feature_label_attendance',
          gradient: const [Color(0xFF11998E), Color(0xFF38EF7D)],
          screenBuilder: (_) => const AttendanceScreen(),
          categoryKey: 'feature_category_core_hr',
          isPopular: true,
        ),
      if (authProvider.canAccessLocationModule)
        FeatureItem(
          icon: Icons.pin_drop,
          labelKey: 'feature_label_my_location',
          gradient: const [
            Color(0xFF3A1C71),
            Color(0xFFD76D77),
            Color(0xFFFFAF7B),
          ],
          screenBuilder: (_) => const MyLocationScreen(),
          categoryKey: 'feature_category_operations',
          isPopular: false,
        ),
      if (authProvider.canAccessClaimsModule)
        FeatureItem(
          icon: Icons.monetization_on,
          labelKey: 'feature_label_claims',
          gradient: const [Color(0xFFAA076B), Color(0xFF61045F)],
          screenBuilder: (_) => ChangeNotifierProvider(
            create: (_) => ClaimProvider(),
            child: const ClaimsScreen(),
          ),
          categoryKey: 'feature_category_financial',
          isPopular: false,
        ),
      if (authProvider.canAccessPerformanceModule)
        FeatureItem(
          icon: Icons.trending_up,
          labelKey: 'feature_label_performance',
          gradient: const [Color(0xFF02AAB0), Color(0xFF00CDAC)],
          screenBuilder: (_) => const PerformanceScreen(),
          categoryKey: 'feature_category_core_hr',
          isPopular: false,
        ),
      if (authProvider.canAccessRecruitmentModule)
        FeatureItem(
          icon: Icons.work_outline,
          labelKey: 'feature_label_recruitment',
          gradient: const [Color(0xFF4568DC), Color(0xFFB06AB3)],
          screenBuilder: (_) => const RecruitmentScreen(),
          categoryKey: 'feature_category_core_hr',
          isPopular: false,
        ),
      if (authProvider.canAccessInventoryModule)
        FeatureItem(
          icon: Icons.inventory_2_outlined,
          labelKey: 'feature_label_inventory',
          gradient: const [Color(0xFF2193B0), Color(0xFF6DD5ED)],
          screenBuilder: (_) => ChangeNotifierProvider(
            create: (_) => InventoryProvider(),
            child: const InventoryScreen(),
          ),
          categoryKey: 'feature_category_operations',
          isPopular: false,
        ),
      FeatureItem(
        icon: Icons.school_outlined,
        labelKey: 'feature_label_training',
        gradient: const [Color(0xFF834D9B), Color(0xFFD04ED6)],
        screenBuilder: (_) => ChangeNotifierProvider(
          create: (_) => TrainingProvider(),
          child: const TrainingScreen(),
        ),
        categoryKey: 'feature_category_development',
        isPopular: false,
      ),
      FeatureItem(
        icon: Icons.check_circle_outline,
        labelKey: 'feature_label_tasks',
        gradient: const [Color(0xFFF09819), Color(0xFFEDDE5D)],
        screenBuilder: (_) => ChangeNotifierProvider(
          create: (_) => TaskProvider(),
          child: const TasksScreen(),
        ),
        categoryKey: 'feature_category_operations',
        isPopular: true,
      ),
      if (authProvider.canAccessDocumentsModule)
        FeatureItem(
          icon: Icons.folder_open,
          labelKey: 'feature_label_documents',
          gradient: const [Color(0xFF757F9A), Color(0xFFD7DDE8)],
          screenBuilder: (_) => ChangeNotifierProvider(
            create: (_) => DocumentProvider(),
            child: const DocumentScreen(),
          ),
          categoryKey: 'feature_category_operations',
          isPopular: false,
        ),
      if (authProvider.canAccessClientModule)
        FeatureItem(
          icon: Icons.business,
          labelKey: 'feature_label_clients',
          gradient: const [Color(0xFF5A3F37), Color(0xFF2C7744)],
          screenBuilder: (_) => const ClientScreen(),
          categoryKey: 'feature_category_operations',
          isPopular: false,
        ),
      if (authProvider.canAccessCorrectionsModule)
        FeatureItem(
          icon: Icons.build_circle_outlined,
          labelKey: 'feature_label_corrections',
          gradient: const [Color(0xFFCB356B), Color(0xFFBD3F32)],
          screenBuilder: (_) => const CorrectionScreen(),
          categoryKey: 'feature_category_core_hr',
          isPopular: false,
        ),
    ];
  }

  List<String> _buildAvailableCategories(List<FeatureItem> features) {
    final categories =
        features.map((feature) => feature.categoryKey).toSet().toList()..sort();

    return ['feature_category_all', ...categories];
  }

  List<FeatureItem> _getFilteredFeatures(
    BuildContext context,
    List<FeatureItem> features,
    String selectedCategory,
  ) {
    var filteredFeatures = features;

    // Filter by category
    if (selectedCategory != 'feature_category_all') {
      filteredFeatures = filteredFeatures
          .where((f) => f.categoryKey == selectedCategory)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredFeatures = filteredFeatures
          .where(
            (f) => context.tr(f.labelKey).toLowerCase().contains(_searchQuery),
          )
          .toList();
    }

    return filteredFeatures;
  }

  String _featureCategoryLabel(BuildContext context, String categoryKey) {
    return context.tr(categoryKey);
  }

  Widget _buildEmptyFeatureState(bool isDark, String selectedCategory) {
    final categoryLabel = _featureCategoryLabel(context, selectedCategory);
    final subtitle = _searchQuery.isNotEmpty
        ? context.tr('feature_empty_search').replaceAll('{query}', _searchQuery)
        : selectedCategory == 'feature_category_all'
        ? context.tr('feature_empty_all')
        : context
              .tr('feature_empty_category')
              .replaceAll('{category}', categoryLabel);

    return Container(
      padding: const EdgeInsets.all(24),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.filter_alt_off_rounded,
              color: Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('feature_empty_title'),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required FeatureItem feature,
    required bool isDark,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (feature.labelKey.hashCode % 300)),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(scale: 0.9 + (0.1 * value), child: child),
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
                MaterialPageRoute(builder: feature.screenBuilder),
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
                      child: const Text('🔥', style: TextStyle(fontSize: 10)),
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
                        context.tr(feature.labelKey),
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
  final String labelKey;
  final List<Color> gradient;
  final WidgetBuilder screenBuilder;
  final String categoryKey;
  final bool isPopular;

  FeatureItem({
    required this.icon,
    required this.labelKey,
    required this.gradient,
    required this.screenBuilder,
    required this.categoryKey,
    this.isPopular = false,
  });
}
