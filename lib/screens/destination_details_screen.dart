import 'package:flutter/material.dart';
import 'plan_trip_screen.dart';
import '../store/favourite_store.dart';

class DestinationDetailsScreen extends StatelessWidget {
  final String title;

  const DestinationDetailsScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isFavourite = FavouriteStore().isFavourite(title);

    return Scaffold(
      body: Column(
        children: [
          _topSection(context),
          Expanded(child: _detailsSection(context, isFavourite)),
        ],
      ),
    );
  }

  Widget _topSection(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 280,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.blue.shade300,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          // child: Image.network(des),
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
          bottom: 20,
          left: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                "Kaski District, Gandaki",
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailsSection(BuildContext context, bool isFavourite) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoBoxes(),
          const SizedBox(height: 20),
          const Text(
            "Description",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Ghandruk is a village development committee in the Kaski "
            "District of the Gandaki Province of Nepal.",
            style: TextStyle(color: Colors.grey),
          ),
          const Spacer(),
          _bottomButtons(context, isFavourite),
        ],
      ),
    );
  }

  Widget _infoBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        _InfoBox(title: "Distance", value: "166 km"),
        _InfoBox(title: "Time", value: "11 hr"),
        _InfoBox(title: "Price", value: "\$485"),
      ],
    );
  }

  Widget _bottomButtons(BuildContext context, bool isFavourite) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              if (!isFavourite) {
                await FavouriteStore().addFavourite(title);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("$title added to favourites")),
                );
              }
            },
            icon: Icon(
              isFavourite ? Icons.favorite : Icons.favorite_border,
              color: isFavourite ? Colors.red : null,
            ),
            label: const Text("Favourite"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlanTripScreen(destination: title),
                ),
              );
            },
            icon: const Icon(Icons.navigation),
            label: const Text("Plan Trip"),
          ),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String title;
  final String value;

  const _InfoBox({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
