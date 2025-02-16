
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:universal_io/io.dart';

class LocationPopup extends Marker {
  /// The location to display.
  final LatLng location;

  /// The time stamp the location was recorded.
  final DateTime time;
  final DateTime end;
  final BuildContext ctx;

  /// Displays a small popup window with the coordinates at [location] and
  /// the [time] in a human readable format.
  LocationPopup(
      {super.key,
      required this.location,
      required this.time,
      required this.end,
      required this.ctx})
      : super(
          width: 250,
          height: 150,
          point: location,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: InkWell(
              onTap: () {
                /* NOOP */
              },
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                        child: Center(
                            child: Text(
                      '${DateFormat.Md(Platform.localeName).format(time)} ${DateFormat.jm(Platform.localeName).format(time)} - ${DateFormat.Md(Platform.localeName).format(end)} ${DateFormat.jm(Platform.localeName).format(end)}',
                    ))),
                    Expanded(
                        child: Center(
                            child: Text(
                      'Lat: ${location.round(decimals: 2).latitude}, '
                      'Lng: ${location.round(decimals: 2).longitude}',
                    ))),
                  ],
                ),
              ),
            ),
          ),
          rotate: true,
        );
}
