import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paryatan_mantralaya_f/models/destination_model.dart';

class WeatherService {
  // Get season based on date
  Season getSeason(String dateStr) {
    final date = DateTime.parse(dateStr);
    final month = date.month;

    if (month >= 3 && month <= 5) {
      return Season.spring;
    } else if (month >= 6 && month <= 8) {
      return Season.summer;
    } else if (month >= 9 && month <= 11) {
      return Season.autumn;
    } else {
      return Season.winter;
    }
  }

  // Get weather for a specific date
  Future<Weather> getWeatherForDate({
    required double latitude,
    required double longitude,
    required String dateStr,
    String timezone = "Asia/Kathmandu",
  }) async {
    final queryDate = DateTime.parse(dateStr);
    final today = DateTime.now();

    // Choose correct endpoint
    String baseUrl;
    if (queryDate.isBefore(today) || 
        queryDate.year == today.year && 
        queryDate.month == today.month && 
        queryDate.day == today.day) {
      baseUrl = "https://archive-api.open-meteo.com/v1/archive";
    } else {
      baseUrl = "https://api.open-meteo.com/v1/forecast";
    }

    // Build URL with query parameters
    final uri = Uri.parse(baseUrl).replace(queryParameters: {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'start_date': dateStr,
      'end_date': dateStr,
      'daily': 'precipitation_sum,cloudcover_mean',
      'timezone': timezone,
    });

    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch weather data: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final daily = data['daily'] as Map<String, dynamic>?;

      if (daily == null) {
        throw Exception('No daily weather data returned: $data');
      }

      final precipitation = (daily['precipitation_sum'] as List)[0] as num;
      final cloudcover = (daily['cloudcover_mean'] as List)[0] as num;

      // Determine weather based on precipitation and cloud cover
      if (precipitation > 0) {
        return Weather.rainy;
      } else if (cloudcover > 60) {
        return Weather.cloudy;
      } else {
        return Weather.sunny;
      }
    } catch (e) {
      throw Exception('Error fetching weather: $e');
    }
  }

  // Get weather for multiple dates
  Future<List<Weather>> getWeatherForDateRange({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
    String timezone = "Asia/Kathmandu",
  }) async {
    final weatherList = <Weather>[];
    
    for (var date = startDate; 
         date.isBefore(endDate.add(const Duration(days: 1))); 
         date = date.add(const Duration(days: 1))) {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final weather = await getWeatherForDate(
        latitude: latitude,
        longitude: longitude,
        dateStr: dateStr,
        timezone: timezone,
      );
      weatherList.add(weather);
    }
    
    return weatherList;
  }
}
