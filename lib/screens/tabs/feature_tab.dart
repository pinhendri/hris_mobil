import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bot_assistant_provider.dart';
import '../../providers/claim_provider.dart';
import '../../providers/discovery_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/payroll_provider.dart';
import '../../providers/saas_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/training_provider.dart';
import '../../services/api_service.dart';
import '../admin/event_management_screen.dart';
import '../attendance/attendance_screen.dart';
import '../bot/bot_assistant_screen.dart';
import '../claims/claims_screen.dart';
import '../clients/client_screen.dart';
import '../corrections/correction_screen.dart';
import '../discovery/discovery_screen.dart';
import '../documents/document_screen.dart';
import '../inventory/inventory_screen.dart';
import '../leave/leave_screen.dart';
import '../location/my_location_screen.dart';
import '../overtime/overtime_screen.dart';
import '../payroll/payslip_screen.dart';
import '../performance/performance_screen.dart';
import '../recruitment/recruitment_screen.dart';
import '../saas/saas_workspace_screen.dart';
import '../tasks/tasks_screen.dart';
import '../training/training_screen.dart';

class FeatureTab extends StatefulWidget {
  const FeatureTab({super.key});

  @override
  State<FeatureTab> createState() => _FeatureTabState();
}

class _FeatureTabState extends State<FeatureTab> {
  static const double _maxContentWidth = 840;
  static const Color _accentColor = AppColors.primary;
  static const Color _lightBackground = Color(0xFFF6F4F1);
  static const Color _darkBackground = Color(0xFF121212);
  static const Set<String> _leaveManagementToneFeatures = <String>{
    'feature_label_leave',
    'feature_label_attendance',
    'feature_label_claims',
    'feature_label_overtime',
    'feature_label_tasks',
  };

  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _searchQuery = '';
  String _selectedCategory = 'feature_category_all';
  String? _lastFeatureContextKey;
  String? _lastFeatureUserKey;
  Map<String, bool> _featureCapabilityFlags = const <String, bool>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final authProvider = context.read<AuthProvider>();
    final userKey = authProvider.user?.uuid.trim() ?? '';
    final contextKey = [
      userKey,
      authProvider.getCompanyCode().trim(),
      ...authProvider.permissions,
    ].join('|');

    if (_lastFeatureUserKey != null && _lastFeatureUserKey != userKey) {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = 'feature_category_all';
    }

    if (_lastFeatureContextKey == contextKey) {
      return;
    }

    _lastFeatureUserKey = userKey;
    _lastFeatureContextKey = contextKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshFeatureCapabilities(authProvider);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final saasProvider = context.watch<SaasProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
    final currentCompany =
        saasProvider.currentCompany ?? authProvider.selectedCompany;
    final companyName = currentCompany?.companyName.trim().isNotEmpty == true
        ? currentCompany!.companyName.trim()
        : 'Company Name';

