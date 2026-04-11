import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// Fetches current weather from the free OpenMeteo API (no key required).
class WeatherService {
  static Future<WeatherData?> fetchWeather(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat'
        '&longitude=$lon'
        '&current_weather=true'
        '&timezone=auto',
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final cw = data['current_weather'] as Map<String, dynamic>;
        return WeatherData(
          temperature: (cw['temperature'] as num).toDouble(),
          weatherCode: (cw['weathercode'] as num).toInt(),
          windspeed: (cw['windspeed'] as num).toDouble(),
        );
      }
    } catch (_) {}
    return null;
  }

  /// Fetch weather for multiple locations concurrently.
  static Future<Map<String, WeatherData>> fetchForExpeditions(
      List<({String id, double lat, double lon})> locations) async {
    final futures = locations.map((l) async {
      final data = await fetchWeather(l.lat, l.lon);
      return MapEntry(l.id, data);
    });
    final results = await Future.wait(futures);
    final map = <String, WeatherData>{};
    for (final entry in results) {
      if (entry.value != null) map[entry.key] = entry.value!;
    }
    return map;
  }
}
