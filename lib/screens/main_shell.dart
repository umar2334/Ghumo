import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'expenses_screen.dart';
import 'explore_screen.dart';
import 'map/map_screen.dart';
import 'planner_screen.dart';
import 'saved_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _items = [
    (icon: Icons.explore_outlined, active: Icons.explore_rounded, label: 'Explore'),
    (icon: Icons.map_outlined, active: Icons.map_rounded, label: 'Map'),
    (icon: Icons.route_outlined, active: Icons.route_rounded, label: 'Planner'),
    (icon: Icons.bookmark_outline_rounded, active: Icons.bookmark_rounded, label: 'Saved'),
  ];

  @override
  Widget build(BuildContext context) {
    final tab = AppScope.nav(context).tab;
    return ValueListenableBuilder<int>(
      valueListenable: tab,
      builder: (context, index, _) => Scaffold(
        body: IndexedStack(
          index: index,
          children: const [ExploreScreen(), MapScreen(), PlannerScreen(), SavedScreen()],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(children: [
                for (var i = 0; i < 2; i++) _navButton(tab, i, index),
                const _ExpensesButton(),
                for (var i = 2; i < _items.length; i++) _navButton(tab, i, index),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navButton(ValueNotifier<int> tab, int i, int current) {
    final item = _items[i];
    final active = i == current;
    final color = active ? AppColors.primary : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: () => tab.value = i,
        child: Semantics(
          selected: active,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(active ? item.active : item.icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(item.label, maxLines: 1, softWrap: false, overflow: TextOverflow.fade, style: txt(10, weight: active ? 700 : 500, color: color)),
          ]),
        ),
      ),
    );
  }
}

class _ExpensesButton extends StatelessWidget {
  const _ExpensesButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExpensesScreen())),
      child: SizedBox(
        width: 72,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_rounded, color: Colors.black, size: 19),
          ),
          const SizedBox(height: 2),
          Text('Expenses', maxLines: 1, softWrap: false, overflow: TextOverflow.fade, style: txt(10, weight: 700, color: AppColors.primary)),
        ]),
      ),
    );
  }
}