    return Scaffold(
      backgroundColor: isDark ? _darkBackground : _lightBackground,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            18,
            14,
            18,
            28 + MediaQuery.of(context).padding.bottom,
          ),
          children: [
            _buildConstrainedContent(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(companyName: companyName, isDark: isDark),
                  const SizedBox(height: 18),
                  _buildIntroCard(
                    isDark: isDark,
                    availableCount: availableFeatures.length,
                    filteredCount: filteredFeatures.length,
                    selectedCategory: selectedCategory,
                    hasActiveFilters: hasActiveFilters,
                  ),
                  const SizedBox(height: 16),
                  _buildSearchAndFilterSection(
                    isDark: isDark,
                    categories: categories,
                    selectedCategory: selectedCategory,
                    hasActiveFilters: hasActiveFilters,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context.tr('nav_features'), isDark),
                  const SizedBox(height: 14),
                  if (availableFeatures.isEmpty)
                    _buildNoAccessState(isDark)
                  else if (filteredFeatures.isEmpty)
                    _buildEmptyFeatureState(isDark, selectedCategory)
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final layoutConfig = _resolveFeatureGridLayout(
                          constraints.maxWidth,
                        );

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredFeatures.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
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
                  const SizedBox(height: 24),
                  _buildFooterCard(
                    isDark: isDark,
                    availableCount: availableFeatures.length,
                    filteredCount: filteredFeatures.length,
                    hasActiveFilters: hasActiveFilters,
                  ),
                ],
              ),
            ),
          ],
        ),
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

  Color _surfaceColor(bool isDark) {
    return isDark ? const Color(0xFF1C1C1C) : Colors.white;
  }

  Color _surfaceBorderColor(bool isDark) {
    return isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFEAE7E2);
  }

  TextStyle _titleStyle(
    bool isDark, {
    double size = 17,
    FontWeight weight = FontWeight.w700,
    Color? color,
    double height = 1.2,
  }) {
    return TextStyle(
      color: color ?? (isDark ? Colors.white : const Color(0xFF1F2937)),
      fontSize: size,
      fontWeight: weight,
      height: height,
    );
  }

  TextStyle _bodyStyle(
    bool isDark, {
    double size = 13,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double height = 1.4,
  }) {
    return TextStyle(
      color: color ?? (isDark ? Colors.white60 : const Color(0xFF6B7280)),
      fontSize: size,
      fontWeight: weight,
      height: height,
    );
  }

  _FeatureTone _toneForCategory(String categoryKey, bool isDark) {
    switch (categoryKey) {
      case 'feature_category_financial':
        return _FeatureTone(
          iconColor: const Color(0xFF2B74D8),
          softColor: isDark ? const Color(0x332B74D8) : const Color(0xFFEAF3FF),
          chipColor: const Color(0xFF2B74D8),
        );
      case 'feature_category_core_hr':
        return _FeatureTone(
          iconColor: const Color(0xFFFF9628),
          softColor: isDark ? const Color(0x33FF9628) : const Color(0xFFFFF1E3),
          chipColor: const Color(0xFFFF9628),
        );
      case 'feature_category_operations':
        return _FeatureTone(
          iconColor: const Color(0xFF2F9D78),
          softColor: isDark ? const Color(0x332F9D78) : const Color(0xFFEAF8F2),
          chipColor: const Color(0xFF2F9D78),
        );
      case 'feature_category_development':
        return _FeatureTone(
          iconColor: const Color(0xFF8B5CF6),
          softColor: isDark ? const Color(0x338B5CF6) : const Color(0xFFF3EEFF),
          chipColor: const Color(0xFF8B5CF6),
        );
      case 'feature_category_workspace':
        return _FeatureTone(
          iconColor: const Color(0xFF4F46E5),
          softColor: isDark ? const Color(0x334F46E5) : const Color(0xFFEEF0FF),
          chipColor: const Color(0xFF4F46E5),
        );
      default:
        return _FeatureTone(
          iconColor: _accentColor,
          softColor: isDark ? const Color(0x33FF9628) : const Color(0xFFFFF1E3),
          chipColor: _accentColor,
        );
    }
  }

  _FeatureTone _toneForFeature(FeatureItem feature, bool isDark) {
    if (_leaveManagementToneFeatures.contains(feature.labelKey)) {
      return _toneForCategory('feature_category_core_hr', isDark);
    }

    return _toneForCategory(feature.categoryKey, isDark);
  }

  Widget _buildTopBar({required String companyName, required bool isDark}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            companyName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _titleStyle(
              isDark,
              size: 18,
              color: isDark ? Colors.white : const Color(0xFF1E1E1E),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildIconShell(
          icon: Icons.search_rounded,
          isDark: isDark,
          onTap: () => _searchFocusNode.requestFocus(),
        ),
      ],
    );
  }

  Widget _buildIntroCard({
    required bool isDark,
    required int availableCount,
    required int filteredCount,
    required String selectedCategory,
    required bool hasActiveFilters,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _surfaceBorderColor(isDark)),
        boxShadow: _surfaceShadows(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isDark
                      ? _accentColor.withValues(alpha: 0.18)
                      : const Color(0xFFFFF1E3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: _accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('feature_header_title'),
                      style: _titleStyle(isDark, size: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('feature_header_subtitle'),
                      style: _bodyStyle(isDark),
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
              _buildInfoChip(
                label:
                    '${context.tr('feature_footer_count').replaceAll('{count}', availableCount.toString())} | $filteredCount',
                isDark: isDark,
              ),
              _buildInfoChip(
                label: _featureCategoryLabel(context, selectedCategory),
                isDark: isDark,
                color: hasActiveFilters
                    ? const Color(0xFF3478F6)
                    : const Color(0xFF7A7A7A),
              ),
              if (_searchQuery.isNotEmpty)
                _buildInfoChip(
                  label: _searchQuery,
                  isDark: isDark,
                  color: _accentColor,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection({
    required bool isDark,
    required List<String> categories,
    required String selectedCategory,
    required bool hasActiveFilters,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _surfaceBorderColor(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF8F6F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFEAE7E2),
              ),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF222222),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
              decoration: InputDecoration(
                hintText: context.tr('feature_search_hint'),
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                ),
                suffixIcon: hasActiveFilters
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _selectedCategory = 'feature_category_all';
                          });
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark
                              ? Colors.white54
                              : const Color(0xFF7B7B7B),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories
                .map((category) {
                  final isSelected = selectedCategory == category;

                  return FilterChip(
                    selected: isSelected,
                    showCheckmark: false,
                    label: Text(_featureCategoryLabel(context, category)),
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : const Color(0xFFF8F6F2),
                    selectedColor: _accentColor,
                    side: BorderSide(
                      color: isSelected
                          ? _accentColor
                          : isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFEAE7E2),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : isDark
                          ? Colors.white70
                          : const Color(0xFF5B5B5B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: _titleStyle(
        isDark,
        size: 17,
        color: isDark ? Colors.white : const Color(0xFF2A2A2A),
      ),
    );
  }

  Widget _buildNoAccessState(bool isDark) {
    return _buildMessageCard(
      isDark: isDark,
      icon: Icons.lock_outline_rounded,
      iconColor: _accentColor,
      title: context.tr('feature_no_active_title'),
      subtitle: context.tr('feature_no_active_message'),
    );
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

    return _buildMessageCard(
      isDark: isDark,
      icon: Icons.filter_alt_off_rounded,
      iconColor: _accentColor,
      title: context.tr('feature_empty_title'),
      subtitle: subtitle,
    );
  }

  Widget _buildMessageCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surfaceColor(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _surfaceBorderColor(isDark)),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: _titleStyle(isDark, size: 17),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: _bodyStyle(isDark, height: 1.45),
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
    final tone = _toneForFeature(feature, isDark);
    final iconBoxSize = compact ? 42.0 : 46.0;
    final titleSize = compact ? 13.0 : 14.0;
    final categoryLabel = _featureCategoryLabel(context, feature.categoryKey);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 220 + (feature.labelKey.hashCode % 160)),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: feature.screenBuilder));
          },
          child: Container(
            padding: EdgeInsets.all(compact ? 14 : 16),
            decoration: BoxDecoration(
              color: _surfaceColor(isDark),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _surfaceBorderColor(isDark)),
              boxShadow: _surfaceShadows(isDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: iconBoxSize,
                      height: iconBoxSize,
                      decoration: BoxDecoration(
                        color: tone.softColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        feature.icon,
                        color: tone.iconColor,
                        size: 22,
                      ),
                    ),
                    const Spacer(),
                    if (feature.isPopular)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: _accentColor,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      Icon(
                        Icons.arrow_outward_rounded,
                        size: 18,
                        color: isDark
                            ? Colors.white38
                            : const Color(0xFF9CA3AF),
                      ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: tone.softColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    categoryLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _bodyStyle(
                      isDark,
                      size: 10,
                      weight: FontWeight.w700,
                      color: tone.chipColor,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr(feature.labelKey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _titleStyle(isDark, size: titleSize, height: 1.25),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        categoryLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _bodyStyle(isDark, size: 11, height: 1.2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: tone.iconColor,
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

  Widget _buildFooterCard({
    required bool isDark,
    required int availableCount,
    required int filteredCount,
    required bool hasActiveFilters,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _surfaceBorderColor(isDark)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isDark
                  ? _accentColor.withValues(alpha: 0.18)
                  : const Color(0xFFFFF1E3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.insights_outlined, color: _accentColor),
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
                  style: _titleStyle(isDark, size: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  hasActiveFilters
                      ? '$filteredCount ${context.tr('nav_features').toLowerCase()}'
                      : context.tr('feature_footer_subtitle'),
                  style: _bodyStyle(isDark, size: 12, height: 1.35),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF8F6F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$filteredCount / $availableCount',
              style: _titleStyle(isDark, size: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required String label,
    required bool isDark,
    Color? color,
  }) {
    final resolvedColor =
        color ?? (isDark ? Colors.white70 : const Color(0xFF5E6470));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: _bodyStyle(
          isDark,
          size: 12,
          weight: FontWeight.w700,
          color: resolvedColor,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildIconShell({
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : const Color(0xFFE5E5E5),
            ),
          ),
          child: Icon(
            icon,
            color: isDark ? Colors.white70 : const Color(0xFF444444),
          ),
        ),
      ),
    );
  }

  List<BoxShadow> _surfaceShadows(bool isDark) {
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.18)
            : const Color(0x140F172A),
        blurRadius: isDark ? 18 : 14,
        offset: const Offset(0, 8),
      ),
    ];
  }

  List<FeatureItem> _getAllFeatures(AuthProvider authProvider) {
    final canAccessPayrollFeature = authProvider.hasPermission('view-payroll');
    final canAccessLeaveFeature = _canAccessLeaveFeature(authProvider);
    final canAccessAttendanceFeature = authProvider.hasPermission(
      'view-attendance',
    );
    final canAccessLocationFeature = canAccessAttendanceFeature;
    final canAccessClaimsFeature = _canAccessClaimsFeature(authProvider);
    final canAccessOvertimeFeature = _canAccessOvertimeFeature(authProvider);
    final canAccessPerformanceFeature = _canAccessPerformanceFeature(
      authProvider,
    );
    final canAccessRecruitmentFeature = authProvider.hasPermission(
      'view-recruitment',
    );
    final canAccessInventoryFeature = _canAccessInventoryFeature(authProvider);
    final canAccessTrainingFeature = _canAccessTrainingFeature(authProvider);
    final canAccessTimeTrackingFeature = _canAccessTimeTrackingFeature(
      authProvider,
    );
    final canAccessEventFeature = _canAccessEventFeature(authProvider);
    final canAccessDocumentsFeature = authProvider.hasPermission(
      'view-documents',
    );
    final canAccessClientsFeature = authProvider.hasPermission('view-client');
    final canAccessCorrectionsFeature = _canAccessCorrectionsFeature(
      authProvider,
    );

    return [
      if (canAccessPayrollFeature)
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
      if (canAccessLeaveFeature)
        FeatureItem(
          icon: Icons.calendar_today,
          labelKey: 'feature_label_leave',
          gradient: const [Color(0xFFFF9966), Color(0xFFFF5E62)],
          screenBuilder: (_) => const LeaveScreen(),
          categoryKey: 'feature_category_core_hr',
          isPopular: true,
        ),
      if (canAccessAttendanceFeature)
        FeatureItem(
          icon: Icons.access_time,
          labelKey: 'feature_label_attendance',
          gradient: const [Color(0xFF11998E), Color(0xFF38EF7D)],
          screenBuilder: (_) => const AttendanceScreen(),
          categoryKey: 'feature_category_core_hr',
          isPopular: true,
        ),
      if (canAccessLocationFeature)
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
      if (canAccessClaimsFeature)
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
      if (canAccessOvertimeFeature)
        FeatureItem(
          icon: Icons.schedule_send_outlined,
          labelKey: 'feature_label_overtime',
          gradient: const [Color(0xFFB45309), Color(0xFFF59E0B)],
          screenBuilder: (_) => const OvertimeScreen(),
          categoryKey: 'feature_category_core_hr',
          isPopular: false,
        ),
      if (canAccessPerformanceFeature)
        FeatureItem(
          icon: Icons.trending_up,
          labelKey: 'feature_label_performance',
          gradient: const [Color(0xFF02AAB0), Color(0xFF00CDAC)],
          screenBuilder: (_) => const PerformanceScreen(),
          categoryKey: 'feature_category_core_hr',
          isPopular: false,
        ),
      if (canAccessRecruitmentFeature)
        FeatureItem(
          icon: Icons.work_outline,
          labelKey: 'feature_label_recruitment',
          gradient: const [Color(0xFF4568DC), Color(0xFFB06AB3)],
          screenBuilder: (_) => const RecruitmentScreen(),
          categoryKey: 'feature_category_core_hr',
          isPopular: false,
        ),
      if (canAccessInventoryFeature)
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
      if (canAccessTrainingFeature)
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
      if (canAccessTimeTrackingFeature)
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
      if (canAccessEventFeature)
        FeatureItem(
          icon: Icons.event_available,
          labelKey: 'feature_label_event_management',
          gradient: const [Color(0xFF1D976C), Color(0xFF93F9B9)],
          screenBuilder: (_) => const EventManagementScreen(),
          categoryKey: 'feature_category_operations',
          isPopular: true,
        ),
      if (canAccessDocumentsFeature)
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
      if (canAccessDocumentsFeature)
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
      FeatureItem(
        icon: Icons.smart_toy_outlined,
        labelKey: 'feature_label_bot_assistant',
        gradient: const [Color(0xFF0F172A), Color(0xFF1D4ED8)],
        screenBuilder: (context) => ChangeNotifierProvider(
          create: (_) => BotAssistantProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          child: const BotAssistantScreen(),
        ),
        categoryKey: 'feature_category_operations',
        isPopular: true,
      ),
      if (canAccessClientsFeature)
        FeatureItem(
          icon: Icons.business,
          labelKey: 'feature_label_clients',
          gradient: const [Color(0xFF5A3F37), Color(0xFF2C7744)],
          screenBuilder: (_) => const ClientScreen(),
          categoryKey: 'feature_category_operations',
          isPopular: false,
        ),
      if (canAccessCorrectionsFeature)
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

  bool _canAccessClaimsFeature(AuthProvider authProvider) {
    return authProvider.hasAnyPermission([
          'view-claims',
          'view-claim',
          'view-claims-management',
          'create-claims',
          'create-claim',
          'edit-claims',
          'edit-claim',
          'view-claims-self',
        ]) ||
        _featureCapabilityFlags['claims'] == true ||
        authProvider.canAccessClaimsModule;
  }

  bool _canAccessOvertimeFeature(AuthProvider authProvider) {
    return authProvider.hasAnyPermission([
          'view-overtime',
          'view-overtime-self',
          'create-overtime',
          'edit-overtime',
        ]) ||
        _featureCapabilityFlags['overtime'] == true;
  }

  bool _canAccessLeaveFeature(AuthProvider authProvider) {
    return authProvider.hasAnyPermission([
          'view-leave',
          'create-leave',
          'edit-leave',
        ]) ||
        _featureCapabilityFlags['leave'] == true;
  }

  bool _canAccessPerformanceFeature(AuthProvider authProvider) {
    return authProvider.hasAnyPermission([
      'view-kpi',
      'view-kpi-master',
      'view-kpi-evaluation',
      'view-department-goals',
      'view-employee-goals',
      'view-performance',
    ]);
  }

  bool _canAccessTrainingFeature(AuthProvider authProvider) {
    return authProvider.hasPermission('view-lms');
  }

  bool _canAccessInventoryFeature(AuthProvider authProvider) {
    return authProvider.hasAnyPermission([
      'view-inventory-master',
      'view-inventory-request',
      'view-inventory-receipt',
      'view-inventory-report',
      'view-inventory-issued',
    ]);
  }

  bool _canAccessTimeTrackingFeature(AuthProvider authProvider) {
    return authProvider.hasAnyPermission([
      'view-time-tracking',
      'create-time-tracking',
    ]);
  }

  bool _canAccessEventFeature(AuthProvider authProvider) {
    return authProvider.hasPermission('view-settings');
  }

  bool _canAccessCorrectionsFeature(AuthProvider authProvider) {
    return authProvider.hasPermission('view-settings');
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

    if (selectedCategory != 'feature_category_all') {
      filteredFeatures = filteredFeatures
          .where((feature) => feature.categoryKey == selectedCategory)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filteredFeatures = filteredFeatures
          .where(
            (feature) => context
                .tr(feature.labelKey)
                .toLowerCase()
                .contains(_searchQuery),
          )
          .toList();
    }

    return filteredFeatures;
  }

  String _featureCategoryLabel(BuildContext context, String categoryKey) {
    return context.tr(categoryKey);
  }

  _FeatureGridLayoutConfig _resolveFeatureGridLayout(double availableWidth) {
    if (availableWidth >= 720) {
      return const _FeatureGridLayoutConfig(
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        mainAxisExtent: 184,
        compact: false,
      );
    }

    if (availableWidth >= 520) {
      return const _FeatureGridLayoutConfig(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        mainAxisExtent: 176,
        compact: true,
      );
    }

    if (availableWidth >= 320) {
      return const _FeatureGridLayoutConfig(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 172,
        compact: false,
      );
    }

    return const _FeatureGridLayoutConfig(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      mainAxisExtent: 164,
      compact: false,
    );
  }

  Future<void> _refreshFeatureCapabilities(AuthProvider authProvider) async {
    final nextFlags = <String, bool>{};

    if (authProvider.isAuthenticated) {
      if (!_canAccessClaimsFromPermissions(authProvider)) {
        nextFlags['claims'] = await _probeFeatureEndpoint('/claims');
      }

      if (!_canAccessOvertimeFromPermissions(authProvider)) {
        nextFlags['overtime'] = await _probeFeatureEndpoint('/overtime');
      }

      if (!_canAccessLeaveFromPermissions(authProvider)) {
        nextFlags['leave'] = await _probeFeatureEndpoint('/leave-balance');
      }
    }

    if (!mounted) {
      return;
    }

    if (_mapsEqual(_featureCapabilityFlags, nextFlags)) {
      return;
    }

    setState(() {
      _featureCapabilityFlags = nextFlags;
    });
  }

  bool _canAccessClaimsFromPermissions(AuthProvider authProvider) {
    return authProvider.hasAnyPermission([
          'view-claims',
          'view-claim',
          'view-claims-management',
          'create-claims',
          'create-claim',
          'edit-claims',
          'edit-claim',
          'view-claims-self',
        ]) ||
        authProvider.canAccessClaimsModule;
  }

  bool _canAccessOvertimeFromPermissions(AuthProvider authProvider) {
    return authProvider.hasAnyPermission([
      'view-overtime',
      'view-overtime-self',
      'create-overtime',
      'edit-overtime',
    ]);
  }

  bool _canAccessLeaveFromPermissions(AuthProvider authProvider) {
    return authProvider.hasAnyPermission([
      'view-leave',
      'create-leave',
      'edit-leave',
    ]);
  }

  Future<bool> _probeFeatureEndpoint(String endpoint) async {
    try {
      await _apiService.get(endpoint);
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _mapsEqual(Map<String, bool> left, Map<String, bool> right) {
    if (left.length != right.length) {
      return false;
    }

    for (final entry in left.entries) {
      if (right[entry.key] != entry.value) {
        return false;
      }
    }

    return true;
  }
}

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

class _FeatureTone {
  const _FeatureTone({
    required this.iconColor,
    required this.softColor,
    required this.chipColor,
  });

  final Color iconColor;
  final Color softColor;
  final Color chipColor;
}

class _FeatureGridLayoutConfig {
  const _FeatureGridLayoutConfig({
    required this.crossAxisCount,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
    required this.mainAxisExtent,
    required this.compact,
  });

  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double mainAxisExtent;
  final bool compact;
}
