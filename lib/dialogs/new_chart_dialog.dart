import 'package:flutter/material.dart';

class NewChartDialog extends StatefulWidget {
  final void Function(int style) onCreated;

  const NewChartDialog({super.key, required this.onCreated});

  @override
  State<NewChartDialog> createState() => _NewChartDialogState();
}

class _NewChartDialogState extends State<NewChartDialog> {
  int _style = 104; // VISUAL

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Chart'),
      content: DropdownButtonFormField<int>(
        initialValue: _style,
        decoration: const InputDecoration(isDense: true, labelText: 'Style'),
        items: const [
          DropdownMenuItem(value: 104, child: Text('Visual')),
          DropdownMenuItem(value: 103, child: Text('Textual')),
        ],
        onChanged: (v) => setState(() => _style = v ?? 104),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            widget.onCreated(_style);
            Navigator.pop(context);
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
