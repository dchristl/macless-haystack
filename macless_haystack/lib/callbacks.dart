import 'dart:collection';

import 'accessory/accessory_model.dart';

typedef LoadLocationUpdatesCallback = Future<void> Function(Accessory? data);
typedef SaveOrderUpdatesCallback = Future<void> Function(
    List<Accessory> accessories);
