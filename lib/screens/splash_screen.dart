import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

/// Welcome screen, shown on first launch only.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  void _start(BuildContext context) {
    AppScope.read(context).completeOnboarding();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.darkSlate, AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                const Icon(Icons.terrain_rounded, color: AppColors.primary, size: 72),
                const SizedBox(height: 16),
                Text('GHUMO', style: txt(44, weight: 800, spacing: 6, color: AppColors.primary)),
                const SizedBox(height: 8),
                Text('Explore the unexplored.', style: txt(20, weight: 600)),
                const SizedBox(height: 28),
                const _Feature(Icons.explore_rounded, 'A guide to Pakistan\'s valleys, peaks and heritage'),
                const _Feature(Icons.map_rounded, 'Live maps, routes and nearby fuel or hospitals'),
                const _Feature(Icons.route_rounded, 'Trip planning and budgets that stay on your phone'),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _start(context),
                    child: Text('Start exploring', style: txt(16, weight: 700, color: Colors.black)),
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

class _Feature extends StatelessWidget {
  const _Feature(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: txt(14, color: AppColors.textSecondary, height: 1.4))),
      ]),
    );
  }
}
