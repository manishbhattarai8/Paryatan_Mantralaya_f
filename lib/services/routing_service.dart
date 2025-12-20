import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paryatan_mantralaya_f/config.dart';

class RouteService {
  // 👇 Use your PC IP address
  static const String baseUrl = API_URL;

  static Future<List<List<double>>> fetchRoute({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    String profile = "car",
  }) async {
    final uri = Uri.parse(
      "$baseUrl/route/"
      "?profile=$profile"
      "&start_lat=$startLat"
      "&start_lon=$startLon"
      "&end_lat=$endLat"
      "&end_lon=$endLon",
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception("Failed to load route");
    }

    final data = jsonDecode(response.body);
    return List<List<double>>.from(
      data["coordinates"].map((c) => List<double>.from(c)),
    );
  }
}

