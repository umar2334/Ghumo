import 'dart:math' as math;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

// ─── POI data model ──────────────────────────────────────────────────────────

class _POI {
  final String id;
  final String type; // destination | mechanic | hospital | fuel
  final String name;
  final String detail;
  final LatLng position;

  const _POI({
    required this.id,
    required this.type,
    required this.name,
    required this.detail,
    required this.position,
  });

  Color get color {
    switch (type) {
      case 'destination': return AppColors.primary;
      case 'mechanic':    return const Color(0xFFFFCC44);
      case 'hospital':    return const Color(0xFF4499FF);
      case 'fuel':        return const Color(0xFF44DD88);
      default:            return AppColors.textSecondary;
    }
  }

  IconData get icon {
    switch (type) {
      case 'destination': return Icons.terrain_rounded;
      case 'mechanic':    return Icons.build_rounded;
      case 'hospital':    return Icons.local_hospital_rounded;
      case 'fuel':        return Icons.local_gas_station_rounded;
      default:            return Icons.location_on_rounded;
    }
  }
}

class _DownloadedRegion {
  final String name;
  final int tiles;
  final double sizeMB;
  final DateTime downloadedAt;
  _DownloadedRegion({
    required this.name,
    required this.tiles,
    required this.sizeMB,
    required this.downloadedAt,
  });
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapCtrl = MapController();
  bool _mapReady = false;

  int _filterIndex = 0; // 0=All 1=Mechanic 2=Hospital 3=Fuel
  _POI? _selected;
  int _layerIndex = 0;   // 0=Dark 1=Standard 2=Satellite 3=Topo

  // Directions / routing
  bool _routeMode = false;
  LatLng? _routeStart;
  LatLng? _routeEnd;
  List<LatLng> _routePoints = [];
  String _routeDistance = '';
  String _routeDuration = '';
  bool _loadingRoute = false;
  bool _routeOffline = false; // true = straight-line fallback was used

  // Download
  bool _showDlPanel = false;
  bool _downloading = false;
  double _dlProgress = 0;
  int _dlDone = 0;
  int _dlTotal = 0;
  String _dlRegionName = '';
  final List<_DownloadedRegion> _dlRegions = [];

  // ─── POIs ─────────────────────────────────────────────────────────────────

  final List<_POI> _allPOIs = const [
    // Destinations
    _POI(id: 'hunza',   type: 'destination', name: 'Hunza Valley',
         detail: 'Gilgit-Baltistan • 7-day trek',
         position: LatLng(36.3167, 74.6500)),
    _POI(id: 'skardu',  type: 'destination', name: 'Skardu',
         detail: 'K2 Base Camp Gateway • 10 days',
         position: LatLng(35.2971, 75.6130)),
    _POI(id: 'attabad', type: 'destination', name: 'Attabad Lake',
         detail: 'Turquoise glacial lake',
         position: LatLng(36.3300, 74.8600)),
    _POI(id: 'passu',   type: 'destination', name: 'Passu Cones',
         detail: 'Cathedral peaks trek',
         position: LatLng(36.4783, 74.8650)),
    _POI(id: 'fairy',   type: 'destination', name: 'Fairy Meadows',
         detail: 'Nanga Parbat base',
         position: LatLng(35.3736, 74.5783)),
    _POI(id: 'gilgit',  type: 'destination', name: 'Gilgit City',
         detail: 'Gateway to GB • All facilities',
         position: LatLng(35.9221, 74.3087)),
    // Mechanics
    _POI(id: 'mech1', type: 'mechanic', name: 'Khan Auto Workshop',
         detail: '24/7 • 4x4 specialist',
         position: LatLng(35.920, 74.305)),
    _POI(id: 'mech2', type: 'mechanic', name: 'Karakoram Repairs',
         detail: 'Jeep & SUV experts',
         position: LatLng(36.310, 74.640)),
    // Hospitals
    _POI(id: 'hosp1', type: 'hospital', name: 'DHQ Hospital Gilgit',
         detail: 'Emergency 24/7 • Dial 15',
         position: LatLng(35.930, 74.310)),
    _POI(id: 'hosp2', type: 'hospital', name: 'Aga Khan Health',
         detail: 'Karimabad, Hunza',
         position: LatLng(36.320, 74.660)),
    // Fuel
    _POI(id: 'fuel1', type: 'fuel', name: 'PSO Pump – Karakoram Hwy',
         detail: 'Diesel & Petrol',
         position: LatLng(36.100, 74.510)),
    _POI(id: 'fuel2', type: 'fuel', name: 'Shell Station – Gilgit',
         detail: 'CNG available',
         position: LatLng(35.915, 74.310)),
    _POI(id: 'fuel3', type: 'fuel', name: 'PSO – Skardu Road',
         detail: 'Petrol only',
         position: LatLng(35.600, 75.100)),
  ];

