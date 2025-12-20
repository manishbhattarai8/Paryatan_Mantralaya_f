import 'package:flutter/material.dart';
import 'package:paryatan_mantralaya_f/models/destination_model.dart';
import 'package:paryatan_mantralaya_f/services/recommendation_service.dart';
import 'package:paryatan_mantralaya_f/screens/ongoing_trip_screen.dart';
import 'package:paryatan_mantralaya_f/store/trip_store.dart';
import '../services/routing_service.dart';
import '../services/location_service.dart';
import 'route_map_screen.dart';

class PlanningScreen extends StatefulWidget {
  final String destination;
  final String tripId;

  const PlanningScreen({
    super.key,
    required this.destination,
  });
  
  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> with SingleTickerProviderStateMixin {
  final RecommendationService recService = RecommendationService();
  
  List<Destination> allPrimary = [];
  List<Destination> allAccommodations = [];
  List<Destination> selectedAccommodations = [];
  Map<int, List<Destination>> dayWiseAttractions = {};
  
  int recommendedPrimary = 0;
  int recommendedAccommodations = 0;
  String? error;
  bool isLoading = false;
  
  late TabController _tabController;
  final DateTime fromDate = DateTime(2025, 1, 15);
  final DateTime toDate = DateTime(2025, 1, 20);
  final List<Mood> moods = [Mood.cultural];
  final double budget = 15000.0;
  
  int get tripDays => toDate.difference(fromDate).inDays + 1;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tripDays, vsync: this);
    _loadRecommendations();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadRecommendations() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    
    try {
      final RecommendationResult result = await recService.generateRecommendations(
        location: widget.destination,
        fromDate: fromDate,
        toDate: toDate,
        moods: moods,
        budget: budget,
      );
      
      allPrimary = result.primary;
      allAccommodations = result.accommodations;
      recommendedPrimary = result.recommendedPrimary;
      recommendedAccommodations = result.recommendedAccommodations;
      
      // Get top 3 accommodations
      selectedAccommodations = allAccommodations
          .take(recommendedAccommodations.clamp(0, 3))
          .toList();
      
      // Distribute places into days
      final recommendedPrimaryList = allPrimary.take(recommendedPrimary).toList();
      final distributedAttractions = await recService.distributePlacesIntoDays(
        primaryAttractions: recommendedPrimaryList,
        fromDate: fromDate,
        toDate: toDate,
      );
      
      // Limit each day to maximum 3 attractions
      dayWiseAttractions = {};
      for (var day = 1; day <= tripDays; day++) {
        final attractions = distributedAttractions[day] ?? [];
        dayWiseAttractions[day] = attractions.take(3).toList();
      }
      
      setState(() {
        isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }
  
  void _removeAccommodation(Destination accommodation) {
    setState(() {
      selectedAccommodations.remove(accommodation);
    });
  }
  
  void _showAddAccommodationDialog() {
    final availableAccommodations = allAccommodations
        .where((acc) => !selectedAccommodations.contains(acc))
        .toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Accommodation'),
        content: SizedBox(
          width: double.maxFinite,
          child: availableAccommodations.isEmpty
              ? const Text('No more accommodations available')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableAccommodations.length,
                  itemBuilder: (context, index) {
                    final acc = availableAccommodations[index];
                    return ListTile(
                      title: Text(acc.name ?? 'Unknown'),
                      subtitle: Text('NPR ${acc.avg_price.toStringAsFixed(2)}'),
                      trailing: Text('⭐ ${acc.rating}'),
                      onTap: () {
                        setState(() {
                          selectedAccommodations.add(acc);
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _removeAttractionFromDay(int day, Destination attraction) {
    setState(() {
      dayWiseAttractions[day]?.remove(attraction);
    });
  }
  
  void _showAddAttractionDialog(int day) {
    final alreadyAdded = dayWiseAttractions.values
        .expand((list) => list)
        .toSet();
    
    final availableAttractions = allPrimary
        .take(recommendedPrimary)
        .where((attr) => !alreadyAdded.contains(attr))
        .toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Attraction to Day $day'),
        content: SizedBox(
          width: double.maxFinite,
          child: availableAttractions.isEmpty
              ? const Text('No more attractions available')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableAttractions.length,
                  itemBuilder: (context, index) {
                    final attr = availableAttractions[index];
                    return ListTile(
                      title: Text(attr.name ?? 'Unknown'),
                      subtitle: Text(attr.category.toString().split('.').last),
                      trailing: Text('⭐ ${attr.rating}'),
                      onTap: () {
                        setState(() {
                          dayWiseAttractions[day]?.add(attr);
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Planning: ${widget.destination}'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: $error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadRecommendations,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Accommodations Section
                    _buildAccommodationsSection(),
                    
                    // Day-wise Tabs
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: Colors.teal,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.teal,
                      tabs: List.generate(
                        tripDays,
                        (index) => Tab(text: 'Day ${index + 1}'),
                      ),
                    ),
                    
                    // Day-wise Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: List.generate(
                          tripDays,
                          (index) => _buildDayContent(index + 1),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
  
  Widget _buildAccommodationsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.teal.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Accommodations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _showAddAccommodationDialog,
                icon: const Icon(Icons.add_circle, color: Colors.teal),
                tooltip: 'Add Accommodation',
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: selectedAccommodations.isEmpty
                ? const Center(child: Text('No accommodations selected'))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedAccommodations.length,
                    itemBuilder: (context, index) {
                      final acc = selectedAccommodations[index];
                      return Card(
                        margin: const EdgeInsets.only(right: 12),
                        child: Container(
                          width: 200,
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      acc.name ?? 'Unknown',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () => _removeAccommodation(acc),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 14, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text('${acc.rating}'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'NPR ${acc.avg_price.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDayContent(int day) {
    final attractions = dayWiseAttractions[day] ?? [];
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attractions for Day $day',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${attractions.length} attractions',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _showAddAttractionDialog(day),
                icon: const Icon(Icons.add_circle, color: Colors.teal),
                tooltip: 'Add Attraction',
              ),
            ],
          ),
        ),
        Expanded(
          child: attractions.isEmpty
              ? const Center(
                  child: Text(
                    'No attractions for this day',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: attractions.length,
                  itemBuilder: (context, index) {
                    final attraction = attractions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Text(
                            attraction.name?.substring(0, 1).toUpperCase() ?? '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          attraction.name ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category: ${attraction.category.toString().split('.').last}',
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 14, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text('${attraction.rating}'),
                                const SizedBox(width: 12),
                                Text('NPR ${attraction.avg_price.toStringAsFixed(2)}'),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeAttractionFromDay(day, attraction),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
