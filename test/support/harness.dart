import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/widgets.dart';
import 'package:ghumo/services/location_service.dart';
import 'package:ghumo/services/nearby_service.dart';
import 'package:ghumo/services/routing_service.dart';
import 'package:ghumo/services/weather_service.dart';
import 'package:ghumo/state/app_scope.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A 1x1 transparent PNG, so map tiles load without a network.
final Uint8List transparentPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

class FakeTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) => MemoryImage(transparentPng);
}

const sampleCurrent = {'temperature_2m': 7.6, 'weather_code': 2, 'wind_speed_10m': 11.0};

String weatherBody(Uri uri) {
  final count = uri.queryParameters['latitude']!.split(',').length;
  final daily = {
    'time': ['2026-11-05', '2026-11-06', '2026-11-07', '2026-11-08', '2026-11-09'],
    'weather_code': [0, 3, 61, 71, 95],
    'temperature_2m_max': [12.0, 11.0, 9.0, 6.0, 8.0],
    'temperature_2m_min': [2.0, 1.0, 0.0, -3.0, -1.0],
  };
  if (count == 1) return jsonEncode({'current': sampleCurrent, 'daily': daily});
  return jsonEncode(List.generate(count, (_) => {'current': sampleCurrent}));
}

/// Services backed by canned responses, so tests never touch the network.
AppServices fakeServices({bool online = true}) {
  final client = MockClient((request) async {
    if (!online) throw http.ClientException('offline');
    if (request.url.host == 'api.open-meteo.com') return http.Response(weatherBody(request.url), 200);
    return http.Response('{}', 200);
  });
  return AppServices(
    weather: WeatherService(client: client),
    routing: RoutingService(client: client),
    nearby: NearbyService(client: client),
    location: LocationService(),
    tileProvider: FakeTileProvider(),
  );
}
