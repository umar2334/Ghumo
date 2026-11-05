import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import '../services/weather_service.dart';
import '../state/app_scope.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/trip_form.dart';

class DestinationScreen extends StatelessWidget {
  const DestinationScreen({super.key, required this.destination});
  final Destination destination;

  Future<void> _addToTrip(BuildContext context) async {
    final store = AppScope.read(context);
    final d = destination;
    var trip = store.activeTrip;
    trip ??= await showTripForm(context, destinationId: d.id);
    if (trip == null || !context.mounted) return;
    if (trip.stops.any((s) => s.destinationId == d.id)) {
      showMessage(context, '${d.name} is already in "${trip.name}"');
      return;
    }
    store.addStop(trip, name: d.name, destinationId: d.id);
    showMessage(context, 'Added to "${trip.name}"');
  }

  void _share() {
    final d = destination;
    Share.share('${d.name}, ${d.region}\n\n${d.description}\n\nBest time: ${d.bestSeason}\nShared from Ghumo');
  }

  @override
  Widget build(BuildContext context) {
    final d = destination;
    final saved = AppScope.store(context).isSaved(d.id);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        actions: [
          IconButton(tooltip: 'Share', icon: const Icon(Icons.share_rounded), onPressed: _share),
          IconButton(
            tooltip: saved ? 'Remove from saved' : 'Save',
            icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded, color: saved ? AppColors.primary : null),
            onPressed: () => AppScope.read(context).toggleSaved(d.id),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
        Text(d.name, style: txt(30, weight: 800)),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 15),
          const SizedBox(width: 4),
          Expanded(child: Text(d.region, style: txt(13, weight: 500, color: AppColors.primary))),
        ]),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          Pill(icon: Icons.signal_cellular_alt_rounded, label: d.difficulty, color: difficultyColor(d.difficulty)),
          Pill(icon: Icons.schedule_rounded, label: d.suggestedStay),
          Pill(icon: Icons.landscape_rounded, label: 'About ${d.elevationM} m', color: AppColors.textSecondary),
          Pill(icon: Icons.calendar_month_rounded, label: d.bestSeason, color: AppColors.textSecondary),
        ]),
        const SizedBox(height: 20),
        _WeatherSection(destination: d),
        const SizedBox(height: 24),
        const SectionLabel('About'),
        const SizedBox(height: 8),
        Text(d.description, style: txt(15, color: AppColors.textSecondary, height: 1.6)),
        const SizedBox(height: 24),
        const SectionLabel('Highlights'),
        const SizedBox(height: 8),
        for (final h in d.highlights)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(h, style: txt(14, height: 1.4))),
            ]),
          ),
        const SizedBox(height: 16),
        const SectionLabel('Getting there'),
        const SizedBox(height: 8),
        Text(d.gettingThere, style: txt(15, color: AppColors.textSecondary, height: 1.6)),
        const SizedBox(height: 14),
        Text('General guidance only. Confirm road, permit and security conditions locally before you travel.',
            style: txt(12, color: AppColors.textMuted, height: 1.5)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          key: const Key('add-to-trip'),
          onPressed: () => _addToTrip(context),
          icon: const Icon(Icons.add_rounded),
          label: Text('Add to trip', style: txt(15, weight: 700, color: Colors.black)),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            AppScope.nav(context).showOnMap(MapTarget(LatLng(d.lat, d.lon), d.id));
            Navigator.of(context).popUntil((r) => r.isFirst);
          },
          icon: const Icon(Icons.map_rounded),
          label: Text('Show on map', style: txt(15, weight: 600, color: AppColors.primary)),
        ),
      ]),
    );
  }
}

class _WeatherSection extends StatefulWidget {
  const _WeatherSection({required this.destination});
  final Destination destination;

  @override
  State<_WeatherSection> createState() => _WeatherSectionState();
}

class _WeatherSectionState extends State<_WeatherSection> {
  Future<WeatherReport>? _report;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _report ??= _fetch();
  }

  Future<WeatherReport> _fetch() {
    final report = AppScope.servicesOf(context).weather.fetchReport(widget.destination.lat, widget.destination.lon);
    // The FutureBuilder shows the error. This stops a failure that lands before
    // the next frame from also being reported as uncaught.
    report.ignore();
    return report;
  }

  void _retry() {
    setState(() {
      _report = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: FutureBuilder<WeatherReport>(
        future: _report,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const SizedBox(height: 64, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
          }
          if (snap.hasError) {
            return Row(children: [
              const Icon(Icons.cloud_off_rounded, color: AppColors.textMuted),
              const SizedBox(width: 12),
              Expanded(child: Text('${snap.error}', style: txt(13, color: AppColors.textSecondary))),
              TextButton(onPressed: _retry, child: const Text('Retry')),
            ]);
          }
          final report = snap.data!;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(report.current.icon, color: AppColors.primary, size: 30),
              const SizedBox(width: 12),
              Text(report.current.temperatureLabel, style: txt(26, weight: 800)),
              const SizedBox(width: 12),
              Expanded(
                child: Text('${report.current.summary}\nWind ${report.current.windKmh.round()} km/h',
                    style: txt(12, color: AppColors.textSecondary, height: 1.4)),
              ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              for (final day in report.daily.take(5))
                Expanded(
                  child: Column(children: [
                    Text(_weekday(day.date), style: txt(11, color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    Icon(weatherIcon(day.code), size: 18, color: AppColors.textSecondary),
                    const SizedBox(height: 4),
                    Text('${day.max.round()}°', style: txt(12, weight: 700)),
                    Text('${day.min.round()}°', style: txt(11, color: AppColors.textMuted)),
                  ]),
                ),
            ]),
          ]);
        },
      ),
    );
  }

  String _weekday(DateTime d) => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
}
