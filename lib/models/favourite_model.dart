class Favourite {
  final String destination;

  Favourite({required this.destination});

  Map<String, dynamic> toJson() {
    return {'destination': destination};
  }

  factory Favourite.fromJson(Map<String, dynamic> json) {
    return Favourite(destination: json['destination']);
  }
}
