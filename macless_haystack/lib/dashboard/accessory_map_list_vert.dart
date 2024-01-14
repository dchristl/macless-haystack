import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:provider/provider.dart';
import 'package:macless_haystack/accessory/accessory_list.dart';
import 'package:macless_haystack/accessory/accessory_registry.dart';
import 'package:macless_haystack/location/location_model.dart';
import 'package:macless_haystack/map/map.dart';
import 'package:latlong2/latlong.dart';

class AccessoryMapListVertical extends StatefulWidget {
  final AsyncCallback loadLocationUpdates;

  /// Displays a map view and the accessory list in a vertical alignment.
  const AccessoryMapListVertical({
    Key? key,
    required this.loadLocationUpdates,
  }) : super(key: key);

  @override
  State<AccessoryMapListVertical> createState() =>
      _AccessoryMapListVerticalState();
}

class _AccessoryMapListVerticalState extends State<AccessoryMapListVertical> {
  final MapController _mapController = MapController();

  void _centerPoint(LatLng point) {
    _mapController
      ..fitCamera(CameraFit.bounds(bounds: LatLngBounds.fromPoints([point])))
      ..move(_mapController.camera.center, _mapController.camera.zoom + 0.00001);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AccessoryRegistry, LocationModel>(
      builder: (BuildContext context, AccessoryRegistry accessoryRegistry,
          LocationModel locationModel, Widget? child) {
        return Column(
          children: [
            Flexible(
              fit: FlexFit.tight,
              child: AccessoryMap(
                mapController: _mapController,
              ),
            ),
            Flexible(
              fit: FlexFit.tight,
              child: AccessoryList(
                loadLocationUpdates: widget.loadLocationUpdates,
                centerOnPoint: _centerPoint,
              ),
            ),
          ],
        );
      },
    );
  }
}
