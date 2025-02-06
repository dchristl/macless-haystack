import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CodeBlock extends StatelessWidget {
  final String text;

  /// Displays a code block that can easily copied by the user.
  const CodeBlock({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 50),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              color: Theme.of(context).colorScheme.surface,
            ),
            padding: const EdgeInsets.all(5),
            child: SelectableText(text),
          ),
          Positioned(
            top: 0,
            right: 5,
            child: OutlinedButton(
              child: const Text('Copy'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: text));
              },
            ),
          ),
        ],
      ),
    );
  }
}
