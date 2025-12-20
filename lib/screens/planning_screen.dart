import 'package:flutter/material.dart';
import 'package:paryatan_mantralaya_f/screens/ongoing_trip_screen.dart';
import 'package:paryatan_mantralaya_f/store/trip_store.dart';
import '../services/routing_service.dart';
import '../services/location_service.dart';
import 'route_map_screen.dart';

class PlanningScreen extends StatelessWidget {
  final String destination;

  const PlanningScreen({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trip Planning")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              destination,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const Spacer(),

            ElevatedButton.icon(
              icon: const Icon(Icons.my_location),
              label: const Text("Route from my location"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () async {
                try {
                  // 1️⃣ Get current GPS location
                  final position = await LocationService.getCurrentLocation();

                  // 2️⃣ Fetch route from backend
                  final route = await RouteService.fetchRoute(
                    profile: "car",
                    startLat: position.latitude,
                    startLon: position.longitude,
                    endLat: 27.6736, // Destination
                    endLon: 85.3250,
                  );

                  if (!context.mounted) return;

                  // 3️⃣ Show route on map
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RouteMapScreen(coordinates: route),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Route error: $e")));
                }
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.flag),
              label: const Text("Start the Trip"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () async {
                try {
                  // 1️⃣ Get current GPS location
                  final position = await LocationService.getCurrentLocation();

                  // // 2️⃣ Fetch route from backend
                  // final route = await RouteService.fetchRoute(
                  //   profile: "car",
                  //   startLat: position.latitude,
                  //   startLon: position.longitude,
                  //   endLat: 27.6736, // Destination
                  //   endLon: 85.3250,
                  // );
                  await TripStore().addOngoingTrip(destination);

                  if (!context.mounted) return;

                  // 3️⃣ Show route on map
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          OngoingTripScreen(destination: destination),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Route error: $e")));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
