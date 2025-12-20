import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/destination_model.dart';
import 'package:paryatan_mantralaya_f/config.dart';

class ApiService {
  static const String baseUrl = API_URL;

  Future<List<Destination>> getAllDestinations() async {
    final response = await http.get(
      Uri.parse("$baseUrl/destinations/"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['data'];
      return list.map((e) => Destination.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load destinations");
    }
  }

  Future<List<Destination>> searchDestinations({
    List<String>? categories,
    List<String>? moods,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/destinations/search"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "category": categories,
        "moods": moods,
      }),
    );

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => Destination.fromJson(e)).toList();
    } else {
      throw Exception("Search failed");
    }
  }

  Future<List<Destination>> getPlacesFromLocation(String location) async {
    final response = await http.post(
      Uri.parse("$baseUrl/destinations/search"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "location": location,
      }),
    );

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => Destination.fromJson(e)).toList();
    } else {
      throw Exception("Search failed");
    }
  }
}
