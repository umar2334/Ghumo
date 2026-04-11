import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  // Local mutable copies of regions & checklist
  late List<_RegionState> _regions;

  final Map<String, bool> _checked = {
    'Power Bank (20k mAh)': true,
    'Offline Vector Maps': true,
    'First Aid Kit': false,
    'Altitude Sickness Meds': false,
    'Emergency Cash (PKR)': false,
    'Satellite Communicator': false,
  };

  @override
  void initState() {
    super.initState();
    _regions = mapRegions.map((r) => _RegionState(region: r)).toList();
  }

  void _startDownload(int i) {
    if (_regions[i].isDownloading || _regions[i].region.isDownloaded) return;
    setState(() => _regions[i].isDownloading = true);

    // Simulate download progress
    const steps = 20;
    int step = 0;
    Timer.periodic(const Duration(milliseconds: 250), (timer) {
      step++;
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        _regions[i].progress = step / steps;
      });
      if (step >= steps) {
        timer.cancel();
        setState(() {
          _regions[i].isDownloading = false;
          _regions[i].region.isDownloaded = true;
          _regions[i].region.detail = 'Downloaded';
          _regions[i].progress = 1.0;
        });
      }
    });
  }

  void _deleteRegion(int i) {
    setState(() {
      _regions[i].region.isDownloaded = false;
      _regions[i].region.detail = 'High Detail';
      _regions[i].progress = 0.0;
    });
  }

  int get _checkedCount => _checked.values.where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(children: [
                  const Icon(Icons.download_for_offline_rounded,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Text('OFFLINE ACCESS',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      )),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showSettingsSheet(context),
                    child: const Icon(Icons.settings_outlined,
                        color: AppColors.textSecondary, size: 22),
                  ),
                ]),
              ),
            ),

            // Sync card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: _SyncCard(),
              ),
            ),

            // Storage bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _StorageBar(regions: _regions),
              ),
            ),

            // Map regions header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Map Regions',
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600)),
                    Text(
                        '${_regions.where((r) => r.region.isDownloaded).length}/${_regions.length} downloaded',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ),

            // Region tiles
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _RegionTile(
                  state: _regions[i],
                  onDownload: () => _startDownload(i),
                  onDelete: () => _deleteRegion(i),
                ),
                childCount: _regions.length,
              ),
            ),

            // Travel essentials
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _TravelEssentials(
                  checked: _checked,
                  checkedCount: _checkedCount,
                  onToggle: (key, val) =>
                      setState(() => _checked[key] = val),
                ),
              ),
            ),

            // Emergency access
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: _EmergencyAccess(onCall: (num) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Calling $num...',
                        style: GoogleFonts.inter(color: Colors.black)),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ));
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('Offline Settings',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _SettingRow('Auto-sync on WiFi', true, (_) {}),
          _SettingRow('Download high-res maps', false, (_) {}),
          _SettingRow('Background sync', true, (_) {}),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _RegionState {
  final MapRegion region;
  bool isDownloading;
  double progress;

  _RegionState({required this.region})
      : isDownloading = false,
        progress = region.downloadProgress;
}

// ─── Sync Card ────────────────────────────────────────────────────────────────

class _SyncCard extends StatefulWidget {
  @override
  State<_SyncCard> createState() => _SyncCardState();
}

class _SyncCardState extends State<_SyncCard> {
  bool _syncing = false;
  double _syncProgress = 0.85;
  Timer? _timer;

  void _startSync() {
    if (_syncing) {
      _timer?.cancel();
      setState(() { _syncing = false; _syncProgress = 0.85; });
      return;
    }
    setState(() { _syncing = true; });
    _timer = Timer.periodic(const Duration(milliseconds: 120), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _syncProgress = (_syncProgress + 0.01).clamp(0.0, 1.0));
      if (_syncProgress >= 1.0) {
        t.cancel();
        setState(() => _syncing = false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkSlate, AppColors.surface],
        ),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CURRENT SYNC',
            style: GoogleFonts.inter(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Hunza\nOdyssey',
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.1)),
              const SizedBox(height: 4),
              Text(
                _syncing
                    ? 'Syncing...'
                    : '${(_syncProgress * 100).round()}% Downloaded',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 12)),
            ]),
            SizedBox(
              width: 52,
              height: 52,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                  value: _syncProgress,
                  backgroundColor: AppColors.divider,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeWidth: 4,
                ),
                Text('${(_syncProgress * 100).round()}%',
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: _startSync,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _syncing ? AppColors.primaryDark : AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  _syncing ? 'PAUSE SYNC' : 'SYNC NOW',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(
              _syncing ? Icons.pause_rounded : Icons.refresh_rounded,
              color: AppColors.textSecondary, size: 20,
            ),
          ),
        ]),
      ]),
    );
  }
}

// ─── Storage Bar ─────────────────────────────────────────────────────────────

class _StorageBar extends StatelessWidget {
  final List<_RegionState> regions;
  const _StorageBar({required this.regions});

  @override
  Widget build(BuildContext context) {
    final downloaded = regions.where((r) => r.region.isDownloaded).length;
    final total = regions.length;
    final usedMB = regions
        .where((r) => r.region.isDownloaded)
        .fold(0.0, (s, r) => s + double.parse(r.region.size.replaceAll('MB', '')));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Storage Management',
            style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
        Text('${usedMB.round()} MB / 2 GB',
            style: GoogleFonts.inter(
                color: AppColors.textSecondary, fontSize: 12)),
      ]),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: usedMB / 2048,
          backgroundColor: AppColors.divider,
          valueColor:
              const AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 6,
        ),
      ),
      const SizedBox(height: 8),
      Text('$downloaded of $total regions downloaded',
          style: GoogleFonts.inter(
              color: AppColors.textMuted, fontSize: 12)),
    ]);
  }
}

