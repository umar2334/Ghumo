import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';

import '../data/destinations.dart';
import '../models/models.dart';
import '../state/app_scope.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/trip_form.dart';
import 'expenses_screen.dart';

/// Plain-text itinerary, used for sharing.
String itineraryText(Trip trip) {
  final b = StringBuffer(trip.name);
  if (trip.budget > 0) b.write('\nBudget: ${formatPkr(trip.budget)}');
  b.writeln('\n');
  for (var i = 0; i < trip.stops.length; i++) {
    final s = trip.stops[i];
    b.write('${i + 1}. ${s.day == null ? '' : 'Day ${s.day}: '}${s.name}${s.done ? ' (done)' : ''}\n');
    if (s.notes != null) b.write('   ${s.notes}\n');
  }
  b.write('\nPlanned with Ghumo');
  return b.toString();
}

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.store(context);
    final trip = store.activeTrip;
    if (trip == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: EmptyState(
                icon: Icons.route_rounded,
                title: 'Plan your first trip',
                message: 'Build a day-by-day route, track your budget, and share the itinerary.',
                actions: [
                  ElevatedButton(
                    key: const Key('new-trip'),
                    onPressed: () => showTripForm(context),
                    child: Text('Create a trip', style: txt(15, weight: 700, color: Colors.black)),
                  ),
                  OutlinedButton(
                    key: const Key('sample-trip'),
                    onPressed: store.createSampleTrip,
                    child: Text('Try a sample trip', style: txt(15, weight: 600, color: AppColors.primary)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        key: const Key('add-stop'),
        tooltip: 'Add stop',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        shape: const CircleBorder(),
        onPressed: () => _showStopForm(context, trip),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 96), children: [
          Row(children: [
            Expanded(
              child: InkWell(
                onTap: () => _showTripSwitcher(context),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SectionLabel('Current trip'),
                  const SizedBox(height: 4),
                  Row(children: [
                    Flexible(child: Text(trip.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: txt(24, weight: 800))),
                    const Icon(Icons.expand_more_rounded, color: AppColors.textSecondary),
                  ]),
                ]),
              ),
            ),
            IconButton(
              tooltip: 'Trip options',
              icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textSecondary),
              onPressed: () => _showOptions(context, trip),
            ),
          ]),
          if (trip.isSample) ...[
            const SizedBox(height: 8),
            Text('This is sample data. Delete it from trip options whenever you like.', style: txt(12, color: AppColors.warning)),
          ],
          const SizedBox(height: 16),
          _BudgetSummary(trip: trip),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Timeline', style: txt(18, weight: 600)),
            Text('${trip.completedStops}/${trip.stops.length} done', style: txt(13, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 12),
          if (trip.stops.isEmpty)
            const EmptyState(
              icon: Icons.add_location_alt_rounded,
              title: 'No stops yet',
              message: 'Tap + to add a stop, or use "Add to trip" on any destination.',
            ),
          for (var i = 0; i < trip.stops.length; i++)
            _StopCard(trip: trip, stop: trip.stops[i], index: i),
        ]),
      ),
    );
  }

  void _showTripSwitcher(BuildContext context) {
    showAppSheet<void>(context, builder: (sheet) {
      final store = AppScope.store(sheet);
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SheetTitle('Your trips'),
        for (final t in store.trips)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              t.id == store.activeTrip?.id ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: AppColors.primary,
            ),
            title: Text(t.name, style: txt(15, weight: 500)),
            subtitle: Text('${t.stops.length} stops · ${formatPkr(t.totalSpent)} spent', style: txt(12, color: AppColors.textMuted)),
            onTap: () {
              store.setActiveTrip(t);
              Navigator.pop(sheet);
            },
          ),
        ActionTile(
          icon: Icons.add_rounded,
          label: 'New trip',
          color: AppColors.primary,
          onTap: () {
            Navigator.pop(sheet);
            showTripForm(context);
          },
        ),
      ]);
    });
  }

  void _showOptions(BuildContext context, Trip trip) {
    showAppSheet<void>(context, builder: (sheet) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ActionTile(
          icon: Icons.share_rounded,
          label: 'Share itinerary',
          onTap: () {
            Navigator.pop(sheet);
            Share.share(itineraryText(trip), subject: trip.name);
          },
        ),
        ActionTile(
          icon: Icons.edit_rounded,
          label: 'Edit trip',
          onTap: () {
            Navigator.pop(sheet);
            showTripForm(context, trip: trip);
          },
        ),
        ActionTile(
          icon: Icons.delete_outline_rounded,
          label: 'Delete trip',
          color: AppColors.danger,
          onTap: () async {
            Navigator.pop(sheet);
            final ok = await confirm(
              context,
              title: 'Delete "${trip.name}"?',
              body: 'Its stops and expenses will be removed too. This cannot be undone.',
              action: 'Delete',
            );
            if (ok && context.mounted) AppScope.read(context).deleteTrip(trip);
          },
        ),
      ]);
    });
  }
}

