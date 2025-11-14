// lib/screens/alerts_screen.dart

import 'package:flutter/material.dart';
import 'package:fleetwise/models/alert.dart';
import 'package:fleetwise/services/alert_service.dart';
import 'package:fleetwise/widgets/status_badge.dart';
import 'package:fleetwise/widgets/empty_state.dart';
import 'package:fleetwise/screens/alert_detail_screen.dart';
import 'package:fleetwise/theme.dart';

class AlertsScreen extends StatefulWidget {
  // ✅ ADDED: Callback to notify the parent/main screen to refresh the count
  final VoidCallback? onAlertCountChanged;

  const AlertsScreen({super.key, this.onAlertCountChanged});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Alert> _alerts = [];
  
  @override
  void initState() {
    super.initState();
    _fetchCriticalAlerts();
  }

  void _fetchCriticalAlerts() {
    final allAlerts = AlertService.getMockAlerts();
    _alerts = allAlerts
        .where((a) => a.severity == AlertSeverity.critical && !a.acknowledged)
        .toList();
  }

  void _navigateToDetail(Alert alert) async {
    final bool? wasAcknowledged = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AlertDetailScreen(alert: alert),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );

    if (wasAcknowledged == true) {
      setState(() {
        _alerts.removeWhere((a) => a.id == alert.id);
      });
      
      // ✅ TRIGGER CALLBACK: Notify the MainNavigationScreen to rebuild the Fleet tab
      widget.onAlertCountChanged?.call(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          Expanded(
            child: _alerts.isEmpty
              ? const EmptyState(
                  icon: Icons.notifications_outlined,
                  message: 'No active alerts', 
                  subtitle: 'Everything\'s running smoothly!',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _alerts.length,
                  itemBuilder: (context, index) {
                    final alert = _alerts[index];
                    return _AlertCard(
                      alert: alert,
                      onTap: () => _navigateToDetail(alert),
                    );
                  },
                ),
          ),
        ],
      );
  }
}

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
          color: alert.acknowledged
            ? theme.cardTheme.color
            : _getSeverityColor(alert.severity).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: alert.acknowledged
              ? Colors.transparent
              : _getSeverityColor(alert.severity).withOpacity(0.2),
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
                          alert.vehicleName,
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