// ─── Region Tile ─────────────────────────────────────────────────────────────

class _RegionTile extends StatelessWidget {
  final _RegionState state;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _RegionTile({
    required this.state,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final r = state.region;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: r.isDownloaded
              ? AppColors.primary.withOpacity(0.2)
              : AppColors.divider,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: r.isDownloaded
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.card,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              r.isDownloaded ? Icons.map_rounded : Icons.terrain_rounded,
              color: AppColors.primary, size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.name,
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('${r.size} • ${r.detail}',
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted, fontSize: 12)),
            ]),
          ),
          GestureDetector(
            onTap: r.isDownloaded ? onDelete : onDownload,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: r.isDownloaded
                    ? AppColors.danger.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: state.isDownloading
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        value: state.progress,
                        strokeWidth: 2.5,
                        backgroundColor: AppColors.divider,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary),
                      ),
                    )
                  : Icon(
                      r.isDownloaded
                          ? Icons.delete_outline_rounded
                          : Icons.download_rounded,
                      color: r.isDownloaded
                          ? AppColors.danger
                          : AppColors.primary,
                      size: 20,
                    ),
            ),
          ),
        ]),
        // Progress bar while downloading
        if (state.isDownloading) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: state.progress,
              backgroundColor: AppColors.divider,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Downloading... ${(state.progress * 100).round()}%',
            style: GoogleFonts.inter(
                color: AppColors.primary, fontSize: 10,
                fontWeight: FontWeight.w600),
          ),
        ],
      ]),
    );
  }
}

// ─── Travel Essentials ────────────────────────────────────────────────────────

class _TravelEssentials extends StatelessWidget {
  final Map<String, bool> checked;
  final int checkedCount;
  final void Function(String, bool) onToggle;

  const _TravelEssentials({
    required this.checked,
    required this.checkedCount,
    required this.onToggle,
  });

  static const _items = [
    ('Power Bank (20k mAh)', Icons.battery_charging_full_rounded, 'TACTICAL GEAR'),
    ('Offline Vector Maps', Icons.map_rounded, 'TACTICAL GEAR'),
    ('First Aid Kit', Icons.medical_services_rounded, 'HEALTH & SAFETY'),
    ('Altitude Sickness Meds', Icons.medication_rounded, 'HEALTH & SAFETY'),
    ('Emergency Cash (PKR)', Icons.payments_rounded, 'FINANCES'),
    ('Satellite Communicator', Icons.satellite_alt_rounded, 'SAFETY'),
  ];

  @override
  Widget build(BuildContext context) {
    String? lastCat;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Travel Essentials',
            style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('$checkedCount/${checked.length}',
              style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
      ]),
      const SizedBox(height: 14),
      ..._items.map((item) {
        final (label, icon, cat) = item;
        final showCat = cat != lastCat;
        lastCat = cat;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (showCat) ...[
            Text(cat,
                style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
            const SizedBox(height: 8),
          ],
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (checked[label] ?? false)
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.divider,
              ),
            ),
            child: Row(children: [
              Icon(icon,
                  color: (checked[label] ?? false)
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ),
              GestureDetector(
                onTap: () => onToggle(label, !(checked[label] ?? false)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: (checked[label] ?? false)
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (checked[label] ?? false)
                          ? AppColors.primary
                          : AppColors.textMuted,
                      width: 1.5,
                    ),
                  ),
                  child: (checked[label] ?? false)
                      ? const Icon(Icons.check_rounded,
                          color: Colors.black, size: 16)
                      : null,
                ),
              ),
            ]),
          ),
        ]);
      }),
    ]);
  }
}

// ─── Emergency Access ─────────────────────────────────────────────────────────

class _EmergencyAccess extends StatelessWidget {
  final void Function(String) onCall;

  const _EmergencyAccess({required this.onCall});

  static const _contacts = [
    (Icons.local_police_rounded, Color(0xFFCC2222),
        'Police Assistance', 'Dial 15 • 24/7 Response', '15'),
    (Icons.medical_services_rounded, Color(0xFF2255CC),
        'Rescue & Medical', 'Dial 1122 • Emergency Services', '1122'),
    (Icons.travel_explore_rounded, Color(0xFF226622),
        'GB Tourism', 'Local Information Desk', '051-9201818'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Emergency Access',
          style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 14),
      ..._contacts.map((c) {
        final (icon, color, title, sub, num) = c;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                Text(sub,
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 12)),
              ]),
            ),
            GestureDetector(
              onTap: () => onCall(num),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle),
                child: Icon(Icons.phone_rounded, color: color, size: 18),
              ),
            ),
          ]),
        );
      }),
    ]);
  }
}

class _SettingRow extends StatefulWidget {
  final String label;
  final bool initial;
  final ValueChanged<bool> onChange;
  const _SettingRow(this.label, this.initial, this.onChange);

  @override
  State<_SettingRow> createState() => _SettingRowState();
}

class _SettingRowState extends State<_SettingRow> {
  late bool _val;

  @override
  void initState() {
    super.initState();
    _val = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: _val,
      activeColor: AppColors.primary,
      title: Text(widget.label,
          style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500)),
      contentPadding: EdgeInsets.zero,
      onChanged: (v) {
        setState(() => _val = v);
        widget.onChange(v);
      },
    );
  }
}
