import 'package:flutter/material.dart';
import '../models/destination_model.dart';
import '../store/favourite_store.dart';

class DestinationDetailsScreen extends StatefulWidget {
  final Destination destination;

  const DestinationDetailsScreen({
    super.key,
    required this.destination,
  });

  @override
  State<DestinationDetailsScreen> createState() =>
      _DestinationDetailsScreenState();
}

class _DestinationDetailsScreenState
    extends State<DestinationDetailsScreen> {
  late bool isFavourite;

  @override
  void initState() {
    super.initState();
    isFavourite =
        FavouriteStore().isFavourite(widget.destination.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _topSection(context),
          Expanded(child: _detailsSection()),
        ],
      ),
    );
  }

  // 🔝 TOP IMAGE SECTION
  Widget _topSection(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 280,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.green.shade300,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: widget.destination.imageUrl.isNotEmpty
              ? Image.network(
                  widget.destination.imageUrl,
                  fit: BoxFit.cover,
                )
              : null,
        ),

        // ⬅ BACK BUTTON
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

        // ❤️ FAVOURITE BUTTON (BOTTOM RIGHT ON IMAGE)
        Positioned(
          bottom: 20,
          right: 16,
          child: GestureDetector(
            onTap: _toggleFavourite,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                isFavourite
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: isFavourite ? Colors.red : Colors.grey,
                size: 26,
              ),
            ),
          ),
        ),

        // 📍 TITLE & LOCATION
        Positioned(
          bottom: 20,
          left: 16,
          right: 70, // space for heart icon
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.destination.name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                widget.destination.location,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 📄 DETAILS SECTION
  Widget _detailsSection() {
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
          Text(
            widget.destination.description,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ℹ️ INFO BOXES
  Widget _infoBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _InfoBox(
          title: "Location",
          value: widget.destination.location,
        ),
        _InfoBox(
          title: "Rating",
          value: "⭐ ${widget.destination.rating}",
        ),
        _InfoBox(
          title: "Category",
          value: widget.destination.category.value,
        ),
      ],
    );
  }

  // 🔄 TOGGLE FAVOURITE
  Future<void> _toggleFavourite() async {
    if (isFavourite) {
      await FavouriteStore()
          .removeFavourite(widget.destination.name);
    } else {
      await FavouriteStore()
          .addFavourite(widget.destination.name);
    }

    setState(() {
      isFavourite = !isFavourite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavourite
              ? "${widget.destination.name} added to favourites"
              : "${widget.destination.name} removed from favourites",
        ),
      ),
    );
  }
}

// 🔲 INFO BOX WIDGET
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
      width: 110,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
