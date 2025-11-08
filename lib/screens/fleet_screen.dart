import 'package:flutter/material.dart';
import 'package:fleetwise/models/vehicle.dart';
import 'package:fleetwise/services/vehicle_service.dart';
import 'package:fleetwise/services/alert_service.dart';
import 'package:fleetwise/widgets/kpi_card.dart';
import 'package:fleetwise/widgets/status_badge.dart';
import 'package:fleetwise/widgets/empty_state.dart';
import 'package:fleetwise/screens/vehicle_detail_screen.dart';
import 'package:fleetwise/theme.dart';
import 'package:fleetwise/screens/profile_screen.dart';

class FleetScreen extends StatefulWidget {
  // ⬅️ START OF CHANGE 1: Add the callback property
  final VoidCallback onAlertsTap;

  // 🐛 FIX: Make the parameter OPTIONAL and give it a default empty function.
  // This allows the few remaining calls of FleetScreen() that you haven't
  // found yet (like test/debug routes) to run without error.
  const FleetScreen({super.key, this.onAlertsTap = _defaultOnTap});
  
  // 🐛 FIX: Define the static default function outside the constructor.
  static void _defaultOnTap() {}
  // ➡️ END OF CHANGE 1: Updated to be optional with default

  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> {
  // ❌ REMOVED: ScrollController is no longer needed for this effect.
  // final ScrollController _vehicleListScrollController = ScrollController();

  // 🟢 NEW STATE: Boolean to track if the list is maximized/focused.
  bool _isListMaximized = false; 

  final _searchController = TextEditingController();
  List<Vehicle> _vehicles = [];
  List<Vehicle> _filteredVehicles = [];

  @override
  void initState() {
    super.initState();
    _vehicles = VehicleService.getMockVehicles();
    _filteredVehicles = _vehicles;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    // ❌ REMOVED: ScrollController dispose is no longer needed.
    // _vehicleListScrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredVehicles = VehicleService.searchVehicles(_vehicles, _searchController.text);
    });
  }

  // 🟢 NEW FUNCTION: Toggles the list maximization state.
  void _toggleListMaximize() {
    setState(() {
      _isListMaximized = !_isListMaximized;
    });
    // Optional: Reset search if list is maximized, to show all vehicles.
    if (_isListMaximized) {
      _searchController.clear();
      _onSearchChanged();
    }
  }

  void _navigateToDetail(Vehicle vehicle) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => VehicleDetailScreen(vehicle: vehicle),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alerts = AlertService.getMockAlerts();
    final activeAlerts = AlertService.getActiveAlertsCount(alerts);
    final healthyVehicles = _vehicles.where((v) => v.status == VehicleStatus.healthy).length;

    return Scaffold(
      // ➡️ ADD THE DRAWER HERE (MOVED FROM MAIN_NAVIGATION.DART)
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            // Drawer Header
            DrawerHeader(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
              ),
              child: const Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            // Profile Navigation Item: Navigates to the ProfileScreen
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                // Close the drawer before navigating
                Navigator.pop(context);
                
                // Push the ProfileScreen onto the navigation stack
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(), 
                  ),
                );
              },
            ),
          ],
        ),
      ),
      
      appBar: AppBar(
        title: const Text('FLEET OVERVIEW'),
        // 🟢 CHANGE 1: Update AppBar to show a close button if the list is maximized.
        leading: _isListMaximized
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleListMaximize,
              )
            : null, // Let Flutter handle the drawer icon when not maximized.
        
      ),

      body: _filteredVehicles.isEmpty && _searchController.text.isEmpty
        ? const EmptyState(
            icon: Icons.directions_car_outlined,
            message: 'No vehicles yet',
            subtitle: 'Add one to get started',
          )
        : Column(
            children: [
              // 🟢 CHANGE 2: Wrap the header content in Visibility and use an animation
              // for a smooth collapse/expand effect. This section is hidden when maximized.
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _isListMaximized ? 0 : null, // Set height to 0 when maximized
                padding: _isListMaximized ? EdgeInsets.zero : const EdgeInsets.all(20),
                child: SingleChildScrollView( // Prevents layout error during transition
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // 🟢 CHANGE 3: Update the "Total Vehicles" GestureDetector to toggle maximization.
                          Expanded(
                            child: GestureDetector(
                              onTap: _toggleListMaximize, // ⬅️ Call the new toggle function here
                              child: KPICard(
                                title: 'Total Vehicles',
                                value: '${_vehicles.length}',
                                icon: Icons.directions_car,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          // ➡️ END OF CHANGE 3
                          const SizedBox(width: 12),
                          // ⬅️ START OF CHANGE 4: Active Alerts remains the same.
                          Expanded(
                            child: GestureDetector(
                              onTap: widget.onAlertsTap, 
                              child: KPICard(
                                title: 'Active Alerts',
                                value: '$activeAlerts',
                                icon: Icons.warning_amber,
                                color: const Color.fromARGB(255, 245, 11, 11),
                              ),
                            ),
                          ),
                          // ➡️ END OF CHANGE 4
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by plate or model',
                          prefixIcon: Icon(Icons.search, color: theme.colorScheme.secondary),
                          suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged();
                                },
                              )
                            : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ➡️ END OF CHANGE 2
              
              Expanded(
                child: _filteredVehicles.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off,
                      message: 'No vehicles found',
                      subtitle: 'Try adjusting your search',
                    )
                  : ListView.builder(
                      // ❌ REMOVED: ScrollController is no longer needed here.
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: _filteredVehicles.length,
                      itemBuilder: (context, index) {
                        final vehicle = _filteredVehicles[index];
                        return _VehicleCard(
                          vehicle: vehicle,
                          onTap: () => _navigateToDetail(vehicle),
                        );
                      },
                    ),
              ),
            ],
          ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
// ... (rest of _VehicleCard class is unchanged)
  final Vehicle vehicle;
  final VoidCallback onTap;

  const _VehicleCard({required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeAgo = _formatTimeAgo(vehicle.lastReading);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        vehicle.plateNumber,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (vehicle.status == VehicleStatus.critical)
                          const StatusBadge(vehicleStatus: VehicleStatus.critical),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    vehicle.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last reading: $timeAgo',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.secondary.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}