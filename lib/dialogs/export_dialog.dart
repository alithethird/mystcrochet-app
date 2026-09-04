import 'package:flutter/material.dart';

class ExportDialogOptions {
  final String fileName;
  final double pixelRatio;
  final bool includeGuidelines;
  final bool transparent;

  const ExportDialogOptions({
    required this.fileName,
    required this.pixelRatio,
    required this.includeGuidelines,
    required this.transparent,
  });
}

class ExportDialog extends StatefulWidget {
  final String initialName;
  final void Function(ExportDialogOptions options) onExport;

  const ExportDialog({
    super.key,
    required this.initialName,
    required this.onExport,
  });

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  late final TextEditingController _nameController;
  double _pixelRatio = 2.0;
  bool _includeGuidelines = true;
  bool _transparent = false;

  @override
  void initState() {
    super.initState();
    final baseName = widget.initialName.trim().isNotEmpty && widget.initialName != 'Untitled'
        ? widget.initialName.trim().replaceAll(RegExp(r'\s+'), '_').replaceAll(RegExp(r'[^\w-]'), '_')
        : 'crochet_chart';
    _nameController = TextEditingController(text: '$baseName.png');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    var name = _nameController.text.trim();
    if (name.isEmpty) {
      name = 'crochet_chart.png';
    }
    if (!name.toLowerCase().endsWith('.png')) {
      name = '$name.png';
    }

    widget.onExport(ExportDialogOptions(
      fileName: name,
      pixelRatio: _pixelRatio,
      includeGuidelines: _includeGuidelines,
      transparent: _transparent,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.image, size: 22, color: Color(0xFF3B82F6)),
          SizedBox(width: 8),
          Text('Export as PNG', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'File Name',
                hintText: 'crochet_chart.png',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.description, size: 20),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<double>(
              initialValue: _pixelRatio,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Resolution Quality',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.high_quality, size: 20),
              ),
              items: const [
                DropdownMenuItem(value: 1.0, child: Text('1x - Standard (Screen)')),
                DropdownMenuItem(value: 2.0, child: Text('2x - High Quality (Print/HD)')),
                DropdownMenuItem(value: 3.0, child: Text('3x - Ultra Quality (4K/Vector crisp)')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _pixelRatio = val);
              },
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Include Guide Lines'),
              subtitle: const Text('Show round and polygon layout guides', style: TextStyle(fontSize: 11)),
              value: _includeGuidelines,
              onChanged: (val) => setState(() => _includeGuidelines = val ?? true),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Transparent Background'),
              subtitle: const Text('Export with transparent background instead of white', style: TextStyle(fontSize: 11)),
              value: _transparent,
              onChanged: (val) => setState(() => _transparent = val ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.download, size: 18),
          label: const Text('Export PNG'),
        ),
      ],
    );
  }
}
