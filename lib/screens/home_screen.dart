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

  final List<String> topLocations = const [
    "Kathmandu",
    "Bhaktapur",
    "Lalitpur",
    "Pokhara",
  ];

  List<Destination> destinations = [];
  List<Destination> filteredDestinations = [];

  bool isLoading = true;
  bool isSearching = false;

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
      name: "Lalitpur",
      imageUrl:
          "https://happymountainnepal.com/wp-content/uploads/2025/07/image_processing20181221-4-k261ph.jpg",
    ),
    LocationItem(
      name: "Pokhara",
      imageUrl:
          "https://www.andbeyond.com/wp-content/uploads/sites/5/pokhara-valley-nepal.jpg",
    ),
  ];

  final Map<String, String> locationDescriptions = const {
    "Kathmandu": "Capital city rich in temples, culture & history",
    "Bhaktapur": "Ancient city famous for heritage & architecture",
    "Lalitpur": "Artistic city with monasteries & craftsmanship",
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
            dest.category.toString().split('.').last.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _loadDestinations() async {
    try {
      final data = await _service.fetchDestinations();

      for (final d in data) {
        if (d.imageUrl.isNotEmpty) {
          precacheImage(CachedNetworkImageProvider(d.imageUrl), context);
        }
      }

      for (final loc in locations) {
        precacheImage(CachedNetworkImageProvider(loc.imageUrl), context);
      }

      setState(() {
        destinations = data;
        filteredDestinations = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("ERROR: $e");
      // setState(() => isLoading = false);
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
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  /// ⭐ FINAL TOP DESTINATION DESIGN
  Widget _topDestinationBoxes(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final excludedCategories = [
      'restaurant',
      'food',
      'accomodations',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: topLocations.map((location) {
        final locationDestinations = destinations
            .where((d) =>
                d.location.toLowerCase() == location.toLowerCase() &&
                !excludedCategories
                    .contains(d.category.value))
            .toList()
          ..sort((a, b) => b.rating.compareTo(a.rating));

        if (locationDestinations.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                location,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: locationDestinations.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final dest = locationDestinations[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DestinationDetailsScreen(
                            destination: dest,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 270,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius:
                                const BorderRadius.horizontal(
                              left: Radius.circular(22),
                            ),
                            child: Stack(
                              children: [
                                CachedNetworkImage(
                                  imageUrl: dest.imageUrl,
                                  width: 90,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  width: 90,
                                  height: double.infinity,
                                  color:
                                      Colors.black.withOpacity(0.25),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(right: 12),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dest.name,
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dest.location,
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }
}
