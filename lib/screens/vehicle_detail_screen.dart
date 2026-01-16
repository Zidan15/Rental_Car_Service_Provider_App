// lib/screens/vehicle_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:fleetwise/models/vehicle.dart';
import 'package:fleetwise/models/sensor_reading.dart';
import 'package:fleetwise/services/vehicle_service.dart';
import 'package:fleetwise/widgets/status_badge.dart';
import 'package:fleetwise/widgets/sparkline_chart.dart';
import 'package:fleetwise/theme.dart';
import 'package:fleetwise/screens/add_vehicle_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  late Vehicle _vehicle;
  final VehicleService _vehicleService = VehicleService();
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddVehicleScreen(vehicleToEdit: _vehicle),
      ),
    );

    // If updated, refresh vehicle data
    if (result == true) {
      await _refreshVehicle();
    }
  }

  Future<void> _refreshVehicle() async {
    try {
      final vehicles = await _vehicleService.getVehicles();
      final updated = vehicles.firstWhere(
        (v) => v.id == _vehicle.id,
        orElse: () => _vehicle,
      );
      if (mounted) {
        setState(() {
          _vehicle = updated;
        });
      }
    } catch (e) {
      // Keep existing vehicle data on error
    }
  }

  Future<void> _deleteVehicle() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text(
          'Are you sure you want to delete "${_vehicle.displayName}"?\n\n'
          'This action cannot be undone. All sensor data and booking history for this vehicle will also be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await _vehicleService.deleteVehicle(_vehicle.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate deletion
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting vehicle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, 
      child: Scaffold(
        appBar: AppBar(
          title: Text(_vehicle.displayName),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Vehicle',
              onPressed: _isDeleting ? null : _navigateToEdit,
            ),
            IconButton(
              icon: _isDeleting 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.delete_outline),
              tooltip: 'Delete Vehicle',
              onPressed: _isDeleting ? null : _deleteVehicle,
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'OVERVIEW'),
              Tab(text: 'DASHCAM'),
              Tab(text: 'INTERNAL CAM'),
              Tab(text: 'GPS'), 
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(vehicle: _vehicle), 
            _PlaceholderTab(message: 'Dashcam footage will appear here'),
            _PlaceholderTab(message: 'Internal camera footage will appear here'),
            _GPSTab(vehicle: _vehicle), 
          ],
        ),
      ),
    );
  }
}


// --------------------------------------------------------
// --- OVERVIEW TAB: CONVERTED TO STATEFUL FOR DATA FETCH ---
// --------------------------------------------------------
class _OverviewTab extends StatefulWidget {
  final Vehicle vehicle;
  const _OverviewTab({required this.vehicle});

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  // Create instance of the service
  final VehicleService _vehicleService = VehicleService();
  
