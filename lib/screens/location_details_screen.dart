import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../models/destination_model.dart';
import 'plan_trip_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LocationDetailsScreen extends StatelessWidget {
  final LocationItem location;
  final String description;

  const LocationDetailsScreen({
    super.key,
    required this.location,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _topSection(context),
          Expanded(child: _detailsSection(context)),
        ],
      ),
    );
  }

  // 🔹 TOP IMAGE SECTION
  Widget _topSection(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.green.shade300,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: CachedNetworkImage(
            imageUrl: location.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                Container(color: Colors.green.shade200),
            errorWidget: (context, url, error) =>
                Container(color: Colors.green.shade200),
          ),
        ),

        Positioned(
          top: 40,
          left: 16,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),

        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: Text(
            location.name,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // 🔹 DETAILS + ACTION
  Widget _detailsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "About this location",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          Text(
            description,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: GestureDetector(
              onTap: () => _goToPlanTrip(context),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1E1E1E),
                      Color(0xFF3A3A3A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.travel_explore, color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Text(
                      "Plan Trip",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 NAVIGATION (FIXED & SAFE)
  void _goToPlanTrip(BuildContext context) {
    /// ✅ Create a MINIMAL Destination from LocationItem
    final destination = Destination(
      id: '', // no id available
      name: location.name,
      description: description,
      location: location.name,
      category: Category.other,
      avg_price: 0,
      rating: 0,
      open_hours: '',
      latitude: 0,
      longitude: 0,
      suitable_season: const [],
      suitable_weather: const [],
      compatable_moods: const [],
      imageUrl: location.imageUrl,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlanTripScreen(
          destination: destination,
        ),
      ),
    );
  }
}
