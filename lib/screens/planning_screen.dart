import 'package:flutter/material.dart';
import '../store/trip_store.dart';

class PlanningScreen extends StatelessWidget {
  final String destination;

  const PlanningScreen({
    super.key,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trip Planning"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              destination,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            _infoCard("Status", "Planned"),
            _infoCard("Dates", "Not set"),
            _infoCard("Trip Type", "Not specified"),
            _infoCard("Transport", "Not specified"),
            _infoCard("Budget", "Not specified"),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      // ❌ Cancel trip
                      await TripStore().cancelTrip(destination);
                      Navigator.pop(context);
                    },
                    child: const Text("Cancel Trip"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // ▶ Start trip
                      await TripStore().startTrip(destination);
                      Navigator.pop(context);
                    },
                    child: const Text("Start Trip"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
