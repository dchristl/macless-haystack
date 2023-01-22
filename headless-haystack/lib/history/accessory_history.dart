import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:openhaystack_mobile/accessory/accessory_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:openhaystack_mobile/history/days_selection_slider.dart';
import 'package:openhaystack_mobile/history/location_popup.dart';

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
  Pair<LatLng, DateTime>? popupEntry;

  double numberOfDays = 7;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mapReady();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter for the locations after the specified cutoff date (now - number of days)
    var now = DateTime.now();
    List<Pair<LatLng, DateTime>> locationHistory =
        widget.accessory.locationHistory
            .where(
              (element) => element.b.isAfter(
                now.subtract(Duration(days: numberOfDays.round())),
              ),
            )
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.accessory.name),
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
                  center: LatLng(49.874739, 8.656280),
                  // onMapReady: mapReady,
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
                        points:
                            locationHistory.map((entry) => entry.a).toList(),
                        strokeWidth: 4,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                  // The markers for the historic locations
                  MarkerLayer(
                    markers: locationHistory
                        .map((entry) => Marker(
                              point: entry.a,
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
                          location: popupEntry!.a,
                          time: popupEntry!.b,
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
                numberOfDays: numberOfDays,
                onChanged: (double newValue) {
                  setState(() {
                    numberOfDays = newValue;
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
      var historicLocations =
          widget.accessory.locationHistory.map((entry) => entry.a).toList();
      var bounds = LatLngBounds.fromPoints(historicLocations);
      _mapController.fitBounds(bounds);
    }
  }
}