  List<_POI> get _visible {
    if (_filterIndex == 0) return _allPOIs;
    final types = ['', 'mechanic', 'hospital', 'fuel'];
    return _allPOIs.where((p) => p.type == types[_filterIndex]).toList();
  }

  // ─── Tile layers ──────────────────────────────────────────────────────────
  // 0 = OSM Standard  (OpenStreetMap — free, no key)
  // 1 = OSM Outdoors  (Stadia Outdoors — perfect for mountain travel, free)
  // 2 = Dark          (Stadia Alidade Smooth Dark — free)
  // 3 = Satellite     (ESRI World Imagery — free)
  // 4 = Topo          (OpenTopoMap — free)

  static const _layers = [
    {
      'name': 'Standard',
      'url' : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      'subs': ['a', 'b', 'c'],
      'icon': 0, // index into icons list
    },
    {
      'name': 'Outdoors',
      'url' : 'https://tiles.stadiamaps.com/tiles/outdoors/{z}/{x}/{y}{r}.png',
      'subs': <String>[],
      'icon': 1,
    },
    {
      'name': 'Dark',
      'url' : 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png',
      'subs': <String>[],
      'icon': 2,
    },
    {
      'name': 'Satellite',
      'url' : 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      'subs': <String>[],
      'icon': 3,
    },
    {
      'name': 'Topo',
      'url' : 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
      'subs': ['a', 'b', 'c'],
      'icon': 4,
    },
  ];

  // ─── Tile math ────────────────────────────────────────────────────────────

  int _lonToTile(double lon, int z) =>
      ((lon + 180) / 360 * (1 << z)).floor().clamp(0, (1 << z) - 1);

  int _latToTile(double lat, int z) {
    final r = lat * math.pi / 180;
    return ((1 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) /
                2 *
                (1 << z))
        .floor()
        .clamp(0, (1 << z) - 1);
  }

  int _countTiles(LatLngBounds b, int minZ, int maxZ) {
    int n = 0;
    for (int z = minZ; z <= maxZ; z++) {
      final x1 = _lonToTile(b.west, z);
      final x2 = _lonToTile(b.east, z);
      final y1 = _latToTile(b.north, z);
      final y2 = _latToTile(b.south, z);
      n += ((x2 - x1).abs() + 1) * ((y2 - y1).abs() + 1);
    }
    return n;
  }

  // ─── Offline download ─────────────────────────────────────────────────────

