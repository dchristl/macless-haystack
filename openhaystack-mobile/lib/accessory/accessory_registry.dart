import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:openhaystack_mobile/accessory/accessory_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:openhaystack_mobile/findMy/find_my_controller.dart';
import 'package:openhaystack_mobile/findMy/models.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:openhaystack_mobile/preferences/user_preferences_model.dart';

const accessoryStorageKey = 'ACCESSORIES';

class AccessoryRegistry extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  List<Accessory> _accessories = [];
  bool loading = false;
  bool initialLoadFinished = false;

  var logger = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );

  /// Creates the accessory registry.
  ///
  /// This is used to manage the accessories of the user.
  AccessoryRegistry() : super();

  /// A list of the user's accessories.
  UnmodifiableListView<Accessory> get accessories =>
      UnmodifiableListView(_accessories);

  /// Loads the user's accessories from persistent storage.
  Future<void> loadAccessories() async {
    loading = true;

    String? serialized = await _storage.read(key: accessoryStorageKey);
    if (serialized != null) {
      List accessoryJson = json.decode(serialized);
      List<Accessory> loadedAccessories =
          accessoryJson.map((val) => Accessory.fromJson(val)).toList();
      _accessories = loadedAccessories;
    } else {
      _accessories = [];
    }

    // For Debugging:
    // await overwriteEverythingWithDemoDataForDebugging();

    loading = false;

    notifyListeners();
  }

  /// Fetches new location reports and matches them to their accessory.
  Future<void> loadLocationReports() async {
    List<Future<List<FindMyLocationReport>>> runningLocationRequests = [];

    // request location updates for all accessories simultaneously
    List<Accessory> currentAccessories = accessories;
    String? url = Settings.getValue<String>(haystackurl);
    for (var i = 0; i < currentAccessories.length; i++) {
      var accessory = currentAccessories.elementAt(i);

      var keyPair =
          await FindMyController.getKeyPair(accessory.hashedPublicKey);

      List<FindMyKeyPair> hashedPublicKeys =
          await Stream.fromIterable(accessory.additionalKeys)
              .asyncMap((hashedPublicKey) =>
                  FindMyController.getKeyPair(hashedPublicKey))
              .toList();

      hashedPublicKeys.add(keyPair);

      var locationRequest =
          FindMyController.computeResults(hashedPublicKeys, url);
      runningLocationRequests.add(locationRequest);
    }

    var reportsForAccessories = await Future.wait(runningLocationRequests);

    for (var i = 0; i < currentAccessories.length; i++) {
      var accessory = currentAccessories.elementAt(i);
      var reports = reportsForAccessories.elementAt(i);
      logger.i('${reports.length} reports fetched for $accessory overall');
      accessory.locationHistory = reports
          .where((report) =>
              report.latitude.abs() <= 90 && report.longitude.abs() < 90)
          .map((report) => Pair<LatLng, DateTime>(
                LatLng(report.latitude, report.longitude),
                report.timestamp ?? report.published,
              ))
          .toList();

      if (reports.isNotEmpty) {
        var lastReport = reports.first;
        accessory.lastLocation =
            LatLng(lastReport.latitude, lastReport.longitude);
        accessory.datePublished = lastReport.timestamp ?? lastReport.published;
      }
    }

    // Store updated lastLocation and datePublished for accessories
    _storeAccessories();

    initialLoadFinished = true;
    notifyListeners();
  }

  /// Stores the user's accessories in persistent storage.
  Future<void> _storeAccessories() async {
    List jsonList = _accessories.map(jsonEncode).toList();
    await _storage.write(key: accessoryStorageKey, value: jsonList.toString());
  }

  /// Adds a new accessory to this registry.
  void addAccessory(Accessory accessory) {
    _accessories.add(accessory);
    _storeAccessories();
    notifyListeners();
  }

  /// Removes [accessory] from this registry.
  void removeAccessory(Accessory accessory) {
    _accessories.remove(accessory);
    // TODO: remove private key from keychain
    _storeAccessories();
    notifyListeners();
  }

  /// Updates [oldAccessory] with the values from [newAccessory].
  void editAccessory(Accessory oldAccessory, Accessory newAccessory) {
    oldAccessory.update(newAccessory);
    _storeAccessories();
    notifyListeners();
  }
}
