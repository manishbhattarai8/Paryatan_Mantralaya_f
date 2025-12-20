import 'package:flutter/material.dart';
import '../models/destination_model.dart';
import '../services/destination_service.dart';
import 'destination_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DestinationService _service = DestinationService();
  final TextEditingController _searchController = TextEditingController();
  List<Destination> destinations = [];
  List<Destination> filteredDestinations = [];
  bool isLoading = true;
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadDestinations();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      if (_searchController.text.isEmpty) {
        filteredDestinations = destinations;
      } else {
        final query = _searchController.text.toLowerCase();
        
        // Separate matches by priority with scoring
        final exactTitleMatches = <Destination>[];
        final startsWithMatches = <Destination>[];
        final titleContainsMatches = <Destination>[];
        final otherMatches = <Destination>[];
        
        for (var dest in destinations) {
          final nameLower = dest.name.toLowerCase();
          
          if (nameLower == query) {
            // Exact match has highest priority
            exactTitleMatches.add(dest);
          } else if (nameLower.startsWith(query)) {
            // Starts with query has second priority
            startsWithMatches.add(dest);
          } else if (nameLower.contains(query)) {
            // Contains in title has third priority
            titleContainsMatches.add(dest);
          } else if (dest.description.toLowerCase().contains(query) ||
              dest.category.toLowerCase().contains(query)) {
            // Description/category matches last
            otherMatches.add(dest);
          }
        }
        
        // Combine in priority order
        filteredDestinations = [
          ...exactTitleMatches,
          ...startsWithMatches,
          ...titleContainsMatches,
          ...otherMatches
        ];
      }
    });
  }

  Future<void> _loadDestinations() async {
    try {
      final data = await _service.fetchDestinations();

      // 🔎 DEBUG (remove later)
      debugPrint("DESTINATIONS LOADED: ${data.length}");
      for (var d in data) {
        debugPrint("${d.name} → ${d.description}");
      }

      setState(() {
        destinations = data;
        filteredDestinations = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("ERROR FETCHING DESTINATIONS: $e");
      setState(() => isLoading = false);
    }
  }

  void _toggleSearch() {
    setState(() {
      isSearching = !isSearching;
      if (!isSearching) {
        _searchController.clear();
        filteredDestinations = destinations;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            if (isSearching) ...[
              const SizedBox(height: 16),
              _searchBar(),
            ],
            const SizedBox(height: 20),
            if (!isSearching) ...[
              _categories(),
              const SizedBox(height: 20),
              _featuredBoxes(context),
              const SizedBox(height: 30),
            ],
            _sectionTitle(isSearching ? "Search Results" : "Top Destinations"),
            const SizedBox(height: 12),
            _topDestinationBoxes(context),
          ],
        ),
      ),
    );
  }

  // 🔹 Header
  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Discover",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: Icon(isSearching ? Icons.close : Icons.search, size: 26),
          onPressed: _toggleSearch,
        ),
      ],
    );
  }

  // 🔹 Search Bar
  Widget _searchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: "Search destinations...",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // 🔹 Categories (static for now)
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

  // 🔹 Featured (Top 2 destinations)
  Widget _featuredBoxes(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final featured = destinations.take(2).toList();

    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: featured.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final dest = featured[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DestinationDetailsScreen(
                    title: dest.name,
                  ),
                ),
              );
            },
            child: SizedBox(
              width: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // background image or fallback color
                    if (dest.imageUrl.isNotEmpty)
                      Image.network(
                        dest.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(color: Colors.green.shade100),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(color: Colors.green.shade100);
                        },
                      )
                    else
                      Container(color: Colors.green.shade100),

                    // subtle overlay for legibility
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withOpacity(0.35), Colors.transparent],
                        ),
                      ),
                    ),

                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          dest.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 🔹 Section title
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // 🔹 Top destinations list (NAME + DESCRIPTION FIXED)
  Widget _topDestinationBoxes(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // ❌ Categories to exclude
    final excludedCategories = [
      'restaurant',
      'food',
      'accomodations',
    ];

    // ✅ Use filtered destinations when searching, otherwise use all
    final destinationsToShow = isSearching ? filteredDestinations : destinations;

    // ✅ Filter + sort
    final topDestinations = destinationsToShow
        .where((dest) =>
            !excludedCategories.contains(dest.category.toLowerCase()))
        .toList();

    if (!isSearching) {
      topDestinations.sort((a, b) => b.rating.compareTo(a.rating));
    }

    if (topDestinations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            isSearching
                ? "No destinations found matching '${_searchController.text}'"
                : "No destinations available",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final displayCount = isSearching ? topDestinations.length : 5;

    return Column(
      children: topDestinations.take(displayCount).map((dest) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DestinationDetailsScreen(
                  title: dest.name,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                  clipBehavior: Clip.hardEdge,
                  
                  decoration: BoxDecoration(
                    color: Colors.red.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.network(dest.imageUrl, fit: BoxFit.cover,),
                ),
                const SizedBox(width: 12),

                // 📌 Name + description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dest.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dest.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                Text("⭐ ${dest.rating}"),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
