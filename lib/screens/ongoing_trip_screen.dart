import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:paryatan_mantralaya_f/models/destination_model.dart';
import 'package:paryatan_mantralaya_f/models/trip_model.dart';

import 'package:paryatan_mantralaya_f/services/routing_service.dart';
import 'package:paryatan_mantralaya_f/services/location_service.dart';
import '../store/trip_store.dart';

class OngoingTripScreen extends StatefulWidget {
  final String destination;
  final String tripId;

  const OngoingTripScreen({
    super.key,
    required this.destination,
    required this.tripId,
  });

  @override
  State<OngoingTripScreen> createState() => _OngoingTripScreenState();
}

class _OngoingTripScreenState extends State<OngoingTripScreen> {
  List<List<double>>? _route;
  String? _error;
  bool _loading = true;
  final List<String> dropdownItems = [
    'Main Attractions',
    'Restaurants and cafes',
    'Accomodations',
  ];
  String selectedItem = 'Main Attractions';
  final List<String> modeList = ["Direction, Overview"];
  String mode = "Overview";
  Timer? _positionTimer;
  bool _updatingPosition = false;

  @override
  void initState() {
    super.initState();
    _loadRoute();
    // Periodically update the user's position & route on this screen only.
    _positionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _periodicUpdate();
    });
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRoute() async {
    setState(() {
      _loading = true;
      _error = null;
      _route = null;
    });

    try {
      final position = await LocationService.getCurrentLocation();

      final trip = TripStore().trips.firstWhere(
        (t) => t.id == widget.tripId,
        orElse: () => Trip(destinations: [], status: TripStatus.ongoing),
      );

      double endLat = 27.6736;
      double endLon = 85.3250;

      if (trip.destinations.isNotEmpty) {
        final dest = trip.destinations.first;
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

      // No UI blocking: map will rebuild with new route (key forces reinit)
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

  Future<void> _periodicUpdate() async {
    if (_updatingPosition) return;
    _updatingPosition = true;
    try {
      final position = await LocationService.getCurrentLocation();

      final trip = TripStore().trips.firstWhere(
        (t) => t.id == widget.tripId,
        orElse: () => Trip(destinations: [], status: TripStatus.ongoing),
      );

      double endLat = 27.6736;
      double endLon = 85.3250;

      if (trip.destinations.isNotEmpty) {
        final dest = trip.destinations.first;
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

      // Map will rebuild to reflect updated route (key forces reinit)
    } catch (e) {
      // Swallow errors for periodic updates (we don't want to interrupt the UI)
    } finally {
      _updatingPosition = false;
    }
  }

  Widget _buildMap() {
    Trip dummyTrip= Trip(id:"1",destinations: [
      Destination(id: "1", name: "durbar square", description: "this is durbar", location: "Kathmandu", category: "Main Attractions", rating: 4, suitableSeason: ["winter"], suitableWeather: ["sunny"], compatableMoods: ["food"], latitude: 23, longitude: 83),
      Destination(id: "1", name: "PAATAN", description: "this is patan", location: "Kathmandu", category: "Restaurants and Cafes", rating: 4, suitableSeason: ["winter"], suitableWeather: ["sunny"], compatableMoods: ["food"], latitude: 26, longitude: 87)
    ], status: TripStatus.ongoing);

    if (_loading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _route == null || _route!.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(child: Text(_error ?? 'No route found')),
      );
    }

    final points = _route!.map((c) => LatLng(c[1], c[0])).toList();
    final bounds = LatLngBounds.fromPoints(points);

    final overviewPoints = _route!.map((c) => LatLng(c[1], c[0])).toList();
    final overviewBounds = LatLngBounds.fromPoints(overviewPoints);

    if(mode=="direction") {
    return SizedBox(
      height: 540,
      child: FlutterMap(
        key: ValueKey(_route?.hashCode ?? 0),
        options: MapOptions(
          initialCameraFit: CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(32),
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.paryatan_mantralaya_f',
          ),
         PolylineLayer(
            polylines: [
              Polyline(points: points, strokeWidth: 4, color: Colors.blue),
            ],
          ),
          
          MarkerLayer(
            markers: [
              Marker(
                point: points.first,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.green,
                  size: 40,
                ),
              ),
              Marker(
                point: points.last,
                width: 40,
                height: 40,
                child: const Icon(Icons.flag, color: Colors.red, size: 40),
              ),
            ],
          ),
        ],
      ),
    );}

    return SizedBox(
      height: 540,
      child: FlutterMap(
        key: ValueKey(_route?.hashCode ?? 0),
        options: MapOptions(
          initialCameraFit: CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(32),
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.paryatan_mantralaya_f',
          ),
          MarkerLayer(
            markers: [
              // Marker(
              //   point: points.first,
              //   width: 40,
              //   height: 40,
              //   child: const Icon(
              //     Icons.location_on,
              //     color: Colors.green,
              //     size: 40,
              //   ),
              // ),
              // Marker(
              //   point: points.last,
              //   width: 40,
              //   height: 40,
              //   child: const Icon(Icons.flag, color: Colors.red, size: 40),
              // ),
              ...overviewPoints.map((point) => 
                Marker(point: point, child: const Icon(Icons.local_atm))
              )
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ongoing Trip')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.destination,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButton<String>(
                  value: selectedItem,
                  items: dropdownItems.map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedItem = newValue!;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            _buildMap(),

            const SizedBox(height: 20),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await TripStore().completeTrip(widget.tripId);
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Complete Trip',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
