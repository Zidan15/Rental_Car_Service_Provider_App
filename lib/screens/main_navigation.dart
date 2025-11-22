import 'package:flutter/material.dart';
import 'package:fleetwise/screens/fleet_screen.dart';
import 'package:fleetwise/screens/alerts_screen.dart';
import 'package:fleetwise/screens/add_vehicle_screen.dart';
import 'package:fleetwise/screens/bookings_screen.dart'; // ✅ Import BookingsScreen
import 'package:fleetwise/screens/profile_screen.dart';
import 'package:fleetwise/screens/login_screen.dart'; 
import 'package:fleetwise/screens/terms_and_conditions_screen.dart';
import 'package:fleetwise/screens/about_rent_goa_screen.dart';


class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  // ✅ FIX: Key for the FleetScreen to force a rebuild
  Key _fleetKey = UniqueKey(); 

  void selectTab(int index) {
    // If the selected index is 0 (FLEET), update the key to force a rebuild.
    if (index == 0) {
      _fleetKey = UniqueKey();
    }
    setState(() {
      _currentIndex = index;
    });
  }

  // Callback function to force a rebuild (called from AlertsScreen)
  void _onAlertsCountChange() {
    // We already call setState, but let's also update the key to ensure the next
    // time the FLEET tab is selected, it gets a fresh build.
    _fleetKey = UniqueKey();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
  }

  // Function to handle the Log Out action
  void _handleLogout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // NOTE: We must regenerate the screen list in build() to use the new key
    final List<Widget> currentScreens = [
      // ✅ CRUCIAL: Use the stateful key here in the build method
      FleetScreen(key: _fleetKey, onAlertsTap: () => selectTab(2)), // Update to index 2 (Alerts)
      const BookingsScreen(), // ✅ New Bookings Screen at index 1
      AlertsScreen(onAlertCountChanged: _onAlertsCountChange),
      const AddVehicleScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true, 
        title: Text(
          _getTitleForIndex(_currentIndex), 
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [],
      ),
      
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
              ),
              child: const Text('RENT.GOA', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context); 
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(), 
                  ),
                );
              },
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Terms and Conditions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TermsAndConditionsScreen(),
                  ),
                );
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About RENT.GOA'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AboutRentGoaScreen(),
                  ),
                );
              },
            ),
            
            const Divider(),

            ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text('LOG OUT', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
              onTap: _handleLogout, 
            ),

            const Divider(),
          ],
        ),
      ),
      
      body: IndexedStack(
        index: _currentIndex,
        // ✅ CRUCIAL: Use the list generated in build() with the updated key
        children: currentScreens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.secondary.withAlpha(26), 
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          // Use selectTab to ensure the key is updated before setState runs
          onTap: selectTab, 
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
            // ✅ New Bookings Item
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'BOOKINGS',
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
  
  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'FLEET OVERVIEW';
      case 1:
        return 'BOOKINGS & LISTINGS'; // ✅ New Title
      case 2:
        return 'ALERTS';
      case 3:
        return 'ADD VEHICLE';
      default:
        return 'FLEETWISE';
    }
  }
}