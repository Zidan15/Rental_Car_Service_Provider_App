// lib/screens/fleet_screen.dart
import 'package:flutter/material.dart';
import 'package:fleetwise/models/vehicle.dart';
import 'package:fleetwise/services/vehicle_service.dart';
import 'package:fleetwise/services/alert_service.dart';
import 'package:fleetwise/widgets/kpi_card.dart';
import 'package:fleetwise/widgets/status_badge.dart';
import 'package:fleetwise/widgets/empty_state.dart';
import 'package:fleetwise/screens/vehicle_detail_screen.dart';

class FleetScreen extends StatefulWidget {
  final VoidCallback onAlertsTap;

  const FleetScreen({super.key, this.onAlertsTap = _defaultOnTap});
  
  static void _defaultOnTap() {}

  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> {
  // --- 1. ADD STATE VARIABLES ---
  bool _isLoading = true; // To show a loading circle
  int _activeAlerts = 0; // To store the real alert count

  bool _isListMaximized = false; 
  final _searchController = TextEditingController();
  List<Vehicle> _vehicles = [];
  List<Vehicle> _filteredVehicles = [];

  // --- 2. CREATE INSTANCES OF YOUR REAL SERVICES ---
  // We can't use 'static' anymore, we need real instances.
  final VehicleService _vehicleService = VehicleService();
  final AlertService _alertService = AlertService();


  @override
  void initState() {
    super.initState();
    // --- 3. LOAD REAL DATA IN INITSTATE ---
    _loadData(); // This replaces the mock data call
    _searchController.addListener(_onSearchChanged);
  }

  // --- 4. CREATE A FUNCTION TO LOAD DATA ---
  Future<void> _loadData() async {
    // Show loading spinner
    setState(() {
      _isLoading = true;
    });
    
    // Call your real services at the same time
    final futures = [
      _vehicleService.getVehicles(),
      _alertService.getActiveAlertsCount(),
    ];

    // Wait for both to finish
    final results = await Future.wait(futures);

    // Update the state with the real data
    setState(() {
      _vehicles = results[0] as List<Vehicle>;
      _filteredVehicles = _vehicles;
      _activeAlerts = results[1] as int;
      _isLoading = false; // Hide loading spinner
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      // Your search function is still perfect
      _filteredVehicles = VehicleService.searchVehicles(_vehicles, _searchController.text);
    });
  }

  void _toggleListMaximize() {
    // ... (This function is perfect, no change needed)
    setState(() {
      _isListMaximized = !_isListMaximized;
    });
    if (_isListMaximized) {
      _searchController.clear();
      _onSearchChanged();
    }
  }

  void _navigateToDetail(Vehicle vehicle) {
    // ... (This function is perfect, no change needed)
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
    
    // --- 5. SHOW A LOADING CIRCLE ---
    // This shows a spinner while we fetch data
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // --- 6. CHECK FOR EMPTY STATE *AFTER* LOADING ---
    // This now correctly checks the REAL list
    if (_filteredVehicles.isEmpty && _searchController.text.isEmpty) {
      return const EmptyState(
        icon: Icons.directions_car_outlined,
        message: 'No vehicles yet',
        subtitle: 'Add one to get started',
      );
    }
    
    return Column(
        children: [
          // Header for Maximized List 
          if (_isListMaximized)
            Container(
              padding: const EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.1)),
                ),
              ),
              child: Row(
                children: [
                  // The "Cancel" or Minimize button
                  IconButton(
                    icon: const Icon(Icons.arrow_back), 
                    onPressed: _toggleListMaximize,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total Vehicles',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),

          // Header Content (KPIs and Search) - Hidden when maximized
          AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isListMaximized ? 0 : null, 
              padding: _isListMaximized ? EdgeInsets.zero : const EdgeInsets.all(20),
              child: SingleChildScrollView( 
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _toggleListMaximize, 
                              child: KPICard(
                                title: 'Total Vehicles',
                                // --- 7. USE REAL DATA ---
                                value: '${_vehicles.length}', // Uses real list length
                                icon: Icons.directions_car,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: widget.onAlertsTap, 
                              child: KPICard(
                                title: 'Active Alerts',
                                // --- 8. USE REAL DATA ---
                                value: '$_activeAlerts', // Uses real alert count
                                icon: Icons.warning_amber,
                                color: const Color.fromARGB(255, 245, 11, 11),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      // Search field for the normal view
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
          
          // Vehicle List
          Expanded(
            child: _filteredVehicles.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    message: 'No vehicles found',
                    subtitle: 'Try adjusting your search',
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(20, _isListMaximized ? 0 : 20, 20, 20),
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
    );
  }
}

// --- NO CHANGES NEEDED BELOW THIS LINE ---
// Your _VehicleCard and _formatTimeAgo are perfect.
// They will work with the real data because we updated 
// the Vehicle.fromJson translator.

class _VehicleCard extends StatelessWidget {
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
                            // This logic is now driven by real data
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
                          'Last reading: $timeAgo', // This uses real data
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.secondary.withOpacity(0.4),
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