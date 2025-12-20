

class Destination {
  final int id;
  final String name;        // PLACE NAME
  final String description; // PLACE DESCRIPTION
  final String location;
  final String category;
  final double rating;
  final String imageUrl;

  Destination({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.category,
    required this.rating,
    this.imageUrl = '',
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      category: json['category'] ?? '',
      imageUrl: (json['image_url'] ?? json['image'] ?? json['imageUrl'])?.toString() ?? '',
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : 0.0,
    );
  }
}
