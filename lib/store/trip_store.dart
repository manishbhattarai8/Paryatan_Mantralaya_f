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

  final ValueNotifier<List<Trip>> tripsNotifier =
      ValueNotifier<List<Trip>>([]);

  List<Trip> get trips => tripsNotifier.value;

  // LOAD
  Future<void> loadTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null) {
      final List decoded = jsonDecode(data);
      tripsNotifier.value =
          decoded.map((e) => Trip.fromJson(e)).toList();
    }
  }

  // SAVE
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(tripsNotifier.value.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  // ADD PLANNED TRIP
  Future<String> addPlannedTrip({
    required Destination destination,
    required DateTime fromDate,
    required DateTime toDate,
    required List<Mood> moods,
    required double budget,
    List<Destination>? primaryAttractions,
    List<Destination>? accommodations,
    Map<int, List<Destination>>? dayWiseAttractions,
  }) async {
    final newTrip = Trip(
      destinations: [destination],
      primaryAttractions: primaryAttractions ?? [],
      accommodations: accommodations ?? [],
      dayWiseAttractions: dayWiseAttractions,
      status: TripStatus.planned,
      fromDate: fromDate,
      toDate: toDate,
      moods: moods,
      budget: budget,
    );

    tripsNotifier.value = [
      ...tripsNotifier.value,
      newTrip,
    ];
    
    await _save();
    
    return newTrip.id; // ✅ Return the trip ID
  }

  // ADD ATTRACTIONS TO SPECIFIC DAY
  Future<void> addAttractionsToDay({
    required String tripId,
    required int day,
    required List<Destination> attractions,
  }) async {
    tripsNotifier.value = tripsNotifier.value.map((trip) {
      if (trip.id == tripId) {
        final updatedDayWise = Map<int, List<Destination>>.from(trip.dayWiseAttractions);
        updatedDayWise[day] = [...(updatedDayWise[day] ?? []), ...attractions];
        
        return trip.copyWith(dayWiseAttractions: updatedDayWise);
      }
      return trip;
    }).toList();
    await _save();
  }

  // SET ATTRACTIONS FOR SPECIFIC DAY (REPLACE)
  Future<void> setAttractionsForDay({
    required String tripId,
    required int day,
    required List<Destination> attractions,
  }) async {
    tripsNotifier.value = tripsNotifier.value.map((trip) {
      if (trip.id == tripId) {
        final updatedDayWise = Map<int, List<Destination>>.from(trip.dayWiseAttractions);
        updatedDayWise[day] = attractions;
        
        return trip.copyWith(dayWiseAttractions: updatedDayWise);
      }
      return trip;
    }).toList();
    await _save();
  }

  // REMOVE ATTRACTION FROM SPECIFIC DAY
  Future<void> removeAttractionFromDay({
    required String tripId,
    required int day,
    required String attractionId,
  }) async {
    tripsNotifier.value = tripsNotifier.value.map((trip) {
      if (trip.id == tripId) {
        final updatedDayWise = Map<int, List<Destination>>.from(trip.dayWiseAttractions);
        if (updatedDayWise.containsKey(day)) {
          updatedDayWise[day] = updatedDayWise[day]!
              .where((d) => d.id != attractionId)
              .toList();
        }
        
        return trip.copyWith(dayWiseAttractions: updatedDayWise);
      }
      return trip;
    }).toList();
    await _save();
  }

  // CLEAR ALL ATTRACTIONS FOR SPECIFIC DAY
  Future<void> clearDayAttractions({
    required String tripId,
    required int day,
  }) async {
    tripsNotifier.value = tripsNotifier.value.map((trip) {
      if (trip.id == tripId) {
        final updatedDayWise = Map<int, List<Destination>>.from(trip.dayWiseAttractions);
        updatedDayWise.remove(day);
        
        return trip.copyWith(dayWiseAttractions: updatedDayWise);
      }
      return trip;
    }).toList();
    await _save();
  }

  // SET ENTIRE DAY-WISE ATTRACTIONS MAP
  Future<void> setDayWiseAttractions({
    required String tripId,
    required Map<int, List<Destination>> dayWiseAttractions,
  }) async {
    tripsNotifier.value = tripsNotifier.value.map((trip) {
      if (trip.id == tripId) {
        return trip.copyWith(dayWiseAttractions: dayWiseAttractions);
      }
      return trip;
    }).toList();
    await _save();
  }

  // ADD PRIMARY ATTRACTIONS TO TRIP
  Future<void> addPrimaryAttractions({
    required String tripId,
    required List<Destination> attractions,
  }) async {
    tripsNotifier.value = tripsNotifier.value.map((trip) {
      if (trip.id == tripId) {
        return trip.copyWith(
          primaryAttractions: [...trip.primaryAttractions, ...attractions],
        );
      }
      return trip;
    }).toList();
    await _save();
  }

  // ADD ACCOMMODATIONS TO TRIP
  Future<void> addAccommodations({
    required String tripId,
    required List<Destination> accommodations,
  }) async {
    tripsNotifier.value = tripsNotifier.value.map((trip) {
      if (trip.id == tripId) {
        return trip.copyWith(
          accommodations: [...trip.accommodations, ...accommodations],
        );
      }
      return trip;
    }).toList();
    await _save();
  }

  // SET PRIMARY ATTRACTIONS (REPLACE)
  Future<void> setPrimaryAttractions({
    required String tripId,
    required List<Destination> attractions,
  }) async {
    tripsNotifier.value = tripsNotifier.value.map((trip) {
      if (trip.id == tripId) {
        return trip.copyWith(primaryAttractions: attractions);
      }
      return trip;
    }).toList();
    await _save();
  }

  // SET ACCOMMODATIONS (REPLACE)
  Future<void> setAccommodations({
    required String tripId,
    required List<Destination> accommodations,
  }) async {
    tripsNotifier.value = tripsNotifier.value.map((trip) {
      if (trip.id == tripId) {
        return trip.copyWith(accommodations: accommodations);
      }
      return trip;
    }).toList();
    await _save();
  }

  // REMOVE PRIMARY ATTRACTION FROM TRIP
  Future<void> removePrimaryAttraction({
    required String tripId,
    required String attractionId,
  }) async {
    tripsNotifier.value = tripsNotifier.value.map((trip) {
      if (trip.id == tripId) {
        return trip.copyWith(
          primaryAttractions: trip.primaryAttractions
              .where((d) => d.id != attractionId)
              .toList(),
        );
      }
      return trip;
    }).toList();
    await _save();
  }

  // REMOVE ACCOMMODATION FROM TRIP
  Future<void> removeAccommodation({
    required String tripId,
    required String accommodationId,
  }) async {
    tripsNotifier.value = tripsNotifier.value.map((trip) {
      if (trip.id == tripId) {
        return trip.copyWith(
          accommodations: trip.accommodations
              .where((d) => d.id != accommodationId)
              .toList(),
        );
      }
      return trip;
    }).toList();
    await _save();
  }

  // START TRIP
  Future<void> startTrip(String tripId) async {
    tripsNotifier.value = tripsNotifier.value.map((trip) {
      if (trip.id == tripId && trip.status == TripStatus.planned) {
        return trip.copyWith(status: TripStatus.ongoing);
      }
      return trip;
    }).toList();
    await _save();
  }

  // COMPLETE TRIP
  Future<void> completeTrip(String tripId) async {
    tripsNotifier.value = tripsNotifier.value.map((trip) {
      if (trip.id == tripId && trip.status == TripStatus.ongoing) {
        return trip.copyWith(status: TripStatus.past);
      }
      return trip;
    }).toList();
    await _save();
  }

  // CANCEL
  Future<void> cancelTrip(String tripId) async {
    tripsNotifier.value =
        tripsNotifier.value.where((t) => t.id != tripId).toList();
    await _save();
  }

  // GET TRIP BY ID
  Trip? getTripById(String tripId) {
    try {
      return trips.firstWhere((t) => t.id == tripId);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateTripBudget(String tripId, double newBudget) async {
    try {
      // Find the trip in the list
      final tripIndex = trips.indexWhere((trip) => trip.id == tripId);
      
      if (tripIndex == -1) {
        throw Exception('Trip not found');
      }
      
      // Create updated trip with new budget
      final updatedTrip = Trip(
        id: trips[tripIndex].id,
        destinations: trips[tripIndex].destinations,
        primaryAttractions: trips[tripIndex].primaryAttractions,
        accommodations: trips[tripIndex].accommodations,
        dayWiseAttractions: trips[tripIndex].dayWiseAttractions,
        status: trips[tripIndex].status,
        fromDate: trips[tripIndex].fromDate,
        toDate: trips[tripIndex].toDate,
        budget: newBudget, // Updated budget
        moods: trips[tripIndex].moods,
      );
      
      // Replace the trip in the list
      trips[tripIndex] = updatedTrip;
      
      // Save to persistent storage
      await _save();
    } catch (e) {
      print('Error updating trip budget: $e');
      rethrow;
    }
  }

  List<Trip> get plannedTrips =>
      trips.where((t) => t.status == TripStatus.planned).toList();

  List<Trip> get ongoingTrips =>
      trips.where((t) => t.status == TripStatus.ongoing).toList();

  List<Trip> get pastTrips =>
      trips.where((t) => t.status == TripStatus.past).toList();
}
