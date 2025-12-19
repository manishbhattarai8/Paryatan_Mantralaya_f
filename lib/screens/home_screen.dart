import 'package:flutter/material.dart';
import 'destination_details_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 20),
            _categories(),
            const SizedBox(height: 20),
            _featuredBoxes(context),
            const SizedBox(height: 30),
            _sectionTitle("Top Destinations"),
            const SizedBox(height: 12),
            _topDestinationBoxes(),
          ],
        ),
      ),
    );
  }

  // 🔹 Discover Header
  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text(
          "Discover",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        Icon(Icons.search, size: 26),
      ],
    );
  }

  // 🔹 Categories
  Widget _categories() {
    final categories = ["Mountain", "Jungle", "Water", "Beach"];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          return Text(
            categories[index],
            style: TextStyle(
              fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
              color: index == 0 ? Colors.black : Colors.grey,
            ),
          );
        },
      ),
    );
  }

  // 🔹 Featured Placeholder Boxes
  Widget _featuredBoxes(BuildContext context) {
    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 2,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DestinationDetailsScreen(
                    title: index == 0 ? "Ghandruk" : "Destination B",
                  ),
                ),
              );
            },
            child: Container(
              width: 200,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    index == 0 ? "Ghandruk" : "Destination B",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  // 🔹 Section Title
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // 🔹 Top Destination Boxes
  Widget _topDestinationBoxes() {
    return Row(
      children: [
        _smallBox("Place 1"),
        const SizedBox(width: 12),
        _smallBox("Place 2"),
      ],
    );
  }

  Widget _smallBox(String title) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.green.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
      ),
    );
  }
}
