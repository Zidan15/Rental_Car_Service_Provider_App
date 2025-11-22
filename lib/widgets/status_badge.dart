// lib/widgets/status_badge.dart
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
    
    // Non-nullable variables must be assigned a default value
    Color bgColor = Colors.transparent; 
    Color textColor = Colors.black;
    String text = '';
    String emoji = '❓';

    // 1. Vehicle Status Logic
    if (vehicleStatus != null) {
      switch (vehicleStatus!) {
        case VehicleStatus.healthy:
          bgColor = LightModeColors.lightSuccess.withAlpha(26);
          textColor = LightModeColors.lightSuccess;
          text = 'Healthy';
          emoji = '🟢';
          break; // Added break
        case VehicleStatus.warning:
          bgColor = LightModeColors.lightWarning.withAlpha(26);
          textColor = LightModeColors.lightWarning;
          text = 'Warning';
          emoji = '🟡';
          break; // Added break
        case VehicleStatus.critical:
          bgColor = LightModeColors.lightCritical.withAlpha(26);
          textColor = LightModeColors.lightCritical;
          text = 'Critical';
          emoji = '🔴';
          break; // Added break
      }
    } 
    // 2. Alert Severity Logic
    else if (alertSeverity != null) { // Added an 'else if' check
      switch (alertSeverity!) {
        case AlertSeverity.info:
          // NOTE: Your theme file likely defines LightModeColors.lightInfo
          // But using Colors.blue for now as a safe default
          bgColor = Colors.blue.withAlpha(26); 
          textColor = Colors.blue;
          text = 'Info';
          emoji = 'ℹ️'; // Changed emoji for Info
          break;
        case AlertSeverity.warning:
          bgColor = LightModeColors.lightWarning.withAlpha(26);
          textColor = LightModeColors.lightWarning;
          text = 'Warning';
          emoji = '🟡';
          break;
        case AlertSeverity.critical:
          bgColor = LightModeColors.lightCritical.withAlpha(26);
          textColor = LightModeColors.lightCritical;
          text = 'Critical';
          emoji = '🔴';
          break;
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