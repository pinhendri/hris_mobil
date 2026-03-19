import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_strings.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'tabs/admin_tab.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/feature_tab.dart';
import 'tabs/profile_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isDark = themeProvider.isDarkMode;

    final tabs = <_MainNavigationItem>[
      _MainNavigationItem(
        label: context.tr('nav_dashboard'),
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        screen: const DashboardTab(),
      ),
      _MainNavigationItem(
        label: context.tr('nav_features'),
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view,
        screen: const FeatureTab(),
      ),
      if (authProvider.canAccessAdminPanel)
        _MainNavigationItem(
          label: context.tr('nav_admin'),
          icon: Icons.admin_panel_settings_outlined,
          activeIcon: Icons.admin_panel_settings,
          screen: const AdminTab(),
        ),
      _MainNavigationItem(
        label: context.tr('nav_profile'),
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        screen: const ProfileTab(),
      ),
    ];

    final currentIndex = _selectedIndex >= tabs.length
        ? tabs.length - 1
        : _selectedIndex;

    return Scaffold(
      body: tabs[currentIndex].screen,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        selectedItemColor: isDark ? Colors.blue.shade300 : Colors.blue,
        unselectedItemColor: isDark ? Colors.grey.shade600 : Colors.grey,
        items: tabs
            .map(
              (tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon),
                activeIcon: Icon(tab.activeIcon),
                label: tab.label,
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _MainNavigationItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;

  const _MainNavigationItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.screen,
  });
}
