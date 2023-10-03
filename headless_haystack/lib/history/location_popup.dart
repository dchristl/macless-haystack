import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

class LocationPopup extends Marker {
  /// The location to display.
  LatLng location;

  /// The time stamp the location was recorded.
  DateTime time;
  DateTime end;

  /// Displays a small popup window with the coordinates at [location] and
  /// the [time] in a human readable format.
  LocationPopup({
    Key? key,
    required this.location,
    required this.time,
    required this.end,
  }) : super(
          key: key,
          width: 200,
          height: 150,
          point: location,
          builder: (ctx) => Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: InkWell(
              onTap: () {
                /* NOOP */
              },
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text(
                        '${DateFormat('MM/dd H:mm',
                                    Localizations.localeOf(ctx).toString())
                                .format(time.toLocal())} - ${DateFormat('MM/dd H:mm',
                                    Localizations.localeOf(ctx).toString())
                                .format(end.toLocal())}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Lat: ${location.round(decimals: 2).latitude}, '
                        'Lng: ${location.round(decimals: 2).longitude}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          rotate: true,
        );
}
