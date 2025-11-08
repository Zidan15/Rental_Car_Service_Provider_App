import 'package:flutter/material.dart';
import 'package:fleetwise/models/vehicle.dart';
import 'package:fleetwise/models/alert.dart';
import 'package:fleetwise/theme.dart';

class StatusBadge extends StatelessWidget {
  final VehicleStatus? vehicleStatus;
  final AlertSeverity? alertSeverity;

  const StatusBadge({
    super.key,
    this.vehicleStatus,
    this.alertSeverity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color bgColor;
    Color textColor;
    String text;
    String emoji;

    if (vehicleStatus != null) {
      switch (vehicleStatus!) {
        case VehicleStatus.healthy:
          bgColor = LightModeColors.lightSuccess.withValues(alpha: 0.1);
          textColor = LightModeColors.lightSuccess;
          text = 'Healthy';
          emoji = '🟢';
        case VehicleStatus.warning:
          bgColor = LightModeColors.lightWarning.withValues(alpha: 0.1);
          textColor = LightModeColors.lightWarning;
          text = 'Warning';
          emoji = '🟡';
        case VehicleStatus.critical:
          bgColor = LightModeColors.lightCritical.withValues(alpha: 0.1);
          textColor = LightModeColors.lightCritical;
          text = 'Critical';
          emoji = '🔴';
      }
    } else {
      switch (alertSeverity!) {
        case AlertSeverity.info:
          bgColor = Colors.blue.withValues(alpha: 0.1);
          textColor = Colors.blue;
          text = 'Info';
          emoji = '🟢';
        case AlertSeverity.warning:
          bgColor = LightModeColors.lightWarning.withValues(alpha: 0.1);
          textColor = LightModeColors.lightWarning;
          text = 'Warning';
          emoji = '🟡';
        case AlertSeverity.critical:
          bgColor = LightModeColors.lightCritical.withValues(alpha: 0.1);
          textColor = LightModeColors.lightCritical;
          text = 'Critical';
          emoji = '🔴';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
