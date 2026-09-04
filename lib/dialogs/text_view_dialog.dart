import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chart_provider.dart';
import '../services/chart_file_service.dart';

class TextViewDialog extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final VoidCallback? onOpenFile;

  const TextViewDialog({super.key, required this.onClose, this.onOpenFile});

  @override
  ConsumerState<TextViewDialog> createState() => _TextViewDialogState();
}

class _TextViewDialogState extends ConsumerState<TextViewDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _importController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importController.dispose();
    super.dispose();
  }

  void _handleImport() {
    final text = _importController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen içe aktarılacak JSON verisini yapıştırın.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final chart = ChartFileService.parseChartJson(text);
      ref.read(chartProvider.notifier).loadChart(chart);
      widget.onClose();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${chart.name.isNotEmpty ? chart.name : "Grafik"} başarıyla içe aktarıldı.'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'İçe aktarma hatası: ${e is FormatException ? e.message : "Geçersiz JSON"}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chart = ref.watch(chartProvider).chart;
    final json = chart.toJson();
    final formattedJson = _formatJson(json);

    return AlertDialog(
      title: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.code), text: 'Veri (JSON)'),
          Tab(icon: Icon(Icons.file_download), text: 'İçe Aktar (Import)'),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 420,
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: View / Copy JSON
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        formattedJson,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: formattedJson));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('JSON panoya kopyalandı.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Panoya Kopyala'),
                ),
              ],
            ),
            // Tab 2: Import JSON / File
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Kaydedilmiş bir .crochet veya .json dosyasının içeriğini buraya yapıştırıp içe aktarabilirsiniz:',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TextField(
                    controller: _importController,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      hintText: '{\n  "name": "...",\n  "patternRounds": [...]\n}',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (widget.onOpenFile != null)
                      OutlinedButton.icon(
                        onPressed: () {
                          widget.onClose();
                          widget.onOpenFile!();
                        },
                        icon: const Icon(Icons.folder_open, size: 16),
                        label: const Text('Dosyadan Aç'),
                      ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _handleImport,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('İçe Aktar & Yükle'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onClose, child: const Text('Kapat')),
      ],
    );
  }

  String _formatJson(Map<String, dynamic> json) {
    try {
      return const JsonEncoder.withIndent('  ').convert(json);
    } catch (_) {
      return json.toString();
    }
  }
}