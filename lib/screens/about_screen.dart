import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/app_scope.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _sources = [
    ('OpenStreetMap', 'Map data and nearby places', 'https://www.openstreetmap.org/copyright'),
    ('OpenTopoMap', 'Topographic map style', 'https://opentopomap.org/about'),
    ('Esri', 'Satellite imagery', 'https://www.esri.com/'),
    ('Open-Meteo', 'Weather forecasts', 'https://open-meteo.com/'),
    ('OSRM', 'Driving routes', 'https://project-osrm.org/'),
  ];

  Future<void> _open(BuildContext context, String url) async {
    final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication).catchError((_) => false);
    if (!opened && context.mounted) showMessage(context, 'Could not open the link');
  }

  Future<void> _reset(BuildContext context) async {
    final ok = await confirm(
      context,
      title: 'Erase all your data?',
      body: 'This removes your trips, expenses, saved places and checklist changes from this device. It cannot be undone.',
      action: 'Erase',
    );
    if (ok && context.mounted) {
      AppScope.read(context).resetAll();
      showMessage(context, 'Your data was erased');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.background, title: Text('About Ghumo', style: txt(18, weight: 700))),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
        Text('Ghumo is a travel companion for exploring Pakistan. It is version 1.0.0.',
            style: txt(15, color: AppColors.textSecondary, height: 1.6)),
        const SizedBox(height: 24),
        const SectionLabel('Your data'),
        const SizedBox(height: 8),
        Text('Trips, expenses and saved places are stored only on this device. There is no account, and nothing is uploaded.',
            style: txt(14, color: AppColors.textSecondary, height: 1.6)),
        ActionTile(
          icon: Icons.delete_outline_rounded,
          label: 'Erase all my data',
          color: AppColors.danger,
          onTap: () => _reset(context),
        ),
        const SizedBox(height: 16),
        const SectionLabel('What works offline'),
        const SizedBox(height: 8),
        Text('The destination guide, planner, expenses, checklist and emergency numbers all work offline. Map areas you have already viewed stay cached on your phone. Live weather, routes and nearby search need a connection.',
            style: txt(14, color: AppColors.textSecondary, height: 1.6)),
        const SizedBox(height: 24),
        const SectionLabel('Data sources'),
        for (final (name, use, url) in _sources)
          ActionTile(icon: Icons.open_in_new_rounded, label: name, subtitle: use, onTap: () => _open(context, url)),
        ActionTile(
          icon: Icons.code_rounded,
          label: 'Source code',
          subtitle: 'github.com/umar2334/Ghumo',
          onTap: () => _open(context, 'https://github.com/umar2334/Ghumo'),
        ),
      ]),
    );
  }
}
