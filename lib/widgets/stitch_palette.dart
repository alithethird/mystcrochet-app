import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/stitch_provider.dart';
import '../utils/svg.dart';

class StitchPalette extends ConsumerWidget {
  final VoidCallback? onClose;

  const StitchPalette({super.key, this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stitchNotifier = ref.watch(stitchStoreProvider);
    final store = stitchNotifier.store;
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
                const Text('Stitches',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onClose,
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
                    label: 'All',
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
                    onPressed: onClose,
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
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search...',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 12),
              onChanged: (v) =>
                  ref.read(stitchStoreProvider.notifier).setSearchText(v),
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
                return ListTile(
                  dense: true,
                  selected: isSelected,
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
                  onTap: () => ref
                      .read(stitchStoreProvider.notifier)
                      .setActiveStitchName(stitch.name),
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
