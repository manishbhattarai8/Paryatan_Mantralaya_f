import 'destination_model.dart';

enum TripStatus { planned, ongoing, past }

class Trip {
  final String id;
  final List<Destination> destinations;
  final List<Destination> primaryAttractions;
  final List<Destination> accommodations;
  final Map<int, List<Destination>> dayWiseAttractions;
  final TripStatus status;
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<Mood>? moods;
  final double? budget;

  Trip({
    String? id,
    required this.destinations,
    this.primaryAttractions = const [],
    this.accommodations = const [],
    Map<int, List<Destination>>? dayWiseAttractions,
    this.status = TripStatus.planned,
    this.fromDate,
    this.toDate,
    this.moods,
    this.budget,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        dayWiseAttractions = dayWiseAttractions ?? {};

  /// ✅ BACKWARD COMPATIBILITY (VERY IMPORTANT)
  String get destination =>
      destinations.isNotEmpty ? destinations.first.name : '';

  /// Get total number of days in the trip
  int get tripDays {
    if (fromDate != null && toDate != null) {
      return toDate!.difference(fromDate!).inDays + 1;
    }
    return 0;
  }

  // ---------------- SERIALIZATION ----------------
  Map<String, dynamic> toJson() {
    // Convert Map<int, List<Destination>> to Map<String, dynamic>
    Map<String, dynamic> serializedDayWise = {};
    dayWiseAttractions.forEach((day, destinations) {
      serializedDayWise[day.toString()] =
          destinations.map((d) => d.toJson()).toList();
    });

    return {
      'id': id,
      'destinations': destinations.map((d) => d.toJson()).toList(),
      'primaryAttractions': primaryAttractions.map((d) => d.toJson()).toList(),
      'accommodations': accommodations.map((d) => d.toJson()).toList(),
      'dayWiseAttractions': serializedDayWise,
      'status': status.index,
      'fromDate': fromDate?.toIso8601String(),
      'toDate': toDate?.toIso8601String(),
      'moods': moods?.map((m) => m.index).toList(),
      'budget': budget,
    };
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    List<Destination> parsedDestinations = [];
    if (json['destinations'] is List) {
      parsedDestinations = (json['destinations'] as List)
          .map((e) => Destination.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else if (json['destination'] != null) {
      final name = json['destination'].toString();
      parsedDestinations = [
        Destination(
          id: '',
          name: name,
          description: '',
          location: name,
          category: Category.other,
          avg_price: 0,
          rating: 0,
          open_hours: '',
          latitude: 0,
          longitude: 0,
          suitable_season: const [],
          suitable_weather: const [],
          compatable_moods: const [],
        ),
      ];
    }

    List<Destination> parsedPrimaryAttractions = [];
    if (json['primaryAttractions'] is List) {
      parsedPrimaryAttractions = (json['primaryAttractions'] as List)
          .map((e) => Destination.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    List<Destination> parsedAccommodations = [];
    if (json['accommodations'] is List) {
      parsedAccommodations = (json['accommodations'] as List)
          .map((e) => Destination.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    // Parse dayWiseAttractions
    Map<int, List<Destination>> parsedDayWise = {};
    if (json['dayWiseAttractions'] is Map) {
      final dayWiseJson = json['dayWiseAttractions'] as Map;
      dayWiseJson.forEach((key, value) {
        final day = int.parse(key.toString());
        if (value is List) {
          parsedDayWise[day] = (value)
              .map((e) => Destination.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      });
    }

    return Trip(
      id: json['id'],
      destinations: parsedDestinations,
      primaryAttractions: parsedPrimaryAttractions,
      accommodations: parsedAccommodations,
      dayWiseAttractions: parsedDayWise,
      status: TripStatus.values[json['status'] ?? 0],
      fromDate:
          json['fromDate'] != null ? DateTime.parse(json['fromDate']) : null,
      toDate:
          json['toDate'] != null ? DateTime.parse(json['toDate']) : null,
      moods: json['moods'] != null
          ? (json['moods'] as List).map((i) => Mood.values[i]).toList()
          : null,
      budget: json['budget']?.toDouble(),
    );
  }

  /// Create a copy of the trip with updated fields
  Trip copyWith({
    String? id,
    List<Destination>? destinations,
    List<Destination>? primaryAttractions,
    List<Destination>? accommodations,
    Map<int, List<Destination>>? dayWiseAttractions,
    TripStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    List<Mood>? moods,
    double? budget,
  }) {
    return Trip(
      id: id ?? this.id,
      destinations: destinations ?? this.destinations,
      primaryAttractions: primaryAttractions ?? this.primaryAttractions,
      accommodations: accommodations ?? this.accommodations,
      dayWiseAttractions: dayWiseAttractions ?? this.dayWiseAttractions,
      status: status ?? this.status,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      moods: moods ?? this.moods,
      budget: budget ?? this.budget,
    );
  }
}
