import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';
import 'trips_screen.dart';
import 'favourites_screen.dart';
import 'loginsignup.dart';

import '../services/location_permission_service.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int currentIndex;

  final List<Widget> screens = const [
    HomeScreen(),
    TripsScreen(),
    FavouritesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;

    // Request location permission once after login
    _initLocationPermission();
  }

  Future<void> _initLocationPermission() async {
    final granted =
        await LocationPermissionService.requestLocationPermission();

    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permission is required for maps and trip planning features.',
          ),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('username');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signed out')),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const Loginsignup()),
    );
  }
Widget _navItem({
  required IconData icon,
  required int index,
}) {
  final bool isActive = currentIndex == index;

  return GestureDetector(
    onTap: () {
      setState(() => currentIndex = index);
    },
    behavior: HitTestBehavior.opaque,
    child: SizedBox(
      width: 60, // fixed width prevents navbar shift
      height: 44,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(
            0,
            isActive ? -6 : 0, // 🔼 lift ONLY icon
            0,
          ),
          child: AnimatedScale(
            scale: isActive ? 1.3 : 1.0, // 🔍 icon enlarge
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: Icon(
              icon,
              size: 26,
              color: isActive ? Colors.green : Colors.grey,
            ),
          ),
        ),
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TravlApes'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),

      // 👇 CUSTOM BOTTOM NAV
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(icon: Icons.home_outlined, index: 0),
            _navItem(icon: Icons.map_outlined, index: 1),
            _navItem(icon: Icons.favorite_border, index: 2),
          ],
        ),
      ),
    );
  }
}
