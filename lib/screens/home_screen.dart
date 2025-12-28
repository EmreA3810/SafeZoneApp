import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
    final isDesktop = kIsWeb || MediaQuery.of(context).size.width > 600;

    if (isDesktop) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                selectedIndex: _currentIndex,
                onDestinationSelected: _onTabTapped,
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.feed_outlined),
                    selectedIcon: Icon(Icons.feed),
                    label: Text('Feed'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.map_outlined),
                    selectedIcon: Icon(Icons.map),
                    label: Text('Map'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.description_outlined),
                    selectedIcon: Icon(Icons.description),
                    label: Text('My Reports'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: Text('Profile'),
                  ),
                ],
                trailing: _currentIndex != 3
                    ? Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: FloatingActionButton(
                          onPressed: _navigateToAddReport,
                          child: const Icon(Icons.add),
                        ),
                      )
                    : null,
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: IndexedStack(index: _currentIndex, children: _screens),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: _screens),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: _destinations,
      ),
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
