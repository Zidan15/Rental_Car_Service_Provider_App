import 'package:flutter/material.dart';
import 'package:fleetwise/models/alert.dart';
import 'package:fleetwise/services/alert_service.dart';

class AlertDetailScreen extends StatelessWidget {
  final Alert alert;

  const AlertDetailScreen({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailItem(label: 'Vehicle', value: alert.vehicleName),
            const SizedBox(height: 16),
            _DetailItem(
              label: 'Current Reading',
              value: '${alert.reading.toStringAsFixed(2)} ${_getUnit(alert.sensorType)}',
            ),
            const SizedBox(height: 16),
            _DetailItem(
              label: 'Timestamp',
              value: _formatDateTime(alert.timestamp),
            ),
            const SizedBox(height: 32),
            // CONDITIONAL BUTTON: Only show if the alert is NOT already acknowledged
            if (!alert.acknowledged)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // 1. Call service to mark the alert as acknowledged globally
                    await AlertService().acknowledgeAlert(alert.id); 
                    
                    if (context.mounted) {
                      // 2. Pop the screen and pass 'true' to signal the list needs refreshing
                      Navigator.of(context).pop(true);
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Acknowledge Alert'),
                ),
              ),
            // Show a message if already acknowledged
            if (alert.acknowledged)
               Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    'This alert has been acknowledged.',
                    style: TextStyle(color: theme.colorScheme.secondary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getUnit(String sensorType) {
    return '%';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}