import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../theme/app_theme.dart';

Future<T?> showAppSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.card,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            builder(ctx),
          ],
        ),
      ),
    ),
  );
}

void showMessage(BuildContext context, String message, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action));
}

Future<bool> confirm(BuildContext context, {required String title, required String body, required String action}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: txt(18, weight: 700)),
      content: Text(body, style: txt(14, color: AppColors.textSecondary, height: 1.5)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(action, style: const TextStyle(color: AppColors.danger)),
        ),
      ],
    ),
  );
  return result ?? false;
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.actions = const []});

  final IconData icon;
  final String title;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: AppColors.textMuted, size: 52),
        const SizedBox(height: 14),
        Text(title, textAlign: TextAlign.center, style: txt(18, weight: 700)),
        const SizedBox(height: 6),
        Text(message, textAlign: TextAlign.center, style: txt(14, color: AppColors.textSecondary, height: 1.5)),
        if (actions.isNotEmpty) const SizedBox(height: 20),
        for (final a in actions) Padding(padding: const EdgeInsets.only(bottom: 10), child: SizedBox(width: double.infinity, child: a)),
      ]),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: txt(11, weight: 700, spacing: 1.4, color: AppColors.primary));
}

class SheetTitle extends StatelessWidget {
  const SheetTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(text, style: txt(18, weight: 700)),
      );
}

class Pill extends StatelessWidget {
  const Pill({super.key, required this.icon, required this.label, this.color = AppColors.primary});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: txt(12, weight: 600, color: color))),
      ]),
    );
  }
}

class ActionTile extends StatelessWidget {
  const ActionTile({super.key, required this.icon, required this.label, required this.onTap, this.color = AppColors.textPrimary, this.subtitle});
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(label, style: txt(15, weight: 500, color: color)),
      subtitle: subtitle == null ? null : Text(subtitle!, style: txt(12, color: AppColors.textMuted)),
      onTap: onTap,
    );
  }
}

Color difficultyColor(String difficulty) => switch (difficulty) {
      'Easy' => AppColors.success,
      'Moderate' => AppColors.warning,
      _ => AppColors.danger,
    };
