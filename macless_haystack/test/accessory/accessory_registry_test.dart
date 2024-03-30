import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:macless_haystack/accessory/accessory_model.dart';
import 'package:macless_haystack/accessory/accessory_registry.dart';
import 'package:macless_haystack/findMy/models.dart';
import 'package:macless_haystack/location/location_model.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'accessory_registry_test.mocks.dart';

// class MockLocationModel extends Mock implements LocationModel {}

@GenerateMocks([LocationModel, FlutterSecureStorage])
void main() {
  var locationModel = MockLocationModel();
  var registry = AccessoryRegistry();
  Accessory accessory = Accessory(
      id: '',
      name: '',
      hashedPublicKey: '',
      datePublished: DateTime.now(),
      additionalKeys: List.empty());
  setUp(() {
    when(locationModel.getAddress(any))
        .thenAnswer((_) async => const Placemark());
    registry.setStorage = MockFlutterSecureStorage();
    accessory.locationModel = locationModel;
  });

  test('Add location history same location unsorted with no entries before',
      () async {
    List<FindMyLocationReport> reports = [];
    // 8 o'clock
    reports.add(FindMyLocationReport.withHash(
        1,
        2,
        DateTime(2024, 1, 1, 8, 0, 0),
        DateTime.now().microsecondsSinceEpoch.toString()));
    //6 o'clock
    reports.add(FindMyLocationReport.withHash(
        1,
        2,
        DateTime(2024, 1, 1, 6, 0, 0),
        DateTime.now().microsecondsSinceEpoch.toString()));
    //10 o'clock
    reports.add(FindMyLocationReport.withHash(
        1,
        2,
        DateTime(2024, 1, 1, 10, 0, 0),
        DateTime.now().microsecondsSinceEpoch.toString()));

    await registry.fillLocationHistory(reports, accessory);
    var latest = accessory.latestHistoryEntry();
    expect(DateTime(2024, 1, 1, 10, 0, 0), latest);
    expect(1, accessory.locationHistory.length);
    expect(DateTime(2024, 1, 1, 10, 0, 0),
        accessory.locationHistory.elementAt(0).end);
    expect(DateTime(2024, 1, 1, 6, 0, 0),
        accessory.locationHistory.elementAt(0).start);
  });

  test(
      'Add location history different location unsorted with no entries before',
      () async {
    List<FindMyLocationReport> reports = [];
    // 8 o'clock 1st location
    reports.add(FindMyLocationReport.withHash(
        1,
        2,
        DateTime(2024, 1, 1, 8, 0, 0),
        DateTime.now().microsecondsSinceEpoch.toString()));
    //10 o'clock second location
    reports.add(FindMyLocationReport.withHash(
        2,
        2,
        DateTime(2024, 1, 1, 10, 0, 0),
        DateTime.now().microsecondsSinceEpoch.toString()));
    // 9 o'clock first location
    reports.add(FindMyLocationReport.withHash(
        1,
        2,
        DateTime(2024, 1, 1, 9, 0, 0),
        DateTime.now().microsecondsSinceEpoch.toString()));
    //12 o'clock 1st location
    reports.add(FindMyLocationReport.withHash(
        1,
        2,
        DateTime(2024, 1, 1, 12, 0, 0),
        DateTime.now().microsecondsSinceEpoch.toString()));
    await registry.fillLocationHistory(reports, accessory);
    var locationHistory = accessory.locationHistory;
    expect(3, locationHistory.length);

    var latest = accessory.datePublished;
    var lastLocation = accessory.lastLocation;
    var endOfFirstEntry = accessory.latestHistoryEntry();

    expect(endOfFirstEntry, DateTime(2024, 1, 1, 9, 0, 0));
    expect(latest, DateTime(2024, 1, 1, 12, 0, 0));
    expect(lastLocation, const LatLng(1, 2));

    expect(locationHistory.elementAt(0).start, DateTime(2024, 1, 1, 8, 0, 0));
    expect(locationHistory.elementAt(0).end, DateTime(2024, 1, 1, 9, 0, 0));

    expect(locationHistory.elementAt(1).start, DateTime(2024, 1, 1, 10, 0, 0));
    expect(locationHistory.elementAt(1).end, DateTime(2024, 1, 1, 10, 0, 0));

    expect(locationHistory.elementAt(2).start, DateTime(2024, 1, 1, 12, 0, 0));
    expect(locationHistory.elementAt(2).end, DateTime(2024, 1, 1, 12, 0, 0));
  });
}