  Future<void> _startDownload(String regionName) async {
    if (!_mapReady) return;
    final bounds = _mapCtrl.camera.visibleBounds;
    const minZ = 9;
    const maxZ = 13;

    final total = _countTiles(bounds, minZ, maxZ);
    setState(() {
      _downloading = true;
      _dlProgress = 0;
      _dlDone = 0;
      _dlTotal = total;
      _dlRegionName = regionName;
    });

    int done = 0;

    for (int z = minZ; z <= maxZ && _downloading; z++) {
      final x1 = math.min(_lonToTile(bounds.west, z), _lonToTile(bounds.east, z));
      final x2 = math.max(_lonToTile(bounds.west, z), _lonToTile(bounds.east, z));
      final y1 = math.min(_latToTile(bounds.north, z), _latToTile(bounds.south, z));
      final y2 = math.max(_latToTile(bounds.north, z), _latToTile(bounds.south, z));

      for (int x = x1; x <= x2 && _downloading; x++) {
        for (int y = y1; y <= y2 && _downloading; y++) {
          try {
            final layerSubs = (_layers[_layerIndex]['subs'] as List).cast<String>();
            final tileUrl = (_layers[_layerIndex]['url'] as String)
                .replaceAll('{z}', '$z')
                .replaceAll('{x}', '$x')
                .replaceAll('{y}', '$y')
                .replaceAll('{r}', '')
                .replaceAll('{s}', layerSubs.isNotEmpty
                    ? layerSubs[(x + y) % layerSubs.length]
                    : '');
            await http.get(Uri.parse(tileUrl))
                .timeout(const Duration(seconds: 4));
          } catch (_) {}
          done++;
          if (mounted) {
            setState(() {
              _dlDone = done;
              _dlProgress = done / total;
            });
          }
          // Small delay to avoid hammering the server
          await Future.delayed(const Duration(milliseconds: 5));
        }
      }
    }

    if (_downloading && mounted) {
      setState(() {
        _downloading = false;
        _dlProgress = 1.0;
        _dlRegions.add(_DownloadedRegion(
          name: regionName,
          tiles: done,
          sizeMB: done * 20 / 1024, // ~20KB per tile
          downloadedAt: DateTime.now(),
        ));
        Future.delayed(const Duration(seconds: 2),
            () { if (mounted) setState(() => _showDlPanel = false); });
      });
    }
  }

  void _cancelDownload() => setState(() => _downloading = false);

  // ─── Routing ──────────────────────────────────────────────────────────────

