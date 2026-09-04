import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chart_provider.dart';

class TextViewDialog extends ConsumerWidget {
  final VoidCallback onClose;

  const TextViewDialog({super.key, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chart = ref.watch(chartProvider).chart;
    final json = chart.toJson();

    return AlertDialog(
      title: const Text('Grafik Verisi (JSON)'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: SingleChildScrollView(
          child: SelectableText(
            _formatJson(json),
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
          ),
        ),
      ),
      actions: [
        FilledButton(onPressed: onClose, child: const Text('Kapat')),
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