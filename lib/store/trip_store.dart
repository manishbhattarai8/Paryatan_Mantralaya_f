import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_model.dart';

class TripStore {
  static final TripStore _instance = TripStore._internal();
  factory TripStore() => _instance;
  TripStore._internal();

  static const String _storageKey = "trips_storage";

  /// 🔔 Reactive trips list
  final ValueNotifier<List<Trip>> tripsNotifier =
      ValueNotifier<List<Trip>>([]);

  List<Trip> get trips => tripsNotifier.value;

  // 🔹 Load from storage
  Future<void> loadTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);

    if (data != null) {
      final List decoded = jsonDecode(data);
      tripsNotifier.value =
          decoded.map((e) => Trip.fromJson(e)).toList();
    }
  }

  // 🔹 Save to storage
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(tripsNotifier.value.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  // 🔹 Add planned trip
  Future<void> addPlannedTrip(String destination) async {
    tripsNotifier.value = [
      ...tripsNotifier.value,
      Trip(destination: destination, status: TripStatus.planned),
    ];
    await _save();
  }

  // 🔹 Cancel planned trip
  Future<void> cancelTrip(String destination) async {
    tripsNotifier.value = tripsNotifier.value
        .where((t) => t.destination != destination)
        .toList();
    await _save();
  }

  // 🔹 Planned → Ongoing
  Future<void> startTrip(String destination) async {
    tripsNotifier.value = tripsNotifier.value.map((trip) {
      if (trip.destination == destination &&
          trip.status == TripStatus.planned) {
        return Trip(
          destination: trip.destination,
          status: TripStatus.ongoing,
        );
      }
      return trip;
    }).toList();

    await _save();
  }

  // 🔹 Ongoing → Past  ✅ THIS FIXES YOUR ERROR
  Future<void> completeTrip(String destination) async {
    tripsNotifier.value = tripsNotifier.value.map((trip) {
      if (trip.destination == destination &&
          trip.status == TripStatus.ongoing) {
        return Trip(
          destination: trip.destination,
          status: TripStatus.past,
        );
      }
      return trip;
    }).toList();

    await _save();
  }

  // 🔹 Getters
  List<Trip> get plannedTrips =>
      trips.where((t) => t.status == TripStatus.planned).toList();

  List<Trip> get ongoingTrips =>
      trips.where((t) => t.status == TripStatus.ongoing).toList();

  List<Trip> get pastTrips =>
      trips.where((t) => t.status == TripStatus.past).toList();
}
