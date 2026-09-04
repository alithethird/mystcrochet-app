import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chart_provider.dart';
import '../providers/edit_mode_provider.dart';

class AppToolbar extends ConsumerWidget {
  final VoidCallback onNew;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final VoidCallback onTextView;

  const AppToolbar({
    super.key,
    required this.onNew,
    required this.onOpen,
    required this.onSave,
    required this.onTextView,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editState = ref.watch(editModeProvider);
    final chartState = ref.watch(chartProvider);

    final tools = [
      _ToolButton(
        icon: Icons.auto_fix_high,
        label: 'Stitch',
        selected: editState.mode == EditMode.stitch,
        onTap: () => ref.read(editModeProvider.notifier).setMode(EditMode.stitch),
      ),
      _ToolButton(
        icon: Icons.open_with,
        label: 'Move',
        selected: editState.mode == EditMode.move,
        onTap: () => ref.read(editModeProvider.notifier).setMode(EditMode.move),
      ),
      _ToolButton(
        icon: Icons.format_paint,
        label: 'Color',
        selected: editState.mode == EditMode.color,
        onTap: () => ref.read(editModeProvider.notifier).setMode(EditMode.color),
      ),
      _ToolButton(
        icon: Icons.rotate_right,
        label: 'Rotate',
        selected: editState.mode == EditMode.rotation,
        onTap: () => ref.read(editModeProvider.notifier).setMode(EditMode.rotation),
      ),
      _ToolButton(
        icon: Icons.zoom_out_map,
        label: 'Scale',
        selected: editState.mode == EditMode.scale,
        onTap: () => ref.read(editModeProvider.notifier).setMode(EditMode.scale),
      ),
      _ToolButton(
        icon: Icons.text_fields,
        label: 'Text',
        selected: editState.mode == EditMode.indicator,
        onTap: () => ref.read(editModeProvider.notifier).setMode(EditMode.indicator),
      ),
      _ToolButton(
        icon: Icons.pan_tool,
        label: 'Pan',
        selected: editState.mode == EditMode.pan,
        onTap: () => ref.read(editModeProvider.notifier).setMode(EditMode.pan),
      ),
    ];

    return Container(
      height: 48,
      color: Colors.white,
      child: Row(
        children: [
          const SizedBox(width: 8),
          ...tools,
          const Spacer(),
          Text(
            chartState.chart.name.isNotEmpty ? chartState.chart.name : 'Untitled',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.undo, size: 20),
            tooltip: 'Undo',
            onPressed: chartState.canUndo ? () => ref.read(chartProvider.notifier).undo() : null,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: const Icon(Icons.redo, size: 20),
            tooltip: 'Redo',
            onPressed: chartState.canRedo ? () => ref.read(chartProvider.notifier).redo() : null,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            tooltip: 'New',
            onPressed: onNew,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: const Icon(Icons.folder_open, size: 20),
            tooltip: 'Open',
            onPressed: onOpen,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: const Icon(Icons.save, size: 20),
            tooltip: 'Save',
            onPressed: onSave,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: const Icon(Icons.description, size: 20),
            tooltip: 'Text View',
            onPressed: onTextView,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const SizedBox(width: 8),
        ],
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