  /// Haversine distance in km between two points.
  double _haversine(LatLng a, LatLng b) {
    const R = 6371.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(a.latitude * math.pi / 180) *
            math.cos(b.latitude * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  String _fmtDist(double km) =>
      km >= 1 ? '${km.toStringAsFixed(1)} km' : '${(km * 1000).round()} m';

  String _fmtDuration(int seconds) {
    if (seconds < 3600) return '${(seconds / 60).round()} min';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${h}h ${m}m';
  }

  Future<void> _fetchRoute(LatLng start, LatLng end) async {
    setState(() => _loadingRoute = true);
    try {
      final url = Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final route = (data['routes'] as List).first as Map<String, dynamic>;
        final coords = (route['geometry']['coordinates'] as List)
            .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();
        final distKm = (route['distance'] as num).toDouble() / 1000;
        final durSec = (route['duration'] as num).toInt();
        setState(() {
          _routePoints = coords;
          _routeDistance = _fmtDist(distKm);
          _routeDuration = _fmtDuration(durSec);
          _routeOffline = false;
          _loadingRoute = false;
        });
        return;
      }
    } catch (_) {}
    // Offline fallback — straight line
    final km = _haversine(start, end);
    setState(() {
      _routePoints = [start, end];
      _routeDistance = _fmtDist(km);
      _routeDuration = _fmtDuration((km / 40 * 3600).round()); // ~40 km/h mountain avg
      _routeOffline = true;
      _loadingRoute = false;
    });
  }

  void _setRoutePoint(LatLng point) {
    if (_routeStart == null) {
      setState(() { _routeStart = point; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Start point set — now tap destination',
            style: GoogleFonts.inter(color: Colors.black)),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } else if (_routeEnd == null) {
      setState(() { _routeEnd = point; });
      _fetchRoute(_routeStart!, point);
    }
  }

  void _clearRoute() {
    setState(() {
      _routeMode = false;
      _routeStart = null;
      _routeEnd = null;
      _routePoints = [];
      _routeDistance = '';
      _routeDuration = '';
      _routeOffline = false;
      _loadingRoute = false;
    });
  }

  void _startDirectionsTo(_POI poi) {
    // Use Gilgit as current location start
    setState(() {
      _routeMode = true;
      _routeStart = const LatLng(35.9221, 74.3087);
      _routeEnd = poi.position;
      _routePoints = [];
      _selected = null;
    });
    _fetchRoute(const LatLng(35.9221, 74.3087), poi.position);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(children: [
        // ── Real Map ──────────────────────────────────────────────────────
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(
            initialCenter: const LatLng(36.3167, 74.6500),
            initialZoom: 9.0,
            minZoom: 4.0,
            maxZoom: 18.0,
            onMapReady: () => setState(() => _mapReady = true),
            onTap: (_, point) {
              if (_routeMode) {
                _setRoutePoint(point);
              } else {
                setState(() => _selected = null);
              }
            },
          ),
          children: [
            // Tile layer
            TileLayer(
              urlTemplate: _layers[_layerIndex]['url'] as String,
              subdomains:
                  (_layers[_layerIndex]['subs'] as List).cast<String>(),
              userAgentPackageName: 'com.ghumo.app',
              tileBuilder: _layerIndex == 0
                  ? null // dark layer already dark
                  : null,
            ),

            // Download area highlight
            if (_showDlPanel && _mapReady)
              PolygonLayer(polygons: [
                Polygon(
                  points: _boundsToPoints(_mapCtrl.camera.visibleBounds),
                  color: AppColors.primary.withOpacity(0.08),
                  borderColor: AppColors.primary.withOpacity(0.5),
                  borderStrokeWidth: 2,
                  isFilled: true,
                ),
              ]),

            // Route polyline
            if (_routePoints.isNotEmpty)
              PolylineLayer(polylines: [
                Polyline(
                  points: _routePoints,
                  color: AppColors.primary,
                  strokeWidth: 4.5,
                ),
                if (_routeOffline)
                  Polyline(
                    points: _routePoints,
                    color: AppColors.primary.withOpacity(0.3),
                    strokeWidth: 10,
                  ),
              ]),

            // Route start / end markers
            if (_routeStart != null || _routeEnd != null)
              MarkerLayer(markers: [
                if (_routeStart != null)
                  Marker(
                    point: _routeStart!,
                    width: 44, height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF44DD88),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [BoxShadow(
                            color: const Color(0xFF44DD88).withOpacity(0.5),
                            blurRadius: 10)],
                      ),
                      child: const Icon(Icons.my_location_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                if (_routeEnd != null)
                  Marker(
                    point: _routeEnd!,
                    width: 44, height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [BoxShadow(
                            color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 10)],
                      ),
                      child: const Icon(Icons.flag_rounded,
                          color: Colors.black, size: 20),
                    ),
                  ),
              ]),

            // Markers
            MarkerLayer(
              markers: _visible.map((poi) => Marker(
                point: poi.position,
                width: _selected?.id == poi.id ? 50 : 40,
                height: _selected?.id == poi.id ? 50 : 40,
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selected = _selected?.id == poi.id ? null : poi;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: _selected?.id == poi.id
                          ? poi.color
                          : AppColors.surface.withOpacity(0.95),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: poi.color,
                        width: _selected?.id == poi.id ? 2.5 : 1.5,
                      ),
                      boxShadow: _selected?.id == poi.id
                          ? [BoxShadow(
                              color: poi.color.withOpacity(0.5),
                              blurRadius: 12, spreadRadius: 2)]
                          : [],
                    ),
                    child: Icon(poi.icon,
                        color: _selected?.id == poi.id
                            ? Colors.black
                            : poi.color,
                        size: _selected?.id == poi.id ? 24 : 18),
                  ),
                ),
              )).toList(),
            ),
          ],
        ),

        // ── Top bar ───────────────────────────────────────────────────────
        SafeArea(
          child: Column(children: [
            _buildTopBar(context),
            const SizedBox(height: 10),
            _buildFilterTabs(),
          ]),
        ),

        // ── Right controls ────────────────────────────────────────────────
        Positioned(
          right: 14,
          top: MediaQuery.of(context).padding.top + 100,
          child: _buildControls(context),
        ),

        // ── Route mode banner ─────────────────────────────────────────────
        if (_routeMode && _routePoints.isEmpty && !_loadingRoute)
          Positioned(
            top: MediaQuery.of(context).padding.top + 90,
            left: 16,
            right: 72,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.darkSlate,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.5)),
              ),
              child: Row(children: [
                const Icon(Icons.touch_app_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _routeStart == null
                        ? 'Tap map to set your start point'
                        : 'Now tap your destination on the map',
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary, fontSize: 13),
                  ),
                ),
              ]),
            ),
          ),

        // ── Route loading spinner ──────────────────────────────────────────
        if (_loadingRoute)
          Positioned(
            top: MediaQuery.of(context).padding.top + 90,
            left: 16,
            right: 72,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.darkSlate,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.5)),
              ),
              child: Row(children: [
                const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text('Calculating route…',
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary, fontSize: 13)),
              ]),
            ),
          ),

        // ── Route info panel ──────────────────────────────────────────────
        if (_routePoints.isNotEmpty && !_loadingRoute)
          Positioned(
            bottom: _showDlPanel ? 240 : 16,
            left: 16,
            right: 16,
            child: _RouteInfoPanel(
              distance: _routeDistance,
              duration: _routeDuration,
              isOffline: _routeOffline,
              onClear: _clearRoute,
              startLabel: 'My Location (Gilgit)',
              endLabel: _routeEnd != null
                  ? (_allPOIs
                          .where((p) =>
                              p.position.latitude == _routeEnd!.latitude &&
                              p.position.longitude == _routeEnd!.longitude)
                          .firstOrNull
                          ?.name ??
                      'Selected Point')
                  : 'Destination',
            ),
          ),

        // ── POI popup ─────────────────────────────────────────────────────
        if (_selected != null && _routePoints.isEmpty)
          Positioned(
            bottom: _showDlPanel ? 220 : 16,
            left: 16,
            right: 16,
            child: _POIPopup(
              poi: _selected!,
              onClose: () => setState(() => _selected = null),
              onFly: () => _mapCtrl.move(_selected!.position, 14),
              onDirections: () => _startDirectionsTo(_selected!),
            ),
          ),

        // ── Download panel ────────────────────────────────────────────────
        if (_showDlPanel)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _DownloadPanel(
              mapCtrl: _mapCtrl,
              mapReady: _mapReady,
              downloading: _downloading,
              progress: _dlProgress,
              done: _dlDone,
              total: _dlTotal,
              regionName: _dlRegionName,
              downloadedRegions: _dlRegions,
              countTiles: (bounds) => _countTiles(bounds, 9, 13),
              onDownload: (name) => _startDownload(name),
              onCancel: _cancelDownload,
              onClose: () {
                if (!_downloading) setState(() => _showDlPanel = false);
              },
            ),
          ),
      ]),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  List<LatLng> _boundsToPoints(LatLngBounds b) => [
    LatLng(b.north, b.west),
    LatLng(b.north, b.east),
    LatLng(b.south, b.east),
    LatLng(b.south, b.west),
  ];

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Text('GHUMO',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              )),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => _showSearch(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(children: [
                const Icon(Icons.search_rounded,
                    color: AppColors.textMuted, size: 16),
                const SizedBox(width: 8),
                Text('Search places...',
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted, fontSize: 13)),
              ]),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Layer toggle
        GestureDetector(
          onTap: () => _showLayerPicker(context),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.95),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(Icons.layers_rounded,
                color: AppColors.textSecondary, size: 20),
          ),
        ),
      ]),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = [
      (Icons.layers_rounded, 'ALL'),
      (Icons.build_rounded, 'MECHANIC'),
      (Icons.local_hospital_rounded, 'HOSPITAL'),
      (Icons.local_gas_station_rounded, 'FUEL'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = _filterIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _filterIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary
                    : AppColors.surface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.divider,
                ),
              ),
              child: Row(children: [
                Icon(tabs[i].$1,
                    color: active ? Colors.black : AppColors.textSecondary,
                    size: 14),
                const SizedBox(width: 6),
                Text(tabs[i].$2,
                    style: GoogleFonts.inter(
                      color: active ? Colors.black : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    )),
              ]),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Column(children: [
      // My location
      _MapBtn(
        icon: Icons.my_location_rounded,
        onTap: () {
          _mapCtrl.move(const LatLng(35.9221, 74.3087), 12);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Centered on Gilgit',
                  style: GoogleFonts.inter(color: Colors.black)),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
      const SizedBox(height: 8),
      // Directions
      _MapBtn(
        icon: _routeMode ? Icons.close_rounded : Icons.directions_rounded,
        label: _routeMode ? 'CLEAR' : 'ROUTE',
        color: _routeMode ? AppColors.danger : null,
        onTap: () {
          if (_routeMode) {
            _clearRoute();
          } else {
            setState(() {
              _routeMode = true;
              _routeStart = null;
              _routeEnd = null;
              _routePoints = [];
            });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Tap map to set start point',
                  style: GoogleFonts.inter(color: Colors.black)),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ));
          }
        },
      ),
      const SizedBox(height: 8),
      // Download offline
      _MapBtn(
        icon: _dlRegions.isNotEmpty
            ? Icons.download_done_rounded
            : Icons.download_for_offline_rounded,
        label: 'OFFLINE',
        color: _showDlPanel ? AppColors.primary : null,
        onTap: () => setState(() => _showDlPanel = !_showDlPanel),
      ),
      const SizedBox(height: 8),
      // Zoom in
      _MapBtn(
        icon: Icons.add_rounded,
        onTap: () {
          if (_mapReady) {
            _mapCtrl.move(
                _mapCtrl.camera.center, _mapCtrl.camera.zoom + 1);
          }
        },
      ),
      const SizedBox(height: 4),
      // Zoom out
      _MapBtn(
        icon: Icons.remove_rounded,
        onTap: () {
          if (_mapReady) {
            _mapCtrl.move(
                _mapCtrl.camera.center, _mapCtrl.camera.zoom - 1);
          }
        },
      ),
    ]);
  }

  void _showSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 20, right: 20, top: 20,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          TextField(
            autofocus: true,
            style: GoogleFonts.inter(
                color: AppColors.textPrimary, fontSize: 15),
            decoration: const InputDecoration(
              hintText: 'Search places, landmarks...',
              prefixIcon:
                  Icon(Icons.search_rounded, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          ..._allPOIs.where((p) => p.type == 'destination').map((p) =>
            ListTile(
              leading: Icon(p.icon, color: p.color, size: 20),
              title: Text(p.name,
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary, fontSize: 14)),
              subtitle: Text(p.detail,
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted, fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                _mapCtrl.move(p.position, 12);
                setState(() => _selected = p);
              },
              contentPadding: EdgeInsets.zero,
            )),
        ]),
      ),
    );
  }

  void _showLayerPicker(BuildContext context) {
    const icons = [
      Icons.map_rounded,             // Standard OSM
      Icons.landscape_rounded,       // Outdoors
      Icons.dark_mode_rounded,       // Dark
      Icons.satellite_alt_rounded,   // Satellite
      Icons.terrain_rounded,         // Topo
    ];
    const subtitles = [
      'OpenStreetMap · Free',
      'Stadia Outdoors · Great for mountains',
      'Stadia Dark · Night mode',
      'ESRI World Imagery · Satellite',
      'OpenTopoMap · Elevation contours',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 18),
            Text('Map Style',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            ...List.generate(_layers.length, (i) {
              final active = _layerIndex == i;
              return GestureDetector(
                onTap: () {
                  setState(() => _layerIndex = i);
                  setLocal(() {});
                  Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active
                          ? AppColors.primary.withOpacity(0.5)
                          : AppColors.divider,
                    ),
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary.withOpacity(0.15)
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icons[i],
                          color: active
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(_layers[i]['name'] as String,
                            style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(subtitles[i],
                            style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 11)),
                      ]),
                    ),
                    if (active)
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary, size: 22),
                  ]),
                ),
              );
            }),
          ]),
        ),
      ),
    );
  }
}

