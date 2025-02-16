import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:macless_haystack/accessory/accessory_battery.dart';
import 'package:macless_haystack/accessory/accessory_icon_model.dart';
import 'package:macless_haystack/findMy/find_my_controller.dart';
import 'package:macless_haystack/location/location_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';

import '../findMy/models.dart';

class Pair<T1, T2> {
  final LatLng location;
  final DateTime start;
  DateTime end;

  Pair(this.location, this.start, this.end);

  Map<String, dynamic> toJson() {
    return {
      'lat': location.latitude,
      'lon': location.longitude,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    };
  }

  static Pair fromJson(Map<String, dynamic> json) {
    return Pair(
      LatLng(json['lat'], json['lon']),
      DateTime.parse(json['start'] as String),
      DateTime.parse(json['end'] as String),
    );
  }
}

const defaultIcon = Icons.push_pin;

class Accessory {
  static final logger = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );

  /// The ID of the accessory key.
  String id;

  /// A hash of the public key.
  /// An identifier for the private key stored separately in the key store.
  String hashedPublicKey;

  /// If the accessory uses rolling keys.
  bool usesDerivation;

  // Parameters for rolling keys (only relevant is usesDerivation == true)
  String? symmetricKey;
  double? lastDerivationTimestamp;
  int? updateInterval;
  String? oldestRelevantSymmetricKey;

  /// The display name of the accessory.
  String name;
  List<String> additionalKeys;

  /// The display icon of the accessory.
  String _icon;

  /// The display color of the accessory.
  Color color;

  /// If the accessory is active.
  bool isActive;

  /// The timestamp of the last known location
  /// (null if no location known).
  DateTime? datePublished;

  /// The last known locations coordinates
  /// (null if no location known).
  LatLng? _lastLocation;

  /// The last known battery status
  /// (null if battery data not found)
  AccessoryBatteryStatus? lastBatteryStatus;

  /// A list of known locations over time.
  List<Pair<dynamic, dynamic>> locationHistory = [];
  Map<String, dynamic> hashesWithTS = {};

  /// Stores address information about the current location.
  Future<Placemark?> place = Future.value(null);

  LocationModel locationModel = LocationModel();

  /// Creates an accessory with the given properties.
  Accessory(
      {required this.id,
      required this.name,
      required this.hashedPublicKey,
      required this.datePublished,
      this.isActive = true,
      LatLng? lastLocation,
      String icon = 'mappin',
      this.color = Colors.grey,
      this.usesDerivation = false,
      this.symmetricKey,
      this.lastDerivationTimestamp,
      this.updateInterval,
      this.oldestRelevantSymmetricKey,
      required this.additionalKeys})
      : _icon = icon,
        _lastLocation = lastLocation,
        super() {
    _init();
  }

  void _init() {
    if (_lastLocation != null) {
      place = locationModel.getAddress(_lastLocation!);
    }
  }

  /// Creates a new accessory with exactly the same properties of this accessory.
  Accessory clone() {
    return Accessory(
        datePublished: datePublished,
        id: id,
        name: name,
        hashedPublicKey: hashedPublicKey,
        color: color,
        icon: _icon,
        isActive: isActive,
        lastLocation: lastLocation,
        usesDerivation: usesDerivation,
        symmetricKey: symmetricKey,
        lastDerivationTimestamp: lastDerivationTimestamp,
        updateInterval: updateInterval,
        oldestRelevantSymmetricKey: oldestRelevantSymmetricKey,
        additionalKeys: additionalKeys);
  }

  /// Updates the properties of this accessor with the new values of the [newAccessory].
  void update(Accessory newAccessory) {
    datePublished = newAccessory.datePublished;
    id = newAccessory.id;
    name = newAccessory.name;
    hashedPublicKey = newAccessory.hashedPublicKey;
    color = newAccessory.color;
    _icon = newAccessory._icon;
    isActive = newAccessory.isActive;
    lastLocation = newAccessory.lastLocation;
    additionalKeys = newAccessory.additionalKeys;
  }

  /// The last known location of the accessory.
  LatLng? get lastLocation {
    return _lastLocation;
  }

  /// The last known location of the accessory.
  set lastLocation(LatLng? newLocation) {
    _lastLocation = newLocation;
    if (_lastLocation != null) {
      place = locationModel.getAddress(_lastLocation!);
    }
  }

  /// The display icon of the accessory.
  IconData get icon {
    IconData? icon = AccessoryIconModel.mapIcon(_icon);
    return icon ?? defaultIcon;
  }

  /// The cupertino icon name.
  String get rawIcon {
    return _icon;
  }

  /// The display icon of the accessory.
  setIcon(String icon) {
    _icon = icon;
  }

  /// Creates an accessory from deserialized JSON data.
  ///
  /// Uses the same format as in [toJson]
  ///
  /// Typically used with JSON decoder.
  /// ```dart
  ///   String json = '...';
  ///   var accessoryDTO = Accessory.fromJSON(jsonDecode(json));
  /// ```
  Accessory.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        hashedPublicKey = json['hashedPublicKey'],
        datePublished = json['datePublished'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['datePublished'])
            : null,
        _lastLocation = json['latitude'] != null && json['longitude'] != null
            ? LatLng(json['latitude'].toDouble(), json['longitude'].toDouble())
            : null,
        /*isDeployed is only for migration an can be removed in the future*/
        isActive = json['isDeployed'] ?? json['isActive'],
        _icon = json['icon'],
        color = Color(int.parse(json['color'].substring(0, 8), radix: 16)),
        usesDerivation = json['usesDerivation'] ?? false,
        symmetricKey = json['symmetricKey'],
        lastDerivationTimestamp = json['lastDerivationTimestamp'],
        updateInterval = json['updateInterval'],
        oldestRelevantSymmetricKey = json['oldestRelevantSymmetricKey'],
        lastBatteryStatus = json['lastBatteryStatus'] != null
            ? AccessoryBatteryStatus.values.byName(json['lastBatteryStatus'])
            : null,
        hashesWithTS = json['hashesWithTS'] != null
            ? jsonDecode(json['hashesWithTS']) as Map<String, dynamic>
            : <String, dynamic>{},
        additionalKeys =
            json['additionalKeys']?.cast<String>() ?? List.empty() {
    _init();
  }

  /// Creates a JSON map of the serialized accessory.
  ///
  /// Uses the same format as in [Accessory.fromJson].
  ///
  /// Typically used by JSON encoder.
  /// ```dart
  ///   var accessory = Accessory(...);
  ///   jsonEncode(accessory);
  /// ```
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'hashedPublicKey': hashedPublicKey,
        'datePublished': datePublished?.millisecondsSinceEpoch,
        'latitude': _lastLocation?.latitude,
        'longitude': _lastLocation?.longitude,
        'isActive': isActive,
        'icon': _icon,
        'color': color.value.toRadixString(16).padLeft(8, '0'),
        'usesDerivation': usesDerivation,
        'hashesWithTS': jsonEncode(hashesWithTS),
        'symmetricKey': symmetricKey,
        'lastDerivationTimestamp': lastDerivationTimestamp,
        'updateInterval': updateInterval,
        'oldestRelevantSymmetricKey': oldestRelevantSymmetricKey,
        'additionalKeys': additionalKeys,
        ...lastBatteryStatus != null
            ? {'lastBatteryStatus': lastBatteryStatus!.name}
            : {}
      };

  /// Returns the Base64 encoded hash of the advertisement key
  /// (used to fetch location reports).
  Future<String> getHashedAdvertisementKey() async {
    var keyPair = await FindMyController.getKeyPair(hashedPublicKey);
    return keyPair.getHashedAdvertisementKey();
  }

  /// Returns the Base64 encoded advertisement key
  /// (sent out by the accessory via BLE).
  Future<String> getAdvertisementKey() async {
    var keyPair = await FindMyController.getKeyPair(hashedPublicKey);
    return keyPair.getBase64AdvertisementKey();
  }

  /// Returns the Base64 encoded private key.
  Future<String> getPrivateKey() async {
    var keyPair = await FindMyController.getKeyPair(hashedPublicKey);
    return keyPair.getBase64PrivateKey();
  }

  Future<String> getHashedPublicKey() async {
    return hashedPublicKey;
  }

  Future<List<String>> getAdditionalPrivateKeys() {
    return Stream.fromIterable(additionalKeys)
        .asyncMap(
            (hashedPublicKey) => FindMyController.getKeyPair(hashedPublicKey))
        .map((event) => event.getBase64PrivateKey())
        .toList();
  }

  void addLocationHistoryEntry(FindMyLocationReport report) {
    var reportDate = report.timestamp ?? report.published!;
    logger.d(
        'Adding report with timestamp $reportDate and ${report.longitude} - ${report.latitude}');

    Pair? closest;
    //Find the closest history report by time
    for (int i = 0; i < locationHistory.length; i++) {
      Pair currentPair = locationHistory[i];
      //If it is between the first pair, we have the closest one and will finish
      if (reportDate.isAtSameMomentAs(currentPair.start) ||
          reportDate.isAtSameMomentAs(currentPair.end) ||
          (reportDate.isAfter(locationHistory[0].start) &&
              reportDate.isBefore(locationHistory[0].end))) {
        closest = currentPair;
        break;
      }
      //closest already set, but is earlier than current one
      if (reportDate.isAtSameMomentAs(currentPair.start) ||
          reportDate.isAtSameMomentAs(currentPair.end) ||
          (closest != null &&
              currentPair.start.isBefore(reportDate) &&
              reportDate.isAfter(closest.start))) {
        closest = currentPair;
        continue;
      }
      if (reportDate.isAtSameMomentAs(currentPair.start) ||
          (closest == null && currentPair.start.isBefore(reportDate))) {
        closest = currentPair;
        continue;
      }
    }

    if (closest != null) {
      logger.d(
          'Found closest with ts ${closest.start} - ${closest.end} and ${closest.location.longitude} - ${closest.location.latitude}');
      bool latIsClose =
          (closest.location.latitude - report.latitude!).abs() <= 0.001;
      bool lonIsClose =
          (closest.location.longitude - report.longitude!).abs() <= 0.001;
      if (latIsClose && lonIsClose) {
        //similar
        if (reportDate.isAfter(closest.end)) {
          logger.d('Changing closest end date to $reportDate');
          closest.end = reportDate;
        } else {
          logger.d('Date not changed, because is before current date.');
        }
      } else if (!reportDate.isAtSameMomentAs(closest.start) &&
          !reportDate.isAtSameMomentAs(closest.end)) {
        logger.d('Adding new one, because closest is too far away');
        //not like before, so add new one
        Pair<LatLng, DateTime> pair = Pair(
            LatLng(report.latitude!, report.longitude!),
            reportDate,
            reportDate);
        //add the new one
        locationHistory.add(pair);
        if (reportDate.isAfter(closest.start) &&
            reportDate.isBefore(closest.end)) {
          logger.d(
              'Splitting closest, because new entry is in between with other location.');
          //add the closest entry again with the end time only
          locationHistory.add(Pair(
              LatLng(closest.location.latitude, closest.location.longitude),
              closest.end,
              closest.end));
          //change the existing closest entry end date to the former start date
          closest.end = closest.start;
        }
      } else {
        logger.w(
            'New entry at $reportDate (Lon: ${report.location.longitude}, Lat: ${report.location.latitude}) will be skipped, because we have already an entry at other location. (Lon: ${closest.location.longitude}, Lat: ${closest.location.latitude})');
      }
    } else {
      logger.d('Closest not found. Adding to list.');
      //no report before
      Pair<LatLng, DateTime> pair = Pair(
          LatLng(report.latitude!, report.longitude!), reportDate, reportDate);
      locationHistory.add(pair);
    }
  }

  void addLocationHistory(List<dynamic> historyList) {
    locationHistory = historyList.map((item) {
      return Pair.fromJson(item);
    }).toList();
  }

  DateTime latestHistoryEntry() {
    if (locationHistory.isEmpty) {
      return DateTime.fromMicrosecondsSinceEpoch(0);
    }
    return locationHistory.first.end;
  }

  void addDecryptedHash(String? hash) {
    if (hash != null && hash.length >= 10) {
      hashesWithTS[hash.substring(hash.length - 10)] =
          DateTime.now().millisecondsSinceEpoch;
    }
  }

  bool containsHash(String? hash) {
    if (hash == null || hash.length < 10) {
      return false;
    }

    return hashesWithTS.containsKey(hash.substring(hash.length - 10));
  }

  void removeOldHashes() {
    hashesWithTS.removeWhere((key, value) {
      int sevenDaysAgo =
          DateTime.now().millisecondsSinceEpoch - (7 * 24 * 60 * 60 * 1000);
      return value < sevenDaysAgo;
    });
  }

  void clearLocationHistory() {
    locationHistory.clear();
  }

  List<Pair<dynamic, dynamic>> getSortedLocationHistory() {
    locationHistory.sort((a, b) {
      return a.start.compareTo(b.start);
    });

    return locationHistory;
  }
}
