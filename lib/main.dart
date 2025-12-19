import 'package:flutter/material.dart';
import 'screens/main_shell.dart';
import 'store/trip_store.dart';
import 'store/favourite_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TripStore().loadTrips(); // 👈 LOAD SAVED TRIPS
  await FavouriteStore().loadFavourites();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainShell(),
    );
  }
}
