import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dialogs/language_selection_dialog.dart';
import '../l10n/app_strings.dart';
import '../providers/chart_provider.dart';
import '../providers/edit_mode_provider.dart';
import '../providers/locale_provider.dart';
import '../services/stitch_replace_service.dart';
import '../services/sound_service.dart';
import '../providers/auth_provider.dart';
import 'auth_dialog.dart';

class AppToolbar extends ConsumerWidget {
  final VoidCallback onNew;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final VoidCallback onTextView;
  final VoidCallback? onExportPng;
  final VoidCallback? onSavedDesigns;
  final VoidCallback? onTutorial;

  const AppToolbar({
    super.key,
    required this.onNew,
    required this.onOpen,
    required this.onSave,
    required this.onTextView,
    this.onExportPng,
    this.onSavedDesigns,
    this.onTutorial,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editState = ref.watch(editModeProvider);
    final chartState = ref.watch(chartProvider);
    final strings = ref.watch(stringsProvider);
    final authState = ref.watch(authProvider);
    final soundEnabled = ref.watch(soundEffectsEnabledProvider);
    final soundService = ref.read(soundServiceProvider);
    final currentLang = ref.watch(localeProvider);
    final currentLangName = AppStrings.supportedLanguages
        .firstWhere((l) => l['code'] == currentLang, orElse: () => {'name': 'Türkçe'})['name'];

    final tools = [
      _ToolButton(
        icon: Icons.auto_fix_high,
        label: strings.stitch,
        selected: editState.mode == EditMode.stitch,
        onTap: () {
          soundService.play(SoundEffect.click);
          ref.read(editModeProvider.notifier).setMode(EditMode.stitch);
        },
      ),
      _ToolButton(
        icon: Icons.checklist,
        label: editState.selectedStitchKeys.isNotEmpty ? '${strings.select} (${editState.selectedStitchKeys.length})' : strings.select,
        selected: editState.mode == EditMode.select,
        onTap: () {
          soundService.play(SoundEffect.click);
          ref.read(editModeProvider.notifier).setMode(EditMode.select);
        },
      ),
      _ToolButton(
        icon: Icons.swap_horiz,
        label: editState.selectedStitchKeys.isNotEmpty ? '${strings.replace} (${editState.selectedStitchKeys.length})' : strings.replace,
        selected: editState.mode == EditMode.replace,
        onTap: () {
          soundService.play(SoundEffect.click);
          ref.read(editModeProvider.notifier).setMode(EditMode.replace);
        },
      ),
      _ToolButton(
        icon: Icons.delete_outline,
        label: editState.selectedStitchKeys.isNotEmpty ? '${strings.delete} (${editState.selectedStitchKeys.length})' : strings.delete,
        selected: editState.mode == EditMode.delete,
        onTap: () {
          if (editState.selectedStitchKeys.isNotEmpty) {
            final chartNotifier = ref.read(chartProvider.notifier);
            final res = deleteSelectedStitches(
              chart: chartNotifier.chart,
              selectedKeys: editState.selectedStitchKeys,
            );
            if (res.deletedCount > 0) {
              soundService.play(SoundEffect.delete);
              chartNotifier.setChart(res.updatedChart, recordUndo: true);
              ref.read(editModeProvider.notifier).clearSelection();
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${res.deletedCount} ${strings.selected} ${strings.delete.toLowerCase()}.'),
                  backgroundColor: const Color(0xFFDC2626),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } else {
            soundService.play(SoundEffect.click);
            ref.read(editModeProvider.notifier).setMode(EditMode.delete);
          }
        },
      ),
      _ToolButton(
        icon: Icons.open_with,
        label: strings.move,
        selected: editState.mode == EditMode.move,
        onTap: () {
          soundService.play(SoundEffect.click);
          ref.read(editModeProvider.notifier).setMode(EditMode.move);
        },
      ),
      _ToolButton(
        icon: Icons.pan_tool,
        label: strings.pan,
        selected: editState.mode == EditMode.pan,
        onTap: () {
          soundService.play(SoundEffect.click);
          ref.read(editModeProvider.notifier).setMode(EditMode.pan);
        },
      ),
    ];

    final actions = [
      IconButton(
        icon: const Icon(Icons.undo, size: 20),
        tooltip: strings.undo,
        onPressed: chartState.canUndo
            ? () {
                soundService.play(SoundEffect.click);
                ref.read(chartProvider.notifier).undo();
              }
            : null,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
      IconButton(
        icon: const Icon(Icons.redo, size: 20),
        tooltip: strings.redo,
        onPressed: chartState.canRedo
            ? () {
                soundService.play(SoundEffect.click);
                ref.read(chartProvider.notifier).redo();
              }
            : null,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
      if (onSavedDesigns != null)
        IconButton(
          key: const ValueKey('toolbar_saved_designs'),
          icon: const Icon(Icons.collections_bookmark_outlined, size: 20),
          tooltip: strings.savedDesigns,
          onPressed: () {
            soundService.play(SoundEffect.click);
            onSavedDesigns!();
          },
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      if (onExportPng != null)
        IconButton(
          key: const ValueKey('toolbar_export_png'),
          icon: const Icon(Icons.image_outlined, size: 20),
          tooltip: strings.exportPng,
          onPressed: () {
            soundService.play(SoundEffect.success);
            onExportPng!();
          },
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      PopupMenuButton<String>(
        key: const ValueKey('toolbar_settings'),
        icon: const Icon(Icons.settings, size: 20),
        tooltip: strings.settings,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
        onSelected: (val) {
          switch (val) {
            case 'new':
              soundService.play(SoundEffect.click);
              onNew();
              break;
            case 'open':
              soundService.play(SoundEffect.click);
              onOpen();
              break;
            case 'save':
              soundService.play(SoundEffect.success);
              onSave();
              break;
            case 'text_view':
              soundService.play(SoundEffect.click);
              onTextView();
              break;
            case 'language':
              soundService.play(SoundEffect.click);
              LanguageSelectionDialog.show(context);
              break;
            case 'sound_effects':
              ref.read(soundEffectsEnabledProvider.notifier).toggle();
              if (!soundEnabled) {
                soundService.play(SoundEffect.click);
              }
              break;
            case 'tutorial':
              soundService.play(SoundEffect.click);
              onTutorial?.call();
              break;
            case 'auth':
              soundService.play(SoundEffect.click);
              AuthDialog.show(context);
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
                Text(strings.newChart, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'open',
            child: Row(
              children: [
                const Icon(Icons.folder_open, size: 18),
                const SizedBox(width: 8),
                Text(strings.openChart, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'save',
            child: Row(
              children: [
                const Icon(Icons.save, size: 18),
                const SizedBox(width: 8),
                Text(strings.saveChart, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'text_view',
            child: Row(
              children: [
                const Icon(Icons.description, size: 18),
                const SizedBox(width: 8),
                Text(strings.dataView, style: const TextStyle(fontSize: 13)),
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
          PopupMenuItem(
            key: const ValueKey('toolbar_sound_effects'),
            value: 'sound_effects',
            child: Row(
              children: [
                Icon(
                  soundEnabled ? Icons.volume_up : Icons.volume_off,
                  size: 18,
                  color: soundEnabled ? const Color(0xFF3B82F6) : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${strings.soundEffects}: ${soundEnabled ? strings.soundOn : strings.soundOff}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          if (onTutorial != null) ...[
            const PopupMenuDivider(),
            PopupMenuItem(
              key: const ValueKey('toolbar_tutorial'),
              value: 'tutorial',
              child: Row(
                children: [
                  const Icon(Icons.help_outline, size: 18),
                  const SizedBox(width: 8),
                  Text(strings.help, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
          const PopupMenuDivider(),
          PopupMenuItem(
            key: const ValueKey('toolbar_auth'),
            value: 'auth',
            child: Row(
              children: [
                Icon(
                  authState.isAuthenticated ? Icons.account_circle : Icons.login,
                  size: 18,
                  color: authState.isAuthenticated ? const Color(0xFF7C3AED) : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    authState.isAuthenticated
                        ? (authState.user?.username ?? strings.profile)
                        : strings.loginOrRegister,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: authState.isAuthenticated ? FontWeight.w600 : FontWeight.normal,
                      color: authState.isAuthenticated ? const Color(0xFF7C3AED) : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ];

    final chartNameText = EditableChartTitle(
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

class EditableChartTitle extends ConsumerStatefulWidget {
  final String chartName;
  const EditableChartTitle({super.key, required this.chartName});

  @override
  ConsumerState<EditableChartTitle> createState() => _EditableChartTitleState();
}

class _EditableChartTitleState extends ConsumerState<EditableChartTitle> {
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
  void didUpdateWidget(covariant EditableChartTitle oldWidget) {
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