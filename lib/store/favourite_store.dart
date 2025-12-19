import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favourite_model.dart';

class FavouriteStore {
  static final FavouriteStore _instance = FavouriteStore._internal();
  factory FavouriteStore() => _instance;
  FavouriteStore._internal();

  static const String _storageKey = "favourites_storage";

  /// 🔔 Reactive notifier
  final ValueNotifier<List<Favourite>> favouritesNotifier =
      ValueNotifier<List<Favourite>>([]);

  List<Favourite> get favourites => favouritesNotifier.value;

  /// Load favourites at app start
  Future<void> loadFavourites() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);

    if (data != null) {
      final List decoded = jsonDecode(data);
      favouritesNotifier.value =
          decoded.map((e) => Favourite.fromJson(e)).toList();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(favouritesNotifier.value.map((f) => f.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  bool isFavourite(String destination) {
    return favouritesNotifier.value
        .any((f) => f.destination == destination);
  }

  Future<void> addFavourite(String destination) async {
    if (isFavourite(destination)) return;

    favouritesNotifier.value = [
      ...favouritesNotifier.value,
      Favourite(destination: destination),
    ];

    await _save();
  }

  Future<void> removeFavourite(String destination) async {
    favouritesNotifier.value = favouritesNotifier.value
        .where((f) => f.destination != destination)
        .toList();

    await _save();
  }
}
