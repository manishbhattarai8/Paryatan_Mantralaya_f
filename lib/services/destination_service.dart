import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/destination_model.dart';

class DestinationService {
  static const String baseUrl = "http://10.10.254.254:8000";

  Future<List<Destination>> fetchDestinations() async {
    final response = await http.get(
      Uri.parse("$baseUrl/destinations/"),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // 👇 THIS IS THE KEY LINE
      final List list = decoded['data'];
      print("sdfsdfdsdsfsf${list.toString()}");

      return list
          .map((e) => Destination.fromJson(e))
          .toList();
    } else {
      throw Exception("Failed to load destinations");
    }
  }
}