// ─── POI Popup ───────────────────────────────────────────────────────────────

class _POIPopup extends StatelessWidget {
  final _POI poi;
  final VoidCallback onClose;
  final VoidCallback onFly;
  final VoidCallback onDirections;

  const _POIPopup({
    required this.poi,
    required this.onClose,
    required this.onFly,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: poi.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: poi.color.withOpacity(0.3)),
          ),
          child: Icon(poi.icon, color: poi.color, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(poi.name,
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(poi.detail,
                style: GoogleFonts.inter(
                    color: AppColors.textMuted, fontSize: 12)),
          ]),
        ),
        const SizedBox(width: 8),
        Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: onFly,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
              ),
              child: Text('FLY TO',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 11)),
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 34,
            child: OutlinedButton.icon(
              onPressed: onDirections,
              icon: const Icon(Icons.directions_rounded, size: 14),
              label: Text('ROUTE',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 11)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: Size.zero,
              ),
            ),
          ),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close_rounded,
                color: AppColors.textMuted, size: 18),
          ),
        ]),
      ]),
    );
  }
}

// ─── Download Panel ───────────────────────────────────────────────────────────

class _DownloadPanel extends StatefulWidget {
  final MapController mapCtrl;
  final bool mapReady;
  final bool downloading;
  final double progress;
  final int done;
  final int total;
  final String regionName;
  final List<_DownloadedRegion> downloadedRegions;
  final int Function(LatLngBounds) countTiles;
  final void Function(String) onDownload;
  final VoidCallback onCancel;
  final VoidCallback onClose;

