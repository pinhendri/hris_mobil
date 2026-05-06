import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_strings.dart';
import '../providers/auth_provider.dart';
import '../providers/bot_assistant_provider.dart';
import '../providers/theme_provider.dart';
import 'bot/bot_assistant_screen.dart';
import 'tabs/approval_tab.dart';
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

  Future<void> _openBotAssistant() async {
    final authProvider = context.read<AuthProvider>();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => BotAssistantProvider(authProvider),
          child: const BotAssistantScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final tabs = <_MainNavigationItem>[
      _MainNavigationItem(
        label: context.tr('nav_home'),
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        screen: DashboardTab(
          onOpenFeatures: () {
            setState(() {
              _selectedIndex = 1;
            });
          },
        ),
      ),
      _MainNavigationItem(
        label: context.tr('nav_features'),
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view,
        screen: const FeatureTab(),
      ),
      _MainNavigationItem(
        label: context.tr('nav_approval'),
        icon: Icons.fact_check_outlined,
        activeIcon: Icons.fact_check_rounded,
        screen: const ApprovalTab(),
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
      floatingActionButton: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SizedBox(
          width: 68,
          height: 68,
          child: FloatingActionButton(
            heroTag: 'bot_assistant_launcher',
            tooltip: context.tr('feature_label_bot_assistant'),
            onPressed: _openBotAssistant,
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: Image.asset(
                  botAssistantAvatarAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.smart_toy_outlined, size: 24);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
