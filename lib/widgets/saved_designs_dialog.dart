import 'package:flutter/material.dart';
import '../models/chart.dart';
import '../services/chart_file_service.dart';
import '../services/local_design_service.dart';

class SavedDesignsDialog extends StatefulWidget {
  final Chart currentChart;
  final void Function(Chart chart) onSelect;

  const SavedDesignsDialog({
    super.key,
    required this.currentChart,
    required this.onSelect,
  });

  @override
  State<SavedDesignsDialog> createState() => _SavedDesignsDialogState();
}

class _SavedDesignsDialogState extends State<SavedDesignsDialog> {
  List<SavedDesign> _designs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDesigns();
  }

  Future<void> _loadDesigns() async {
    setState(() => _isLoading = true);
    final list = await LocalDesignService.getSavedDesigns();
    if (mounted) {
      setState(() {
        _designs = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCurrentDesign() async {
    final controller = TextEditingController(
      text: widget.currentChart.name.isNotEmpty ? widget.currentChart.name : 'Yeni Tasarım',
    );

    final saveName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tasarımı Yerel Hafızaya Kaydet'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Tasarım Adı',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (val) => Navigator.of(ctx).pop(val.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (saveName != null && saveName.isNotEmpty) {
      await LocalDesignService.saveDesign(widget.currentChart, name: saveName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$saveName" yerel hafızaya kaydedildi.'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
        _loadDesigns();
      }
    }
  }

  Future<void> _confirmDelete(SavedDesign design) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tasarımı Sil'),
        content: Text('"${design.name}" tasarımını yerel hafızadan silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await LocalDesignService.deleteDesign(design.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${design.name}" silindi.'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
        _loadDesigns();
      }
    }
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d.$m.$y $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.collections_bookmark_outlined, color: Color(0xFF6750A4), size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Kayıtlı Tasarımlar',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    key: const ValueKey('saved_designs_save_current_button'),
                    icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                    label: const Text('Mevcut Grafiği Kaydet', style: TextStyle(fontSize: 12)),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onPressed: _saveCurrentDesign,
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Kapat',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Bu cihazda / tarayıcıda yerel olarak saklanan önceki tasarımlarınız.',
                style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
              ),
              const Divider(height: 24),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _designs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.folder_open_outlined, size: 54, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                const Text(
                                  'Henüz yerel olarak kaydedilmiş tasarım bulunmuyor.',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF555555)),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Üzerinde çalıştığınız grafiği yukarıdaki "Mevcut Grafiği Kaydet" butonu ile ekleyebilirsiniz.',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _designs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final d = _designs[index];
                              return Container(
                                key: ValueKey('saved_design_card_${d.id}'),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3E8FF),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.gesture,
                                        color: Color(0xFF7E22CE),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            d.name,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              Text(
                                                _formatDate(d.updatedAt),
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEFF6FF),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                                ),
                                                child: Text(
                                                  '${d.roundCount} Tur',
                                                  style: const TextStyle(fontSize: 10, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF0FDF4),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: const Color(0xFFBBF7D0)),
                                                ),
                                                child: Text(
                                                  '${d.stitchCount} İlmek',
                                                  style: const TextStyle(fontSize: 10, color: Color(0xFF15803D), fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton.icon(
                                      key: ValueKey('saved_design_open_${d.id}'),
                                      icon: const Icon(Icons.folder_open, size: 16),
                                      label: const Text('Yükle'),
                                      style: FilledButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        widget.onSelect(d.toChart());
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      key: ValueKey('saved_design_download_${d.id}'),
                                      icon: const Icon(Icons.download, size: 18),
                                      tooltip: '.crochet olarak İndir',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () async {
                                        final chart = d.toChart();
                                        final fileName = '${d.name.replaceAll(' ', '_')}.crochet';
                                        await ChartFileService.saveChart(chart, fileName);
                                      },
                                    ),
                                    IconButton(
                                      key: ValueKey('saved_design_delete_${d.id}'),
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                                      tooltip: 'Sil',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _confirmDelete(d),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
