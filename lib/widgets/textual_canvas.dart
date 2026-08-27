import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/guidelines.dart';
import '../models/visual_stitch.dart';
import '../providers/chart_provider.dart';
import '../providers/edit_mode_provider.dart';
import '../providers/stitch_provider.dart';

class TextualCanvas extends ConsumerStatefulWidget {
  const TextualCanvas({super.key});

  @override
  ConsumerState<TextualCanvas> createState() => _TextualCanvasState();
}

class _TextualCanvasState extends ConsumerState<TextualCanvas> {
  final TransformationController _transform = TransformationController();

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chartState = ref.watch(chartProvider);
    final editState = ref.watch(editModeProvider);
    final stitchNotifier = ref.watch(stitchStoreProvider);
    final chart = chartState.chart;
    final visualStitches = chart.visualStitches;
    final options = chart.guidelines;

    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          InteractiveViewer(
            transformationController: _transform,
            minScale: 0.25,
            maxScale: 4,
            panEnabled: editState.mode == EditMode.pan,
            child: SizedBox(
              width: 800,
              height: 800,
              child: CustomPaint(
                painter: _TextualCanvasPainter(
                  visualStitches: visualStitches,
                  options: options,
                  stitchNotifier: stitchNotifier,
                  mode: editState.mode,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextualCanvasPainter extends CustomPainter {
  final List<VisualStitch> visualStitches;
  final Guidelines options;
  final StitchStoreNotifier stitchNotifier;
  final EditMode mode;

  _TextualCanvasPainter({
    required this.visualStitches,
    required this.options,
    required this.stitchNotifier,
    required this.mode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final rounds = options.visualRounds;
    final spacing = options.visualRoundSpacing;
    final radialDivisions = options.visualRadialDivisions;

    final gridPaint = Paint()
      ..color = const Color(0xFFD4D4D4)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= rounds; i++) {
      canvas.drawCircle(Offset.zero, i * spacing, gridPaint);
    }

    if (radialDivisions > 0) {
      final step = 6.283185 / radialDivisions;
      final extent = rounds * spacing + 10;
      for (int i = 0; i < radialDivisions; i++) {
        final angle = i * step;
        canvas.drawLine(
          Offset.zero,
          Offset(extent * cos(angle), extent * sin(angle)),
          Paint()..color = const Color(0xFFECECEC)..strokeWidth = 0.5,
        );
      }
    }

    canvas.drawCircle(Offset.zero, 3, Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TextualCanvasPainter oldDelegate) => true;
}
