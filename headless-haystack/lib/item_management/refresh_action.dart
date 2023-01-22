import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:openhaystack_mobile/dashboard/dashboard.dart';
import 'package:openhaystack_mobile/item_management/item_creation.dart';
import 'package:openhaystack_mobile/item_management/item_file_import.dart';
import 'package:openhaystack_mobile/item_management/item_import.dart';
import 'dart:io';

class RefreshAction extends StatefulWidget {
  final AsyncCallback callback;

  /// A new accessory can be created or an existing one imported manually.
  const RefreshAction({Key? key, required this.callback}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _RefreshingWidgetState();
  }
}

class _RefreshingWidgetState extends State<RefreshAction> {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
        heroTag: null,
        onPressed: () {
          widget.callback.call();
        },
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh));
  }
}
