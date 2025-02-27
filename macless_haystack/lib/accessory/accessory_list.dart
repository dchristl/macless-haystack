import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:macless_haystack/accessory/accessory_model.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:macless_haystack/accessory/accessory_list_item.dart';
import 'package:macless_haystack/accessory/accessory_list_item_placeholder.dart';
import 'package:macless_haystack/accessory/accessory_registry.dart';
import 'package:macless_haystack/accessory/no_accessories.dart';
import 'package:macless_haystack/history/accessory_history.dart';
import 'package:macless_haystack/location/location_model.dart';
import 'package:visibility_detector/visibility_detector.dart';

class AccessoryList extends StatefulWidget {
  // final AsyncCallback loadLocationUpdates;
  final AsyncCallback loadVisibleItemsLocationUpdates;
  final AsyncValueSetter<Accessory> loadOneLocationUpdates;
  final void Function(LatLng point)? centerOnPoint;

  /// Display a location overview all accessories in a concise list form.
  ///
  /// For each accessory the name and last known locaiton information is shown.
  /// Uses the accessories in the [AccessoryRegistry].
  const AccessoryList({
    super.key,
    // required this.loadLocationUpdates,
    required this.loadVisibleItemsLocationUpdates,
    required this.loadOneLocationUpdates,
    this.centerOnPoint,
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
          child: RefreshIndicator(
            // onRefresh: widget.loadLocationUpdates,
            onRefresh: widget.loadVisibleItemsLocationUpdates,
            child: Scrollbar(
              child: ListView(
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
                                    loc.latitude,
                                    loc.longitude,
                                    accessory.name);
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
                      return VisibilityDetector(
                        key: Key('item_${accessory.id}'),
                        onVisibilityChanged: (visibilityInfo) {
                          final visiblePercentage =
                              visibilityInfo.visibleFraction;
                          if (visiblePercentage > 0) {
                            accessoryRegistry.visibleAccessories.add(accessory);
                          } else {
                            accessoryRegistry.visibleAccessories.remove(accessory);
                          }
                          if (accessory.isActive &&
                              visiblePercentage > 0 &&
                              mounted &&
                              !accessoryRegistry.loadedAccessoryIds.contains(accessory.id)) {
                            accessoryRegistry.loadedAccessoryIds.add(accessory.id);
                            widget.loadOneLocationUpdates(accessory);
                          }
                        },
                        child: AccessoryListItem(
                          accessory: accessory,
                          distance: trailing,
                          herePlace: locationModel.herePlace,
                          onTap: () {
                            var lastLocation = accessory.lastLocation;
                            if (lastLocation != null) {
                              widget.centerOnPoint?.call(lastLocation);
                            }
                          },
                          onLongPress: Slidable.of(context)?.openEndActionPane,
                        ),
                      );

                      /* return AccessoryListItem(
                        accessory: accessory,
                        distance: trailing,
                        herePlace: locationModel.herePlace,
                        onTap: () {
                          var lastLocation = accessory.lastLocation;
                          if (lastLocation != null) {
                            widget.centerOnPoint?.call(lastLocation);
                          }
                        },
                        onLongPress: Slidable.of(context)?.openEndActionPane,
                      ); */
                    }),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
