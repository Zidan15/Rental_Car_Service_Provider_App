// lib/screens/vehicle_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:fleetwise/models/vehicle.dart';
import 'package:fleetwise/models/sensor_reading.dart';
import 'package:fleetwise/widgets/status_badge.dart';
import 'package:fleetwise/widgets/sparkline_chart.dart';
import 'package:fleetwise/theme.dart';

class VehicleDetailScreen extends StatelessWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      // Increased length to 4 for the new GPS tab
      length: 4, 
      child: Scaffold(
        appBar: AppBar(
          title: Text(vehicle.displayName),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.secondary,
            labelPadding: const EdgeInsets.symmetric(horizontal: 20),
            tabs: const [
              Tab(text: 'OVERVIEW'),
              Tab(text: 'DASHCAM'),
              Tab(text: 'INTERNAL CAM'),
              // ADDED GPS Tab
              Tab(text: 'GPS'), 
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(vehicle: vehicle),
            _PlaceholderTab(message: 'Dashcam footage will appear here'),
            _PlaceholderTab(message: 'Internal camera footage will appear here'),
            // ADDED GPS Tab View
            _GPSTab(vehicle: vehicle), 
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Vehicle vehicle;

  const _OverviewTab({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          _SensorCard(
            title: 'Alcohol Level',
            value: '${vehicle.alcoholLevel?.toStringAsFixed(2) ?? "N/A"} %',
            threshold: '0.08 %',
            color: LightModeColors.lightCritical,
            readings: vehicle.alcoholReadings,
          ),
          const SizedBox(height: 12),
          _SensorCard(
            title: 'Fuel Level',
            value: '${vehicle.engineTemp?.toStringAsFixed(1) ?? "N/A"} °C',
            threshold: '10l',
            color: LightModeColors.lightWarning,
            readings: vehicle.engineTempReadings,
          ),
          // ✅ GPS SENSOR CARD IS REMOVED FROM HERE
          /*
          const SizedBox(height: 12),
          _SensorCard(
            title: 'GPS',
            value: '${vehicle.batteryVoltage?.toStringAsFixed(1) ?? "N/A"} V',
            threshold: '12.0 V',
            color: Colors.blue,
            readings: vehicle.batteryReadings,
          ),
          */
          const SizedBox(height: 12),
          _SensorCard(
            title: 'Speed',
            value: '${vehicle.speed?.toStringAsFixed(0) ?? "N/A"} km/h',
            threshold: '80 km/h',
            color: LightModeColors.lightSuccess,
            readings: vehicle.speedReadings,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// GPS TAB WIDGET (Contains only the map placeholder)
class _GPSTab extends StatelessWidget {
  final Vehicle vehicle;

  const _GPSTab({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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
                  Icon(
                    Icons.location_on,
                    size: 60,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Live Map Placeholder',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last known location: 15.35° N, 74.01° E (Goa)',
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


class _PlaceholderTab extends StatelessWidget {
  final String message;

  const _PlaceholderTab({required this.message});

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
  final List<dynamic> readings;

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
          /*const SizedBox(height: 16),
          SparklineChart(
            data: readings.cast<SensorReading>(),
            color: color,
            height: 80,
          ),*/
        ],
      ),
    );
  }
}