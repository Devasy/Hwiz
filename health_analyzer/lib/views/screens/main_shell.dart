import 'package:flutter/material.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/navigation/m3_floating_nav_bar.dart';
import 'home_tab.dart';
import 'ask_ai_screen.dart';

/// Main shell with floating M3 bottom navigation (2 tabs: Home & Ask AI)
class MainShell extends StatefulWidget {
  final Function(bool)? onAmoledModeChanged;
  final Function(String)? onThemeChanged;

  const MainShell({
    super.key,
    this.onAmoledModeChanged,
    this.onThemeChanged,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _navItems = [
    M3FloatingNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    M3FloatingNavItem(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome_rounded,
      label: 'Ask AI',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      const HomeTab(),
      const AskAiScreen(),
    ];

    return Scaffold(
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: tabs,
          ),
          M3FloatingNavBar(
            currentIndex: _currentIndex,
            items: _navItems,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ],
      ),
    );
  }
}
