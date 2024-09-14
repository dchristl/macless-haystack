import 'package:flutter/material.dart';
import 'package:macless_haystack/accessory/accessory_battery.dart';
import 'package:macless_haystack/accessory/accessory_model.dart';

class AccessoryListItemBattery extends StatelessWidget {
  const AccessoryListItemBattery({super.key, required this.accessory});

  final Accessory accessory;

  @override
  Widget build(BuildContext context) {
    // Prepare battery icon
    Icon batteryIcon;
    String batteryStatusText;

    if (accessory.lastBatteryStatus == AccessoryBatteryStatus.ok) {
      batteryIcon = const Icon(Icons.battery_full, color: Colors.green);
      batteryStatusText = 'OK';
    } else if (accessory.lastBatteryStatus == AccessoryBatteryStatus.medium) {
      batteryIcon = const Icon(Icons.battery_3_bar, color: Colors.green);
      batteryStatusText = 'Medium';
    } else if (accessory.lastBatteryStatus == AccessoryBatteryStatus.low) {
      batteryIcon = const Icon(Icons.battery_1_bar, color: Colors.green);
      batteryStatusText = 'Low';
    } else if (accessory.lastBatteryStatus == AccessoryBatteryStatus.criticalLow) {
      batteryIcon = const Icon(Icons.battery_alert, color: Colors.red);
      batteryStatusText = 'Alert';
    } else {
      batteryIcon = const Icon(Icons.battery_alert, color: Colors.orange);
      batteryStatusText = 'Unknown';
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        batteryIcon,
        Text(batteryStatusText),
      ],
    );
  }
}
