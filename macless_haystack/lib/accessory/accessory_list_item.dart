import 'package:universal_io/io.dart';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:macless_haystack/accessory/accessory_icon.dart';
import 'package:macless_haystack/accessory/accessory_model.dart';
import 'package:intl/intl.dart';

import 'accessory_battery.dart';

class AccessoryListItem extends StatelessWidget {
  /// The accessory to display the information for.
  final Accessory accessory;

  /// A trailing distance information widget.
  final Widget? distance;

  /// Address information about the accessories location.
  final Placemark? herePlace;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// Displays the location of an accessory as a concise list item.
  ///
  /// Shows the icon and name of the accessory, as well as the current
  /// location and distance to the user's location (if known; `distance != null`)
  const AccessoryListItem({
    super.key,
    required this.accessory,
    required this.onTap,
    this.onLongPress,
    this.distance,
    this.herePlace,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Placemark?>(
      future: accessory.place,
      builder: (BuildContext context, AsyncSnapshot<Placemark?> snapshot) {
        // Format the location of the accessory. Use in this order:
        //   * Address if known
        //   * Coordinates (latitude & longitude) if known
        //   * `Unknown` if unknown
        String locationString = accessory.lastLocation != null
            ? '${accessory.lastLocation!.latitude.toStringAsFixed(4)}, ${accessory.lastLocation!.longitude.toStringAsFixed(4)}'
            : 'Unknown';
        if (snapshot.hasData && snapshot.data != null) {
          Placemark place = snapshot.data!;
          locationString = '${place.locality}, ${place.administrativeArea}';
          if (herePlace != null && herePlace!.country != place.country) {
            locationString = '${place.locality}, ${place.country}';
          }
        }
        // Format published date in a human readable way
        String? dateString = accessory.datePublished != null &&
                accessory.datePublished != DateTime(1970)
            ? ' · ${DateFormat.yMMMd(Platform.localeName).format(accessory.datePublished!)} ${DateFormat.jm(Platform.localeName).format(accessory.datePublished!)}'
            : '';
        return ListTile(
          onTap: onTap,
          onLongPress: onLongPress,
          title: Text(
            accessory.name + (accessory.isActive ? '' : ' (inactive)'),
            style: TextStyle(
              color: accessory.isActive
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).disabledColor,
            ),
          ),
          subtitle: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(locationString + dateString),
              const SizedBox(width: 5),
              buildIcon(),
            ],
          ),
          trailing: distance,
          dense: true,
          leading: accessory.isLoadingReports
              ? Padding(
                  padding: EdgeInsets.all(iconSize / 4),
                  child: SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: iconSize / 6,
                    ),
                  ))
              : AccessoryIcon(
                  icon: accessory.icon,
                  color: accessory.color,
                ),
        );
      },
    );
  }

  Widget buildIcon() {
    switch (accessory.lastBatteryStatus) {
      case AccessoryBatteryStatus.ok:
        return const Icon(Icons.battery_full, color: Colors.green, size: 15);
      case AccessoryBatteryStatus.medium:
        return const Icon(Icons.battery_3_bar, color: Colors.orange, size: 15);
      case AccessoryBatteryStatus.low:
        return const Icon(Icons.battery_1_bar, color: Colors.red, size: 15);
      case AccessoryBatteryStatus.criticalLow:
        return const Icon(Icons.battery_alert, color: Colors.red, size: 15);
      default:
        return const SizedBox(width: 15);
    }
  }
}
