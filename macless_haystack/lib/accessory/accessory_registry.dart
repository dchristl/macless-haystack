import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:macless_haystack/accessory/accessory_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:macless_haystack/findMy/find_my_controller.dart';
import 'package:macless_haystack/findMy/models.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:macless_haystack/preferences/user_preferences_model.dart';

const accessoryStorageKey = 'ACCESSORIES';
const historyStorageKey = 'HISTORY';

const int DEFAULT_MIN_ACCURACY = 50;

class AccessoryRegistry extends ChangeNotifier {
  var _storage = const FlutterSecureStorage();
  List<Accessory> _accessories = [];
  bool loading = false;
  bool initialLoadFinished = false;
  
  Set<String> loadedAccessoryIds = {};
  Set<Accessory> visibleAccessories = {};

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
      clearInvalidAccessories(_accessories);
      if (_accessories.length != loadedAccessories.length) {
        _storeAccessories();
      }
    } else {
      _accessories = [];
    }
    await loadHistory();

    loading = false;

    notifyListeners();
  }

  set setStorage(FlutterSecureStorage s) {
    _storage = s;
  }

  Future<void> loadHistory() async {
    String? history = await _storage.read(key: historyStorageKey);
    if (history != null) {
      Map<String, dynamic> jsonDecoded = jsonDecode(history);
      for (var item in _accessories) {
        var currElement = jsonDecoded[item.id];
        if (currElement != null) {
          item.addLocationHistory(currElement);
        }
      }
    }
  }

  /// Fetches new location reports for one accessory.
  Future<int> loadOneLocationReports(Accessory accessory) async {
    // request location updates for all accessories simultaneously
    String? url = Settings.getValue<String>(endpointUrl);
    var keyPair = await FindMyController.getKeyPair(accessory.hashedPublicKey);

    List<FindMyKeyPair> hashedPublicKeys =
        await Stream.fromIterable(accessory.additionalKeys)
            .asyncMap((hashedPublicKey) =>
                FindMyController.getKeyPair(hashedPublicKey))
            .toList();

    hashedPublicKeys.add(keyPair);

    var reports = await FindMyController.computeResults(hashedPublicKeys, url);

    logger.i(
        '${reports.length} reports fetched for ${accessory.hashedPublicKey} in total');

    if (reports.where((element) => !element.isEncrypted()).isNotEmpty) {
      var lastReport = reports.where((element) => !element.isEncrypted()).first;
      var reportDate = (lastReport.timestamp ?? lastReport.published) ??
          DateTime.fromMicrosecondsSinceEpoch(0);
      if (accessory.datePublished !=
              null /* &&
            reportDate.isAfter(accessory.datePublished!)*/
          ) {
        accessory.datePublished = reportDate;
        accessory.lastLocation =
            LatLng(lastReport.latitude!, lastReport.longitude!);

        // Update last battery status
        accessory.lastBatteryStatus = lastReport.batteryStatus!;
      }
    }
    await fillLocationHistory(reports, accessory);

    // Store updated lastLocation and datePublished for accessories
    _storeAccessories();

    _storeHistories();

    notifyListeners();

    return Future.value(reports.length);
  }

  /// Fetches new location reports and matches them to their accessory.
  Future<int> loadLocationReports() async {
    List<Future<List<FindMyLocationReport>>> runningLocationRequests = [];

    // request location updates for all accessories simultaneously
    Iterable<Accessory> currentAccessories = accessories.where((a) => a.isActive);
    String? url = Settings.getValue<String>(endpointUrl);
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
    int out = 0;
    Map<Accessory, Future<List<Pair<dynamic, dynamic>>>> historyEntries = {};
    for (var i = 0; i < currentAccessories.length; i++) {
      var accessory = currentAccessories.elementAt(i);
      var reports = reportsForAccessories.elementAt(i);
      out += reports.length;
      logger.i(
          '${reports.length} reports fetched for ${accessory.hashedPublicKey} in total');

      if (reports.where((element) => !element.isEncrypted()).isNotEmpty) {
        var lastReport =
            reports.where((element) => !element.isEncrypted()).first;
        var reportDate = (lastReport.timestamp ?? lastReport.published) ??
            DateTime.fromMicrosecondsSinceEpoch(0);
        if (accessory.datePublished != null &&
            reportDate.isAfter(accessory.datePublished!)) {
          accessory.datePublished = reportDate;
          accessory.lastLocation =
              LatLng(lastReport.latitude!, lastReport.longitude!);

          // Update last battery status
          accessory.lastBatteryStatus = lastReport.batteryStatus!;
        }
      }
      historyEntries[accessory] = fillLocationHistory(reports, accessory);
    }
    // Store updated lastLocation and datePublished for accessories
    _storeAccessories();

    _storeHistory(historyEntries);

    initialLoadFinished = true;
    notifyListeners();
    return Future.value(out);
  }

  Future<void> _storeHistories() async {
    Map<String, List<Pair<dynamic, dynamic>>> historyEntriesAsJson = {};
    for (var acc in _accessories) {
      List<Pair<dynamic, dynamic>> result = acc.locationHistory;
      var nowMinusDays = DateTime.now().subtract(const Duration(days: 7));
      var upperDayLimit =
          DateTime(nowMinusDays.year, nowMinusDays.month, nowMinusDays.day);
      var filtered = result
          .where((element) => element.end.isAfter(upperDayLimit))
          .toList();
      if (filtered.length != result.length) {
        logger.i(
            '${result.length - filtered.length} history elements have been filtered out and will be deleted due to age.');
      }
      historyEntriesAsJson[acc.id] = filtered;
    }
    var historyJson = jsonEncode(historyEntriesAsJson);
    _storage.write(key: historyStorageKey, value: historyJson);
  }

  Future<void> _storeHistory(
      Map<Accessory, Future<List<Pair<dynamic, dynamic>>>>
          historyEntries) async {
    Map<String, List<Pair<dynamic, dynamic>>> historyEntriesAsJson = {};
    for (var entry in historyEntries.entries) {
      Accessory key = entry.key;
      Future<List<Pair<dynamic, dynamic>>> future = entry.value;
      List<Pair<dynamic, dynamic>> result = await future;
      var nowMinusDays = DateTime.now().subtract(const Duration(days: 7));
      var upperDayLimit =
          DateTime(nowMinusDays.year, nowMinusDays.month, nowMinusDays.day);
      var filtered = result
          .where((element) => element.end.isAfter(upperDayLimit))
          .toList();
      if (filtered.length != result.length) {
        logger.i(
            '${result.length - filtered.length} history elements have been filtered out and will be deleted due to age.');
      }
      historyEntriesAsJson[key.id] = filtered;
    }
    var historyJson = jsonEncode(historyEntriesAsJson);
    _storage.write(key: historyStorageKey, value: historyJson);
  }

  /// Stores the user's accessories in persistent storage.
  Future<void> _storeAccessories() async {
    List jsonList = _accessories.map(jsonEncode).toList();
    await _storage.write(key: accessoryStorageKey, value: jsonList.toString());
  }

  /// Adds a new accessory to this registry.
  void addAccessory(Accessory accessory) {
    Accessory? foundOne;
    for (var acc in _accessories) {
      if (accessory.hashedPublicKey == acc.hashedPublicKey) {
        foundOne = acc;
        break; // There is already one with this id
      }
    }
    if (foundOne != null) {
      _accessories.remove(foundOne);
    }

    _accessories.add(accessory);
    _storeAccessories();
    notifyListeners();
  }

  /// Removes [accessory] from this registry.
  void removeAccessory(Accessory accessory) {
    _accessories.remove(accessory);
    accessory.getHashedPublicKey().then((publicKey) {
      _storage.delete(key: publicKey);
    });

    _storeAccessories();
    notifyListeners();
  }

  Future<List<Pair<dynamic, dynamic>>> fillLocationHistory(
      List<FindMyLocationReport> reports, Accessory accessory) async {
    List<FindMyLocationReport> decryptedReports = [];
    //Decrypt only reports that are not already decrypted
    Set<String> hashes = {};
    int count = 0;
    //This will be achieved by saving the hash(payload) of all already decrypted reports
    for (var i = 0; i < reports.length; i++) {
      var currHash = reports[i].hash;
      if (!accessory.containsHash(currHash)) {
        accessory.addDecryptedHash(currHash);
        logger.d('Decrypting report $i of ${reports.length} with id $currHash');
        await reports[i].decrypt();
        decryptedReports.add(reports[i]);
      } else {
        count++;
      }

      hashes.add(currHash!);
    }
    logger.d(
        '${reports.length - count} reports decrypted. Decryption of $count reports skipped, because they are already fetched and decrypted.');
    //All hashes, that are not in the reports anymore can be deleted, because they are out of time
    accessory.removeOldHashes();
    //Sort by date
    decryptedReports.sort((a, b) {
      var aDate = a.timestamp ?? DateTime(1970);
      var bDate = b.timestamp ?? DateTime(1970);
      return aDate.compareTo(bDate);
    });

    //Update the latest timestamp
    if (decryptedReports.isNotEmpty) {
      var lastReport = decryptedReports[decryptedReports.length - 1];
      var oldTs = accessory.datePublished;
      var latestReportTS = lastReport.timestamp ?? lastReport.published ?? DateTime(1971);
      if (oldTs == null || oldTs.isBefore(latestReportTS) ) {
        //only an actualization if oldTS is not set or is older than the latest of the new ones
        accessory.lastLocation =
            LatLng(lastReport.latitude!, lastReport.longitude!);
        accessory.datePublished = latestReportTS;
        //If battery status exists, update last battery status
        if (lastReport.batteryStatus != null) {
          accessory.lastBatteryStatus = lastReport.batteryStatus;
        }
        notifyListeners(); //redraw the UI, if the timestamp has changed
      }
    }

//add to history in correct order
    for (var i = 0; i < decryptedReports.length; i++) {
      FindMyLocationReport report = decryptedReports[i];
      if (report.accuracy! >= DEFAULT_MIN_ACCURACY &&
          report.longitude!.abs() <= 180 &&
          report.latitude!.abs() <= 90) {
        accessory.addLocationHistoryEntry(report);
      } else {
        logger.d(
            'Report skipped, because of anomaly data (lat: ${report.latitude}, lon: ${report.longitude}, acc: ${report.accuracy})');
      }
    }
    _storeAccessories();
    return accessory.locationHistory;
  }

  /// Updates [oldAccessory] with the values from [newAccessory].
  void editAccessory(Accessory oldAccessory, Accessory newAccessory) {
    oldAccessory.update(newAccessory);
    _storeAccessories();
    notifyListeners();
  }

  void clearInvalidAccessories(List<Accessory> loadedAccessories) async {
    List<int> indicesToRemove = [];
    for (int i = 0; i < accessories.length; i++) {
      bool containsKey =
          await _storage.containsKey(key: accessories[i].hashedPublicKey);
      if (!containsKey) {
        // Invalid Element should be removed
        indicesToRemove.add(i);
      }
    }
    for (int index in indicesToRemove.reversed) {
      loadedAccessories.removeAt(index);
    }
  }
}
