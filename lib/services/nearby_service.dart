import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'http_support.dart';

enum PoiType {
  fuel('Fuel', 'Fuel station', Icons.local_gas_station_rounded, Color(0xFF44DD88),
      'node["amenity"="fuel"]', 'way["amenity"="fuel"]'),
  hospital('Hospital', 'Hospital or clinic', Icons.local_hospital_rounded, Color(0xFF5C9DFF),
      'node["amenity"~"^(hospital|clinic)\$"]', 'way["amenity"~"^(hospital|clinic)\$"]'),
  mechanic('Mechanic', 'Car repair', Icons.build_rounded, Color(0xFFFFCC44),
      'node["shop"="car_repair"]', 'way["shop"="car_repair"]');

  const PoiType(this.label, this.fallbackName, this.icon, this.color, this.nodeFilter, this.wayFilter);
  final String label;
  final String fallbackName;
  final IconData icon;
  final Color color;
  final String nodeFilter;
  final String wayFilter;
}

class NearbyPlace {
  const NearbyPlace({required this.id, required this.type, required this.name, required this.position, this.detail});
  final String id;
  final PoiType type;
  final String name;
  final LatLng position;
  final String? detail;
}

/// Real fuel stations, hospitals and mechanics from OpenStreetMap, through the
/// free Overpass API. Coverage depends on what volunteers have mapped.
class NearbyService {
  NearbyService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  static const _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];
  static const maxResults = 100;

  static String buildQuery(PoiType type, {required double south, required double west, required double north, required double east}) {
    final box = '($south,$west,$north,$east)';
    return '[out:json][timeout:20];(${type.nodeFilter}$box;${type.wayFilter}$box;);out center $maxResults;';
  }

  Future<List<NearbyPlace>> search(PoiType type, {required double south, required double west, required double north, required double east}) async {
    final query = buildQuery(type, south: south, west: west, north: north, east: east);
    for (final endpoint in _endpoints) {
      try {
        final res = await _client
            .post(Uri.parse(endpoint), headers: apiHeaders, body: {'data': query})
            .timeout(const Duration(seconds: 20));
        if (res.statusCode == 200) return parse(res.body, type);
      } catch (_) {
        // Try the next mirror.
      }
    }
    throw const ServiceException('Could not reach the map data service. Please try again.');
  }

  static List<NearbyPlace> parse(String body, PoiType type) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final out = <NearbyPlace>[];
    for (final raw in (json['elements'] as List? ?? [])) {
      final e = raw as Map<String, dynamic>;
      final center = e['center'] as Map<String, dynamic>?;
      final lat = (e['lat'] ?? center?['lat']) as num?;
      final lon = (e['lon'] ?? center?['lon']) as num?;
      if (lat == null || lon == null) continue;
      final tags = e['tags'] as Map<String, dynamic>? ?? const {};
      final name = (tags['name'] ?? tags['brand'] ?? tags['operator']) as String?;
      out.add(NearbyPlace(
        id: '${e['type']}/${e['id']}',
        type: type,
        name: name ?? type.fallbackName,
        position: LatLng(lat.toDouble(), lon.toDouble()),
        detail: tags['phone'] as String? ?? tags['addr:city'] as String?,
      ));
    }
    return out;
  }
}
