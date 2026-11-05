import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/destinations.dart';
import '../models/models.dart';
import '../state/app_scope.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'destination_screen.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: SafeArea(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text('Saved', style: txt(26, weight: 800)),
            ),
            const TabBar(
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              dividerColor: AppColors.divider,
              tabs: [Tab(text: 'Places'), Tab(text: 'Packing'), Tab(text: 'Safety')],
            ),
            const Expanded(child: TabBarView(children: [_PlacesTab(), _PackingTab(), _SafetyTab()])),
          ]),
        ),
      ),
    );
  }
}

class _PlacesTab extends StatelessWidget {
  const _PlacesTab();

  @override
  Widget build(BuildContext context) {
    final saved = AppScope.store(context).savedDestinations;
    if (saved.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: EmptyState(
            icon: Icons.bookmark_outline_rounded,
            title: 'No saved places yet',
            message: 'Tap the bookmark on any destination to keep it here.',
            actions: [
              OutlinedButton(
                onPressed: () => AppScope.nav(context).tab.value = 0,
                child: Text('Browse destinations', style: txt(15, weight: 600, color: AppColors.primary)),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: saved.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final Destination d = saved[i];
        return ListTile(
          tileColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          leading: Icon(d.category.icon, color: AppColors.primary),
          title: Text(d.name, style: txt(15, weight: 600)),
          subtitle: Text(d.region, style: txt(12, color: AppColors.textMuted)),
          trailing: IconButton(
            tooltip: 'Remove ${d.name} from saved',
            icon: const Icon(Icons.bookmark_rounded, color: AppColors.primary),
            onPressed: () => AppScope.read(context).toggleSaved(d.id),
          ),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DestinationScreen(destination: d))),
        );
      },
    );
  }
}

class _PackingTab extends StatefulWidget {
  const _PackingTab();

  @override
  State<_PackingTab> createState() => _PackingTabState();
}

class _PackingTabState extends State<_PackingTab> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _add() {
    final label = _input.text.trim();
    if (label.isEmpty) return;
    AppScope.read(context).addChecklistItem(label);
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final items = AppScope.store(context).checklist;
    final done = items.where((i) => i.checked).length;
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('$done of ${items.length} packed', style: txt(13, color: AppColors.textSecondary)),
      const SizedBox(height: 12),
      TextField(
        key: const Key('checklist-input'),
        controller: _input,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _add(),
        decoration: InputDecoration(
          hintText: 'Add an item',
          suffixIcon: IconButton(tooltip: 'Add item', icon: const Icon(Icons.add_rounded, color: AppColors.primary), onPressed: _add),
        ),
      ),
      const SizedBox(height: 8),
      for (final item in items)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: item.checked,
          activeColor: AppColors.primary,
          checkColor: Colors.black,
          title: Text(item.label, style: txt(14)),
          secondary: IconButton(
            tooltip: 'Remove ${item.label}',
            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
            onPressed: () => AppScope.read(context).removeChecklistItem(item),
          ),
          onChanged: (_) => AppScope.read(context).toggleChecklist(item),
        ),
    ]);
  }
}

class _SafetyTab extends StatelessWidget {
  const _SafetyTab();

  Future<void> _call(BuildContext context, String number) async {
    final ok = await launchUrl(Uri(scheme: 'tel', path: number)).catchError((_) => false);
    if (!ok && context.mounted) showMessage(context, 'Calling is not available here. Dial $number');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('Emergency numbers', style: txt(16, weight: 600)),
      const SizedBox(height: 4),
      Text('Mobile signal is limited in many northern valleys, so tell someone your route before leaving.',
          style: txt(13, color: AppColors.textSecondary, height: 1.5)),
      const SizedBox(height: 14),
      for (final c in emergencyContacts)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            leading: const Icon(Icons.phone_in_talk_rounded, color: AppColors.danger),
            title: Text('${c.title}  ·  ${c.number}', style: txt(14, weight: 600)),
            subtitle: Text(c.subtitle, style: txt(12, color: AppColors.textMuted)),
            onTap: () => _call(context, c.number),
          ),
        ),
      const SizedBox(height: 14),
      Text('Altitude', style: txt(16, weight: 600)),
      const SizedBox(height: 6),
      Text('Above roughly 2,500 m, ascend gradually and watch for headache, nausea or dizziness. If symptoms get worse, go down and seek medical help.',
          style: txt(13, color: AppColors.textSecondary, height: 1.5)),
    ]);
  }
}
