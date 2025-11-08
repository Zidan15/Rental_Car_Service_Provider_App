import 'package:flutter/material.dart';
import 'package:fleetwise/models/alert.dart';
import 'package:fleetwise/services/alert_service.dart';
import 'package:fleetwise/widgets/status_badge.dart';
import 'package:fleetwise/widgets/empty_state.dart';
import 'package:fleetwise/screens/alert_detail_screen.dart';
import 'package:fleetwise/theme.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Alert> _alerts = [];
  bool _showBanner = true;

  @override
  void initState() {
    super.initState();
    // 1. Fetch all alerts.
    final allAlerts = AlertService.getMockAlerts();
    
    // 2. Filter the list to only include CRITICAL alerts.
    _alerts = allAlerts
        .where((a) => a.severity == AlertSeverity.critical)
        .toList();
  }

  void _navigateToDetail(Alert alert) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AlertDetailScreen(alert: alert),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unacknowledgedAlerts = _alerts.where((a) => !a.acknowledged).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ALERTS'),
      ),
      body: Column(
        children: [
          if (_showBanner && unacknowledgedAlerts.isNotEmpty)
            _AlertBanner(
              count: unacknowledgedAlerts.length,
              onDismiss: () => setState(() => _showBanner = false),
            ),
          Expanded(
            child: _alerts.isEmpty
              ? const EmptyState(
                  icon: Icons.notifications_outlined,
                  message: 'No alerts yet',
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
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final int count;
  final VoidCallback onDismiss;

  const _AlertBanner({required this.count, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LightModeColors.lightCritical.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: LightModeColors.lightCritical.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber,
            color: LightModeColors.lightCritical,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Alerts',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: LightModeColors.lightCritical,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You have $count unacknowledged alert${count > 1 ? 's' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            color: theme.colorScheme.secondary,
            onPressed: onDismiss,
          ),
        ],
      ),
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
            : _getSeverityColor(alert.severity).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: alert.acknowledged
              ? Colors.transparent
              : _getSeverityColor(alert.severity).withValues(alpha: 0.2),
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

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return LightModeColors.lightCritical;
      case AlertSeverity.warning:
        return LightModeColors.lightWarning;
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
