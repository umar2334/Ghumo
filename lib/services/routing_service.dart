import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'http_support.dart';

class RouteResult {
  const RouteResult({required this.points, required this.distanceKm, this.durationSeconds, this.isEstimate = false});
  final List<LatLng> points;
  final double distanceKm;

  /// Null for straight-line estimates, where a drive time would be a guess.
  final int? durationSeconds;

  /// True when this is a straight line because no road route was available.
  final bool isEstimate;
}

/// Driving routes from the public OSRM server, with a labelled straight-line
/// fallback for when the phone is offline.
class RoutingService {
  RoutingService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<RouteResult> fetchRoute(LatLng start, LatLng end) async {
    final uri = Uri.https(
      'router.project-osrm.org',
      '/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}',
      {'overview': 'full', 'geometries': 'geojson'},
    );
    try {
      final res = await _client.get(uri, headers: apiHeaders).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final parsed = parseRoute(res.body);
        if (parsed != null) return parsed;
      }
    } catch (_) {
      // Fall through to the straight-line estimate.
    }
    return straightLine(start, end);
  }

  static RouteResult straightLine(LatLng start, LatLng end) => RouteResult(
        points: [start, end],
        distanceKm: const Distance().as(LengthUnit.Meter, start, end) / 1000,
        isEstimate: true,
      );

  /// Returns null when the response contains no usable route.
  static RouteResult? parseRoute(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final routes = json['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final route = routes.first as Map<String, dynamic>;
      final coords = (route['geometry'] as Map<String, dynamic>)['coordinates'] as List;
      return RouteResult(
        points: coords.map((c) {
          final pair = c as List;
          return LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());
        }).toList(),
        distanceKm: (route['distance'] as num).toDouble() / 1000,
        durationSeconds: (route['duration'] as num).round(),
      );
    } catch (_) {
      return null;
    }
  }
}
