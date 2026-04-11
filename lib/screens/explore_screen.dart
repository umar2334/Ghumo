import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/weather_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  int _selectedFilter = 0;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  Map<String, WeatherData> _weather = {};
  bool _loadingWeather = true;

  final List<String> _filters = ['All', 'Popular', 'Scenic', 'Trekking'];

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase());
    });
  }

  Future<void> _fetchWeather() async {
    final locs = featuredExpeditions
        .map((e) => (id: e.id, lat: e.lat, lon: e.lon))
        .toList();
    final data = await WeatherService.fetchForExpeditions(locs);
    if (mounted) setState(() { _weather = data; _loadingWeather = false; });
  }

  List<Expedition> get _filtered {
    var list = featuredExpeditions.where((e) {
      if (_searchQuery.isNotEmpty) {
        return e.name.toLowerCase().contains(_searchQuery) ||
            e.location.toLowerCase().contains(_searchQuery) ||
            e.tags.any((t) => t.toLowerCase().contains(_searchQuery));
      }
      return true;
    }).toList();

    switch (_selectedFilter) {
      case 1: // Popular
        list = list.where((e) => e.rating >= 4.8).toList();
        break;
      case 2: // Scenic
        list = list.where((e) => e.tags.any((t) =>
            t.toLowerCase().contains('scenic') ||
            t.toLowerCase().contains('valley') ||
            t.toLowerCase().contains('lake') ||
            t.toLowerCase().contains('nature'))).toList();
        break;
      case 3: // Trekking
        list = list.where((e) => e.tags.any((t) =>
            t.toLowerCase().contains('trekking') ||
            t.toLowerCase().contains('camping') ||
            t.toLowerCase().contains('adventure'))).toList();
        break;
    }
    return list;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('GHUMO',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        )),
                    Row(children: [
                      IconButton(
                        onPressed: () => _showNotificationsSheet(context),
                        icon: const Icon(Icons.notifications_outlined,
                            color: AppColors.textSecondary, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => _showProfileSheet(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity(0.15),
                            border: Border.all(color: AppColors.primary, width: 1.5),
                          ),
                          child: const Icon(Icons.person_outline_rounded,
                              color: AppColors.primary, size: 20),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),

            // Headline
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: RichText(
                  text: TextSpan(children: [
                    TextSpan(
                        text: 'Where to\n',
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            height: 1.1)),
                    TextSpan(
                        text: 'explore next?',
                        style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            height: 1.3)),
                  ]),
                ),
              ),
            ),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(children: [
                    const SizedBox(width: 14),
                    const Icon(Icons.search_rounded,
                        color: AppColors.textMuted, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search destinations, valleys, trails...',
                          hintStyle: GoogleFonts.inter(
                              color: AppColors.textMuted, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          filled: false,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () => _searchCtrl.clear(),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.close_rounded,
                              color: AppColors.textMuted, size: 16),
                        ),
                      )
                    else
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.tune_rounded,
                            color: AppColors.primary, size: 16),
                      ),
                  ]),
                ),
              ),
            ),

            // Filter chips
            SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  itemCount: _filters.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => setState(() => _selectedFilter = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 6),
                      decoration: BoxDecoration(
                        color: _selectedFilter == i
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedFilter == i
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        _filters[i],
                        style: GoogleFonts.inter(
                          color: _selectedFilter == i
                              ? Colors.black
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: _selectedFilter == i
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      filtered.isEmpty
                          ? 'No Results'
                          : '${filtered.length} Expedition${filtered.length == 1 ? '' : 's'}',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _selectedFilter = 0;
                        _searchCtrl.clear();
                      }),
                      child: Text(
                        _selectedFilter != 0 || _searchQuery.isNotEmpty
                            ? 'Clear'
                            : 'View All',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Expedition cards
            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(children: [
                    const Icon(Icons.search_off_rounded,
                        color: AppColors.textMuted, size: 48),
                    const SizedBox(height: 12),
                    Text('No expeditions found',
                        style: GoogleFonts.inter(
                            color: AppColors.textMuted, fontSize: 14)),
                  ]),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final exp = filtered[index];
                    return _ExpeditionCard(
                      expedition: exp,
                      weather: _weather[exp.id],
                      loadingWeather: _loadingWeather,
                      onTap: () => _showExpeditionDetail(context, exp),
                      onSave: () => setState(() => exp.isSaved = !exp.isSaved),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  void _showExpeditionDetail(BuildContext context, Expedition exp) {
    final weather = _weather[exp.id];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.textMuted,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(exp.name,
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_rounded,
                        color: AppColors.primary, size: 14),
                    const SizedBox(width: 4),
                    Text(exp.location,
                        style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ]),
                ]),
              ),
              if (weather != null)
                Column(children: [
                  Text(weather.icon, style: const TextStyle(fontSize: 26)),
                  Text(weather.tempStr,
                      style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ]),
            ]),
            const SizedBox(height: 20),
            // Stats row
            Row(children: [
              _StatChip(Icons.star_rounded, exp.rating.toString(),
                  const Color(0xFFFFCC00)),
              const SizedBox(width: 10),
              _StatChip(Icons.timer_outlined, exp.duration, AppColors.primary),
              const SizedBox(width: 10),
              _StatChip(Icons.signal_cellular_alt_rounded, exp.difficulty,
                  exp.difficulty == 'Easy'
                      ? AppColors.success
                      : exp.difficulty == 'Moderate'
                          ? AppColors.warning
                          : AppColors.danger),
            ]),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: exp.tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Text(t,
                            style: GoogleFonts.inter(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            Text('About',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(exp.description,
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.6)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text('Add to Planner',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          Text('Notifications',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          _NotifTile('🌄', 'Best season for Hunza starts in April',
              '2 hours ago'),
          _NotifTile('⛽', 'Fuel available at Chilas – 45 PKR/L',
              'Yesterday'),
          _NotifTile('🏔️', 'New trail added: Shispare Base Camp',
              '2 days ago'),
        ]),
      ),
    );
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.2),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: const Icon(Icons.person_rounded,
                color: AppColors.primary, size: 38),
          ),
          const SizedBox(height: 12),
          Text('Explorer',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          Text('Pakistan Traveller',
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _ProfileStat('12', 'Trips'),
            _ProfileStat('5', 'Countries'),
            _ProfileStat('340', 'km'),
          ]),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.inter(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String time;
  const _NotifTile(this.emoji, this.title, this.time);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            Text(time,
                style: GoogleFonts.inter(
                    color: AppColors.textMuted, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  const _ProfileStat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: GoogleFonts.inter(
              color: AppColors.primary,
              fontSize: 22,
              fontWeight: FontWeight.w800)),
      Text(label,
          style: GoogleFonts.inter(
              color: AppColors.textSecondary, fontSize: 12)),
    ]);
  }
}

