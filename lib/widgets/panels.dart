import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/guidelines.dart';
import '../models/pattern.dart';
import '../providers/chart_provider.dart';
import '../providers/edit_mode_provider.dart';

class PropertiesPanel extends ConsumerWidget {
  const PropertiesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartState = ref.watch(chartProvider);
    final editState = ref.watch(editModeProvider);
    final chart = chartState.chart;

    final styleLabel = chart.style == GuidelinesType.visual ? 'Visual' : 'Textual';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _propRow('Name', chart.name),
        _propRow('Style', styleLabel),
        _propRow('Rounds', '${chart.patternRounds.length}'),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Rounds:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.remove, size: 16),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
              onPressed: chart.patternRounds.isNotEmpty
                  ? () {
                      final notifier = ref.read(chartProvider.notifier);
                      final rounds = List<PatternRound>.from(chart.patternRounds)..removeLast();
                      notifier.setChart(chart.copyWith(patternRounds: assignConnections(rounds)));
                    }
                  : null,
            ),
            SizedBox(
              width: 32,
              child: Text(
                '${chart.patternRounds.length}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 16),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
              onPressed: () {
                final notifier = ref.read(chartProvider.notifier);
                final rounds = List<PatternRound>.from(chart.patternRounds)
                  ..add(PatternRound(number: chart.patternRounds.length + 1, stitches: []));
                notifier.setChart(chart.copyWith(patternRounds: assignConnections(rounds)));
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Zoom:', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: Slider(
                value: editState.zoom,
                min: 0.25,
                max: 4,
                onChanged: (v) => ref.read(editModeProvider.notifier).setZoom(v),
              ),
            ),
            Text('${(editState.zoom * 100).round()}%', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _propRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

class PatternPanel extends ConsumerStatefulWidget {
  final void Function(List<dynamic> rounds)? onParse;

  const PatternPanel({super.key, this.onParse});

  @override
  ConsumerState<PatternPanel> createState() => _PatternPanelState();
}

class _PatternPanelState extends ConsumerState<PatternPanel> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pattern Text', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(
          controller: _controller,
          maxLines: 8,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Paste your pattern here...',
            isDense: true,
          ),
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: () {
            final text = _controller.text;
            if (text.trim().isEmpty) return;
            final parsed = parsePattern(text);
            if (parsed.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No rounds found in pattern text')),
              );
              return;
            }
            widget.onParse?.call(parsed.map((r) => r.toJson()).toList());
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Parsed ${parsed.length} round(s)')),
            );
          },
          icon: const Icon(Icons.auto_awesome, size: 16),
          label: const Text('Parse Pattern', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}