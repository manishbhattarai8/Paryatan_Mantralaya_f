class Destination {
  // id usually comes from Mongo ("_id": { "\$oid": "..." }) or from an "id" key
  final String id;
  final String location;
  final String name; // PLACE NAME
  final String description; // PLACE DESCRIPTION
  final String category;
  final int avgPrice;
  final double rating;
  final String openHours;
  final double latitude;
  final double longitude;
  final List<String> suitableSeason;
  final List<String> suitableWeather;
  final List<String> compatableMoods;
  // Keep the original server key name `image` but expose `imageUrl` for compatibility
  final String imageUrl;

  Destination({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.category,
    required this.rating,
    this.imageUrl = '',
    this.avgPrice = 0,
    this.openHours = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
     required this.suitableSeason, required this.suitableWeather, required this.compatableMoods,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    // Extract id: accept _id: {"$oid": "..."} or string id or int id
    String id = '';
    if (json.containsKey('_id')) {
      final v = json['_id'];
      if (v is Map && v.containsKey(r'$oid')) {
        id = v[r'$oid']?.toString() ?? '';
      } else {
        id = v?.toString() ?? '';
      }
    } else if (json.containsKey('id')) {
      id = json['id']?.toString() ?? '';
    }

    return Destination(
      id: id,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      category: json['category'] ?? '',
      imageUrl: (json['image'] ?? json['image_url'] ?? json['imageUrl'])?.toString() ?? '',
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : 0.0,
      avgPrice: json['avg_price'] != null ? (json['avg_price'] as num).toInt() : 0,
      openHours: json['open_hours'] ?? json['openHours'] ?? '',
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : 0.0,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : 0.0,
      suitableSeason: json['suitable_season'] != null
          ? List<String>.from(json['suitable_season'])
          : [],
      suitableWeather: json['suitable_weather'] != null
          ? List<String>.from(json['suitable_weather'])
          : [],
      compatableMoods: json['compatable_moods'] != null
          ? List<String>.from(json['compatable_moods'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': {r'$oid': id},
      'name': name,
      'description': description,
      'location': location,
      'category': category,
      'avg_price': avgPrice,
      'rating': rating,
      'open_hours': openHours,
      'latitude': latitude,
      'longitude': longitude,
      'suitable_season': suitableSeason,
      'suitable_weather': suitableWeather,
      'compatable_moods': compatableMoods,
      'image': imageUrl,
    };
  }
}
