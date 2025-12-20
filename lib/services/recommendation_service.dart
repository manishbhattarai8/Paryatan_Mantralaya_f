import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paryatan_mantralaya_f/config.dart';
import 'package:paryatan_mantralaya_f/services/api_service.dart';
import 'package:paryatan_mantralaya_f/services/weather_service.dart';
import 'package:paryatan_mantralaya_f/models/destination_model.dart';
import 'dart:math';

class RecommendationResult {
  final List<Destination> primary;
  final int recommendedPrimary;
  final List<Destination> accommodations;
  final int recommendedAccommodations;

  RecommendationResult({
    required this.primary,
    required this.recommendedPrimary,
    required this.accommodations,
    required this.recommendedAccommodations,
  });
}

class RecommendationService {
  final WeatherService weatherService = WeatherService();
  final ApiService apiService = ApiService();

  double haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;

    final phi1 = _toRadians(lat1);
    final phi2 = _toRadians(lat2);
    final dphi = _toRadians(lat2 - lat1);
    final dlambda = _toRadians(lon2 - lon1);

    final a = pow(sin(dphi / 2), 2) +
        cos(phi1) * cos(phi2) * pow(sin(dlambda / 2), 2);

    return 2 * R * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  bool isWithinRadius(
    double lat1,
    double lon1,
    Destination destination,
    double radiusKm,
  ) {
    final lat2 = destination.latitude;
    final lon2 = destination.longitude;
    
    if (lat2 == 0.0 || lon2 == 0.0) return false;
    
    final distance = haversine(lat1, lon1, lat2, lon2);
    return distance <= radiusKm;
  }

  // Filter attractions within a certain radius of primary attractions
  List<MapEntry<double, Destination>> filterWithinRadius(
    List<MapEntry<double, Destination>> primaryAttractions,
    List<MapEntry<double, Destination>> otherAttractions,
    double radiusKm,
  ) {
    final filtered = <MapEntry<double, Destination>>[];

    for (final entry in otherAttractions) {
      final place = entry.value;
      final lat = place.latitude;
      final lon = place.longitude;

      if (lat == null || lon == null) continue;

      for (final primaryEntry in primaryAttractions) {
        final primary = primaryEntry.value;
        final primaryLat = primary.latitude;
        final primaryLon = primary.longitude;

        if (primaryLat == null || primaryLon == null) continue;

        final distance = haversine(lat, lon, primaryLat, primaryLon);

        if (distance <= radiusKm) {
          filtered.add(entry);
          break; // No need to check other primaries
        }
      }
    }

    return filtered;
  }

  Future<RecommendationResult> generateRecommendations({
    required String location,
    required DateTime fromDate,
    required DateTime toDate,
    required List<Mood> moods,
    required double budget,
  }) async {
    final placesData = await apiService.getPlacesFromLocation(location);
    final tripDays = toDate.difference(fromDate).inDays + 1;
    List<MapEntry<double, Destination>> primaryAttractions = [];
    List<MapEntry<double, Destination>> accommodations = [];
    
    // Collecting primary attractions based on moods
    for (final place in placesData) {
      double score = 0;
      for (final mood in moods) {
        // Check if place category matches mood categories
        List<Category>? cats = MOOD_TO_CATEGORY[mood];
        if (cats == null || !cats.contains(place.category)) {
          continue;
        }
        
        if (place.compatable_moods != null) {
          for (final compatibleMood in place.compatable_moods!) {
            if (mood == compatibleMood) {
              score += 1;
            }
          }
        }
      }
      if (score > 0) {
        primaryAttractions.add(MapEntry(score, place));
      }
    }
    
    // Collecting accommodations
    for (final place in placesData) {
      final categoryStr = place.category?.toString().split('.').last.toLowerCase() ?? '';
      if (categoryStr != Category.accomodations.value) {
        continue;
      }
      double score = 0;
      if (place.compatable_moods != null) {
        for (final mood in moods) {
          for (final compatibleMood in place.compatable_moods!) {
            if (mood == compatibleMood) {
              score += 1;
            }
          }
        }
      }
      if (score > 0) {
        accommodations.add(MapEntry(score, place));
      }
    }
    
    // Sort by score + rating
    primaryAttractions.sort((a, b) {
      final scoreA = a.key + (a.value.rating ?? 0.0);
      final scoreB = b.key + (b.value.rating ?? 0.0);
      return scoreB.compareTo(scoreA); // Descending order
    });
    
    accommodations.sort((a, b) {
      final scoreA = a.key + (a.value.rating ?? 0.0);
      final scoreB = b.key + (b.value.rating ?? 0.0);
      return scoreB.compareTo(scoreA); // Descending order
    });
    
    // Filter accommodations within budget (no accommodation needed for 1-day trip)
    List<Destination> accommodationDestinations = [];
    if (tripDays > 1) {
      accommodationDestinations = accommodations
          .where((entry) => (entry.value.avg_price ?? 0.0) <= budget)
          .map((e) => e.value)
          .toList();
    }
    
    // Filter primary attractions within budget
    final primaryDestinations = primaryAttractions
        .where((entry) => (entry.value.avg_price ?? 0.0) <= budget)
        .map((e) => e.value)
        .toList();
    
    return RecommendationResult(
      primary: primaryDestinations,
      recommendedPrimary: primaryDestinations.length,
      accommodations: accommodationDestinations,
      recommendedAccommodations: accommodationDestinations.length,
    );
  }