void _showStopForm(BuildContext context, Trip trip, {TripStop? stop}) {
  showAppSheet<void>(context, builder: (_) => _StopForm(trip: trip, stop: stop));
}

class _BudgetSummary extends StatelessWidget {
  const _BudgetSummary({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final over = trip.isOverBudget;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExpensesScreen())),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Spent', style: txt(12, color: AppColors.textSecondary)),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
          ]),
          Text(formatPkr(trip.totalSpent), style: txt(24, weight: 800)),
          const SizedBox(height: 10),
          if (trip.budget > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: trip.budgetUsed,
                minHeight: 6,
                backgroundColor: AppColors.divider,
                color: over ? AppColors.danger : AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              over
                  ? '${formatPkr(-trip.remaining)} over your ${formatPkr(trip.budget)} budget'
                  : '${formatPkr(trip.remaining)} left of ${formatPkr(trip.budget)}',
              style: txt(12, color: over ? AppColors.danger : AppColors.textSecondary),
            ),
          ] else
            Text('No budget set. Add one from trip options.', style: txt(12, color: AppColors.textMuted)),
        ]),
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  const _StopCard({required this.trip, required this.stop, required this.index});
  final Trip trip;
  final TripStop stop;
  final int index;

  void _showActions(BuildContext context) {
    final destination = destinationById(stop.destinationId);
    final store = AppScope.read(context);
    showAppSheet<void>(context, builder: (sheet) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SheetTitle(stop.name),
        if (destination != null)
          ActionTile(
            icon: Icons.map_rounded,
            label: 'Show on map',
            onTap: () {
              Navigator.pop(sheet);
              AppScope.nav(context).showOnMap(MapTarget(LatLng(destination.lat, destination.lon), destination.id));
            },
          ),
        ActionTile(
          icon: Icons.edit_rounded,
          label: 'Edit stop',
          onTap: () {
            Navigator.pop(sheet);
            _showStopForm(context, trip, stop: stop);
          },
        ),
        if (index > 0)
          ActionTile(
            icon: Icons.arrow_upward_rounded,
            label: 'Move up',
            onTap: () {
              store.moveStop(trip, stop, -1);
              Navigator.pop(sheet);
            },
          ),
        if (index < trip.stops.length - 1)
          ActionTile(
            icon: Icons.arrow_downward_rounded,
            label: 'Move down',
            onTap: () {
              store.moveStop(trip, stop, 1);
              Navigator.pop(sheet);
            },
          ),
        ActionTile(
          icon: Icons.delete_outline_rounded,
          label: 'Remove stop',
          color: AppColors.danger,
          onTap: () {
            store.removeStop(trip, stop);
            Navigator.pop(sheet);
          },
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showActions(context),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: stop.done ? AppColors.primary.withValues(alpha: 0.35) : AppColors.divider),
          ),
          child: Row(children: [
            Checkbox(
              value: stop.done,
              activeColor: AppColors.primary,
              checkColor: Colors.black,
              onChanged: (_) => AppScope.read(context).toggleStop(stop),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (stop.day != null) Text('DAY ${stop.day}', style: txt(10, weight: 700, spacing: 1.2, color: AppColors.primary)),
                Text(stop.name, style: txt(15, weight: 600, color: stop.done ? AppColors.textSecondary : AppColors.textPrimary)),
                if (stop.notes != null) ...[
                  const SizedBox(height: 3),
                  Text(stop.notes!, style: txt(12, color: AppColors.textSecondary, height: 1.4)),
                ],
              ]),
            ),
            const Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 18),
          ]),
        ),
      ),
    );
  }
}

class _StopForm extends StatefulWidget {
  const _StopForm({required this.trip, this.stop});
  final Trip trip;
  final TripStop? stop;

  @override
  State<_StopForm> createState() => _StopFormState();
}

class _StopFormState extends State<_StopForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.stop?.name);
  late final _day = TextEditingController(text: widget.stop?.day?.toString());
  late final _notes = TextEditingController(text: widget.stop?.notes);

  @override
  void dispose() {
    _name.dispose();
    _day.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final store = AppScope.read(context);
    final name = _name.text.trim();
    final day = int.tryParse(_day.text.trim());
    final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    if (widget.stop == null) {
      store.addStop(widget.trip, name: name, day: day, notes: notes);
    } else {
      store.updateStop(widget.stop!, name: name, day: day, notes: notes);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SheetTitle(widget.stop == null ? 'Add stop' : 'Edit stop'),
        TextFormField(
          key: const Key('stop-name'),
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Stop name'),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a name' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _day,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Day (optional)'),
          validator: (v) {
            final text = (v ?? '').trim();
            if (text.isEmpty) return null;
            final day = int.tryParse(text);
            return day == null || day < 1 ? 'Enter a day number, like 2' : null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notes,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Notes (optional)'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          key: const Key('stop-save'),
          onPressed: _save,
          child: Text(widget.stop == null ? 'Add to timeline' : 'Save changes', style: txt(15, weight: 700, color: Colors.black)),
        ),
      ]),
    );
  }
}
