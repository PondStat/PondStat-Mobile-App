import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:pondstat/core/services/notification_service.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService(ref);
});

class DailyWeatherData {
  final DateTime date;
  final double? temperature;
  final double? rainfall;
  final double? uvIndex;
  final int? weatherCode;

  DailyWeatherData({
    required this.date,
    this.temperature,
    this.rainfall,
    this.uvIndex,
    this.weatherCode,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'temperature': temperature,
        'rainfall': rainfall,
        'uvIndex': uvIndex,
        'weatherCode': weatherCode,
      };

  factory DailyWeatherData.fromJson(Map<String, dynamic> json) => DailyWeatherData(
        date: DateTime.parse(json['date']),
        temperature: json['temperature']?.toDouble(),
        rainfall: json['rainfall']?.toDouble(),
        uvIndex: json['uvIndex']?.toDouble(),
        weatherCode: json['weatherCode']?.toInt(),
      );
}

class WeatherService {
  final Ref _ref;

  // Default Coordinates: Miagao, Iloilo, Philippines
  static const double defaultLat = 10.6389;
  static const double defaultLon = 122.2353;

  WeatherService(this._ref);

  Future<Map<String, dynamic>> _httpGetJson(String urlString) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    try {
      final uri = Uri.parse(urlString);
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } else {
        throw Exception('HTTP error ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  /// Helper to determine if a start date is within 90 days from now.
  bool _isWithin90Days(DateTime date) {
    final difference = DateTime.now().difference(date).inDays;
    return difference < 90;
  }

  /// Fetch 7-day weather forecast with caching (1 hour TTL)
  Future<List<DailyWeatherData>> fetchForecast(double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'weather_forecast_${lat.toStringAsFixed(4)}_${lon.toStringAsFixed(4)}';
    final cachedString = prefs.getString(cacheKey);

    if (cachedString != null) {
      final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final timeDiff = DateTime.now().millisecondsSinceEpoch - timestamp;

      // 1 hour cache TTL
      if (timeDiff < 3600000) {
        final list = cacheData['data'] as List;
        return list.map((item) => DailyWeatherData.fromJson(item)).toList();
      }
    }

    try {
      final url = 'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&daily=temperature_2m_mean,rain_sum,uv_index_max,weather_code&timezone=auto';
      final json = await _httpGetJson(url);
      final weatherList = _parseOpenMeteoResponse(json);

      if (weatherList.isNotEmpty) {
        final cacheToSave = {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': weatherList.map((w) => w.toJson()).toList(),
        };
        await prefs.setString(cacheKey, jsonEncode(cacheToSave));
      }

      return weatherList;
    } catch (e) {
      // Fallback to cache on error if available
      if (cachedString != null) {
        final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
        final list = cacheData['data'] as List;
        return list.map((item) => DailyWeatherData.fromJson(item)).toList();
      }
      rethrow;
    }
  }

  /// Fetch weather history for specific date range (forecast or archive API)
  Future<List<DailyWeatherData>> fetchHistory(double lat, double lon, DateTime start, DateTime end) async {
    final startStr = DateFormat('yyyy-MM-dd').format(start);
    final endStr = DateFormat('yyyy-MM-dd').format(end);

    final String url;
    if (_isWithin90Days(start)) {
      url = 'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&start_date=$startStr&end_date=$endStr&daily=temperature_2m_mean,rain_sum,uv_index_max,weather_code&timezone=auto';
    } else {
      url = 'https://archive-api.open-meteo.com/v1/archive?latitude=$lat&longitude=$lon&start_date=$startStr&end_date=$endStr&daily=temperature_2m_mean,rain_sum,uv_index_max,weather_code&timezone=auto';
    }

    try {
      final json = await _httpGetJson(url);
      return _parseOpenMeteoResponse(json);
    } catch (e) {
      // Return empty list on failure for history chart fallback
      return [];
    }
  }

  List<DailyWeatherData> _parseOpenMeteoResponse(Map<String, dynamic> json) {
    if (!json.containsKey('daily')) return [];
    final daily = json['daily'] as Map<String, dynamic>;
    final times = daily['time'] as List;
    final temps = daily['temperature_2m_mean'] as List?;
    final rains = daily['rain_sum'] as List?;
    final uvs = daily['uv_index_max'] as List?;
    final codes = daily['weather_code'] as List?;

    List<DailyWeatherData> results = [];
    for (int i = 0; i < times.length; i++) {
      final date = DateTime.parse(times[i].toString());
      final temp = temps != null && i < temps.length ? temps[i]?.toDouble() : null;
      final rain = rains != null && i < rains.length ? rains[i]?.toDouble() : null;
      final uv = uvs != null && i < uvs.length ? uvs[i]?.toDouble() : null;
      final code = codes != null && i < codes.length ? codes[i]?.toInt() : null;

      results.add(DailyWeatherData(
        date: date,
        temperature: temp,
        rainfall: rain,
        uvIndex: uv,
        weatherCode: code,
      ));
    }
    return results;
  }

  /// Analyze forecast weather and trigger smart alerts/notifications
  Future<List<String>> checkWeatherAlerts(String pondId, String pondName, double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    List<DailyWeatherData> forecast;
    try {
      forecast = await fetchForecast(lat, lon);
    } catch (e) {
      return [];
    }

    // Examine next 3 days
    final now = DateTime.now();
    final next3Days = forecast.where((w) {
      final diff = w.date.difference(now).inDays;
      return diff >= 0 && diff <= 3;
    }).toList();

    double maxRain = 0.0;
    double maxTemp = 0.0;
    double maxUv = 0.0;

    for (var day in next3Days) {
      if (day.rainfall != null && day.rainfall! > maxRain) maxRain = day.rainfall!;
      if (day.temperature != null && day.temperature! > maxTemp) maxTemp = day.temperature!;
      if (day.uvIndex != null && day.uvIndex! > maxUv) maxUv = day.uvIndex!;
    }

    List<String> activeAlerts = [];

    // Rule 1: Heavy Rain Alert (> 15mm)
    if (maxRain > 15.0) {
      const alertMsg = 'Heavy rain expected — monitor salinity & pH drop.';
      activeAlerts.add(alertMsg);
      await _dispatchAlertOnce(
        prefs: prefs,
        pondId: pondId,
        pondName: pondName,
        alertType: 'heavy_rain',
        title: '🌧️ Heavy Rain Warning',
        body: '$alertMsg expected rainfall up to ${maxRain.toStringAsFixed(1)}mm.',
      );
    }

    // Rule 2: Heat Wave Alert (> 32°C)
    if (maxTemp > 32.0) {
      const alertMsg = 'High temperatures expected — watch dissolved oxygen levels.';
      activeAlerts.add(alertMsg);
      await _dispatchAlertOnce(
        prefs: prefs,
        pondId: pondId,
        pondName: pondName,
        alertType: 'heat_wave',
        title: '🔥 Heat Warning',
        body: '$alertMsg temperatures expected up to ${maxTemp.toStringAsFixed(1)}°C.',
      );
    }

    // Rule 3: Extreme UV Index (>= 9)
    if (maxUv >= 9.0) {
      const alertMsg = 'Extreme UV index predicted — monitor transparency & algae bloom.';
      activeAlerts.add(alertMsg);
      await _dispatchAlertOnce(
        prefs: prefs,
        pondId: pondId,
        pondName: pondName,
        alertType: 'extreme_uv',
        title: '☀️ Extreme UV Warning',
        body: '$alertMsg UV index expected to reach ${maxUv.toStringAsFixed(1)}.',
      );
    }

    return activeAlerts;
  }

  Future<void> _dispatchAlertOnce({
    required SharedPreferences prefs,
    required String pondId,
    required String pondName,
    required String alertType,
    required String title,
    required String body,
  }) async {
    final key = 'weather_alert_sent_${pondId}_$alertType';
    final lastSentTimestamp = prefs.getInt(key) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Suppress notifications if already dispatched within past 24 hours
    if (now - lastSentTimestamp > 86400000) {
      await _ref.read(notificationServiceProvider).dispatchWeatherAlert(
            pondId: pondId,
            pondName: pondName,
            title: title,
            body: body,
          );
      await prefs.setInt(key, now);
    }
  }
}
