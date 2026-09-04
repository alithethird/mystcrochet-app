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

/// Approximate circumscribed radius (px) used when migrating per-stitch drag
/// offsets across a shape switch (angleOffset ⇄ perimeterOffset conversion).
/// Real per-round radius grows with stitch heights; we use a rough proxy
/// faithful enough that drag offsets round-trip within a few pixels.
double _approxRadiusForRound(int roundNumber) => 50 + 30.0 * (roundNumber - 1).clamp(0, 50).toDouble();

class ShapePanel extends ConsumerStatefulWidget {
  const ShapePanel({super.key});

  @override
  ConsumerState<ShapePanel> createState() => _ShapePanelState();
}

class _ShapePanelState extends ConsumerState<ShapePanel> {
  late TextEditingController _cornerCtrl;
  late FocusNode _cornerFocus;
  String _lastCommitted = '';

  @override
  void initState() {
    super.initState();
    final chart = ref.read(chartProvider).chart;
    _lastCommitted = '${(chart.guidelines.visualCornerRatio * 100).round()}';
    _cornerCtrl = TextEditingController(text: _lastCommitted);
    _cornerFocus = FocusNode();
    // Sync the text field if the chart's ratio changes elsewhere (e.g. via the
    // slider, undo/redo) — but only while the field isn't being edited.
    ref.listenManual(chartProvider, (prev, next) {
      if (_cornerFocus.hasFocus) return;
      final pct = '${(next.chart.guidelines.visualCornerRatio * 100).round()}';
      if (_cornerCtrl.text != pct) {
        _cornerCtrl.text = pct;
        _lastCommitted = pct;
      }
    });
  }

  @override
  void dispose() {
    _cornerCtrl.dispose();
    _cornerFocus.dispose();
    super.dispose();
  }

  void _applyCornerRatio(String v) {
    final raw = double.tryParse(v.trim());
    if (raw == null) return;
    final pct = raw.clamp(0.0, 45.0);
    final ratio = pct / 100.0;
    final chart = ref.read(chartProvider).chart;
    if (ratio == chart.guidelines.visualCornerRatio) return;
    final notifier = ref.read(chartProvider.notifier);
    notifier.setChart(chart.copyWith(
      guidelines: chart.guidelines.copyWith(visualCornerRatio: ratio),
    ));
  }

  void _switchShape(int newSides) {
    final chart = ref.read(chartProvider).chart;
    final oldSides = chart.guidelines.visualShapeSides;
    if (newSides == oldSides) return;

    final fromPolygon = oldSides >= 3;
    final toPolygon = newSides >= 3;

    List<PatternRound> migrated = chart.patternRounds;
    if (fromPolygon != toPolygon) {
      migrated = chart.patternRounds.map((round) {
        final r = _approxRadiusForRound(round.number);
        return PatternRound(
          number: round.number,
          isMagicRing: round.isMagicRing,
          stitches: round.stitches.map((s) {
            if (toPolygon) {
              // Circle -> polygon: convert drag offset (radians -> pixels).
              final ao = s.angleOffset;
              if (ao == null) return s;
              return s.copyWith(perimeterOffset: ao * r);
            } else {
              // Polygon -> circle: convert drag offset (pixels -> radians).
              final po = s.perimeterOffset;
              if (po == null) return s;
              return s.copyWith(angleOffset: po / r);
            }
          }).toList(),
        );
      }).toList();
    }

    final notifier = ref.read(chartProvider.notifier);
    notifier.setChart(chart.copyWith(
      patternRounds: assignConnections(migrated),
      guidelines: chart.guidelines.copyWith(visualShapeSides: newSides),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final chart = ref.watch(chartProvider).chart;
    final sides = chart.guidelines.visualShapeSides;
    final ratio = chart.guidelines.visualCornerRatio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Round Shape',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          initialValue: sides,
          decoration: const InputDecoration(
            isDense: true,
            labelText: 'Shape',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: 0, child: Text('Circle')),
            for (var n = 3; n <= 12; n++)
              DropdownMenuItem(value: n, child: Text('$n sides')),
          ],
          onChanged: (v) => _switchShape(v ?? 0),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Corner radius:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: Focus(
                focusNode: _cornerFocus,
                child: TextField(
                  controller: _cornerCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    suffixText: '%',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 12),
                  onSubmitted: (v) {
                    _applyCornerRatio(v);
                    _lastCommitted = _cornerCtrl.text;
                    _cornerFocus.unfocus();
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Slider(
                value: ratio,
                min: 0,
                max: 0.45,
                divisions: 45,
                label: '${(ratio * 100).round()}%',
                onChanged: (v) {
                  final notifier = ref.read(chartProvider.notifier);
                  notifier.setChart(chart.copyWith(
                    guidelines:
                        chart.guidelines.copyWith(visualCornerRatio: v),
                  ));
                  _cornerCtrl.text = '${(v * 100).round()}';
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          sides == 0
              ? 'Circles have no corner rounding. Pick 3-12 sides for a polygonal chart.'
              : 'Rounds render as a $sides-sided polygon with ${ratio == 0 ? "sharp" : "rounded"} corners.',
          style: const TextStyle(fontSize: 10, color: Color(0xFF999999)),
        ),
      ],
    );
  }
}