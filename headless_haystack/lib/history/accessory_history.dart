import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:headless_haystack/accessory/accessory_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:headless_haystack/history/days_selection_slider.dart';
import 'package:headless_haystack/history/location_popup.dart';

import '../preferences/user_preferences_model.dart';
import 'dart:math';
class AccessoryHistory extends StatefulWidget {
  final Accessory accessory;

  /// Shows previous locations of a specific [accessory] on a map.
  /// The locations are connected by a chronological line.
  /// The number of days to go back can be adjusted with a slider.
  const AccessoryHistory({
    Key? key,
    required this.accessory,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AccessoryHistoryState();
  }
}

class _AccessoryHistoryState extends State<AccessoryHistory> {
  late MapController _mapController;

  bool showPopup = false;
  Pair<dynamic, dynamic>? popupEntry;

  int numberOfDays = 7;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    DateTime latest = widget.accessory.latestHistoryEntry();
    numberOfDays = min(latest.difference(DateTime.now()).inDays + 1, numberOfDays);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mapReady();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter for the locations after the specified cutoff date (now - number of days)
    return Scaffold(
      appBar: AppBar(
        title: Text(
            "${widget.accessory.name} (${widget.accessory.locationHistory.length} history reports)"),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Flexible(
              flex: 3,
              fit: FlexFit.tight,
              child: FlutterMap(
                key: ValueKey(MediaQuery.of(context).orientation),
                mapController: _mapController,
                options: MapOptions(
                  center: const LatLng(51.1657, 10.4515),
                  maxZoom: 18.0,
                  minZoom: 2.0,
                  zoom: 13.0,
                  interactiveFlags: InteractiveFlag.pinchZoom |
                      InteractiveFlag.drag |
                      InteractiveFlag.doubleTapZoom |
                      InteractiveFlag.flingAnimation |
                      InteractiveFlag.pinchMove,
                  onTap: (_, __) {
                    setState(() {
                      showPopup = false;
                      popupEntry = null;
                    });
                  },
                ),
                children: [
                  TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      tileBuilder: (context, child, tile) {
                        var isDark =
                            (Theme.of(context).brightness == Brightness.dark);
                        return isDark
                            ? ColorFiltered(
                                colorFilter: const ColorFilter.matrix([
                                  -1,
                                  0,
                                  0,
                                  0,
                                  255,
                                  0,
                                  -1,
                                  0,
                                  0,
                                  255,
                                  0,
                                  0,
                                  -1,
                                  0,
                                  255,
                                  0,
                                  0,
                                  0,
                                  1,
                                  0,
                                ]),
                                child: child,
                              )
                            : child;
                      },
                      subdomains: const ['a', 'b', 'c']),
                  // The line connecting the locations chronologically
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: widget.accessory.locationHistory
                            .map((entry) => entry.location)
                            .toList(),
                        strokeWidth: 4,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                  // The markers for the historic locations
                  MarkerLayer(
                    markers: widget.accessory.locationHistory
                        .map((entry) => Marker(
                              point: entry.location,
                              builder: (ctx) => GestureDetector(
                                onTap: () {
                                  setState(() {
                                    showPopup = true;
                                    popupEntry = entry;
                                  });
                                },
                                child: Icon(
                                  Icons.circle,
                                  size: 15,
                                  color: entry == popupEntry
                                      ? Colors.red
                                      : Theme.of(context).indicatorColor,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  // Displays the tooltip if active
                  MarkerLayer(
                    markers: [
                      if (showPopup)
                        LocationPopup(
                          location: popupEntry!.location,
                          time: popupEntry!.start,
                          end: popupEntry!.end,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Flexible(
              flex: 1,
              fit: FlexFit.tight,
              child: DaysSelectionSlider(
                numberOfDays: numberOfDays.toDouble(),
                onChanged: (double newValue) {
                  setState(() {
                    numberOfDays = newValue as int;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  mapReady() {
    if (widget.accessory.locationHistory.isNotEmpty) {
      var historicLocations = widget.accessory.locationHistory
          .map((entry) => entry.location)
          .toList();
      var bounds = LatLngBounds.fromPoints(historicLocations);
      _mapController
        ..fitBounds(bounds)
        ..move(_mapController.center, _mapController.zoom + 0.00001);
    }
  }
}
