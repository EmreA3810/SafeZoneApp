import 'package:flutter/material.dart';
import 'feed_screen.dart';
import 'map_screen.dart';
import 'my_reports_screen.dart';
import 'profile_screen.dart';
import 'add_report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.feed_outlined),
      selectedIcon: Icon(Icons.feed),
      label: 'Feed',
    ),
    NavigationDestination(
      icon: Icon(Icons.map_outlined),
      selectedIcon: Icon(Icons.map),
      label: 'Map',
    ),
    NavigationDestination(
      icon: Icon(Icons.description_outlined),
      selectedIcon: Icon(Icons.description),
      label: 'My Reports',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = const [
      FeedScreen(),
      MapScreen(),
      MyReportsScreen(),
      ProfileScreen(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToAddReport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddReportScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: _screens),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: _destinations,
      ),
      // Only show Report button when NOT on Profile page (index 3)
      floatingActionButton: _currentIndex != 3
          ? FloatingActionButton.extended(
              onPressed: _navigateToAddReport,
              icon: const Icon(Icons.add),
              label: const Text('Report'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
