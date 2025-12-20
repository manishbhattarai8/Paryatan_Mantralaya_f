import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:paryatan_mantralaya_f/models/destination_model.dart';
import 'package:paryatan_mantralaya_f/models/trip_model.dart';

import 'package:paryatan_mantralaya_f/services/routing_service.dart';
import 'package:paryatan_mantralaya_f/services/location_service.dart';
import 'package:paryatan_mantralaya_f/services/recommendation_service.dart';
import '../store/trip_store.dart';

class OngoingTripScreen extends StatefulWidget {
  final String tripId;

  const OngoingTripScreen({
    super.key,
    required this.tripId,
  });

  @override
  State<OngoingTripScreen> createState() => _OngoingTripScreenState();
}

class _OngoingTripScreenState extends State<OngoingTripScreen> {
  List<List<double>>? _route;
  String? _error;
  bool _loading = true;
  Timer? _positionTimer;
  bool _updatingPosition = false;
  late int selectedDay;
  late List<int> availableDays;
  Destination? _directionDestination;
  double _distanceToDestination = 0.0;
  LatLng? _currentLocation;
  Trip? _trip;
  final MapController _mapController = MapController();
  final MapController _directionMapController = MapController();

  String selectedCategory = 'Attractions';
  bool isDirectionMode = false;
  
  // Restaurant-specific state
  List<Destination> _recommendedRestaurants = [];
  bool _loadingRestaurants = false;

