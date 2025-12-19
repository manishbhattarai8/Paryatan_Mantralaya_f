import 'package:flutter/material.dart';
import '../store/trip_store.dart';
import '../models/trip_model.dart';
import 'planning_screen.dart';
import 'ongoing_trip_screen.dart';
import 'past_trip_screen.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Trips")),

      body: ValueListenableBuilder<List<Trip>>(
        valueListenable: TripStore().tripsNotifier,
        builder: (context, trips, _) {
          final store = TripStore();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _tripSection(
                context,
                title: "Planned Trips",
                trips: store.plannedTrips,
                type: _TripType.planned,
              ),
              _tripSection(
                context,
                title: "Ongoing Trips",
                trips: store.ongoingTrips,
                type: _TripType.ongoing,
              ),
              _tripSection(
                context,
                title: "Past Trips",
                trips: store.pastTrips,
                type: _TripType.past,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tripSection(
    BuildContext context, {
    required String title,
    required List<Trip> trips,
    required _TripType type,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        if (trips.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              "No trips",
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          Column(
            children: trips.map((trip) {
            VoidCallback? onTap;

            if (type == _TripType.planned) {
              onTap = () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlanningScreen(
                      destination: trip.destination,
                    ),
                  ),
                );
              };
            } else if (type == _TripType.ongoing) {
              onTap = () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OngoingTripScreen(
                      destination: trip.destination,
                    ),
                  ),
                );
              };
            } else if (type == _TripType.past) {
              onTap = () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PastTripScreen(
                      destination: trip.destination,
                    ),
                  ),
                );
              };
            }

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.place),
                  title: Text(trip.destination),
                  onTap: onTap,
                  trailing: onTap != null
                      ? const Icon(Icons.arrow_forward_ios, size: 16)
                      : null,
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 24),
      ],
    );
  }
}

enum _TripType { planned, ongoing, past }
