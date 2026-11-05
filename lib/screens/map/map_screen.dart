import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/destinations.dart';
import '../../models/models.dart';
import '../../services/nearby_service.dart';
import '../../services/routing_service.dart';
import '../../state/app_scope.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../destination_screen.dart';
import 'cached_tile_provider.dart';
import 'map_widgets.dart';

class _MapLayer {
  const _MapLayer(this.name, this.description, this.icon, this.url, this.subdomains, this.maxNativeZoom, this.attribution, this.attributionUrl);
  final String name;
  final String description;
  final IconData icon;
  final String url;
  final List<String> subdomains;
  final int maxNativeZoom;
  final String attribution;
  final String attributionUrl;
}

const _layers = [
  _MapLayer('Standard', 'OpenStreetMap', Icons.map_rounded, 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', [], 19,
      '© OpenStreetMap contributors', 'https://www.openstreetmap.org/copyright'),
  _MapLayer('Topographic', 'Elevation contours, good for mountains', Icons.terrain_rounded, 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png', ['a', 'b', 'c'], 17,
      '© OpenStreetMap contributors, SRTM | © OpenTopoMap (CC-BY-SA)', 'https://opentopomap.org/about'),
  _MapLayer('Satellite', 'Esri World Imagery', Icons.satellite_alt_rounded, 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', [], 18,
      'Tiles © Esri and its data providers', 'https://www.esri.com/'),
];

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _pakistanCenter = LatLng(31.5, 71.5);
  static const _minNearbyZoom = 9.0;

  final _map = MapController();
  late final TileProvider _tileProvider =
      AppScope.servicesOf(context).tileProvider ?? (kIsWeb ? NetworkTileProvider() : CachedTileProvider());
  AppNavigation? _navigation;
  bool _ready = false;
  int _layer = 0;

  /// Null shows the destination guide. Otherwise, live results of this type.
  PoiType? _poiType;
  List<NearbyPlace> _nearby = [];
  bool _loadingNearby = false;
  String? _nearbyStatus;

  Destination? _selectedDestination;
  NearbyPlace? _selectedPlace;

  LatLng? _myLocation;
  bool _locating = false;

  bool _pickingRoute = false;
  LatLng? _routeStart;
  LatLng? _routeEnd;
  String _startLabel = 'Start';
  String _endLabel = 'Destination';
  RouteResult? _route;
  bool _loadingRoute = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_navigation == null) {
      _navigation = AppScope.nav(context);
      _navigation!.mapTarget.addListener(_applyTarget);
    }
  }

  @override
  void dispose() {
    _navigation?.mapTarget.removeListener(_applyTarget);
    super.dispose();
  }

  void _applyTarget() {
    final target = _navigation?.mapTarget.value;
    if (target == null || !_ready) return;
    _map.move(target.position, 11);
    setState(() {
      _poiType = null;
      _selectedPlace = null;
      _selectedDestination = destinationById(target.destinationId);
    });
    _navigation!.mapTarget.value = null;
  }

  // ─── Location ─────────────────────────────────────────────────────────────

  Future<LatLng?> _locate() async {
    setState(() => _locating = true);
    try {
      final here = await AppScope.servicesOf(context).location.current();
      if (mounted) setState(() => _myLocation = here);
      return here;
    } catch (e) {
      if (mounted) showMessage(context, '$e');
      return null;
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _goToMyLocation() async {
    final here = await _locate();
    if (here != null && mounted) _map.move(here, 12);
  }

  // ─── Nearby ───────────────────────────────────────────────────────────────

  void _selectFilter(PoiType? type) {
    setState(() {
      _poiType = type;
      _nearby = [];
      _nearbyStatus = null;
      _selectedDestination = null;
      _selectedPlace = null;
    });
    if (type != null) _searchNearby();
  }

  Future<void> _searchNearby() async {
    final type = _poiType;
    if (type == null || !_ready) return;
    if (_map.camera.zoom < _minNearbyZoom) {
      setState(() => _nearbyStatus = 'Zoom in on an area to search for ${type.label.toLowerCase()} places.');
      return;
    }
    final b = _map.camera.visibleBounds;
    setState(() {
      _loadingNearby = true;
      _nearbyStatus = null;
    });
    try {
      final found = await AppScope.servicesOf(context).nearby.search(type, south: b.south, west: b.west, north: b.north, east: b.east);
      if (!mounted || _poiType != type) return;
      setState(() {
        _nearby = found;
        _nearbyStatus = found.isEmpty ? 'None mapped in this area. Coverage depends on OpenStreetMap volunteers.' : null;
      });
    } catch (e) {
      if (mounted && _poiType == type) setState(() => _nearbyStatus = '$e');
    } finally {
      if (mounted) setState(() => _loadingNearby = false);
    }
  }

  // ─── Routing ──────────────────────────────────────────────────────────────

  void _clearRoute() {
    setState(() {
      _pickingRoute = false;
      _routeStart = null;
      _routeEnd = null;
      _route = null;
      _loadingRoute = false;
    });
  }

  Future<void> _computeRoute() async {
    setState(() => _loadingRoute = true);
    final route = await AppScope.servicesOf(context).routing.fetchRoute(_routeStart!, _routeEnd!);
    if (!mounted || _routeStart == null || _routeEnd == null) return;
    setState(() {
      _route = route;
      _loadingRoute = false;
      _pickingRoute = false;
    });
    _map.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(route.points),
      padding: const EdgeInsets.fromLTRB(50, 150, 70, 220),
    ));
  }

  /// Routes from the real location. If unavailable, asks for a start on the map.
  Future<void> _routeTo(LatLng end, String label) async {
    _clearRoute();
    setState(() {
      _routeEnd = end;
      _endLabel = label;
      _selectedDestination = null;
      _selectedPlace = null;
    });
    final here = await _locate();
    if (!mounted) return;
    if (here == null) {
      setState(() => _pickingRoute = true);
      return;
    }
    setState(() {
      _routeStart = here;
      _startLabel = 'My location';
    });
    await _computeRoute();
  }

  void _onMapTap(LatLng point) {
    if (!_pickingRoute) {
      setState(() {
        _selectedDestination = null;
        _selectedPlace = null;
      });
      return;
    }
    if (_routeStart == null) {
      setState(() {
        _routeStart = point;
        _startLabel = 'Selected point';
      });
      if (_routeEnd != null) _computeRoute();
    } else if (_routeEnd == null) {
      setState(() {
        _routeEnd = point;
        _endLabel = 'Selected point';
      });
      _computeRoute();
    }
  }

  Future<void> _navigateExternally(LatLng p) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {'api': '1', 'destination': '${p.latitude},${p.longitude}'});
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) => false);
    if (!ok && mounted) showMessage(context, 'Could not open a navigation app');
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final layer = _layers[_layer];
    final selected = _selectedDestination;
    final place = _selectedPlace;
    return Scaffold(
      body: Stack(children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: _pakistanCenter,
            initialZoom: 5.5,
            minZoom: 4,
            maxZoom: 18,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
            onMapReady: () {
              _ready = true;
              _applyTarget();
            },
            onTap: (_, point) => _onMapTap(point),
          ),
          children: [
            TileLayer(
              urlTemplate: layer.url,
              subdomains: layer.subdomains,
              maxNativeZoom: layer.maxNativeZoom,
              userAgentPackageName: 'com.ghumo.ghumo',
              tileProvider: _tileProvider,
            ),
            if (_route != null)
              PolylineLayer(polylines: [
                Polyline(points: _route!.points, color: AppColors.primary, strokeWidth: 4.5, isDotted: _route!.isEstimate),
              ]),
            MarkerLayer(markers: _markers()),
            SimpleAttributionWidget(
              source: Text(layer.attribution, style: const TextStyle(fontSize: 10, color: Colors.black87)),
              onTap: () => launchUrl(Uri.parse(layer.attributionUrl), mode: LaunchMode.externalApplication),
            ),
          ],
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(children: [
              _topBar(),
              const SizedBox(height: 8),
              _filters(),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 66),
                child: _statusBanner(),
              ),
            ]),
          ),
        ),
        Positioned(
          right: 12,
          top: MediaQuery.paddingOf(context).top + 112,
          child: _controls(),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 28,
          child: _bottomPanel(selected, place),
        ),
      ]),
    );
  }

  Widget _bottomPanel(Destination? selected, NearbyPlace? place) {
    if (_route != null) {
      return RoutePanel(route: _route!, startLabel: _startLabel, endLabel: _endLabel, onClear: _clearRoute);
    }
    if (selected != null) {
      return PlacePanel(
        title: selected.name,
        subtitle: selected.region,
        icon: selected.category.icon,
        color: AppColors.primary,
        onClose: () => setState(() => _selectedDestination = null),
        onRoute: () => _routeTo(LatLng(selected.lat, selected.lon), selected.name),
        onNavigate: () => _navigateExternally(LatLng(selected.lat, selected.lon)),
        onDetails: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DestinationScreen(destination: selected))),
      );
    }
    if (place != null) {
      return PlacePanel(
        title: place.name,
        subtitle: place.detail ?? place.type.fallbackName,
        icon: place.type.icon,
        color: place.type.color,
        onClose: () => setState(() => _selectedPlace = null),
        onRoute: () => _routeTo(place.position, place.name),
        onNavigate: () => _navigateExternally(place.position),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _statusBanner() {
    if (_loadingRoute) return const MapBanner(message: 'Calculating route...', loading: true);
    if (_pickingRoute) {
      return MapBanner(
        icon: Icons.touch_app_rounded,
        message: _routeStart == null ? 'Tap the map to set your start point' : 'Now tap your destination',
        action: 'Cancel',
        onAction: _clearRoute,
      );
    }
    if (_loadingNearby) return const MapBanner(message: 'Searching OpenStreetMap...', loading: true);
    if (_poiType != null) {
      return MapBanner(
        message: _nearbyStatus ?? '${_nearby.length} found in this area${_nearby.length >= NearbyService.maxResults ? ' (zoom in for more)' : ''}',
        action: 'Search here',
        onAction: _searchNearby,
      );
    }
    return const SizedBox.shrink();
  }

  List<Marker> _markers() {
    final markers = <Marker>[];
    if (_poiType == null) {
      for (final d in destinations) {
        final active = _selectedDestination?.id == d.id;
        markers.add(_marker(LatLng(d.lat, d.lon), d.category.icon, AppColors.primary, active, () {
          if (_pickingRoute) return _onMapTap(LatLng(d.lat, d.lon));
          setState(() {
            _selectedDestination = active ? null : d;
            _selectedPlace = null;
          });
        }));
      }
    }
    for (final p in _nearby) {
      final active = _selectedPlace?.id == p.id;
      markers.add(_marker(p.position, p.type.icon, p.type.color, active, () {
        if (_pickingRoute) return _onMapTap(p.position);
        setState(() {
          _selectedPlace = active ? null : p;
          _selectedDestination = null;
        });
      }));
    }
    if (_routeStart != null) markers.add(_endpoint(_routeStart!, Icons.trip_origin_rounded, AppColors.success));
    if (_routeEnd != null) markers.add(_endpoint(_routeEnd!, Icons.flag_rounded, AppColors.primary));
    if (_myLocation != null) {
      markers.add(Marker(
        point: _myLocation!,
        width: 22,
        height: 22,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
        ),
      ));
    }
    return markers;
  }

  Marker _marker(LatLng point, IconData icon, Color color, bool active, VoidCallback onTap) {
    final size = active ? 46.0 : 36.0;
    return Marker(
      point: point,
      width: size,
      height: size,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: active ? color : AppColors.surface.withValues(alpha: 0.96),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: active ? 2.5 : 1.5),
          ),
          child: Icon(icon, color: active ? Colors.black : color, size: active ? 22 : 17),
        ),
      ),
    );
  }

  Marker _endpoint(LatLng point, IconData icon, Color color) => Marker(
        point: point,
        width: 34,
        height: 34,
        child: Container(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
          child: Icon(icon, color: Colors.black, size: 18),
        ),
      );

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        Expanded(
          child: Material(
            color: AppColors.surface.withValues(alpha: 0.96),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.divider),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _showSearch,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Search destinations', maxLines: 1, overflow: TextOverflow.ellipsis, style: txt(13, color: AppColors.textMuted))),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        MapButton(icon: Icons.layers_rounded, tooltip: 'Map style', onTap: _showLayerPicker),
      ]),
    );
  }

  Widget _filters() {
    Widget chip(String label, IconData icon, PoiType? type) {
      final active = _poiType == type;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Material(
          color: active ? AppColors.primary : AppColors.surface.withValues(alpha: 0.96),
          shape: const StadiumBorder(side: BorderSide(color: AppColors.divider)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => _selectFilter(type),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              child: Row(children: [
                Icon(icon, size: 14, color: active ? Colors.black : AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(label, style: txt(12, weight: 600, color: active ? Colors.black : AppColors.textSecondary)),
              ]),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        chip('Destinations', Icons.terrain_rounded, null),
        for (final t in PoiType.values) chip(t.label, t.icon, t),
      ]),
    );
  }

  Widget _controls() {
    return Column(children: [
      MapButton(
        icon: _locating ? Icons.hourglass_top_rounded : Icons.my_location_rounded,
        tooltip: 'My location',
        onTap: _goToMyLocation,
      ),
      const SizedBox(height: 8),
      MapButton(
        icon: _pickingRoute || _route != null ? Icons.close_rounded : Icons.directions_rounded,
        tooltip: _pickingRoute || _route != null ? 'Clear route' : 'Plan a route on the map',
        color: _pickingRoute || _route != null ? AppColors.danger : null,
        onTap: () {
          if (_pickingRoute || _route != null) return _clearRoute();
          _clearRoute();
          setState(() => _pickingRoute = true);
        },
      ),
      const SizedBox(height: 8),
      MapButton(icon: Icons.add_rounded, tooltip: 'Zoom in', onTap: () => _zoom(1)),
      const SizedBox(height: 4),
      MapButton(icon: Icons.remove_rounded, tooltip: 'Zoom out', onTap: () => _zoom(-1)),
    ]);
  }

  void _zoom(double delta) {
    if (_ready) _map.move(_map.camera.center, _map.camera.zoom + delta);
  }

  void _showSearch() {
    var query = '';
    showAppSheet<void>(context, builder: (sheet) {
      return StatefulBuilder(builder: (sheet, setLocal) {
        final matches = destinations.where((d) => d.matches(query)).take(8).toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            autofocus: true,
            style: txt(15),
            onChanged: (v) => setLocal(() => query = v),
            decoration: const InputDecoration(
              hintText: 'Search destinations',
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 8),
          if (matches.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('No destinations match', textAlign: TextAlign.center, style: txt(14, color: AppColors.textSecondary)),
            ),
          for (final d in matches)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(d.category.icon, color: AppColors.primary),
              title: Text(d.name, style: txt(14, weight: 500)),
              subtitle: Text(d.region, style: txt(12, color: AppColors.textMuted)),
              onTap: () {
                Navigator.pop(sheet);
                _navigation!.mapTarget.value = MapTarget(LatLng(d.lat, d.lon), d.id);
              },
            ),
        ]);
      });
    });
  }

  void _showLayerPicker() {
    showAppSheet<void>(context, builder: (sheet) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SheetTitle('Map style'),
        for (var i = 0; i < _layers.length; i++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(_layers[i].icon, color: i == _layer ? AppColors.primary : AppColors.textSecondary),
            title: Text(_layers[i].name, style: txt(15, weight: 600)),
            subtitle: Text(_layers[i].description, style: txt(12, color: AppColors.textMuted)),
            trailing: i == _layer ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
            onTap: () {
              setState(() => _layer = i);
              Navigator.pop(sheet);
            },
          ),
      ]);
    });
  }
}
