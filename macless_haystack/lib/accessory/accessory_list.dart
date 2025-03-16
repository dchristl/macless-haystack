import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:macless_haystack/accessory/accessory_list_item.dart';
import 'package:macless_haystack/accessory/accessory_list_item_placeholder.dart';
import 'package:macless_haystack/accessory/accessory_registry.dart';
import 'package:macless_haystack/accessory/no_accessories.dart';
import 'package:macless_haystack/history/accessory_history.dart';
import 'package:macless_haystack/location/location_model.dart';

import '../callbacks.dart';
import 'accessory_model.dart';

class AccessoryList extends StatefulWidget {
  final LoadLocationUpdatesCallback loadLocationUpdates;
  final SaveOrderUpdatesCallback saveOrderUpdatesCallback;
  final void Function(LatLng point)? centerOnPoint;

  /// Display a location overview all accessories in a concise list form.
  ///
  /// For each accessory the name and last known locaiton information is shown.
  /// Uses the accessories in the [AccessoryRegistry].
  const AccessoryList({
    super.key,
    required this.loadLocationUpdates,
    this.centerOnPoint,
    required this.saveOrderUpdatesCallback,
  });

  @override
  State<StatefulWidget> createState() {
    return _AccessoryListState();
  }
}

class _AccessoryListState extends State<AccessoryList> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<AccessoryRegistry, LocationModel>(
      builder: (context, accessoryRegistry, locationModel, child) {
        var accessories = accessoryRegistry.accessories;

        // Show placeholder while accessories are loading
        if (accessoryRegistry.loading) {
          return LayoutBuilder(builder: (context, constraints) {
            // Show as many accessory placeholder fitting into the vertical space.
            // Minimum one, maximum 6 placeholders
            var nrOfEntries =
                min(max((constraints.maxHeight / 64).floor(), 1), 6);
            List<Widget> placeholderList = [];
            for (int i = 0; i < nrOfEntries; i++) {
              placeholderList.add(const AccessoryListItemPlaceholder());
            }
            return Scrollbar(
              child: ListView(
                children: placeholderList,
              ),
            );
          });
        }

        if (accessories.isEmpty) {
          return const NoAccessoriesPlaceholder();
        }
        // Use pull to refresh method
        return SlidableAutoCloseBehavior(
          child: Scrollbar(
            child: ReorderableListView(
              onReorder: (int oldIndex, int newIndex) {
                List<Accessory> copiedList = List.from(accessories);
                final accessory = copiedList.removeAt(oldIndex);
                if (copiedList.length < newIndex) {
                  copiedList.add(accessory);
                } else {
                  copiedList.insert(newIndex, accessory);
                }
                setState(() {
                  widget.saveOrderUpdatesCallback(copiedList);
                });
              },
              children: accessories.map((accessory) {
                // Calculate distance from users devices location
                Widget? trailing;
                if (locationModel.here != null &&
                    accessory.lastLocation != null) {
                  const Distance distance = Distance();
                  final double km = distance.as(LengthUnit.Kilometer,
                      locationModel.here!, accessory.lastLocation!);
                  trailing = Text('$km km');
                }
                // Get human readable location
                return Slidable(
                  key: ValueKey(accessory),
                  startActionPane: !accessory.isActive
                      ? null
                      : ActionPane(
                          key: ValueKey(accessory),
                          motion: const ScrollMotion(),
                          dragDismissible: false,
                          children: [
                              SlidableAction(
                                onPressed: (context) async {
                                  await widget.loadLocationUpdates(accessory);
                                },
                                foregroundColor: Theme.of(context).primaryColor,
                                icon: Icons.refresh,
                                label: 'Refresh',
                              ),
                            ]),
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    children: [
                      if (accessory.isActive)
                        SlidableAction(
                          onPressed: (context) async {
                            if (accessory.lastLocation != null &&
                                accessory.isActive) {
                              var loc = accessory.lastLocation!;
                              await MapsLauncher.launchCoordinates(
                                  loc.latitude, loc.longitude, accessory.name);
                            }
                          },
                          foregroundColor: Theme.of(context).primaryColor,
                          icon: Icons.directions,
                          label: 'Navigate',
                        ),
                      if (accessory.isActive)
                        SlidableAction(
                          onPressed: (context) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AccessoryHistory(
                                        accessory: accessory,
                                      )),
                            );
                          },
                          backgroundColor: Theme.of(context).primaryColor,
                          icon: Icons.history,
                          label: 'History',
                        ),
                      if (!accessory.isActive)
                        SlidableAction(
                          onPressed: (context) {
                            var accessoryRegistry =
                                Provider.of<AccessoryRegistry>(context,
                                    listen: false);
                            var newAccessory = accessory.clone();
                            newAccessory.isActive = true;
                            accessoryRegistry.editAccessory(
                                accessory, newAccessory);
                          },
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          icon: Icons.toggle_on_outlined,
                          label: 'Activate',
                        ),
                    ],
                  ),
                  child: Builder(builder: (context) {
                    return AccessoryListItem(
                      accessory: accessory,
                      distance: trailing,
                      herePlace: locationModel.herePlace,
                      onTap: () {
                        if (accessory.isActive) {
                          var lastLocation = accessory.lastLocation;
                          if (lastLocation != null) {
                            widget.centerOnPoint?.call(lastLocation);
                          }
                        }
                      },
                      onLongPress: !accessory.isActive
                          ? null
                          : () async {
                              await widget.loadLocationUpdates(accessory);
                            },
                    );
                  }),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
