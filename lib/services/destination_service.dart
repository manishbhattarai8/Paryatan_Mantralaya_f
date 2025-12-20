import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/destination_model.dart';
import 'package:paryatan_mantralaya_f/config.dart';

class DestinationService {
  static const String baseUrl = API_URL;

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