  const _DownloadPanel({
    required this.mapCtrl,
    required this.mapReady,
    required this.downloading,
    required this.progress,
    required this.done,
    required this.total,
    required this.regionName,
    required this.downloadedRegions,
    required this.countTiles,
    required this.onDownload,
    required this.onCancel,
    required this.onClose,
  });

  @override
  State<_DownloadPanel> createState() => _DownloadPanelState();
}

class _DownloadPanelState extends State<_DownloadPanel> {
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: 'Hunza Region');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tileCount = widget.mapReady
        ? widget.countTiles(widget.mapCtrl.camera.visibleBounds)
        : 0;
    final estMB = (tileCount * 20 / 1024).toStringAsFixed(1);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(
            top: BorderSide(color: AppColors.divider, width: 1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, -4)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Center(
          child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2))),
        ),
        const SizedBox(height: 16),

        // Header
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            const Icon(Icons.download_for_offline_rounded,
                color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text('Offline Map Download',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
          ]),
          if (!widget.downloading)
            GestureDetector(
              onTap: widget.onClose,
              child: const Icon(Icons.close_rounded,
                  color: AppColors.textMuted, size: 20),
            ),
        ]),
        const SizedBox(height: 14),

        if (!widget.downloading) ...[
          // Region name input
          TextField(
            controller: _nameCtrl,
            style: GoogleFonts.inter(
                color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Region name',
              prefixIcon:
                  Icon(Icons.label_outline_rounded, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 12),

          // Info row
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
              _InfoStat('TILES', '$tileCount'),
              Container(width: 1, height: 30, color: AppColors.divider),
              _InfoStat('SIZE', '~$estMB MB'),
              Container(width: 1, height: 30, color: AppColors.divider),
              const _InfoStat('ZOOM', '9 – 13'),
            ]),
          ),
          const SizedBox(height: 12),

          // Downloaded regions
          if (widget.downloadedRegions.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Downloaded',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            ...widget.downloadedRegions.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(r.name,
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
                Text('${r.sizeMB.toStringAsFixed(1)} MB',
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted, fontSize: 12)),
              ]),
            )),
            const SizedBox(height: 8),
          ],

          // Download button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () =>
                  widget.onDownload(_nameCtrl.text.trim().isEmpty
                      ? 'My Region'
                      : _nameCtrl.text.trim()),
              icon: const Icon(Icons.download_rounded, size: 20),
              label: Text('Download Visible Area',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ] else ...[
          // Progress view
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Downloading ${widget.regionName}',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            Text('${(widget.progress * 100).round()}%',
                style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: widget.progress,
              backgroundColor: AppColors.divider,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${widget.done} / ${widget.total} tiles cached',
                style: GoogleFonts.inter(
                    color: AppColors.textMuted, fontSize: 12)),
            Text('~${(widget.done * 20 / 1024).toStringAsFixed(1)} MB',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 12)),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.cancel_rounded),
              label: Text('Cancel Download',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

class _InfoStat extends StatelessWidget {
  final String label;
  final String value;
  const _InfoStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label,
          style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1)),
      const SizedBox(height: 4),
      Text(value,
          style: GoogleFonts.inter(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w700)),
    ]);
  }
}

