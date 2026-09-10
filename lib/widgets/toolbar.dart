import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chart_provider.dart';
import '../providers/edit_mode_provider.dart';
import '../services/stitch_replace_service.dart';

class AppToolbar extends ConsumerWidget {
  final VoidCallback onNew;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final VoidCallback onTextView;
  final VoidCallback? onExportPng;
  final VoidCallback? onSavedDesigns;

  const AppToolbar({
    super.key,
    required this.onNew,
    required this.onOpen,
    required this.onSave,
    required this.onTextView,
    this.onExportPng,
    this.onSavedDesigns,
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
        icon: Icons.checklist,
        label: editState.selectedStitchKeys.isNotEmpty ? 'Seç (${editState.selectedStitchKeys.length})' : 'Seç',
        selected: editState.mode == EditMode.select,
        onTap: () => ref.read(editModeProvider.notifier).setMode(EditMode.select),
      ),
      _ToolButton(
        icon: Icons.swap_horiz,
        label: editState.selectedStitchKeys.isNotEmpty ? 'Değiştir (${editState.selectedStitchKeys.length})' : 'Değiştir',
        selected: editState.mode == EditMode.replace,
        onTap: () => ref.read(editModeProvider.notifier).setMode(EditMode.replace),
      ),
      _ToolButton(
        icon: Icons.delete_outline,
        label: editState.selectedStitchKeys.isNotEmpty ? 'Sil (${editState.selectedStitchKeys.length})' : 'Sil',
        selected: editState.mode == EditMode.delete,
        onTap: () {
          if (editState.selectedStitchKeys.isNotEmpty) {
            final chartNotifier = ref.read(chartProvider.notifier);
            final res = deleteSelectedStitches(
              chart: chartNotifier.chart,
              selectedKeys: editState.selectedStitchKeys,
            );
            if (res.deletedCount > 0) {
              chartNotifier.setChart(res.updatedChart, recordUndo: true);
              ref.read(editModeProvider.notifier).clearSelection();
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${res.deletedCount} adet seçili ilmek silindi.'),
                  backgroundColor: const Color(0xFFDC2626),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } else {
            ref.read(editModeProvider.notifier).setMode(EditMode.delete);
          }
        },
      ),
      _ToolButton(
        icon: Icons.open_with,
        label: 'Taşı',
        selected: editState.mode == EditMode.move,
        onTap: () => ref.read(editModeProvider.notifier).setMode(EditMode.move),
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
        key: const ValueKey('toolbar_saved_designs'),
        icon: const Icon(Icons.collections_bookmark_outlined, size: 20),
        tooltip: 'Kayıtlı Tasarımlar',
        onPressed: onSavedDesigns,
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

    final chartNameText = _EditableChartTitle(
      chartName: chartState.chart.name,
    );

    return Container(
      height: 48,
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 1350;
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

class _EditableChartTitle extends ConsumerStatefulWidget {
  final String chartName;
  const _EditableChartTitle({required this.chartName});

  @override
  ConsumerState<_EditableChartTitle> createState() => _EditableChartTitleState();
}

class _EditableChartTitleState extends ConsumerState<_EditableChartTitle> {
  bool _isEditing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.chartName);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _EditableChartTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chartName != widget.chartName && !_isEditing) {
      _controller.text = widget.chartName;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      _submit();
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _controller.text = widget.chartName.isEmpty ? 'İsimsiz' : widget.chartName;
      _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _submit() {
    if (!_isEditing) return;
    final newName = _controller.text.trim();
    if (newName.isNotEmpty && newName != widget.chartName) {
      final notifier = ref.read(chartProvider.notifier);
      notifier.setChart(notifier.chart.copyWith(name: newName), recordUndo: true);
    }
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return SizedBox(
        width: 180,
        height: 32,
        child: TextField(
          key: const ValueKey('toolbar_chart_name_input'),
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF6750A4), width: 1.5),
            ),
          ),
          onSubmitted: (_) => _submit(),
        ),
      );
    }

    final displayName = widget.chartName.isNotEmpty ? widget.chartName : 'İsimsiz';
    return Tooltip(
      message: 'İsmi değiştirmek için çift tıklayın',
      child: GestureDetector(
        key: const ValueKey('toolbar_chart_name_text'),
        onDoubleTap: _startEditing,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.edit_outlined,
                  size: 13,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}