  // State variables to hold the fetched chart data
  List<SensorReading> _alcoholReadings = [];
  List<SensorReading> _engineTempReadings = [];
  List<SensorReading> _speedReadings = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChartData(); // Call the fetch function when the tab loads
  }

  // Function to fetch all three sparkline datasets
  Future<void> _loadChartData() async {
    // We fetch each chart's data individually
    final futures = [
      _vehicleService.getAlcoholReadings(widget.vehicle.id),
      _vehicleService.getEngineTempReadings(widget.vehicle.id),
      _vehicleService.getSpeedReadings(widget.vehicle.id),
    ];
    
    final results = await Future.wait(futures);

    if (mounted) {
      setState(() {
        _alcoholReadings = results[0];
        _engineTempReadings = results[1];
        _speedReadings = results[2];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicle = widget.vehicle;
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle Information
          _InfoCard(
            title: 'Vehicle Information',
            items: [
              _InfoItem(label: 'Plate Number', value: vehicle.plateNumber),
              _InfoItem(label: 'Brand', value: vehicle.brand),
              _InfoItem(label: 'Model', value: vehicle.model),
              _InfoItem(label: 'Year', value: vehicle.year.toString()),
              _InfoItem(label: 'Category', value: vehicle.category ?? 'N/A'),
              _InfoItem(label: 'Fuel Type', value: vehicle.fuelType),
              _InfoItem(label: 'Transmission', value: vehicle.transmission),
              _InfoItem(label: 'Color', value: vehicle.color),
            ],
          ),
          const SizedBox(height: 20),
          // Status
          _InfoCard(
            title: 'Status',
            items: [
              _InfoItem(
                label: 'Current Status',
                widget: StatusBadge(vehicleStatus: vehicle.status),
              ),
              _InfoItem(
                label: 'Last Reading',
                value: _formatDateTime(vehicle.lastReading),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // --- SENSOR CARDS WITH REAL FETCHED DATA ---
          _SensorCard(
            title: 'Alcohol Level',
            value: '${vehicle.alcoholLevel.toStringAsFixed(2)} %',
            threshold: '0.08 %',
            color: LightModeColors.lightCritical,
            readings: _alcoholReadings, // Pass the FETCHED data
          ),
          const SizedBox(height: 12),
          _SensorCard(
            title: 'Engine Temperature',
            value: '${vehicle.engineTemp.toStringAsFixed(1)} °C',
            threshold: '100 °C',
            color: LightModeColors.lightWarning,
            readings: _engineTempReadings, // Pass the FETCHED data
          ),
          const SizedBox(height: 12),
          _SensorCard(
            title: 'Speed',
            value: '${vehicle.speed.toStringAsFixed(0)} km/h',
            threshold: '80 km/h',
            color: LightModeColors.lightSuccess,
            readings: _speedReadings, // Pass the FETCHED data
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// --------------------------------------------------------
// --- GPS TAB: REAL GOOGLE MAP IMPLEMENTATION ---
// --------------------------------------------------------
class _GPSTab extends StatefulWidget {
  final Vehicle vehicle;

  const _GPSTab({required this.vehicle});

  @override
  State<_GPSTab> createState() => _GPSTabState();
}

class _GPSTabState extends State<_GPSTab> {
  GoogleMapController? _mapController;
  
  // Goa center coordinates
  static const LatLng _goaCenter = LatLng(15.2993, 74.1240);
  
  // Goa bounds for restricting the map
  static final LatLngBounds _goaBounds = LatLngBounds(
    southwest: const LatLng(14.8, 73.6),
    northeast: const LatLng(15.8, 74.5),
  );

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  LatLng get _vehicleLocation {
    // Use real vehicle coordinates if available, otherwise fall back to Goa center
    if (widget.vehicle.latitude != 0.0 || widget.vehicle.longitude != 0.0) {
      return LatLng(widget.vehicle.latitude, widget.vehicle.longitude);
    }
    return _goaCenter;
  }

  Set<Marker> get _markers {
    return {
      Marker(
        markerId: MarkerId(widget.vehicle.id),
        position: _vehicleLocation,
        infoWindow: InfoWindow(
          title: widget.vehicle.displayName,
          snippet: widget.vehicle.plateNumber,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRealData = widget.vehicle.latitude != 0.0 || widget.vehicle.longitude != 0.0;
    
    return Column(
      children: [
        // Map container
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(0),
            ),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _vehicleLocation,
                zoom: 12,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              mapType: MapType.normal,
              myLocationEnabled: false,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
              cameraTargetBounds: CameraTargetBounds(_goaBounds),
              minMaxZoomPreference: const MinMaxZoomPreference(8, 18),
            ),
          ),
        ),
        
        // Info card at bottom
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    hasRealData ? Icons.gps_fixed : Icons.gps_off,
                    size: 20,
                    color: hasRealData ? Colors.green : theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasRealData ? 'Live Location' : 'GPS Data Pending',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                hasRealData
                    ? '${widget.vehicle.latitude.toStringAsFixed(4)}° N, ${widget.vehicle.longitude.toStringAsFixed(4)}° E'
                    : 'GPS data from IoT module (Phase 2)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------------
// --- UNCHANGED WIDGETS ---
// --------------------------------------------------------

class _PlaceholderTab extends StatelessWidget {
  final String message;
  const _PlaceholderTab({required this.message});
  // ... (your code is perfect) ...
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_outlined,
              size: 80,
              color: theme.colorScheme.secondary.withAlpha(77),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _InfoCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: item,
          )),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? widget;

  const _InfoItem({required this.label, this.value, this.widget});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
        widget ?? Text(
          value ?? '',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String threshold;
  final Color color;
  final List<SensorReading> readings; // Now expects SensorReading

  const _SensorCard({
    required this.title,
    required this.value,
    required this.threshold,
    required this.color,
    required this.readings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                'Max: $threshold',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          if (readings.isNotEmpty) // Only show chart if data exists
            SparklineChart(
              data: readings, // Pass the real data
              color: color,
              height: 80,
            )
          else
            Container(
              height: 80,
              child: Center(child: Text('No chart data available.', style: theme.textTheme.bodySmall)),
            ),
          
        ],
      ),
    );
  }
}