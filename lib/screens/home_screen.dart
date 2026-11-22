import 'package:flutter/material.dart';

import '../widgets/ui.dart';
import 'activity_tab.dart';
import 'dashboard_tab.dart';
import 'insights_tab.dart';
import 'profile_tab.dart';

/// The signed in shell: four tabs with a bottom navigation bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardTab(onSeeAll: () => setState(() => _tab = 1)),
      const ActivityTab(),
      const InsightsTab(),
      const ProfileTab(),
    ];

    return GlassScaffold(
      body: SafeArea(child: PageWidth(child: pages[_tab])),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Color(0x14101828), blurRadius: 20, offset: Offset(0, -4))],
        ),
        child: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Activity'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Insights'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      ),
    );
  }
}
