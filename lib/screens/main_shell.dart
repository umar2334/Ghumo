import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'explore_screen.dart';
import 'map_screen.dart';
import 'planner_screen.dart';
import 'saved_screen.dart';
import 'expenses_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ExploreScreen(),
    MapScreen(),
    PlannerScreen(),
    SavedScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.explore_outlined, activeIcon: Icons.explore_rounded, label: 'EXPLORE'),
    _NavItem(icon: Icons.map_outlined, activeIcon: Icons.map_rounded, label: 'MAP'),
    _NavItem(icon: Icons.route_outlined, activeIcon: Icons.route_rounded, label: 'PLANNER'),
    _NavItem(icon: Icons.bookmark_outline_rounded, activeIcon: Icons.bookmark_rounded, label: 'SAVED'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _GhumoBottomNav(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: (i) => setState(() => _currentIndex = i),
        onExpenseTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ExpensesScreen()),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

class _GhumoBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;
  final VoidCallback onExpenseTap;

  const _GhumoBottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
    required this.onExpenseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (int i = 0; i < 2; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    isActive: currentIndex == i,
                    onTap: () => onTap(i),
                  ),
                ),
              _CenterExpenseButton(onTap: onExpenseTap),
              for (int i = 2; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    isActive: currentIndex == i,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({required this.item, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? item.activeIcon : item.icon,
            color: isActive ? AppColors.primary : AppColors.textMuted,
            size: 22,
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: GoogleFonts.inter(
              color: isActive ? AppColors.primary : AppColors.textMuted,
              fontSize: 9,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterExpenseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CenterExpenseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  color: Colors.black, size: 20),
            ),
            const SizedBox(height: 3),
            Text(
              'EXPENSES',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
