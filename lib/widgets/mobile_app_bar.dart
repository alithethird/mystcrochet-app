import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chart_provider.dart';
import '../providers/edit_mode_provider.dart';
import '../services/stitch_replace_service.dart';
import 'toolbar.dart';

class MobileAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback onNew;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final VoidCallback onSavedDesigns;
  final VoidCallback onExportPng;
  final VoidCallback onTextView;
  final VoidCallback onOpenDrawer;
  final VoidCallback? onTutorial;

  const MobileAppBar({
    super.key,
    required this.onNew,
    required this.onOpen,
    required this.onSave,
    required this.onSavedDesigns,
    required this.onExportPng,
    required this.onTextView,
    required this.onOpenDrawer,
    this.onTutorial,
  });

  @override
  Size get preferredSize => const Size.fromHeight(94);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartState = ref.watch(chartProvider);
    final editState = ref.watch(editModeProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row: Menu, Title, Undo/Redo, Overflow menu
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, size: 22),
                    tooltip: 'İlmek Paleti',
                    onPressed: onOpenDrawer,
                  ),
                  Expanded(
                    child: EditableChartTitle(
                      chartName: chartState.chart.name,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.undo, size: 20),
                    tooltip: 'Geri Al',
                    onPressed: chartState.canUndo
                        ? () => ref.read(chartProvider.notifier).undo()
                        : null,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                  IconButton(
                    icon: const Icon(Icons.redo, size: 20),
                    tooltip: 'Yinele',
                    onPressed: chartState.canRedo
                        ? () => ref.read(chartProvider.notifier).redo()
                        : null,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 22),
                    tooltip: 'Menü',
                    onSelected: (val) {
                      switch (val) {
                        case 'new':
                          onNew();
                          break;
                        case 'open':
                          onOpen();
                          break;
                        case 'save':
                          onSave();
                          break;
                        case 'saved_designs':
                          onSavedDesigns();
                          break;
                        case 'export_png':
                          onExportPng();
                          break;
                        case 'text_view':
                          onTextView();
                          break;
                        case 'tutorial':
                          onTutorial?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'new',
                        child: Row(
                          children: [
                            Icon(Icons.add_circle_outline, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('Yeni Grafik',
                                  style: TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'open',
                        child: Row(
                          children: [
                            Icon(Icons.folder_open, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('Grafik Aç',
                                  style: TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'save',
                        child: Row(
                          children: [
                            Icon(Icons.save, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('Grafiği Kaydet',
                                  style: TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'saved_designs',
                        child: Row(
                          children: [
                            Icon(Icons.collections_bookmark_outlined, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('Kayıtlı Tasarımlar',
                                  style: TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'export_png',
                        child: Row(
                          children: [
                            Icon(Icons.image_outlined, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('PNG Olarak Dışa Aktar',
                                  style: TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'text_view',
                        child: Row(
                          children: [
                            Icon(Icons.description, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('Veri Görünümü (JSON)',
                                  style: TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'tutorial',
                        child: Row(
                          children: [
                            Icon(Icons.help_outline, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('Kullanım Rehberi',
                                  style: TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Bottom row: Compact mode buttons (Seç, Değiştir, Sil, Taşı, Kaydır)
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _MobileToolChip(
                      icon: Icons.check_box_outlined,
                      label: editState.selectedStitchKeys.isNotEmpty
                          ? 'Seç (${editState.selectedStitchKeys.length})'
                          : 'Seç',
                      selected: editState.mode == EditMode.select,
                      onTap: () => ref
                          .read(editModeProvider.notifier)
                          .setMode(EditMode.select),
                    ),
                    const SizedBox(width: 4),
                    _MobileToolChip(
                      icon: Icons.swap_horiz,
                      label: editState.selectedStitchKeys.isNotEmpty
                          ? 'Değiştir (${editState.selectedStitchKeys.length})'
                          : 'Değiştir',
                      selected: editState.mode == EditMode.replace,
                      onTap: () => ref
                          .read(editModeProvider.notifier)
                          .setMode(EditMode.replace),
                    ),
                    const SizedBox(width: 4),
                    _MobileToolChip(
                      icon: Icons.delete_outline,
                      label: editState.selectedStitchKeys.isNotEmpty
                          ? 'Sil (${editState.selectedStitchKeys.length})'
                          : 'Sil',
                      selected: editState.mode == EditMode.delete,
                      onTap: () {
                        if (editState.selectedStitchKeys.isNotEmpty) {
                          final chartNotifier =
                              ref.read(chartProvider.notifier);
                          final res = deleteSelectedStitches(
                            chart: chartNotifier.chart,
                            selectedKeys: editState.selectedStitchKeys,
                          );
                          if (res.deletedCount > 0) {
                            chartNotifier.setChart(res.updatedChart,
                                recordUndo: true);
                            ref
                                .read(editModeProvider.notifier)
                                .clearSelection();
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${res.deletedCount} adet seçili ilmek silindi.'),
                                backgroundColor: const Color(0xFFDC2626),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } else {
                          ref
                              .read(editModeProvider.notifier)
                              .setMode(EditMode.delete);
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    _MobileToolChip(
                      icon: Icons.open_with,
                      label: 'Taşı',
                      selected: editState.mode == EditMode.move,
                      onTap: () => ref
                          .read(editModeProvider.notifier)
                          .setMode(EditMode.move),
                    ),
                    const SizedBox(width: 4),
                    _MobileToolChip(
                      icon: Icons.pan_tool,
                      label: 'Kaydır',
                      selected: editState.mode == EditMode.pan,
                      onTap: () => ref
                          .read(editModeProvider.notifier)
                          .setMode(EditMode.pan),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileToolChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MobileToolChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF3B82F6) : Colors.white,
      borderRadius: BorderRadius.circular(6),
      elevation: selected ? 1 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : const Color(0xFF374151),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
