import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/access_denied_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/claim_provider.dart';
import '../../providers/discovery_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/payroll_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/training_provider.dart';
import '../attendance/attendance_screen.dart';
import '../location/my_location_screen.dart';
import '../documents/document_screen.dart';
import '../discovery/discovery_screen.dart';
import '../clients/client_screen.dart';
import '../corrections/correction_screen.dart';
import '../leave/leave_screen.dart';
import '../payroll/payslip_screen.dart';
import '../performance/performance_screen.dart';
import '../recruitment/recruitment_screen.dart';
import '../inventory/inventory_screen.dart';
import '../saas/saas_workspace_screen.dart';
import '../training/training_screen.dart';
import '../tasks/tasks_screen.dart';
import '../claims/claims_screen.dart';
import '../admin/event_management_screen.dart';

class FeatureTab extends StatefulWidget {
  const FeatureTab({super.key});

  @override
  State<FeatureTab> createState() => _FeatureTabState();
}

class _FeatureTabState extends State<FeatureTab>
    with SingleTickerProviderStateMixin {
  static const double _maxContentWidth = 520;

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
    final hasActiveFilters =
        _searchQuery.isNotEmpty || selectedCategory != 'feature_category_all';

    if (availableFeatures.isEmpty) {
      return Scaffold(
        backgroundColor: _pageBackground(isDark),
        body: AccessDeniedState(
          title: context.tr('feature_no_active_title'),
          message: context.tr('feature_no_active_message'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _pageBackground(isDark),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            expandedHeight: 208,
            pinned: true,
            floating: true,
            snap: true,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: isDark
                ? const Color(0xFF0F1A2C)
                : const Color(0xFF2563EB),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [Color(0xFF0F172A), Color(0xFF1D4ED8)]
                        : const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      top: -96,
                      right: -36,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -64,
                      bottom: -84,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        child: _buildConstrainedContent(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.16,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.12,
                                        ),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.widgets_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        TweenAnimationBuilder<double>(
                                          duration: const Duration(
                                            milliseconds: 500,
                                          ),
                                          tween: Tween(begin: 0, end: 1),
                                          builder: (context, value, child) {
                                            return Opacity(
                                              opacity: value,
                                              child: Transform.translate(
                                                offset: Offset(
                                                  0,
                                                  16 * (1 - value),
                                                ),
                                                child: child,
                                              ),
                                            );
                                          },
                                          child: Text(
                                            context.tr('feature_header_title'),
                                            style: GoogleFonts.poppins(
                                              fontSize: 26,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        TweenAnimationBuilder<double>(
                                          duration: const Duration(
                                            milliseconds: 650,
                                          ),
                                          tween: Tween(begin: 0, end: 1),
                                          builder: (context, value, child) {
                                            return Opacity(
                                              opacity: value,
                                              child: Transform.translate(
                                                offset: Offset(
                                                  0,
                                                  16 * (1 - value),
                                                ),
                                                child: child,
                                              ),
                                            );
                                          },
                                          child: Text(
                                            context.tr(
                                              'feature_header_subtitle',
                                            ),
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              height: 1.45,
                                              color: Colors.white.withValues(
                                                alpha: 0.88,
                                              ),
                                            ),
                                          ),
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
                                  _buildHeaderPill(
                                    icon: Icons.grid_view_rounded,
                                    label:
                                        '${filteredFeatures.length} / ${availableFeatures.length}',
                                  ),
                                  _buildHeaderPill(
                                    icon: Icons.sell_outlined,
                                    label: _featureCategoryLabel(
                                      context,
                                      selectedCategory,
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty)
                                    _buildHeaderPill(
                                      icon: Icons.search_rounded,
                                      label: _searchQuery,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildConstrainedContent(
                _buildSearchAndFilterSection(
                  isDark: isDark,
                  categories: categories,
                  selectedCategory: selectedCategory,
                  availableCount: availableFeatures.length,
                  filteredCount: filteredFeatures.length,
                  hasActiveFilters: hasActiveFilters,
                ),
              ),
            ),
          ),

          if (filteredFeatures.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _buildConstrainedContent(
                  _buildEmptyFeatureState(isDark, selectedCategory),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _buildConstrainedContent(
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final layoutConfig = _resolveFeatureGridLayout(
                        constraints.maxWidth,
                      );

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredFeatures.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: layoutConfig.crossAxisCount,
                          mainAxisSpacing: layoutConfig.mainAxisSpacing,
                          crossAxisSpacing: layoutConfig.crossAxisSpacing,
                          mainAxisExtent: layoutConfig.mainAxisExtent,
                        ),
                        itemBuilder: (context, index) {
                          final feature = filteredFeatures[index];
                          return _buildFeatureCard(
                            context,
                            feature: feature,
                            isDark: isDark,
                            layoutConfig: layoutConfig,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                96 + MediaQuery.of(context).padding.bottom,
              ),
              child: _buildConstrainedContent(
                _buildFooterCard(
                  isDark: isDark,
                  availableCount: availableFeatures.length,
                  filteredCount: filteredFeatures.length,
                  hasActiveFilters: hasActiveFilters,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConstrainedContent(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: child,
      ),
    );
  }

  Color _pageBackground(bool isDark) {
    return isDark ? const Color(0xFF081120) : const Color(0xFFF3F6FB);
  }

  Color _surfaceColor(bool isDark) {
    return isDark ? const Color(0xFF101A2B) : Colors.white;
  }

  Color _surfaceBorderColor(bool isDark) {
    return isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFDCE5F0);
  }

  Color _subtleSurfaceColor(bool isDark) {
    return isDark
        ? Colors.white.withValues(alpha: 0.05)
        : const Color(0xFFF6F8FC);
  }

  List<BoxShadow> _surfaceShadows(bool isDark) {
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.28)
            : const Color(0xFF0F172A).withValues(alpha: 0.08),
        blurRadius: isDark ? 28 : 22,
        offset: const Offset(0, 12),
      ),
    ];
  }

  Widget _buildSectionCard({
    required bool isDark,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _surfaceColor(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _surfaceBorderColor(isDark)),
        boxShadow: _surfaceShadows(isDark),
      ),
      child: child,
    );
  }

  Widget _buildHeaderPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.92)),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill({
    required bool isDark,
    required IconData icon,
    required String label,
    Color? color,
  }) {
    final accent = color ?? (isDark ? Colors.blue.shade200 : Colors.blue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.28 : 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection({
    required bool isDark,
    required List<String> categories,
    required String selectedCategory,
    required int availableCount,
    required int filteredCount,
    required bool hasActiveFilters,
  }) {
    return _buildSectionCard(
      isDark: isDark,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'searchBar',
            child: Material(
              elevation: 0,
              color: Colors.transparent,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: _subtleSurfaceColor(isDark),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _surfaceBorderColor(isDark)),
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
                              Icons.clear_rounded,
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoPill(
                isDark: isDark,
                icon: Icons.dashboard_customize_outlined,
                label: '$filteredCount / $availableCount',
              ),
              if (hasActiveFilters)
                _buildInfoPill(
                  isDark: isDark,
                  icon: Icons.tune_rounded,
                  label: _featureCategoryLabel(context, selectedCategory),
                  color: isDark ? Colors.cyan.shade200 : Colors.indigo.shade600,
                ),
              if (_searchQuery.isNotEmpty)
                _buildInfoPill(
                  isDark: isDark,
                  icon: Icons.search_rounded,
                  label: _searchQuery,
                  color: isDark
                      ? Colors.orange.shade200
                      : Colors.orange.shade700,
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;

                return Padding(
                  padding: EdgeInsets.only(
                    right: index == categories.length - 1 ? 0 : 10,
                  ),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(_featureCategoryLabel(context, category)),
                    onSelected: (selected) {
                      setState(() => _selectedCategory = category);
                    },
                    backgroundColor: isDark
                        ? const Color(0xFF162238)
                        : const Color(0xFFF6F8FC),
                    selectedColor: isDark
                        ? Colors.blue.shade800
                        : Colors.blue.shade700,
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : _surfaceBorderColor(isDark),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white
                          : isDark
                          ? Colors.white70
                          : Colors.grey.shade700,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterCard({
    required bool isDark,
    required int availableCount,
    required int filteredCount,
    required bool hasActiveFilters,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF122033), Color(0xFF1D4ED8)]
              : const [Color(0xFFEAF2FF), Color(0xFFF7FAFF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFDCE7F5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.82),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context
                      .tr('feature_footer_count')
                      .replaceAll('{count}', availableCount.toString()),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasActiveFilters
                      ? '$filteredCount ${context.tr('feature_header_title').toLowerCase()}'
                      : context.tr('feature_footer_subtitle'),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.blue.shade200 : Colors.blue.shade700)
                      .withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_forward_rounded,
                color: isDark ? Colors.black87 : Colors.white,
                size: 16,
              ),
              onPressed: () {},
              padding: EdgeInsets.zero,
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
      FeatureItem(
        icon: Icons.event_available,
        labelKey: 'feature_label_event_management',
        gradient: const [Color(0xFF1D976C), Color(0xFF93F9B9)],
        screenBuilder: (_) => const EventManagementScreen(),
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
      if (authProvider.canAccessDocumentsModule)
        FeatureItem(
          icon: Icons.auto_awesome,
          labelKey: 'feature_label_discovery',
          gradient: const [Color(0xFF0F2027), Color(0xFF2C5364)],
          screenBuilder: (context) => ChangeNotifierProvider(
            create: (_) => DiscoveryProvider(
              Provider.of<AuthProvider>(context, listen: false),
            ),
            child: const DiscoveryScreen(),
          ),
          categoryKey: 'feature_category_operations',
          isPopular: true,
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
      FeatureItem(
        icon: Icons.shield_outlined,
        labelKey: 'feature_label_saas',
        gradient: const [Color(0xFF1565C0), Color(0xFF26C6DA)],
        screenBuilder: (_) => const SaasWorkspaceScreen(),
        categoryKey: 'feature_category_workspace',
        isPopular:
            authProvider.companyAssignments.length > 1 ||
            authProvider.canAccessPlatformAdmin,
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

    return _buildSectionCard(
      isDark: isDark,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
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
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.5,
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
    required _FeatureGridLayoutConfig layoutConfig,
  }) {
    final compact = layoutConfig.compact;
    final ultraCompact = layoutConfig.ultraCompact;
    final cardRadius = compact ? 18.0 : 22.0;
    final cardPadding = ultraCompact ? 8.0 : (compact ? 10.0 : 12.0);
    final iconSize = ultraCompact ? 18.0 : (compact ? 20.0 : 22.0);
    final iconBoxSize = ultraCompact ? 34.0 : (compact ? 38.0 : 42.0);
    final badgeSize = ultraCompact ? 22.0 : (compact ? 24.0 : 26.0);
    final titleFontSize = ultraCompact ? 10.5 : (compact ? 11.25 : 12.0);
    final chipFontSize = ultraCompact ? 7.0 : (compact ? 7.6 : 9.0);
    final chipHorizontalPadding = ultraCompact ? 6.0 : (compact ? 7.0 : 8.0);
    final chipVerticalPadding = ultraCompact ? 4.0 : 5.0;
    final bubbleSize = ultraCompact ? 60.0 : (compact ? 72.0 : 88.0);

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
          borderRadius: BorderRadius.circular(cardRadius),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cardRadius),
              gradient: LinearGradient(
                colors: feature.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: ultraCompact ? -14 : -18,
                  bottom: ultraCompact ? -14 : -18,
                  child: Container(
                    width: bubbleSize,
                    height: bubbleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),

                // Popular badge
                if (feature.isPopular)
                  Positioned(
                    top: ultraCompact ? 8 : 10,
                    right: ultraCompact ? 8 : 10,
                    child: Container(
                      width: badgeSize,
                      height: badgeSize,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ),

                Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: iconBoxSize,
                        height: iconBoxSize,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(
                            compact ? 14 : 16,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.24),
                          ),
                        ),
                        child: Icon(
                          feature.icon,
                          color: Colors.white,
                          size: iconSize,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        context.tr(feature.labelKey),
                        style: GoogleFonts.poppins(
                          fontSize: titleFontSize,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: compact ? 5 : 6),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: chipHorizontalPadding,
                          vertical: chipVerticalPadding,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _featureCategoryLabel(context, feature.categoryKey),
                          style: GoogleFonts.poppins(
                            fontSize: chipFontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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

  _FeatureGridLayoutConfig _resolveFeatureGridLayout(double availableWidth) {
    if (availableWidth >= 460) {
      return const _FeatureGridLayoutConfig(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 162,
        compact: true,
        ultraCompact: false,
      );
    }

    if (availableWidth >= 340) {
      return const _FeatureGridLayoutConfig(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 156,
        compact: true,
        ultraCompact: false,
      );
    }

    return const _FeatureGridLayoutConfig(
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      mainAxisExtent: 148,
      compact: true,
      ultraCompact: true,
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

class _FeatureGridLayoutConfig {
  const _FeatureGridLayoutConfig({
    required this.crossAxisCount,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
    required this.mainAxisExtent,
    required this.compact,
    required this.ultraCompact,
  });

  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double mainAxisExtent;
  final bool compact;
  final bool ultraCompact;
}
