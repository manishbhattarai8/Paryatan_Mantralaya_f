import 'package:flutter/material.dart';
import 'package:paryatan_mantralaya_f/screens/loginsignup.dart';
import 'screens/main_shell.dart';
import 'store/trip_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TripStore().loadTrips(); // 👈 LOAD SAVED TRIPS
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // start at the login/signup screen and only proceed to MainShell after auth
      home: const Loginsignup(),
    );
  }
}
