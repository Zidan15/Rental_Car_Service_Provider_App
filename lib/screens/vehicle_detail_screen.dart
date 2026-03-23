// lib/screens/vehicle_detail_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fleetwise/models/vehicle.dart';
import 'package:fleetwise/models/sensor_reading.dart';
import 'package:fleetwise/services/vehicle_service.dart';
import 'package:fleetwise/widgets/status_badge.dart';
import 'package:fleetwise/widgets/sparkline_chart.dart';
import 'package:fleetwise/theme.dart';
import 'package:fleetwise/screens/add_vehicle_screen.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
        body: SafeArea(
          top: false,
          child: TabBarView(
            children: [
              _OverviewTab(vehicle: _vehicle), 
              _PlaceholderTab(message: 'Dashcam footage will appear here'),
              _PlaceholderTab(message: 'Internal camera footage will appear here'),
              _GPSTab(vehicle: _vehicle), 
            ],
          ),
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
  final VehicleService _vehicleService = VehicleService();
  
  // Mutable vehicle to reflect real-time sensor updates
  late Vehicle _currentVehicle;
  
  // Alcohol history (string labels)
  List<Map<String, dynamic>> _alcoholHistory = [];
  // Chart data for numeric sensors
  List<SensorReading> _engineTempReadings = [];
  List<SensorReading> _speedReadings = [];
  
  bool _isLoading = true;

  // Real-time subscription
  StreamSubscription<List<Map<String, dynamic>>>? _sensorSubscription;

  @override
  void initState() {
    super.initState();
    _currentVehicle = widget.vehicle;
    _loadChartData();
  }

  // Fetch historical data, then start real-time stream
  Future<void> _loadChartData() async {
    final results = await Future.wait([
      _vehicleService.getAlcoholHistory(widget.vehicle.id),
      _vehicleService.getEngineTempReadings(widget.vehicle.id),
      _vehicleService.getSpeedReadings(widget.vehicle.id),
    ]);

    if (mounted) {
      setState(() {
        _alcoholHistory = results[0] as List<Map<String, dynamic>>;
        _engineTempReadings = results[1] as List<SensorReading>;
        _speedReadings = results[2] as List<SensorReading>;
        _isLoading = false;
      });
    }

    // Start real-time sensor stream for THIS vehicle
    _sensorSubscription = _vehicleService.getSensorDataStream().listen((sensorRows) {
      if (!mounted) return;

      final myReadings = sensorRows
          .where((row) => row['vehicle_id'] == widget.vehicle.id)
          .toList();

      if (myReadings.isEmpty) return;

      final latest = myReadings.first;
      // Alcohol is now a string from the Pi
      final alcohol = latest['alcohol_level'] as String? ?? _currentVehicle.alcoholLevel;
      final temp = (latest['engine_temperature'] as num?)?.toDouble() ?? _currentVehicle.engineTemp;
      final spd = (latest['speed'] as num?)?.toDouble() ?? _currentVehicle.speed;
      final lat = (latest['latitude'] as num?)?.toDouble() ?? _currentVehicle.latitude;
      final lon = (latest['longitude'] as num?)?.toDouble() ?? _currentVehicle.longitude;
      final timestamp = latest['created_at'] != null
          ? DateTime.parse(latest['created_at'])
          : DateTime.now();

      // Calculate updated status using string severity
      final severity = alcoholSeverityFromString(alcohol);
      VehicleStatus newStatus = VehicleStatus.healthy;
      if (severity == AlcoholSeverity.drunk ||
          severity == AlcoholSeverity.intoxicated ||
          temp > 100.0) {
        newStatus = VehicleStatus.critical;
      } else if (severity == AlcoholSeverity.light || temp > 90.0) {
        newStatus = VehicleStatus.warning;
      }

      setState(() {
        _currentVehicle = _currentVehicle.copyWith(
          alcoholLevel: alcohol,
          engineTemp: temp,
          speed: spd,
          latitude: lat,
          longitude: lon,
          lastReading: timestamp,
          status: newStatus,
        );

        // Prepend new alcohol entry to history log (keep last 20)
        _alcoholHistory = [
          {'created_at': timestamp.toIso8601String(), 'alcohol_level': alcohol},
          ..._alcoholHistory,
        ].take(20).toList();

        _engineTempReadings = [
          SensorReading(timestamp: timestamp, value: temp),
          ..._engineTempReadings,
        ].take(50).toList();

        _speedReadings = [
          SensorReading(timestamp: timestamp, value: spd),
          ..._speedReadings,
        ].take(50).toList();
      });
    });
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = _currentVehicle; // Use the live-updated vehicle
    
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
          
          // --- ALCOHOL LEVEL: string badge + recent readings log ---
          _AlcoholCard(
            vehicle: vehicle,
            history: _alcoholHistory,
          ),
          const SizedBox(height: 12),
          _SensorCard(
            title: 'Engine Temperature',
            value: '${vehicle.engineTemp.toStringAsFixed(1)} °C',
            threshold: '100 °C',
            color: LightModeColors.lightWarning,
            readings: _engineTempReadings,
          ),
          const SizedBox(height: 12),
          _SensorCard(
            title: 'Speed',
            value: '${vehicle.speed.toStringAsFixed(0)} km/h',
            threshold: '80 km/h',
            color: LightModeColors.lightSuccess,
            readings: _speedReadings,
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
// --- GPS TAB: REAL OSM IMPLEMENTATION ---
// --------------------------------------------------------
class _GPSTab extends StatefulWidget {
  final Vehicle vehicle;

  const _GPSTab({required this.vehicle});

  @override
  State<_GPSTab> createState() => _GPSTabState();
}

class _GPSTabState extends State<_GPSTab> {
  final MapController _mapController = MapController();
  final VehicleService _vehicleService = VehicleService();
  
  // Live-updating coordinates
  late double _latitude;
  late double _longitude;
  late DateTime _lastUpdated;

  // Real-time subscription
  StreamSubscription<List<Map<String, dynamic>>>? _sensorSubscription;
  
  // Goa center coordinates
  static const LatLng _goaCenter = LatLng(15.2993, 74.1240);
  
  // Goa bounds for restricting the map (approximate for OSM)
  static final LatLngBounds _goaBounds = LatLngBounds(
    const LatLng(14.8, 73.6),
    const LatLng(15.8, 74.5),
  );

  @override
  void initState() {
    super.initState();
    _latitude = widget.vehicle.latitude;
    _longitude = widget.vehicle.longitude;
    _lastUpdated = widget.vehicle.lastReading;
    _startRealtimeStream();
  }

  void _startRealtimeStream() {
    _sensorSubscription = _vehicleService.getSensorDataStream().listen((sensorRows) {
      if (!mounted) return;

      // Find the latest reading for this specific vehicle
      final myReadings = sensorRows
          .where((row) => row['vehicle_id'] == widget.vehicle.id)
          .toList();

      if (myReadings.isEmpty) return;

      final latest = myReadings.first; // First = newest (ordered DESC)
      final newLat = (latest['latitude'] as num?)?.toDouble();
      final newLon = (latest['longitude'] as num?)?.toDouble();

      // Only update if we got real coordinate data
      if (newLat == null && newLon == null) return;

      final lat = newLat ?? _latitude;
      final lon = newLon ?? _longitude;

      // Skip update if coordinates haven't changed
      if (lat == _latitude && lon == _longitude) return;

      setState(() {
        _latitude = lat;
        _longitude = lon;
        _lastUpdated = latest['created_at'] != null
            ? DateTime.parse(latest['created_at'])
            : DateTime.now();
      });

      // Animate map camera to new position
      if (lat != 0.0 || lon != 0.0) {
        try {
          _mapController.move(LatLng(lat, lon), _mapController.camera.zoom);
        } catch (_) {
          // Map controller might not be ready yet
        }
      }
    });
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  LatLng get _vehicleLocation {
    if (_latitude != 0.0 || _longitude != 0.0) {
      return LatLng(_latitude, _longitude);
    }
    return _goaCenter;
  }

  bool get _hasRealData => _latitude != 0.0 || _longitude != 0.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Map container
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _vehicleLocation,
              initialZoom: 12.0,
              minZoom: 8.0,
              maxZoom: 18.0,
              cameraConstraint: CameraConstraint.contain(
                bounds: _goaBounds,
              ),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.fleetwise',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _vehicleLocation,
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.location_on,
                      size: 40,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Info card at bottom
        SafeArea(
          top: false,
          child: Container(
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
                      _hasRealData ? Icons.gps_fixed : Icons.gps_off,
                      size: 20,
                      color: _hasRealData ? Colors.green : theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _hasRealData ? 'Live Location' : 'GPS Data Pending',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_hasRealData)
                      Icon(Icons.circle, size: 8, color: Colors.green.shade400),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _hasRealData
                      ? '${_latitude.toStringAsFixed(4)}° N, ${_longitude.toStringAsFixed(4)}° E'
                      : 'GPS data from IoT module (Phase 2)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
                if (_hasRealData) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Updated: ${_lastUpdated.day}/${_lastUpdated.month}/${_lastUpdated.year} ${_lastUpdated.hour}:${_lastUpdated.minute.toString().padLeft(2, '0')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary.withAlpha(153),
                    ),
                  ),
                ],
              ],
            ),
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

// --------------------------------------------------------
// --- ALCOHOL CARD: STRING LABEL + RECENT READINGS LOG ---
// --------------------------------------------------------
class _AlcoholCard extends StatelessWidget {
  final Vehicle vehicle;
  final List<Map<String, dynamic>> history;

  const _AlcoholCard({required this.vehicle, required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severity = vehicle.alcoholSeverity;

    // Choose color based on severity
    final Color badgeColor;
    final Color badgeBg;
    switch (severity) {
      case AlcoholSeverity.light:
        badgeColor = Colors.orange.shade800;
        badgeBg = Colors.orange.shade50;
        break;
      case AlcoholSeverity.drunk:
        badgeColor = Colors.red.shade700;
        badgeBg = Colors.red.shade50;
        break;
      case AlcoholSeverity.intoxicated:
        badgeColor = Colors.red.shade900;
        badgeBg = Colors.red.shade100;
        break;
      case AlcoholSeverity.sober:
        badgeColor = Colors.green.shade700;
        badgeBg = Colors.green.shade50;
        break;
    }

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
            'Alcohol Level',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 12),
          // Current reading badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_bar_rounded, color: badgeColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      vehicle.alcoholLevel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Live',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          // Recent readings log
          if (history.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Recent Readings',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            ...history.take(5).map((row) {
              final label = row['alcohol_level'] as String? ?? 'Sober';
              final ts = row['created_at'] != null
                  ? DateTime.tryParse(row['created_at'])
                  : null;
              final timeStr = ts != null
                  ? '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}'
                  : '--:--';
              final sev = alcoholSeverityFromString(label);
              final Color dotColor;
              switch (sev) {
                case AlcoholSeverity.light:
                  dotColor = Colors.orange;
                  break;
                case AlcoholSeverity.drunk:
                case AlcoholSeverity.intoxicated:
                  dotColor = Colors.red;
                  break;
                case AlcoholSeverity.sober:
                  dotColor = Colors.green;
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text(timeStr, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}