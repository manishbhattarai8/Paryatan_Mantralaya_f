import 'package:flutter/material.dart';
import '../models/destination_model.dart';
import '../services/recommendation_service.dart';
import 'package:paryatan_mantralaya_f/store/trip_store.dart';
import '../models/trip_model.dart';

class PlanningScreen extends StatefulWidget {
  final String tripId; // Pass trip ID to identify which trip to update
  final String destination;
  final DateTime fromDate;
  final DateTime toDate;
  final List<Mood> moods;
  final double budget;

  const PlanningScreen({
    super.key,
    required this.tripId,
    required this.destination,
    required this.fromDate,
    required this.toDate,
    required this.moods,
    required this.budget,
  });

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen>
    with SingleTickerProviderStateMixin {
  final RecommendationService recService = RecommendationService();
  final TripStore tripStore = TripStore();

  List<Destination> allPrimary = [];
  List<Destination> allAccommodations = [];
  List<Destination> selectedAccommodations = [];
  Map<int, List<Destination>> dayWiseAttractions = {};

  int recommendedPrimary = 0;
  int recommendedAccommodations = 0;

  bool isLoading = false;
  bool isSaving = false;
  String? error;

  late TabController _tabController;

  int get tripDays =>
      widget.toDate.difference(widget.fromDate).inDays + 1;

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

  // 🔹 LOAD DATA
  Future<void> _loadRecommendations() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await recService.generateRecommendations(
        location: widget.destination,
        fromDate: widget.fromDate,
        toDate: widget.toDate,
        moods: widget.moods,
        budget: widget.budget,
      );

      allPrimary = result.primary;
      allAccommodations = result.accommodations;
      recommendedPrimary = result.recommendedPrimary;
      recommendedAccommodations = result.recommendedAccommodations;

      selectedAccommodations =
          allAccommodations.take(recommendedAccommodations.clamp(0, 3)).toList();

      final distributed = await recService.distributePlacesIntoDays(
        primaryAttractions: allPrimary.take(recommendedPrimary).toList(),
        fromDate: widget.fromDate,
        toDate: widget.toDate,
      );

      dayWiseAttractions = {};
      for (int i = 1; i <= tripDays; i++) {
        dayWiseAttractions[i] =
            (distributed[i] ?? []).take(3).toList();
      }

      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  // 🔹 START TRIP - Save and change status to ongoing
  Future<void> _startTrip() async {
    setState(() => isSaving = true);

    try {
      // Save accommodations
      await tripStore.setAccommodations(
        tripId: widget.tripId,
        accommodations: selectedAccommodations,
      );

      // Save day-wise attractions
      await tripStore.setDayWiseAttractions(
        tripId: widget.tripId,
        dayWiseAttractions: dayWiseAttractions,
      );

      // Collect all primary attractions from day-wise map
      final allDayAttractions = dayWiseAttractions.values
          .expand((list) => list)
          .toSet()
          .toList();

      // Save primary attractions
      await tripStore.setPrimaryAttractions(
        tripId: widget.tripId,
        attractions: allDayAttractions,
      );

      // Change trip status from planned to ongoing
      await tripStore.startTrip(widget.tripId);

      setState(() => isSaving = false);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip started successfully! Have a great journey!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back to home after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() => isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting trip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🔹 COMMON UI
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 🔹 ACCOMMODATIONS
  void _removeAccommodation(Destination acc) {
    setState(() => selectedAccommodations.remove(acc));
  }

  void _addAccommodationDialog() {
    final available = allAccommodations
        .where((a) => !selectedAccommodations.contains(a))
        .toList();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Accommodation'),
        content: SizedBox(
          width: double.maxFinite,
          child: available.isEmpty
              ? const Text('No more accommodations available')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: available.length,
                  itemBuilder: (_, i) {
                    final acc = available[i];
                    return ListTile(
                      title: Text(acc.name ?? 'Unknown'),
                      subtitle:
                          Text('NPR ${acc.avg_price.toStringAsFixed(0)}'),
                      trailing: Text('⭐ ${acc.rating}'),
                      onTap: () {
                        setState(() => selectedAccommodations.add(acc));
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildAccommodationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle("Accommodations"),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.teal),
              onPressed: _addAccommodationDialog,
            ),
          ],
        ),
        SizedBox(
          height: 150,
          child: selectedAccommodations.isEmpty
              ? const Center(child: Text("No accommodations selected"))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedAccommodations.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (_, i) {
                    final acc = selectedAccommodations[i];
                    return Container(
                      width: 220,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    acc.name ?? "Unknown",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon:
                                      const Icon(Icons.close, size: 18),
                                  onPressed: () =>
                                      _removeAccommodation(acc),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text("⭐ ${acc.rating}",
                                style:
                                    const TextStyle(fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              "NPR ${acc.avg_price.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // 🔹 ATTRACTIONS
  void _removeAttraction(int day, Destination d) {
    setState(() => dayWiseAttractions[day]?.remove(d));
  }

  void _addAttractionDialog(int day) {
    final alreadyAdded =
        dayWiseAttractions.values.expand((e) => e).toSet();

    final available = allPrimary
        .take(recommendedPrimary)
        .where((a) => !alreadyAdded.contains(a))
        .toList();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Attraction (Day $day)'),
        content: SizedBox(
          width: double.maxFinite,
          child: available.isEmpty
              ? const Text('No attractions left')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: available.length,
                  itemBuilder: (_, i) {
                    final a = available[i];
                    return ListTile(
                      title: Text(a.name ?? 'Unknown'),
                      trailing: Text('⭐ ${a.rating}'),
                      onTap: () {
                        setState(() => dayWiseAttractions[day]?.add(a));
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildDay(int day) {
    final attractions = dayWiseAttractions[day] ?? [];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Attractions",
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => _addAttractionDialog(day),
                icon:
                    const Icon(Icons.add_circle, color: Colors.teal),
              ),
            ],
          ),
        ),
        Expanded(
          child: attractions.isEmpty
              ? const Center(child: Text("No attractions"))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: attractions.length,
                  itemBuilder: (_, i) {
                    final a = attractions[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8),
                        title: Text(
                          a.name ?? "Unknown",
                          style: const TextStyle(
                              fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          "⭐ ${a.rating}  •  NPR ${a.avg_price.toStringAsFixed(0)}",
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red),
                          onPressed: () =>
                              _removeAttraction(day, a),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // 🔹 MAIN BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.destination,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (!isLoading && error == null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: isSaving ? null : _startTrip,
                icon: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                        ),
                      )
                    : const Icon(Icons.flight_takeoff, color: Colors.teal),
                label: Text(
                  isSaving ? 'Starting...' : 'Start Trip',
                  style: const TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : Column(
                  children: [
                    _buildAccommodationSection(),
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: Colors.teal,
                      labelColor: Colors.teal,
                      unselectedLabelColor: Colors.black54,
                      tabs: List.generate(
                        tripDays,
                        (i) => Tab(text: "Day ${i + 1}"),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: List.generate(
                          tripDays,
                          (i) => _buildDay(i + 1),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
