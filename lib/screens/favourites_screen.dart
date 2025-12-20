import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../store/favourite_store.dart';
import '../models/favourite_model.dart';
import '../models/destination_model.dart';
import '../services/destination_service.dart';
import 'destination_details_screen.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  final DestinationService _service = DestinationService();
  List<Destination> allDestinations = [];

  @override
  void initState() {
    super.initState();
    _loadDestinations();
  }

  Future<void> _loadDestinations() async {
    final data = await _service.fetchDestinations();
    setState(() => allDestinations = data);
  }

  Destination? _findDestination(String name) {
    try {
      return allDestinations.firstWhere(
        (d) => d.name == name,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Favourites")),
      body: ValueListenableBuilder<List<Favourite>>(
        valueListenable: FavouriteStore().favouritesNotifier,
        builder: (context, favourites, _) {
          if (favourites.isEmpty) {
            return const Center(
              child: Text(
                "No favourites yet",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: favourites.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final fav = favourites[index];
              final destination = _findDestination(fav.destination);

              if (destination == null) {
                return const SizedBox.shrink();
              }

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DestinationDetailsScreen(destination: destination),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      // 🖼 IMAGE
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: destination.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          memCacheWidth: 120,
                          placeholder: (_, __) =>
                              Container(color: Colors.green.shade200),
                          errorWidget: (_, __, ___) =>
                              Container(color: Colors.green.shade200),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // 📍 TEXT
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              destination.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              destination.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
