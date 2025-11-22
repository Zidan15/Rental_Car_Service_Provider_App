// lib/screens/alerts_screen.dart

import 'package:flutter/material.dart';
import 'package:fleetwise/models/alert.dart';
import 'package:fleetwise/services/alert_service.dart';
import 'package:fleetwise/widgets/status_badge.dart';
import 'package:fleetwise/widgets/empty_state.dart';
import 'package:fleetwise/screens/alert_detail_screen.dart';

class AlertsScreen extends StatefulWidget {
  final VoidCallback? onAlertCountChanged;

  const AlertsScreen({super.key, this.onAlertCountChanged});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final AlertService _alertService = AlertService(); // Instance of service
  
  // We no longer need local state for alerts list because StreamBuilder handles it.

  void _navigateToDetail(Alert alert) async {
    // We don't need to check _isLoading here because the stream handles data availability
    
    final bool? wasAcknowledged = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AlertDetailScreen(alert: alert),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );

    if (wasAcknowledged == true) {
      // With StreamBuilder, we don't need to manually refresh! 
      // The delete operation in the database will automatically trigger a new stream event.
      
      // We might still want to notify the parent to update the badge
      widget.onAlertCountChanged?.call(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Alert>>(
      stream: _alertService.getAlertsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allAlerts = snapshot.data ?? [];
        // Filter locally if needed, though the stream could also filter.
        // The user wants to see active alerts.
        final activeAlerts = allAlerts.where((a) => !a.acknowledged).toList();

        if (activeAlerts.isEmpty) {
          return const Column(
            children: [
              Expanded(
                child: EmptyState(
                  icon: Icons.notifications_outlined,
                  message: 'No active alerts', 
                  subtitle: 'Everything\'s running smoothly!',
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: activeAlerts.length,
                itemBuilder: (context, index) {
                  final alert = activeAlerts[index];
                  return _AlertCard(
                    alert: alert,
                    onTap: () => _navigateToDetail(alert),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// --------------------------------------------------------
// --- AlertCard and Helper Functions remain unchanged ---
// --------------------------------------------------------

class _AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback onTap;

  const _AlertCard({required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeAgo = _formatTimeAgo(alert.timestamp);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Logic for acknowledged/unacknowledged color remains the same
          color: alert.acknowledged
            ? theme.cardTheme.color
            : _getSeverityColor(alert.severity).withAlpha(13),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: alert.acknowledged
              ? Colors.transparent
              : _getSeverityColor(alert.severity).withAlpha(51),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: _getSeverityColor(alert.severity),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.vehicleName, // This uses the enriched name from the service
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      StatusBadge(alertSeverity: alert.severity),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    alert.sensorType,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary.withAlpha(179),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.secondary.withAlpha(102),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red; 
      case AlertSeverity.warning:
        return Colors.orange; 
      case AlertSeverity.info:
        return Colors.blue;
    }
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