// ─── Route Info Panel ─────────────────────────────────────────────────────────

class _RouteInfoPanel extends StatelessWidget {
  final String distance;
  final String duration;
  final bool isOffline;
  final VoidCallback onClear;
  final String startLabel;
  final String endLabel;

  const _RouteInfoPanel({
    required this.distance,
    required this.duration,
    required this.isOffline,
    required this.onClear,
    required this.startLabel,
    required this.endLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Distance + duration row
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_rounded,
                color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Text(distance,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(duration,
                      style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 2),
              if (isOffline)
                Row(children: [
                  const Icon(Icons.wifi_off_rounded,
                      color: AppColors.textMuted, size: 12),
                  const SizedBox(width: 4),
                  Text('Straight-line (offline)',
                      style: GoogleFonts.inter(
                          color: AppColors.textMuted, fontSize: 11)),
                ]),
            ]),
          ),
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded,
                  color: AppColors.textMuted, size: 18),
            ),
          ),
        ]),

        const SizedBox(height: 12),
        Container(height: 1, color: AppColors.divider),
        const SizedBox(height: 10),

        // Start → End labels
        Row(children: [
          Column(children: [
            Container(width: 10, height: 10,
                decoration: const BoxDecoration(
                    color: Color(0xFF44DD88), shape: BoxShape.circle)),
            Container(width: 2, height: 18, color: AppColors.textMuted),
            Container(width: 10, height: 10,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle)),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(startLabel,
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Text(endLabel,
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      ]),
    );
  }
}

// ─── Map Button ───────────────────────────────────────────────────────────────

class _MapBtn extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color? color;
  final VoidCallback onTap;

  const _MapBtn(
      {required this.icon, this.label, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: label != null
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
            : const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color != null
              ? color!.withOpacity(0.15)
              : AppColors.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color ?? AppColors.divider,
          ),
        ),
        child: label != null
            ? Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon,
                    color: color ?? AppColors.textSecondary, size: 16),
                const SizedBox(height: 2),
                Text(label!,
                    style: GoogleFonts.inter(
                        color: color ?? AppColors.textMuted,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
              ])
            : Icon(icon,
                color: color ?? AppColors.textSecondary, size: 20),
      ),
    );
  }
}
