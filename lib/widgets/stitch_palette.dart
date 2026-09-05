import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/chart_provider.dart';
import '../providers/edit_mode_provider.dart';
import '../providers/stitch_provider.dart';
import '../services/stitch_replace_service.dart';
import '../utils/svg.dart';

class StitchPalette extends ConsumerStatefulWidget {
  final VoidCallback? onClose;

  const StitchPalette({super.key, this.onClose});

  @override
  ConsumerState<StitchPalette> createState() => _StitchPaletteState();
}

class _StitchPaletteState extends ConsumerState<StitchPalette> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(stitchStoreProvider).store.searchText,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(stitchStoreProvider.notifier).setSearchText('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final stitchNotifier = ref.watch(stitchStoreProvider);
    final store = stitchNotifier.store;
    if (store.searchText.isEmpty && _searchController.text.isNotEmpty) {
      _searchController.text = '';
    }
    final stitches = store.filtered;
    final categories = store.categories;
    final activeCategory = store.activeCategory;
    final activeStitchName = store.activeStitchName;

    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              children: [
                const Text('İlmekler',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: widget.onClose,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              children: [
                ...categories.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: _CategoryChip(
                        label: cat,
                        selected: activeCategory == cat,
                        onTap: () => ref
                            .read(stitchStoreProvider.notifier)
                            .setActiveCategory(cat),
                      ),
                    )),
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _CategoryChip(
                    label: 'Tümü',
                    selected: activeCategory == null,
                    onTap: () => ref
                        .read(stitchStoreProvider.notifier)
                        .setActiveCategory(null),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                  child: IconButton(
                    onPressed: widget.onClose,
                    alignment: Alignment.center,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'İlmek ara...',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 12),
                    onChanged: (v) {
                      setState(() {});
                      ref.read(stitchStoreProvider.notifier).setSearchText(v);
                    },
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  key: const ValueKey('clear_search_button'),
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: 'Aramayı temizle',
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: (_searchController.text.isNotEmpty ||
                          store.searchText.isNotEmpty)
                      ? _clearSearch
                      : null,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: stitches.length,
              itemBuilder: (context, index) {
                final stitch = stitches[index];
                final isSelected = activeStitchName == stitch.name;
                final colored =
                    substituteColors(stitch.svgContent, '#000000', '#ffffff');
                return Material(
                  child: ListTile(
                  dense: true,
                  selected: isSelected,
                  selectedTileColor: Colors.pink[100],
                  leading: SizedBox(
                    width: 28,
                    height: 28,
                    child: SvgPicture.string(
                      colored,
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                  ),
                  title:
                      Text(stitch.name, style: const TextStyle(fontSize: 12)),
                  onTap: () {
                    final editState = ref.read(editModeProvider);

                    // If multiple stitches are selected, replace all selected stitches
                    if (editState.selectedStitchKeys.isNotEmpty) {
                      final chartNotifier = ref.read(chartProvider.notifier);
                      final result = replaceSelectedStitches(
                        chart: chartNotifier.chart,
                        selectedKeys: editState.selectedStitchKeys,
                        newStitchName: stitch.name,
                      );

                      if (result.replacedCount > 0) {
                        chartNotifier.setChart(result.updatedChart, recordUndo: true);
                        ref.read(editModeProvider.notifier).clearSelection();
                        ref.read(editModeProvider.notifier).clearReplaceTarget();
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${result.replacedCount} adet seçili ilmek "${stitch.name}" ile değiştirildi.',
                            ),
                            backgroundColor: const Color(0xFF16A34A),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                      return;
                    }

                    if (editState.mode == EditMode.replace) {
                      if (editState.replaceStitchName == null) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Lütfen önce grafikten değiştirmek istediğiniz ilmeğe dokunun.'),
                            backgroundColor: Color(0xFFD97706),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      final chartNotifier = ref.read(chartProvider.notifier);
                      final currentChart = chartNotifier.chart;
                      final result = replaceStitches(
                        chart: currentChart,
                        newStitchName: stitch.name,
                        bulk: editState.bulkReplace,
                        targetVisualRoundIdx: editState.replaceRoundIdx,
                        targetExpandedStitchIdx: editState.replaceStitchIdx,
                        targetStitchName: editState.replaceStitchName,
                      );

                      if (result.replacedCount > 0) {
                        chartNotifier.setChart(result.updatedChart, recordUndo: true);
                        ref.read(editModeProvider.notifier).clearReplaceTarget();
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              editState.bulkReplace
                                  ? '${result.replacedCount} adet ilmek "${stitch.name}" ile değiştirildi.'
                                  : 'İlmek "${stitch.name}" ile değiştirildi.',
                            ),
                            backgroundColor: const Color(0xFF16A34A),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                      return;
                    }

                    ref
                        .read(stitchStoreProvider.notifier)
                        .setActiveStitchName(stitch.name);
                    ref
                        .read(editModeProvider.notifier)
                        .setMode(EditMode.stitch);
                  },
                ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3B82F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF3B82F6) : const Color(0xFFCCCCCC),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
