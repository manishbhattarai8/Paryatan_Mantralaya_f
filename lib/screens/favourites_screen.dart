import 'package:flutter/material.dart';
import '../store/favourite_store.dart';
import '../models/favourite_model.dart';
import 'destination_details_screen.dart';

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favourites.length,
            itemBuilder: (context, index) {
              final fav = favourites[index];

              return Card(
                child: ListTile(
                  leading:
                      const Icon(Icons.favorite, color: Colors.red),
                  title: Text(fav.destination),

                  // ✅ TAP TO OPEN DETAILS
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DestinationDetailsScreen(
                          title: fav.destination,
                        ),
                      ),
                    );
                  },

                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      FavouriteStore()
                          .removeFavourite(fav.destination);
                    },
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
