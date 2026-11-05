import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ghumo/services/http_support.dart';
import 'package:ghumo/services/nearby_service.dart';
import 'package:ghumo/services/routing_service.dart';
import 'package:ghumo/services/weather_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

import 'support/harness.dart';

void main() {
  group('WeatherService', () {
    test('parses a report', () async {
      final service = WeatherService(client: MockClient((r) async => http.Response(weatherBody(r.url), 200)));
      final report = await service.fetchReport(36.3, 74.6);
      expect(report.current.temperatureLabel, '8°C');
      expect(report.current.summary, 'Partly cloudy');
      expect(report.daily, hasLength(5));
      expect(report.daily[3].min, -3);
    });

    test('bulk results keep the requested order and count', () async {
      Uri? seen;
      final service = WeatherService(client: MockClient((r) async {
        seen = r.url;
        return http.Response(weatherBody(r.url), 200);
      }));
      final list = await service.fetchCurrentBulk([(lat: 1, lon: 2), (lat: 3, lon: 4)]);
      expect(list, hasLength(2));
      expect(seen!.queryParameters['latitude'], '1.0,3.0');
      expect(seen!.scheme, 'https');
    });

    test('errors become readable messages', () async {
      for (final client in [
        MockClient((_) async => http.Response('oops', 500)),
        MockClient((_) async => throw http.ClientException('offline')),
        MockClient((_) async => http.Response('not json', 200)),
        MockClient((_) async => http.Response(jsonEncode({'current': {}}), 200)),
      ]) {
        await expectLater(WeatherService(client: client).fetchReport(1, 2), throwsA(isA<ServiceException>()));
      }
    });

    test('WMO codes map to the right summary', () {
      expect(weatherSummary(0), 'Clear');
      expect(weatherSummary(45), 'Fog');
      expect(weatherSummary(55), 'Drizzle');
      expect(weatherSummary(63), 'Rain');
      expect(weatherSummary(73), 'Snow');
      expect(weatherSummary(81), 'Showers');
      expect(weatherSummary(95), 'Thunderstorm');
    });
  });

  group('RoutingService', () {
    const a = LatLng(35.92, 74.30);
    const b = LatLng(36.31, 74.65);

    test('parses a road route and converts units', () async {
      final body = jsonEncode({
        'routes': [
          {
            'distance': 96787.7,
            'duration': 4303.2,
            'geometry': {
              'coordinates': [[74.30, 35.92], [74.65, 36.31]],
            },
          },
        ],
      });
      final route = await RoutingService(client: MockClient((r) async {
        expect(r.url.scheme, 'https', reason: 'Android blocks cleartext traffic');
        return http.Response(body, 200);
      })).fetchRoute(a, b);
      expect(route.isEstimate, isFalse);
      expect(route.distanceKm, closeTo(96.79, 0.01));
      expect(route.durationSeconds, 4303);
      expect(route.points.first, const LatLng(35.92, 74.30), reason: 'GeoJSON is lon,lat');
    });

    test('falls back to a labelled straight line with no invented drive time', () async {
      for (final client in [
        MockClient((_) async => throw http.ClientException('offline')),
        MockClient((_) async => http.Response(jsonEncode({'routes': []}), 200)),
        MockClient((_) async => http.Response('bad', 500)),
      ]) {
        final route = await RoutingService(client: client).fetchRoute(a, b);
        expect(route.isEstimate, isTrue);
        expect(route.durationSeconds, isNull);
        expect(route.points, [a, b]);
        expect(route.distanceKm, closeTo(53, 3));
      }
    });
  });

  group('NearbyService', () {
    const body = '''{"elements":[
      {"type":"node","id":1,"lat":35.9,"lon":74.3,"tags":{"name":"PSO Gilgit","phone":"123"}},
      {"type":"way","id":2,"center":{"lat":35.8,"lon":74.2},"tags":{"brand":"Shell"}},
      {"type":"node","id":3,"lat":35.7,"lon":74.1},
      {"type":"way","id":4,"tags":{"name":"No coordinates"}}
    ]}''';

    test('parses nodes and ways, uses fallback names, skips bad entries', () {
      final places = NearbyService.parse(body, PoiType.fuel);
      expect(places, hasLength(3));
      expect(places[0].name, 'PSO Gilgit');
      expect(places[0].detail, '123');
      expect(places[1].name, 'Shell');
      expect(places[1].position, const LatLng(35.8, 74.2));
      expect(places[2].name, 'Fuel station');
    });

    test('query filters by bounding box and result limit', () {
      final q = NearbyService.buildQuery(PoiType.hospital, south: 1, west: 2, north: 3, east: 4);
      expect(q, contains('(1.0,2.0,3.0,4.0)'));
      expect(q, contains('hospital|clinic'));
      expect(q, contains('out center ${NearbyService.maxResults}'));
    });

    test('tries the mirror when the first server fails', () async {
      var calls = 0;
      final service = NearbyService(client: MockClient((_) async {
        calls++;
        return calls == 1 ? http.Response('busy', 429) : http.Response(body, 200);
      }));
      final found = await service.search(PoiType.fuel, south: 1, west: 2, north: 3, east: 4);
      expect(calls, 2);
      expect(found, hasLength(3));
    });

    test('reports an error when every server fails', () async {
      final service = NearbyService(client: MockClient((_) async => throw http.ClientException('offline')));
      await expectLater(service.search(PoiType.fuel, south: 1, west: 2, north: 3, east: 4), throwsA(isA<ServiceException>()));
    });
  });
}
