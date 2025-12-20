import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_model.dart';
import '../models/destination_model.dart';

class TripStore {
  static final TripStore _instance = TripStore._internal();
  factory TripStore() => _instance;
  TripStore._internal();

  static const String _storageKey = "trips_storage";

  /// 🔔 Reactive trips list
  final ValueNotifier<List<Trip>> tripsNotifier = ValueNotifier<List<Trip>>([]);

  List<Trip> get trips => tripsNotifier.value;

  // 🔹 Load from storage
  Future<void> loadTrips() async {
    
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    // await prefs.remove(_storageKey);

    if (data != null) {
      final List decoded = jsonDecode(data);
      tripsNotifier.value = decoded.map((e) => Trip.fromJson(e)).toList();
     
    }
  }

  // 🔹 Save to storage
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      tripsNotifier.value.map((t) => t.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }

  // 🔹 Add planned trip (keeps public API but stores a Destination list)
  Future<void> addPlannedTrip(String destination) async {
    final dest = Destination(
      id: '',
      name: destination,
      description: '',
      location: destination,
      category: '',
      rating: 0.0,
      suitableSeason: const [],
      suitableWeather: const [],
      compatableMoods: const [],
    );

    tripsNotifier.value = [
      ...tripsNotifier.value,
      Trip(destinations: [dest], status: TripStatus.planned),
    ];
    await _save();
  }

  Future<void> addOngoingTrip(String destination) async {
    // Prefer id-based checks when the provided string matches any known
    // destination id in existing trips; otherwise fall back to name-based
    // behaviour for backwards compatibility.
    final isId = tripsNotifier.value.any((t) => t.containsDestinationById(destination));

    // Remove any trip that already contains this destination (by id or name)
    final filtered = tripsNotifier.value.where((t) {
      return isId ? !t.containsDestinationById(destination) : !t.containsDestinationByName(destination);
    }).toList();

    final dest = Destination(
      id: isId ? destination : '',
      name: isId ? '' : destination,
      description: '',
      location: isId ? '' : destination,
      category: '',
      rating: 0.0,
      suitableSeason: const [],
      suitableWeather: const [],
      compatableMoods: const [],
    );

    // Add the new ongoing trip
    tripsNotifier.value = [
      ...filtered,
      Trip(destinations: [dest], status: TripStatus.ongoing),
    ];

    await _save();
  }

  // 🔹 Cancel planned trip
  Future<void> cancelTrip(String destination) async {
    final isId = tripsNotifier.value.any((t) => t.containsDestinationById(destination));
    tripsNotifier.value = tripsNotifier.value.where((t) {
      return isId ? !t.containsDestinationById(destination) : !t.containsDestinationByName(destination);
    }).toList();
    await _save();
  }

  // 🔹 Planned → Ongoing (by trip id)
  Future<void> startTrip(String tripId) async {
    tripsNotifier.value = tripsNotifier.value.map((trip) {
      if (trip.id == tripId && trip.status == TripStatus.planned) {
        return Trip(id: trip.id, destinations: trip.destinations, status: TripStatus.ongoing);
      }
      return trip;
    }).toList();

    await _save();
  }

  // 🔹 Ongoing → Past  ✅ THIS FIXES YOUR ERROR
  // 🔹 Ongoing → Past (by trip id)
  Future<void> completeTrip(String tripId) async {
    tripsNotifier.value = tripsNotifier.value.map((trip) {
      if (trip.id == tripId && trip.status == TripStatus.ongoing) {
        return Trip(id: trip.id, destinations: trip.destinations, status: TripStatus.past);
      }
      return trip;
    }).toList();

    await _save();
  }

  // Future<void> addOngoing(String destination) async {
  //   tripsNotifier.value = tripsNotifier.value.map((trip) {
  //     if (trip.destination == destination &&
  //         trip.status == TripStatus.planned) {
  //       return Trip(destination: trip.destination, status: TripStatus.ongoing);
  //     }
  //     return trip;
  //   }).toList();

  //   await _save();
  // }

  // 🔹 Getters
  List<Trip> get plannedTrips =>
      trips.where((t) => t.status == TripStatus.planned).toList();

  List<Trip> get ongoingTrips =>
      trips.where((t) => t.status == TripStatus.ongoing).toList();

  List<Trip> get pastTrips =>
      trips.where((t) => t.status == TripStatus.past).toList();
}
