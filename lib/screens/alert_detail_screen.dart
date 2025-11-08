import 'package:flutter/material.dart';
import 'package:fleetwise/models/alert.dart';
import 'package:fleetwise/widgets/status_badge.dart';
import 'package:fleetwise/theme.dart';

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
            /*Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getSeverityColor(alert.severity).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getSeverityColor(alert.severity).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 64,
                    color: _getSeverityColor(alert.severity),
                  ),
                  const SizedBox(height: 16),
                  StatusBadge(alertSeverity: alert.severity),
                ],
              ),
            ),
            const SizedBox(height: 24),*/
            _DetailItem(label: 'Vehicle', value: alert.vehicleName),
            //const SizedBox(height: 16),
            //_DetailItem(label: 'Sensor Type', value: alert.sensorType),
            const SizedBox(height: 16),
            _DetailItem(
              label: 'Current Reading',
              value: '${alert.reading.toStringAsFixed(2)} ${_getUnit(alert.sensorType)}',
            ),
            /*const SizedBox(height: 16),
            _DetailItem(
              label: 'Threshold',
              value: '${alert.threshold.toStringAsFixed(2)} ${_getUnit(alert.sensorType)}',
            ),*/
            const SizedBox(height: 16),
            _DetailItem(
              label: 'Timestamp',
              value: _formatDateTime(alert.timestamp),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alert acknowledged (mock only)')),
                  );
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Acknowledge Alert'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /*Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return LightModeColors.lightCritical;
      case AlertSeverity.warning:
        return LightModeColors.lightWarning;
      case AlertSeverity.info:
        return Colors.blue;
    }
  }*/

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
