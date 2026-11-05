import 'package:flutter/material.dart';

import '../data/destinations.dart';
import '../models/models.dart';
import '../services/weather_service.dart';
import '../state/app_scope.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'about_screen.dart';
import 'destination_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  DestinationCategory? _category;
  Map<String, CurrentWeather> _weather = {};
  bool _weatherLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_weatherLoaded) {
      _weatherLoaded = true;
      _loadWeather();
    }
  }

  Future<void> _loadWeather() async {
    try {
      final list = await AppScope.servicesOf(context).weather.fetchCurrentBulk(
            destinations.map((d) => (lat: d.lat, lon: d.lon)).toList(),
          );
      if (!mounted) return;
      setState(() => _weather = {
            for (var i = 0; i < destinations.length; i++) destinations[i].id: list[i],
          });
    } catch (_) {
      // Weather is an enhancement on this list. Cards simply omit it offline,
      // and the detail screen shows the error with a retry.
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Destination> get _results => destinations
      .where((d) => (_category == null || d.category == _category) && d.matches(_search.text))
      .toList();

  void _clearFilters() {
    _search.clear();
    setState(() => _category = null);
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(children: [
                Text('GHUMO', style: txt(20, weight: 800, spacing: 2, color: AppColors.primary)),
                const Spacer(),
                IconButton(
                  tooltip: 'About Ghumo',
                  icon: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text.rich(TextSpan(children: [
                TextSpan(text: 'Where to\n', style: txt(30, weight: 700, height: 1.15)),
                TextSpan(text: 'explore next?', style: txt(30, weight: 700, height: 1.15, color: AppColors.primary)),
              ])),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: TextField(
                key: const Key('explore-search'),
                controller: _search,
                onChanged: (_) => setState(() {}),
                style: txt(14),
                decoration: InputDecoration(
                  hintText: 'Search places, regions, forts...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                          onPressed: () => setState(_search.clear),
                        ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 62,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                children: [
                  _chip('All', _category == null, () => setState(() => _category = null)),
                  for (final c in DestinationCategory.values)
                    _chip(c.label, _category == c, () => setState(() => _category = c)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                results.isEmpty ? 'No matches' : '${results.length} destination${results.length == 1 ? '' : 's'}',
                style: txt(16, weight: 600),
              ),
            ),
          ),
          if (results.isEmpty)
            SliverToBoxAdapter(
              child: Column(children: [
                const SizedBox(height: 40),
                const Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 48),
                const SizedBox(height: 12),
                Text('Nothing matches your search', style: txt(14, color: AppColors.textSecondary)),
                TextButton(onPressed: _clearFilters, child: const Text('Clear filters')),
              ]),
            )
          else
            SliverList.builder(
              itemCount: results.length,
              itemBuilder: (context, i) => _DestinationCard(destination: results[i], weather: _weather[results[i].id]),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ]),
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? AppColors.primary : AppColors.divider),
          ),
          child: Text(label, style: txt(13, weight: active ? 700 : 500, color: active ? Colors.black : AppColors.textSecondary)),
        ),
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({required this.destination, this.weather});
  final Destination destination;
  final CurrentWeather? weather;

  @override
  Widget build(BuildContext context) {
    final d = destination;
    final store = AppScope.store(context);
    final saved = store.isSaved(d.id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DestinationScreen(destination: d))),
          child: Ink(
            height: 172,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [d.category.color, AppColors.surface],
              ),
              border: Border.all(color: AppColors.divider),
            ),
            child: Stack(children: [
              Positioned(
                right: -8,
                bottom: -12,
                child: Icon(d.category.icon, size: 120, color: Colors.white.withValues(alpha: 0.05)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(d.category.label.toUpperCase(), style: txt(10, weight: 700, spacing: 1.2, color: AppColors.textSecondary)),
                    const Spacer(),
                    if (weather != null) ...[
                      Icon(weather!.icon, color: AppColors.primary, size: 15),
                      const SizedBox(width: 4),
                      Text(weather!.temperatureLabel, style: txt(12, weight: 700, color: AppColors.primary)),
                    ],
                    IconButton(
                      tooltip: saved ? 'Remove ${d.name} from saved' : 'Save ${d.name}',
                      onPressed: () => AppScope.read(context).toggleSaved(d.id),
                      icon: Icon(
                        saved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                        color: saved ? AppColors.primary : Colors.white70,
                        size: 22,
                      ),
                    ),
                  ]),
                  const Spacer(),
                  Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: txt(24, weight: 800)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 14),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(d.region, maxLines: 1, overflow: TextOverflow.ellipsis, style: txt(12, weight: 500, color: AppColors.primary)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text('${d.suggestedStay}  ·  ${d.difficulty}  ·  Best: ${d.bestSeason}',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: txt(11, color: AppColors.textSecondary)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
