import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dialogs/language_selection_dialog.dart';
import '../l10n/app_strings.dart';
import '../providers/chart_provider.dart';
import '../providers/edit_mode_provider.dart';
import '../providers/locale_provider.dart';
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
    final strings = ref.watch(stringsProvider);
    final currentLang = ref.watch(localeProvider);
    final currentLangName = AppStrings.supportedLanguages
        .firstWhere((l) => l['code'] == currentLang, orElse: () => {'name': 'Türkçe'})['name'];

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
                    tooltip: strings.stitchPalette,
                    onPressed: onOpenDrawer,
                  ),
                  Expanded(
                    child: EditableChartTitle(
                      chartName: chartState.chart.name,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.undo, size: 20),
                    tooltip: strings.undo,
                    onPressed: chartState.canUndo
                        ? () => ref.read(chartProvider.notifier).undo()
                        : null,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                  IconButton(
                    icon: const Icon(Icons.redo, size: 20),
                    tooltip: strings.redo,
                    onPressed: chartState.canRedo
                        ? () => ref.read(chartProvider.notifier).redo()
                        : null,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 22),
                    tooltip: strings.settings,
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
                        case 'language':
                          LanguageSelectionDialog.show(context);
                          break;
                        case 'tutorial':
                          onTutorial?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'new',
                        child: Row(
                          children: [
                            const Icon(Icons.add_circle_outline, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(strings.newChart,
                                  style: const TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'open',
                        child: Row(
                          children: [
                            const Icon(Icons.folder_open, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(strings.openChart,
                                  style: const TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'save',
                        child: Row(
                          children: [
                            const Icon(Icons.save, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(strings.saveChart,
                                  style: const TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'saved_designs',
                        child: Row(
                          children: [
                            const Icon(Icons.collections_bookmark_outlined, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(strings.savedDesigns,
                                  style: const TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'export_png',
                        child: Row(
                          children: [
                            const Icon(Icons.image_outlined, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(strings.exportPng,
                                  style: const TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'text_view',
                        child: Row(
                          children: [
                            const Icon(Icons.description, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(strings.dataView,
                                  style: const TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'language',
                        child: Row(
                          children: [
                            const Icon(Icons.language, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${strings.language}: $currentLangName',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onTutorial != null) ...[
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'tutorial',
                          child: Row(
                            children: [
                              const Icon(Icons.help_outline, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(strings.help,
                                    style: const TextStyle(fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                          ? '${strings.select} (${editState.selectedStitchKeys.length})'
                          : strings.select,
                      selected: editState.mode == EditMode.select,
                      onTap: () => ref
                          .read(editModeProvider.notifier)
                          .setMode(EditMode.select),
                    ),
                    const SizedBox(width: 4),
                    _MobileToolChip(
                      icon: Icons.swap_horiz,
                      label: editState.selectedStitchKeys.isNotEmpty
                          ? '${strings.replace} (${editState.selectedStitchKeys.length})'
                          : strings.replace,
                      selected: editState.mode == EditMode.replace,
                      onTap: () => ref
                          .read(editModeProvider.notifier)
                          .setMode(EditMode.replace),
                    ),
                    const SizedBox(width: 4),
                    _MobileToolChip(
                      icon: Icons.delete_outline,
                      label: editState.selectedStitchKeys.isNotEmpty
                          ? '${strings.delete} (${editState.selectedStitchKeys.length})'
                          : strings.delete,
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
                                    '${res.deletedCount} ${strings.selected} ${strings.delete.toLowerCase()}.'),
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
                      label: strings.move,
                      selected: editState.mode == EditMode.move,
                      onTap: () => ref
                          .read(editModeProvider.notifier)
                          .setMode(EditMode.move),
                    ),
                    const SizedBox(width: 4),
                    _MobileToolChip(
                      icon: Icons.pan_tool,
                      label: strings.pan,
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
