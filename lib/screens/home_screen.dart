import 'package:flutter/material.dart';
import '../models/destination_model.dart';
import '../models/location_model.dart';
import '../services/destination_service.dart';
import 'destination_details_screen.dart';
import 'location_details_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final DestinationService _service = DestinationService();
  final TextEditingController _searchController = TextEditingController();

  List<Destination> destinations = [];
  List<Destination> filteredDestinations = [];

  bool isLoading = true;
  bool isSearching = false;
  String? selectedLocation;

  @override
  bool get wantKeepAlive => true;

  // 📍 LOCATIONS
  final List<LocationItem> locations = const [
    LocationItem(
      name: "Kathmandu",
      imageUrl:
          "https://admin.ntb.gov.np/image-cache/KDS_oy_lt_(1)-1631095017.jpg?p=main&s=3b13becca2e45fb61e28d3207a8aefff",
    ),
    LocationItem(
      name: "Bhaktapur",
      imageUrl:
          "https://tourguideinnepal.com/wp-content/uploads/2019/11/nagarkot-bhaktapur-day-tour.jpg",
    ),
    LocationItem(
      name: "Lalitpur, Patan",
      imageUrl:
          "https://happymountainnepal.com/wp-content/uploads/2025/07/image_processing20181221-4-k261ph.jpg",
    ),
    LocationItem(
      name: "Pokhara",
      imageUrl:
          "https://www.andbeyond.com/wp-content/uploads/sites/5/pokhara-valley-nepal.jpg",
    ),
  ];

  // 📝 LOCATION DESCRIPTIONS
  final Map<String, String> locationDescriptions = const {
    "Kathmandu": "Capital city rich in temples, culture & history",
    "Bhaktapur": "Ancient city famous for heritage & architecture",
    "Lalitpur, Patan": "Artistic city with monasteries & craftsmanship",
    "Pokhara": "Lakeside city with mountains & adventure",
  };

  @override
  void initState() {
    super.initState();
    _loadDestinations();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredDestinations = destinations.where((dest) {
        return dest.name.toLowerCase().contains(query) ||
            dest.description.toLowerCase().contains(query) ||
            dest.category.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _loadDestinations() async {
    try {
      final data = await _service.fetchDestinations();

      // 🔥 PRE-CACHE DESTINATION IMAGES
      for (final d in data) {
        if (d.imageUrl.isNotEmpty) {
          precacheImage(
            CachedNetworkImageProvider(d.imageUrl),
            context,
          );
        }
      }

      // 🔥 PRE-CACHE LOCATION IMAGES
      for (final loc in locations) {
        precacheImage(
          CachedNetworkImageProvider(loc.imageUrl),
          context,
        );
      }

      setState(() {
        destinations = data;
        filteredDestinations = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("ERROR: $e");
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
    super.build(context);

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
              _locationSection(),
              const SizedBox(height: 28),
            ],
            _sectionTitle("Top Destinations"),
            const SizedBox(height: 12),
            _topDestinationBoxes(context),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Discover",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: Icon(isSearching ? Icons.close : Icons.search),
          onPressed: _toggleSearch,
        ),
      ],
    );
  }

  Widget _searchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: "Search destinations...",
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _locationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Explore by Location"),
        const SizedBox(height: 14),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: locations.length,
            separatorBuilder: (_, __) => const SizedBox(width: 18),
            itemBuilder: (context, index) {
              final location = locations[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LocationDetailsScreen(
                        location: location,
                        description:
                            locationDescriptions[location.name] ?? "",
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: location.imageUrl,
                          fit: BoxFit.cover,
                          memCacheWidth: 400,
                          placeholder: (_, __) =>
                              Container(color: Colors.green.shade200),
                          errorWidget: (_, __, ___) =>
                              Container(color: Colors.green.shade200),
                        ),
                        Container(color: Colors.black.withOpacity(0.4)),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                location.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                locationDescriptions[location.name] ?? "",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _topDestinationBoxes(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final excludedCategories = ['restaurant', 'food', 'accomodations'];

    final filtered = (isSearching ? filteredDestinations : destinations)
        .where((d) => !excludedCategories.contains(d.category.toLowerCase()))
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    return Column(
      children: filtered.take(5).map((dest) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DestinationDetailsScreen(destination: dest),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: dest.imageUrl,
                    width: 50,
                    height: 50,
                    memCacheWidth: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dest.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
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
                Text("⭐ ${dest.rating}"),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
