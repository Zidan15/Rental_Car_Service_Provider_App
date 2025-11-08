import 'package:flutter/material.dart';
import 'package:fleetwise/screens/fleet_screen.dart';
import 'package:fleetwise/screens/alerts_screen.dart';
import 'package:fleetwise/screens/add_vehicle_screen.dart';
import 'package:fleetwise/screens/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // NEW: Add a method to allow other screens to change the tab index.
  void selectTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // OLD: final List<Widget> _screens = const [
  // NEW: Change to 'late final' and remove 'const' so we can initialize 
  // with a callback function passed to FleetScreen.
  late final List<Widget> _screens;
  // NEW: Initialize _screens in initState().
  @override
  void initState() {
    super.initState();
    // The AlertsScreen is at index 1.
    _screens = [
      // Pass the selectTab method to FleetScreen's new 'onAlertsTap' property.
      FleetScreen(onAlertsTap: () => selectTab(1)), 
      const AlertsScreen(),
      const AddVehicleScreen(),
      //const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
    
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.secondary.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.secondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_car_outlined),
              activeIcon: Icon(Icons.directions_car),
              label: 'FLEET',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.warning_amber_outlined),
              activeIcon: Icon(Icons.warning_amber),
              label: 'ALERTS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle),
              label: 'ADD',
            ),
          ],
        ),
      ),
    );
  }
}