// ─── Expedition Card ─────────────────────────────────────────────────────────

class _ExpeditionCard extends StatelessWidget {
  final Expedition expedition;
  final WeatherData? weather;
  final bool loadingWeather;
  final VoidCallback onTap;
  final VoidCallback onSave;

  const _ExpeditionCard({
    required this.expedition,
    required this.weather,
    required this.loadingWeather,
    required this.onTap,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final gradients = {
      'HUNZA': [const Color(0xFF1E3A5C), const Color(0xFF0A1825)],
      'SKARDU': [const Color(0xFF1A4A2C), const Color(0xFF081510)],
      'SWAT': [const Color(0xFF3A4A1A), const Color(0xFF101508)],
      'NARAN': [const Color(0xFF1A3A4A), const Color(0xFF080F14)],
      'FAIRY MEADOWS': [const Color(0xFF3A2A1A), const Color(0xFF110C06)],
    };

    final gradient = gradients[expedition.name] ??
        [AppColors.darkSlate, AppColors.background];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Stack(children: [
          // Terrain icon background
          Positioned(
            right: -10,
            top: -10,
            child: Icon(Icons.terrain_rounded,
                size: 140,
                color: Colors.white.withOpacity(0.04)),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: tags + weather + save
                Row(children: [
                  ...expedition.tags.take(2).map((tag) => Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Text(tag,
                            style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w500)),
                      )),
                  const Spacer(),
                  // Weather badge
                  if (loadingWeather)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary),
                        ),
                      ),
                    )
                  else if (weather != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        Text(weather!.icon,
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(weather!.tempStr,
                            style: GoogleFonts.inter(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onSave,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: expedition.isSaved
                            ? AppColors.primary.withOpacity(0.2)
                            : Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        expedition.isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        color: expedition.isSaved
                            ? AppColors.primary
                            : Colors.white54,
                        size: 16,
                      ),
                    ),
                  ),
                ]),

                const Spacer(),

                // Name
                Text(
                  expedition.name,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),

                // Bottom row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.primary, size: 14),
                      const SizedBox(width: 3),
                      Text(expedition.location,
                          style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(width: 12),
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFFCC00), size: 14),
                      const SizedBox(width: 3),
                      Text(expedition.rating.toString(),
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ]),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(expedition.duration,
                          style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