  @override
  void initState() {
    super.initState();
    _loadTripData();
    _loadRoute();
    
    // Periodically update the user's position
    _positionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _periodicUpdate();
    });
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    super.dispose();
  }

  void _loadTripData() {
    _trip = TripStore().getTripById(widget.tripId);
    
    if (_trip != null) {
      // Initialize available days from dayWiseAttractions
      availableDays = _trip!.dayWiseAttractions.keys.toList()..sort();
      selectedDay = availableDays.isNotEmpty ? availableDays.first : 1;
    }
  }

  Future<void> _loadRoute() async {
    setState(() {
      _loading = true;
      _error = null;
      _route = null;
    });

    try {
      final position = await LocationService.getCurrentLocation();
      
      _currentLocation = LatLng(position.latitude, position.longitude);

      if (_trip == null) {
        throw Exception('Trip not found');
      }

      double endLat = 27.6736;
      double endLon = 85.3250;

      if (_trip!.destinations.isNotEmpty) {
        final dest = _trip!.destinations.first;
        if (dest.latitude != 0.0 || dest.longitude != 0.0) {
          endLat = dest.latitude;
          endLon = dest.longitude;
        }
      }

      final coords = await RouteService.fetchRoute(
        profile: 'car',
        startLat: position.latitude,
        startLon: position.longitude,
        endLat: endLat,
        endLon: endLon,
      );

      if (!mounted) return;

      setState(() {
        _route = coords;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadRestaurants() async {
    if (_currentLocation == null) return;
    
    setState(() {
      _loadingRestaurants = true;
      _recommendedRestaurants = [];
    });

    try {
      // Get location name from trip or use a default
      String locationName = 'Current Location';
      if (_trip != null && _trip!.destinations.isNotEmpty) {
        locationName = _trip!.destinations.first.location;
      }

      // Use trip moods if available, otherwise use default moods
      List<Mood> moods = _trip?.moods ?? [Mood.food];
      
      // Use trip budget if available, otherwise use a reasonable default
      double budget = _trip?.budget ?? 50.0;

      final restaurants = await RecommendationService().recommendRestaurants(
        location: locationName,
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        moods: moods,
        budget: budget,
      );

      if (!mounted) return;

      setState(() {
        _recommendedRestaurants = restaurants;
        _loadingRestaurants = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingRestaurants = false;
        _error = 'Failed to load restaurants: ${e.toString()}';
      });
    }
  }

  Future<void> _periodicUpdate() async {
    if (_updatingPosition) return;
    _updatingPosition = true;
    try {
      final position = await LocationService.getCurrentLocation();
      
      _currentLocation = LatLng(position.latitude, position.longitude);

      if (isDirectionMode && _directionDestination != null) {
        final coords = await RouteService.fetchRoute(
          profile: 'car',
          startLat: position.latitude,
          startLon: position.longitude,
          endLat: _directionDestination!.latitude,
          endLon: _directionDestination!.longitude,
        );
        
        if (!mounted) return;

        setState(() {
          _route = coords;
          _distanceToDestination = _calculateDistance(
            position.latitude,
            position.longitude,
            _directionDestination!.latitude,
            _directionDestination!.longitude,
          );
        });
      } else {
        if (!mounted) return;
        setState(() {});
      }
    } catch (e) {
      // Swallow errors for periodic updates
    } finally {
      _updatingPosition = false;
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000; // meters
    final dLat = _toRadian(lat2 - lat1);
    final dLon = _toRadian(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadian(lat1)) * cos(_toRadian(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadian(double degree) {
    return degree * pi / 180;
  }

  Future<void> _showDirectionToDestination(Destination destination) async {
    setState(() {
      _loading = true;
      _directionDestination = destination;
      isDirectionMode = true;
    });

    try {
      final position = await LocationService.getCurrentLocation();
      _currentLocation = LatLng(position.latitude, position.longitude);

      final coords = await RouteService.fetchRoute(
        profile: 'car',
        startLat: position.latitude,
        startLon: position.longitude,
        endLat: destination.latitude,
        endLon: destination.longitude,
      );

      if (!mounted) return;

      setState(() {
        _route = coords;
        _distanceToDestination = _calculateDistance(
          position.latitude,
          position.longitude,
          destination.latitude,
          destination.longitude,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  void _exitDirectionMode() {
    setState(() {
      _directionDestination = null;
      isDirectionMode = false;
      _route = null;
    });
  }

  void _showExpenseDialog(Destination destination) {
    final TextEditingController expenseController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(Icons.attach_money, color: Colors.teal),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Add Expense',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              destination.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            if (_trip != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Remaining Budget:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '\${_trip!.budget.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: expenseController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount Spent',
                prefixIcon: const Icon(Icons.money, color: Colors.teal),
                prefixText: '\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.teal, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amountStr = expenseController.text.trim();
              if (amountStr.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter an amount'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final amount = double.tryParse(amountStr);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (_trip != null) {
                // Deduct from budget
                await TripStore().updateTripBudget(widget.tripId, _trip!.budget! - amount);
                
                // Reload trip data
                _loadTripData();
                
                if (!mounted) return;
                
                Navigator.pop(context);
                
                setState(() {});
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Expense of \${amount.toStringAsFixed(2)} added'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Add Expense'),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkerPopup(Destination destination) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            destination.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  destination.location,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.star, size: 16, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                '${destination.rating}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showDirectionToDestination(destination);
                  },
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text('Directions'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showExpenseDialog(destination);
                  },
                  icon: const Icon(Icons.attach_money, size: 18),
                  label: const Text('Expense'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final screenHeight = MediaQuery.of(context).size.height;
    final mapHeight = screenHeight - 340; // Account for AppBar, padding, and bottom button
    final anotherMapHeight = screenHeight - 380;

    if (_loading) {
      return Container(
        height: mapHeight,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    if (_currentLocation == null) {
      return Container(
        height: mapHeight,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text('Unable to get current location'),
        ),
      );
    }

    if (_trip == null) {
      return Container(
        height: mapHeight,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: Text('Trip not found')),
      );
    }

    // Get markers based on selected category
    List<Marker> markers = [];

    if (selectedCategory == 'Accommodations') {
      for (var acc in _trip!.accommodations) {
        if (acc.latitude != 0.0 && acc.longitude != 0.0) {
          markers.add(
            Marker(
              point: LatLng(acc.latitude, acc.longitude),
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: _buildMarkerPopup(acc),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.hotel,
                    color: Colors.purple,
                    size: 28,
                  ),
                ),
              ),
            ),
          );
        }
      }
    } else if (selectedCategory == 'Restaurants') {
      // Show recommended restaurants
      for (var restaurant in _recommendedRestaurants) {
        if (restaurant.latitude != 0.0 && restaurant.longitude != 0.0) {
          markers.add(
            Marker(
              point: LatLng(restaurant.latitude, restaurant.longitude),
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: _buildMarkerPopup(restaurant),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: Colors.orange,
                    size: 28,
                  ),
                ),
              ),
            ),
          );
        }
      }
    } else {
      // Show attractions for the selected day
      final dayAttractions = _trip!.dayWiseAttractions[selectedDay] ?? [];
      for (var attr in dayAttractions) {
        if (attr.latitude != 0.0 && attr.longitude != 0.0) {
          markers.add(
            Marker(
              point: LatLng(attr.latitude, attr.longitude),
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: _buildMarkerPopup(attr),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.place,
                    color: Colors.teal,
                    size: 28,
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    if (isDirectionMode) {
      if (_error != null || _route == null || _route!.isEmpty) {
        return Container(
          height: mapHeight,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(child: Text(_error ?? 'No route found')),
        );
      }

      final points = _route!.map((c) => LatLng(c[1], c[0])).toList();
      final bounds = LatLngBounds.fromPoints(points);

      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: mapHeight,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _directionMapController,
                    key: ValueKey('${_route?.hashCode ?? 0}_direction'),
                    options: MapOptions(
                      initialCameraFit: CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.all(50),
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.paryatan_mantralaya_f',
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: points,
                            strokeWidth: 5,
                            color: Colors.teal,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: points.first,
                            width: 50,
                            height: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.my_location,
                                color: Colors.blue,
                                size: 28,
                              ),
                            ),
                          ),
                          Marker(
                            point: points.last,
                            width: 50,
                            height: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.flag,
                                color: Colors.red,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          
                  // 🧭 NORTH ALIGN BUTTON
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        _directionMapController.rotate(0);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 4,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.explore,
                          size: 26,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.teal.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_directionDestination != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.navigation, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _directionDestination!.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.straighten, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${(_distanceToDestination / 1000).toStringAsFixed(2)} km away',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _exitDirectionMode,
                      icon: const Icon(Icons.close),
                      label: const Text('Exit Navigation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    // Overview mode - Show loading indicator for restaurants
    if (selectedCategory == 'Restaurants' && _loadingRestaurants) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.orange),
              SizedBox(height: 16),
              Text('Finding nearby restaurants...'),
            ],
          ),
        ),
      );
    }

    List<LatLng> boundsPoints = [_currentLocation!];
    boundsPoints.addAll(markers.map((m) => m.point));
    
    final bounds = boundsPoints.length > 1
        ? LatLngBounds.fromPoints(boundsPoints)
        : LatLngBounds.fromPoints([
            _currentLocation!,
            LatLng(_currentLocation!.latitude + 0.01, _currentLocation!.longitude + 0.01),
          ]);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: anotherMapHeight,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              key: ValueKey(
                '${_currentLocation?.hashCode ?? 0}_${selectedDay}_$selectedCategory',
              ),
              options: MapOptions(
                initialCameraFit: CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(50),
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.paryatan_mantralaya_f',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 60,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    ...markers,
                  ],
                ),
              ],
            ),

            // 🧭 NORTH ALIGN BUTTON
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: () {
                  _mapController.rotate(0); // 🔥 Align to North
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 4,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.explore, // compass-style icon
                    size: 26,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_trip == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ongoing Trip'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(child: Text('Trip not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          _trip!.destinations.isNotEmpty
              ? _trip!.destinations.first.name
              : 'Ongoing Trip',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Budget Display
            if (_trip != null && _trip!.budget != null && !isDirectionMode)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade400, Colors.teal.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Remaining Budget',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${_trip!.budget!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Category and Day Selection
            if (!isDirectionMode)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
                          isExpanded: true,
                          items: ['Attractions', 'Accommodations', 'Restaurants'].map((String item) {
                            return DropdownMenuItem<String>(
                              value: item,
                              child: Text(
                                item,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedCategory = newValue!;
                              if (isDirectionMode) {
                                _exitDirectionMode();
                              }
                              // Load restaurants when category is selected
                              if (selectedCategory == 'Restaurants' && _recommendedRestaurants.isEmpty) {
                                _loadRestaurants();
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (selectedCategory != 'Restaurants')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedDay,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
                          items: availableDays.map((int day) {
                            return DropdownMenuItem<int>(
                              value: day,
                              child: Text(
                                'Day $day',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (int? newDay) {
                            if (newDay != null) {
                              setState(() {
                                selectedDay = newDay;
                                if (isDirectionMode) {
                                  _exitDirectionMode();
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ),
                ],
              ),

            const SizedBox(height: 20),

            _buildMap(),

            const SizedBox(height: 24),

            // Complete Trip Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: !isDirectionMode
                 ? ElevatedButton.icon(
                     onPressed: () async {
                       final shouldComplete = await showDialog<bool>(
                         context: context,
                         builder: (context) => AlertDialog(
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(20),
                           ),
                           title: const Text('Complete Trip?'),
                           content: const Text(
                             'Are you sure you want to mark this trip as completed?',
                           ),
                           actions: [
                             TextButton(
                               onPressed: () => Navigator.pop(context, false),
                               child: const Text('Cancel'),
                             ),
                             ElevatedButton(
                               onPressed: () => Navigator.pop(context, true),
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: Colors.green,
                               ),
                               child: const Text('Complete'),
                             ),
                           ],
                         ),
                       );

                       if (shouldComplete == true) {
                         await TripStore().completeTrip(widget.tripId);
                         if (!mounted) return;
                         Navigator.pop(context);
                       }
                     },
                     icon: const Icon(Icons.check_circle, size: 24),
                     label: const Text(
                       'Complete Trip',
                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                     ),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.transparent,
                       foregroundColor: Colors.white,
                       shadowColor: Colors.transparent,
                       padding: const EdgeInsets.symmetric(vertical: 18),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(16),
                       ),
                     )
                   )
                :
                  const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
