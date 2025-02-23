import 'package:universal_io/io.dart';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:macless_haystack/accessory/accessory_icon.dart';
import 'package:macless_haystack/accessory/accessory_model.dart';
import 'package:intl/intl.dart';

import 'accessory_battery.dart';

class AccessoryListItem extends StatefulWidget {
  final Accessory accessory;
  final Widget? distance;
  final Placemark? herePlace;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const AccessoryListItem({
    super.key,
    required this.accessory,
    required this.onTap,
    this.onLongPress,
    this.distance,
    this.herePlace,
  });

  @override
  AccessoryListItemState createState() => AccessoryListItemState();
}

class AccessoryListItemState extends State<AccessoryListItem> {
  Color _tileColor = Colors.transparent;

  @override
  Widget build(BuildContext context) {
    var hasChanged = widget.accessory.hasChangedFlag;
    if (hasChanged) {
      _tileColor = widget.accessory.color.withAlpha(50);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          widget.accessory.hasChangedFlag = false;
          setState(() {
            _tileColor = Colors.transparent;
          });
        }
      });
    }
    return FutureBuilder<Placemark?>(
      future: widget.accessory.place,
      builder: (BuildContext context, AsyncSnapshot<Placemark?> snapshot) {
        String locationString = widget.accessory.lastLocation != null
            ? '${widget.accessory.lastLocation!.latitude.toStringAsFixed(4)}, ${widget.accessory.lastLocation!.longitude.toStringAsFixed(4)}'
            : 'Unknown';

        if (snapshot.hasData && snapshot.data != null) {
          Placemark place = snapshot.data!;
          locationString = '${place.locality}, ${place.administrativeArea}';
          if (widget.herePlace != null &&
              widget.herePlace!.country != place.country) {
            locationString = '${place.locality}, ${place.country}';
          }
        }
        // Format published date in a human readable way
        String? dateString = widget.accessory.datePublished != null &&
            widget.accessory.datePublished != DateTime(1970)
            ? '\n${DateFormat.yMMMd(Platform.localeName).format(widget.accessory.datePublished!)} ${DateFormat.jm(Platform.localeName).format(widget.accessory.datePublished!)}'
            : '';

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300), // Sanfter Übergang
          color: _tileColor,
          child: ListTile(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.accessory.name +
                      (widget.accessory.isActive ? '' : ' (inactive)'),
                  style: TextStyle(
                    color: widget.accessory.isActive
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).disabledColor,
                  ),
                ),
                const SizedBox(width: 5),
                _buildIcon(),
              ],
            ),
            subtitle: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Text(locationString + dateString),
            ),
            trailing: widget.distance,
            dense: true,
            leading: AccessoryIcon(
              icon: widget.accessory.icon,
              color: widget.accessory.color,
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcon() {
    switch (widget.accessory.lastBatteryStatus) {
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
