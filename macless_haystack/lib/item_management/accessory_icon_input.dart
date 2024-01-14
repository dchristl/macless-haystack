import 'package:flutter/material.dart';
import 'package:macless_haystack/accessory/accessory_icon_selector.dart';

class AccessoryIconInput extends StatelessWidget {
  /// The initial icon
  final IconData initialIcon;
  /// The original icon name
  final String iconString;
  /// The color of the icon
  final Color color;
  /// Callback called when the icon is changed. Parameter is null
  /// if icon did not change
  final ValueChanged<String?> changeListener;

  /// Displays an icon selection input that previews the current selection.
  const AccessoryIconInput({
    super.key,
    required this.initialIcon,
    required this.iconString,
    required this.color,
    required this.changeListener,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          const Text('Icon: '),
          Icon(initialIcon),
          const Spacer(),
          OutlinedButton(
            child: const Text('Change'),
            onPressed: () async {
              String? selectedIcon = await AccessoryIconSelector
                .showIconSelection(context, iconString, color);
              changeListener(selectedIcon);
            },
          ),
        ],
      ),
    );
  }
}
