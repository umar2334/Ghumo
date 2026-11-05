import 'package:flutter/material.dart';

import '../../services/routing_service.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';

BoxDecoration floatingPanel() => BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.divider),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 18, offset: const Offset(0, 6))],
    );

class MapButton extends StatelessWidget {
  const MapButton({super.key, required this.icon, required this.tooltip, required this.onTap, this.color});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface.withValues(alpha: 0.96),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color ?? AppColors.divider),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(width: 42, height: 42, child: Icon(icon, color: color ?? AppColors.textSecondary, size: 20)),
        ),
      ),
    );
  }
}

class MapBanner extends StatelessWidget {
  const MapBanner({super.key, required this.message, this.loading = false, this.icon = Icons.info_outline_rounded, this.action, this.onAction});
  final String message;
  final bool loading;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        color: AppColors.darkSlate,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Row(children: [
        if (loading)
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
        else
          Icon(icon, color: AppColors.primary, size: 17),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: txt(13, height: 1.3))),
        if (action != null)
          TextButton(
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            onPressed: onAction,
            child: Text(action!),
          ),
      ]),
    );
  }
}

class PlacePanel extends StatelessWidget {
  const PlacePanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onClose,
    required this.onRoute,
    required this.onNavigate,
    this.onDetails,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onClose;
  final VoidCallback onRoute;
  final VoidCallback onNavigate;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: floatingPanel(),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: txt(15, weight: 700)),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: txt(12, color: AppColors.textMuted)),
            ]),
          ),
          IconButton(tooltip: 'Close', onPressed: onClose, icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18)),
        ]),
        const SizedBox(height: 4),
        Wrap(spacing: 4, children: [
          TextButton.icon(onPressed: onRoute, icon: const Icon(Icons.directions_rounded, size: 16), label: const Text('Route')),
          TextButton.icon(onPressed: onNavigate, icon: const Icon(Icons.navigation_rounded, size: 16), label: const Text('Navigate')),
          if (onDetails != null)
            TextButton.icon(onPressed: onDetails, icon: const Icon(Icons.info_outline_rounded, size: 16), label: const Text('Details')),
        ]),
      ]),
    );
  }
}

class RoutePanel extends StatelessWidget {
  const RoutePanel({super.key, required this.route, required this.startLabel, required this.endLabel, required this.onClear});
  final RouteResult route;
  final String startLabel;
  final String endLabel;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: floatingPanel(),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.directions_rounded, color: AppColors.primary, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(spacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(formatDistance(route.distanceKm), style: txt(20, weight: 800)),
              if (route.durationSeconds != null)
                Text(formatDuration(route.durationSeconds!), style: txt(14, weight: 700, color: AppColors.primary)),
            ]),
          ),
          IconButton(tooltip: 'Clear route', onPressed: onClear, icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18)),
        ]),
        const SizedBox(height: 4),
        Text('$startLabel  →  $endLabel', maxLines: 2, overflow: TextOverflow.ellipsis, style: txt(12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          route.isEstimate
              ? 'No road route available, so this is a straight-line distance.'
              : 'Mountain roads and landslides can make the real drive much longer.',
          style: txt(11, color: route.isEstimate ? AppColors.warning : AppColors.textMuted),
        ),
      ]),
    );
  }
}
