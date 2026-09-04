import 'package:flutter/material.dart';

class SaveChartDialog extends StatefulWidget {
  final String initialName;
  final void Function(String fileName, String? updatedChartName) onSave;

  const SaveChartDialog({
    super.key,
    required this.initialName,
    required this.onSave,
  });

  @override
  State<SaveChartDialog> createState() => _SaveChartDialogState();
}

class _SaveChartDialogState extends State<SaveChartDialog> {
  late final TextEditingController _nameController;
  String _extension = '.crochet';
  bool _updateChartName = true;

  @override
  void initState() {
    super.initState();
    var baseName = widget.initialName.trim();
    if (baseName.isEmpty || baseName == 'Untitled') {
      baseName = 'crochet_pattern';
    }
    // If the initial name ends with an extension, strip it for editing
    if (baseName.toLowerCase().endsWith('.crochet')) {
      baseName = baseName.substring(0, baseName.length - 8);
      _extension = '.crochet';
    } else if (baseName.toLowerCase().endsWith('.json')) {
      baseName = baseName.substring(0, baseName.length - 5);
      _extension = '.json';
    }
    _nameController = TextEditingController(text: baseName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    var rawName = _nameController.text.trim();
    if (rawName.isEmpty) {
      rawName = 'crochet_pattern';
    }

    String chosenName = rawName;
    String finalFileName = rawName;

    if (!finalFileName.toLowerCase().endsWith('.crochet') &&
        !finalFileName.toLowerCase().endsWith('.json')) {
      finalFileName = '$finalFileName$_extension';
    } else {
      // If user typed extension manually, extract the base name
      if (chosenName.toLowerCase().endsWith('.crochet')) {
        chosenName = chosenName.substring(0, chosenName.length - 8);
      } else if (chosenName.toLowerCase().endsWith('.json')) {
        chosenName = chosenName.substring(0, chosenName.length - 5);
      }
    }

    final updatedName = _updateChartName ? chosenName.trim() : null;

    widget.onSave(finalFileName, updatedName);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.save_outlined, size: 22),
          SizedBox(width: 8),
          Text('Grafiği Kaydet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dosya Adı',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'crochet_pattern',
                suffixText: _extension,
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Format',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: '.crochet',
                  label: Text('.crochet (Grafik Deseni)'),
                ),
                ButtonSegment(
                  value: '.json',
                  label: Text('.json (JSON Verisi)'),
                ),
              ],
              selected: {_extension},
              onSelectionChanged: (newSelection) {
                setState(() => _extension = newSelection.first);
              },
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _updateChartName,
              onChanged: (val) => setState(() => _updateChartName = val ?? true),
              title: const Text(
                'Çalışma alanındaki grafik başlığını güncelle',
                style: TextStyle(fontSize: 13),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save, size: 18),
          label: const Text('Kaydet'),
        ),
      ],
    );
  }
}
