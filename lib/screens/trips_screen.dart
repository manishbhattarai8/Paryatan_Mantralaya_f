import 'package:flutter/material.dart';
import '../store/trip_store.dart';
import '../models/trip_model.dart';
import 'planning_screen.dart';
import 'ongoing_trip_screen.dart';
import 'past_trip_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  static const Map<String, String> locationImages = {
    "Kathmandu":
        "https://admin.ntb.gov.np/image-cache/KDS_oy_lt_(1)-1631095017.jpg?p=main&s=3b13becca2e45fb61e28d3207a8aefff",
    "Bhaktapur":
        "https://tourguideinnepal.com/wp-content/uploads/2019/11/nagarkot-bhaktapur-day-tour.jpg",
    "Lalitpur, Patan":
        "https://happymountainnepal.com/wp-content/uploads/2025/07/image_processing20181221-4-k261ph.jpg",
    "Pokhara":
        "https://www.andbeyond.com/wp-content/uploads/sites/5/pokhara-valley-nepal.jpg",
  };

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
                type: TripStatus.planned,
              ),
              _tripSection(
                context,
                title: "Ongoing Trips",
                trips: store.ongoingTrips,
                type: TripStatus.ongoing,
              ),
              _tripSection(
                context,
                title: "Past Trips",
                trips: store.pastTrips,
                type: TripStatus.past,
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
    required TripStatus type,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        if (trips.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: Text("No trips",
                style: TextStyle(color: Colors.grey)),
          )
        else
          Column(
            children: trips.map((trip) {
              VoidCallback? onTap;

              if (type == TripStatus.planned) {
                onTap = () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlanningScreen(
                        tripId: trip.id,
                        destination: trip.destination,
                        fromDate: trip.fromDate!,
                        toDate: trip.toDate!,
                        moods: trip.moods!,
                        budget: trip.budget!,
                      ),
                    ),
                  );
                };
              } else if (type == TripStatus.ongoing) {
                onTap = () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          OngoingTripScreen(tripId: trip.id),
                    ),
                  );
                };
              } else {
                onTap = () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PastTripScreen(destination: trip.destination),
                    ),
                  );
                };
              }

              return GestureDetector(
                onTap: onTap,
                child: Container(
                  height: 140,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl:
                              locationImages[trip.destination] ?? "",
                          fit: BoxFit.cover,
                        ),
                        Container(color: Colors.black.withOpacity(0.45)),
                        Center(
                          child: Text(
                            trip.destination,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 28),
      ],
    );
  }
}
