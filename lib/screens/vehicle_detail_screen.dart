// lib/screens/vehicle_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:fleetwise/models/vehicle.dart';
import 'package:fleetwise/models/sensor_reading.dart';
import 'package:fleetwise/services/vehicle_service.dart'; // New Import
import 'package:fleetwise/widgets/status_badge.dart';
// import 'package:fleetwise/widgets/sparkline_chart.dart'; // Uncomment when ready
import 'package:fleetwise/theme.dart';

class VehicleDetailScreen extends StatelessWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, 
      child: Scaffold(
        appBar: AppBar(
          title: Text(vehicle.displayName),
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
            // This is now the Stateful widget that fetches data
            _OverviewTab(vehicle: vehicle), 
            _PlaceholderTab(message: 'Dashcam footage will appear here'),
            _PlaceholderTab(message: 'Internal camera footage will appear here'),
            // This now uses the live GPS coordinates
            _GPSTab(vehicle: vehicle), 
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
        _alcoholReadings = results[0] as List<SensorReading>;
        _engineTempReadings = results[1] as List<SensorReading>;
        _speedReadings = results[2] as List<SensorReading>;
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
              _InfoItem(label: 'Fuel Type', value: vehicle.fuelType),
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
// --- GPS TAB: USING LIVE LAT/LON DATA ---
// --------------------------------------------------------
class _GPSTab extends StatelessWidget {
  final Vehicle vehicle;

  const _GPSTab({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Format the real lat/lon
    final String locationString = (vehicle.latitude == 0.0 && vehicle.longitude == 0.0)
      ? 'No GPS data available.'
      : 'Last known: ${vehicle.latitude.toStringAsFixed(4)}° N, ${vehicle.longitude.toStringAsFixed(4)}° E (Goa)';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Location',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.1)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 60,
                    color: Colors.black, // Assuming primary is dark
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Live Map Placeholder',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    locationString, // Uses the real data
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
              color: theme.colorScheme.secondary.withOpacity(0.3),
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