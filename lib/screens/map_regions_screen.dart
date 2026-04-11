import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class MapRegionsScreen extends StatefulWidget {
  const MapRegionsScreen({super.key});

  @override
  State<MapRegionsScreen> createState() => _MapRegionsScreenState();
}

class _MapRegionsScreenState extends State<MapRegionsScreen> {
  late List<_RS> _regions;

  @override
  void initState() {
    super.initState();
    _regions = mapRegions.map((r) => _RS(r)).toList();
  }

  void _download(int i) {
    if (_regions[i].downloading || _regions[i].region.isDownloaded) return;
    setState(() => _regions[i].downloading = true);
    int step = 0;
    Timer.periodic(const Duration(milliseconds: 200), (t) {
      step++;
      if (!mounted) { t.cancel(); return; }
      setState(() => _regions[i].progress = step / 20);
      if (step >= 20) {
        t.cancel();
        setState(() {
          _regions[i].downloading = false;
          _regions[i].region.isDownloaded = true;
          _regions[i].region.detail = 'Downloaded';
        });
      }
    });
  }

  void _delete(int i) {
    setState(() {
      _regions[i].region.isDownloaded = false;
      _regions[i].region.detail = 'High Detail';
      _regions[i].progress = 0;
    });
  }

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
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textSecondary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Map Regions',
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  const Icon(Icons.search_rounded,
                      color: AppColors.textSecondary, size: 22),
                ]),
              ),
            ),

            // Storage card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _StorageCard(regions: _regions),
              ),
            ),

            // Regions header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  Text('Available Regions',
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600)),
                  GestureDetector(
                    onTap: () {
                      for (int i = 0; i < _regions.length; i++) {
                        if (!_regions[i].region.isDownloaded) _download(i);
                      }
                    },
                    child: Text('Download All',
                        style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ),
                ]),
              ),
            ),

            // Region tiles
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _RegionTile(
                  rs: _regions[i],
                  onDownload: () => _download(i),
                  onDelete: () => _delete(i),
                ),
                childCount: _regions.length,
              ),
            ),

            // Map preview
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _MapPreview(),
              ),
            ),

            // Manage storage
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _ManageStorage(onDelete: (i) => _delete(i)),
              ),
            ),

            // Buttons
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Column(children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          for (int i = 0;
                              i < _regions.length;
                              i++) {
                            _delete(i);
                          }
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Offline cache cleared',
                                style: GoogleFonts.inter(
                                    color: Colors.black)),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(
                            color: AppColors.danger, width: 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Clear Offline Cache',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        for (int i = 0; i < _regions.length; i++) {
                          if (_regions[i].region.isDownloaded) _download(i);
                        }
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text('Update All Downloaded',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RS {
  final MapRegion region;
  bool downloading;
  double progress;
  _RS(this.region)
      : downloading = false,
        progress = region.downloadProgress;
}

// ─── Storage Card ─────────────────────────────────────────────────────────────

class _StorageCard extends StatelessWidget {
  final List<_RS> regions;
  const _StorageCard({required this.regions});

  @override
  Widget build(BuildContext context) {
    final usedMB = regions
        .where((r) => r.region.isDownloaded)
        .fold(0.0, (s, r) =>
            s + double.parse(r.region.size.replaceAll('MB', '')));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.storage_rounded,
              color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 8),
          Text('DEVICE STORAGE',
              style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5)),
        ]),
        const SizedBox(height: 8),
        Text('14.2 GB Available',
            style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (usedMB + 9800) / 24000,
            backgroundColor: AppColors.divider,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${(usedMB / 1024 + 9.8).toStringAsFixed(1)} GB Used',
              style:
                  GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
          Text('24.0 GB Total',
              style:
                  GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
        ]),
      ]),
    );
  }
}

// ─── Region Tile ─────────────────────────────────────────────────────────────

class _RegionTile extends StatelessWidget {
  final _RS rs;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _RegionTile(
      {required this.rs, required this.onDownload, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final r = rs.region;
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
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
              child: rs.downloading
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        value: rs.progress,
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
        if (rs.downloading) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: rs.progress,
              backgroundColor: AppColors.divider,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text('Downloading... ${(rs.progress * 100).round()}%',
              style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ]),
    );
  }
}

// ─── Map Preview ─────────────────────────────────────────────────────────────

class _MapPreview extends StatelessWidget {
  const _MapPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Stack(children: [
        CustomPaint(
          painter: _PreviewPainter(),
          size: const Size(double.infinity, 160),
        ),
        Positioned(
          bottom: 12,
          left: 12,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PREVIEW AREA',
                style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5)),
            const SizedBox(height: 2),
            Text('Upper Hunza & Gojal',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
        const Positioned(
          bottom: 12, right: 12,
          child: Icon(Icons.zoom_in_map_rounded,
              color: AppColors.textSecondary, size: 20),
        ),
      ]),
    );
  }
}

// ─── Manage Storage ───────────────────────────────────────────────────────────

class _ManageStorage extends StatelessWidget {
  final void Function(int) onDelete;

  const _ManageStorage({required this.onDelete});

  static const _unused = [
    ('Naran Valley', '342 MB', 'UNUSED 30 DAYS'),
    ('Fairy Meadows', '88 MB', 'UNUSED 12 DAYS'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.delete_outline_rounded,
            color: AppColors.danger, size: 18),
        const SizedBox(width: 8),
        Text('Manage Storage',
            style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 12),
      ..._unused.map((item) {
        final (name, size, days) = item;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(children: [
            const Icon(Icons.cloud_off_rounded,
                color: AppColors.textMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(name,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                Text('$size • $days',
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted, fontSize: 11)),
              ]),
            ),
            const Icon(Icons.delete_outline_rounded,
                color: AppColors.danger, size: 20),
          ]),
        );
      }),
    ]);
  }
}

class _PreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.07)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final regionPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.12)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.55, size.height * 0.42),
        width: size.width * 0.38,
        height: size.height * 0.50,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(rect, regionPaint);
    canvas.drawRRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
