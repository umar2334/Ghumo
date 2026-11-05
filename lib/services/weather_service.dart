import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'http_support.dart';

class CurrentWeather {
  const CurrentWeather({required this.temperature, required this.code, required this.windKmh});
  final double temperature;
  final int code;
  final double windKmh;

  String get temperatureLabel => '${temperature.round()}°C';
  IconData get icon => weatherIcon(code);
  String get summary => weatherSummary(code);
}

class DailyForecast {
  const DailyForecast({required this.date, required this.code, required this.max, required this.min});
  final DateTime date;
  final int code;
  final double max;
  final double min;
}

class WeatherReport {
  const WeatherReport({required this.current, required this.daily});
  final CurrentWeather current;
  final List<DailyForecast> daily;
}

/// Maps a WMO weather code to an icon.
IconData weatherIcon(int code) {
  if (code == 0) return Icons.wb_sunny_rounded;
  if (code <= 3) return Icons.wb_cloudy_rounded;
  if (code <= 48) return Icons.foggy;
  if (code <= 67) return Icons.water_drop_rounded;
  if (code <= 77) return Icons.ac_unit_rounded;
  if (code <= 82) return Icons.umbrella_rounded;
  if (code <= 86) return Icons.ac_unit_rounded;
  return Icons.thunderstorm_rounded;
}

String weatherSummary(int code) {
  if (code == 0) return 'Clear';
  if (code <= 3) return 'Partly cloudy';
  if (code <= 48) return 'Fog';
  if (code <= 57) return 'Drizzle';
  if (code <= 67) return 'Rain';
  if (code <= 77) return 'Snow';
  if (code <= 82) return 'Showers';
  if (code <= 86) return 'Snow showers';
  return 'Thunderstorm';
}

/// Weather from Open-Meteo, which is free and needs no API key.
class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  static const _host = 'api.open-meteo.com';
  static const _fields = 'temperature_2m,weather_code,wind_speed_10m';

  /// Current weather for many places in one request, keyed by [points] order.
  Future<List<CurrentWeather>> fetchCurrentBulk(List<({double lat, double lon})> points) async {
    final uri = Uri.https(_host, '/v1/forecast', {
      'latitude': points.map((p) => p.lat).join(','),
      'longitude': points.map((p) => p.lon).join(','),
      'current': _fields,
      'timezone': 'auto',
    });
    final decoded = await _get(uri);
    final list = decoded is List ? decoded : [decoded];
    if (list.length != points.length) {
      throw const ServiceException('Weather data was incomplete.');
    }
    return list.map((e) => _parseCurrent(e as Map<String, dynamic>)).toList();
  }

  Future<WeatherReport> fetchReport(double lat, double lon) async {
    final uri = Uri.https(_host, '/v1/forecast', {
      'latitude': '$lat',
      'longitude': '$lon',
      'current': _fields,
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
      'forecast_days': '5',
      'timezone': 'auto',
    });
    final json = await _get(uri) as Map<String, dynamic>;
    try {
      final d = json['daily'] as Map<String, dynamic>;
      final dates = d['time'] as List;
      return WeatherReport(
        current: _parseCurrent(json),
        daily: [
          for (var i = 0; i < dates.length; i++)
            DailyForecast(
              date: DateTime.parse(dates[i] as String),
              code: ((d['weather_code'] as List)[i] as num).toInt(),
              max: ((d['temperature_2m_max'] as List)[i] as num).toDouble(),
              min: ((d['temperature_2m_min'] as List)[i] as num).toDouble(),
            ),
        ],
      );
    } on TypeError {
      throw const ServiceException('Weather data could not be read.');
    }
  }

  CurrentWeather _parseCurrent(Map<String, dynamic> json) {
    try {
      final c = json['current'] as Map<String, dynamic>;
      return CurrentWeather(
        temperature: (c['temperature_2m'] as num).toDouble(),
        code: (c['weather_code'] as num).toInt(),
        windKmh: (c['wind_speed_10m'] as num).toDouble(),
      );
    } on TypeError {
      throw const ServiceException('Weather data could not be read.');
    }
  }

  Future<dynamic> _get(Uri uri) async {
    try {
      final res = await _client.get(uri, headers: apiHeaders).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw const ServiceException('The weather service is unavailable right now.');
      }
      return jsonDecode(res.body);
    } on ServiceException {
      rethrow;
    } catch (_) {
      throw const ServiceException('Could not load weather. Check your connection.');
    }
  }
}
