import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chart_provider.dart';
import '../providers/edit_mode_provider.dart';

class AppToolbar extends ConsumerWidget {
  final VoidCallback onNew;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final VoidCallback onTextView;
  final VoidCallback? onExportPng;

  const AppToolbar({
    super.key,
    required this.onNew,
    required this.onOpen,
    required this.onSave,
    required this.onTextView,
    this.onExportPng,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editState = ref.watch(editModeProvider);
    final chartState = ref.watch(chartProvider);

    final tools = [
      _ToolButton(
        icon: Icons.auto_fix_high,
        label: 'İlmek',
        selected: editState.mode == EditMode.stitch,
        onTap: () => ref.read(editModeProvider.notifier).setMode(EditMode.stitch),
      ),
      _ToolButton(
        icon: Icons.open_with,
        label: 'Taşı',
        selected: editState.mode == EditMode.move,
        onTap: () => ref.read(editModeProvider.notifier).setMode(EditMode.move),
      ),
      _ToolButton(
        icon: Icons.delete_outline,
        label: 'Sil',
        selected: editState.mode == EditMode.delete,
        onTap: () => ref.read(editModeProvider.notifier).setMode(EditMode.delete),
      ),
      _ToolButton(
        icon: Icons.text_fields,
        label: 'Metin',
        selected: editState.mode == EditMode.indicator,
        onTap: () => ref.read(editModeProvider.notifier).setMode(EditMode.indicator),
      ),
      _ToolButton(
        icon: Icons.pan_tool,
        label: 'Kaydır',
        selected: editState.mode == EditMode.pan,
        onTap: () => ref.read(editModeProvider.notifier).setMode(EditMode.pan),
      ),
    ];

    final actions = [
      IconButton(
        icon: const Icon(Icons.undo, size: 20),
        tooltip: 'Geri Al',
        onPressed: chartState.canUndo ? () => ref.read(chartProvider.notifier).undo() : null,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
      IconButton(
        icon: const Icon(Icons.redo, size: 20),
        tooltip: 'Yinele',
        onPressed: chartState.canRedo ? () => ref.read(chartProvider.notifier).redo() : null,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
      IconButton(
        icon: const Icon(Icons.add, size: 20),
        tooltip: 'Yeni Grafik',
        onPressed: onNew,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
      IconButton(
        icon: const Icon(Icons.folder_open, size: 20),
        tooltip: 'Grafik Aç (İçe Aktar)',
        onPressed: onOpen,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
      IconButton(
        icon: const Icon(Icons.save, size: 20),
        tooltip: 'Grafiği Kaydet',
        onPressed: onSave,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
      IconButton(
        icon: const Icon(Icons.description, size: 20),
        tooltip: 'Veri Görünümü (JSON / İçe Aktar)',
        onPressed: onTextView,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
      IconButton(
        key: const ValueKey('toolbar_export_png'),
        icon: const Icon(Icons.image_outlined, size: 20),
        tooltip: 'PNG Olarak Dışa Aktar',
        onPressed: onExportPng,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    ];

    final chartNameText = Text(
      chartState.chart.name.isNotEmpty ? chartState.chart.name : 'İsimsiz',
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    );

    return Container(
      height: 48,
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 950;
          if (isCompact) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  ...tools,
                  const SizedBox(width: 12),
                  chartNameText,
                  const SizedBox(width: 12),
                  ...actions,
                  const SizedBox(width: 8),
                ],
              ),
            );
          }

          return Row(
            children: [
              const SizedBox(width: 8),
              ...tools,
              const Spacer(),
              chartNameText,
              const Spacer(),
              ...actions,
              const SizedBox(width: 8),
            ],
          );
        },
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFCE8EC) : null,
          border: Border(
            bottom: BorderSide(
              color: selected ? const Color(0xFFE85A7A) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: selected ? const Color(0xFFE85A7A) : Colors.black87),
            Text(label, style: TextStyle(fontSize: 10, color: selected ? const Color(0xFFE85A7A) : Colors.black54)),
          ],
        ),
      ),
    );
  }
}