  // Give me attractions and ill spread it into trip days ;3
  Future<Map<int, List<Destination>>> distributePlacesIntoDays({
    required List<Destination> primaryAttractions,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final tripDays = toDate.difference(fromDate).inDays + 1;

    // Prepare empty days
    final Map<int, List<Destination>> tripPlacesPerDay = {};
    for (int i = 0; i < tripDays; i++) {
      tripPlacesPerDay[i + 1] = [];
    }

    // Filter using season and weather
    final List<Season> seasonInTrip = [];
    final List<Weather> weatherInTrip = [];

    DateTime current = fromDate;
    while (current.isBefore(toDate.add(const Duration(days: 1)))) {
      final dateStr = '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';

      // Get each day season
      seasonInTrip.add(weatherService.getSeason(dateStr));

      // Get weather for each day using first primary attraction's coordinates
      if (primaryAttractions.isNotEmpty) {
        final place = primaryAttractions[0];
        final weather = await weatherService.getWeatherForDate(
          latitude: place.latitude,
          longitude: place.longitude,
          dateStr: dateStr,
        );
        weatherInTrip.add(weather);
      } else {
        weatherInTrip.add(Weather.sunny); // Default weather if no attractions
      }

      current = current.add(const Duration(days: 1));
    }

    // Append primary attractions
    int day = 0;
    int placeStep = 0;
    int placeCnt = 0;

    while (placeCnt < primaryAttractions.length) {
      placeStep++;
      final place = primaryAttractions[placeCnt];

      if (place.suitable_season.contains(seasonInTrip[day])) {
        if (place.suitable_weather.contains(weatherInTrip[day])) {
          tripPlacesPerDay[day + 1]!.add(place);
          placeCnt++;
          placeStep = 0;
        }
      }

      day++;
      if (placeStep >= tripDays) {
        placeCnt++;
      }
      if (day >= tripDays) {
        day = 0;
      }
    }

    return tripPlacesPerDay;
  }

  Future<List<Destination>> recommendRestaurants({
    required String location,
    required double latitude,
    required double longitude,
    required List<Mood> moods,
    required double budget,
  }) async {
    final placesData = await apiService.getPlacesFromLocation(location);
    List<MapEntry<double, Destination>> restaurants = [];

    for (final place in placesData) {
      if (place.category != Category.restaurant) {
        continue;
      }

      // Radius check
      if (!isWithinRadius(latitude, longitude, place, 2)) {
        continue;
      }

      double score = 0;
      for (final mood in moods) {
        List<Category>? cats = MOOD_TO_CATEGORY[mood];
        if (cats == null || !cats.contains(place.category)) {
          continue;
        }
        if (place.compatable_moods != null) {
          for (final compatibleMood in place.compatable_moods!) {
            if (mood == compatibleMood) {
              score += 1;
            }
          }
        }
      }

      if (score > 0 && place.avg_price <= budget) {
        restaurants.add(MapEntry(score, place));
      }
    }

    restaurants.sort((a, b) {
      final scoreA = a.key + (a.value.rating ?? 0.0);
      final scoreB = b.key + (b.value.rating ?? 0.0);
      return scoreB.compareTo(scoreA); // Descending order
    });

    final finalRestaurants = restaurants
        .map((e) => e.value)
        .toList();

    return finalRestaurants;
  }
}
