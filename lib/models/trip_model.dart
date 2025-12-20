import 'destination_model.dart';

enum TripStatus { planned, ongoing, past }

class Trip {
  /// A unique identifier for this trip. Introduced to allow stable
  /// references to trips across app sessions.
  final String id;

  /// A trip may contain one or more destinations. Kept as a list to
  /// support multi-stop trips in the future.
  final List<Destination> destinations;
  final TripStatus status;

  Trip({
    String? id,
    required this.destinations,
    this.status = TripStatus.planned,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  /// Backwards-compatible convenience getter used by the UI which still
  /// expects a single `destination` string in many places.
  String get destination =>
      destinations.isNotEmpty ? destinations.first.name : '';

 

  factory Trip.fromJson(Map<String, dynamic> json) {
    // Accept the new `destinations` schema (list of objects) or
    // fall back to the legacy `destination` string for older saved data.
    List<Destination> parsedDestinations = [];
    final String parsedId = json['id']?.toString() ??
        DateTime.now().microsecondsSinceEpoch.toString();

    if (json['destinations'] != null && json['destinations'] is List) {
      parsedDestinations = (json['destinations'] as List)
          .map((e) => Destination.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else if (json['destination'] != null) {
      // legacy single destination string -> create a minimal Destination
      final name = json['destination']?.toString() ?? '';
      parsedDestinations = [
        Destination(
          id: '',
          name: name,
          description: '',
          location: name,
          category: '',
          rating: 0.0,
          suitableSeason: const [],
          suitableWeather: const [],
          compatableMoods: const [],
        )
      ];
    }

    return Trip(
      id: parsedId,
      destinations: parsedDestinations,
      status: TripStatus.values[json['status']],
    );
  }

  /// Utility: true if this trip contains a destination matching [name].
  bool containsDestinationByName(String name) {
    return destinations.any((d) => d.name == name);
  }

  /// Utility: true if this trip contains a destination matching [id].
  /// This supports the updated schema where destinations are identified by ids.
  bool containsDestinationById(String id) {
    return destinations.any((d) => d.id == id);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'destinations': destinations.map((d) => d.toJson()).toList(),
      'status': status.index,
    };
  }
}
