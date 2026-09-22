import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/chart.dart';
import '../models/visual_stitch.dart';
import '../models/yarn_render_config.dart';

/// Helper to extract/flatten VisualStitch items from either visualStitches or patternRounds
List<VisualStitch> extractStitchesFromChart(Chart chart) {
  if (chart.visualStitches.isNotEmpty) {
    return chart.visualStitches;
  }

  final list = <VisualStitch>[];
  if (chart.patternRounds.isEmpty) return list;

  for (int r = 0; r < chart.patternRounds.length; r++) {
    final round = chart.patternRounds[r];
    final stitches = round.stitches.where((s) => s.kind != 'magicRing').toList();
    if (stitches.isEmpty) continue;

    final radius = 50.0 + r * 45.0 + (round.radiusOffset ?? 0.0);
    final count = stitches.length;
    final angleStep = (2.0 * math.pi) / count;

    for (int i = 0; i < count; i++) {
      final s = stitches[i];
      final angle = i * angleStep;
      final x = radius * math.cos(angle);
      final y = radius * math.sin(angle);
      final name = s.name ?? s.kind;

      list.add(VisualStitch(
        id: 'pr_${r}_$i',
        stitchName: name,
        x: x,
        y: y,
        roundIndex: r,
        rotation: angle,
      ));
    }
  }

  return list;
}

/// Procedural 2D Realistic Yarn Renderer:
/// Renders 2D realistic yarn textures, multi-ply strand winding, drop shadows, and halo fuzziness.
class ProceduralYarn2DEngine {
  static void render(
    Canvas canvas,
    Size size,
    Chart chart,
    YarnRenderConfig config,
  ) {
    final stitches = extractStitchesFromChart(chart);
    final hasStarter = chart.starterStitchName != null && chart.starterStitchName!.isNotEmpty;

    if (stitches.isEmpty && !hasStarter) {
      _drawEmptyPlaceholder(canvas, size);
      return;
    }

    // 1. Draw Background
    if (config.showBackgroundGrid) {
      _drawSurfaceBackground(canvas, size, config);
    }

    // 2. Calculate 2D Bounds to center motif
    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (final v in stitches) {
      if (v.x < minX) minX = v.x;
      if (v.x > maxX) maxX = v.x;
      if (v.y < minY) minY = v.y;
      if (v.y > maxY) maxY = v.y;
    }

    if (minX == double.infinity) {
      minX = -100;
      maxX = 100;
      minY = -100;
      maxY = 100;
    }

    final centerX = (minX + maxX) / 2;
    final centerY = (minY + maxY) / 2;
    final boundsW = math.max(120.0, maxX - minX);
    final boundsH = math.max(120.0, maxY - minY);
    final motifScale = (math.min(size.width, size.height) * 0.7) / math.max(boundsW, boundsH) * config.cameraZoom;

    final centerOffset = Offset(
      size.width / 2 + config.cameraYaw * 100, // Pan X offset from yaw
      size.height / 2 + config.cameraPitch * 100, // Pan Y offset from pitch
    );

    canvas.save();
    canvas.translate(centerOffset.dx, centerOffset.dy);

    final random = math.Random(12345);

    // 3. Draw Starter Ring (Magic Ring) if present
    if (hasStarter) {
      _draw2DStarterRing(canvas, motifScale, config);
    }

    // Group stitches by roundIndex to draw interconnecting yarn loops per round
    final roundMap = <int, List<VisualStitch>>{};
    for (final s in stitches) {
      roundMap.putIfAbsent(s.roundIndex, () => []).add(s);
    }

    // 4. Draw Interconnecting Round Yarn Loops (Background Fabric Connection)
    final sortedRounds = roundMap.keys.toList()..sort();
    for (final r in sortedRounds) {
      final roundStitches = roundMap[r]!;
      final roundColorHex = config.roundColors[r] ?? (roundStitches.isNotEmpty ? roundStitches.first.fgColor : '#000000');
      final yarnColor = _parseColor(roundColorHex);

      _drawRoundYarnConnections(canvas, roundStitches, centerX, centerY, motifScale, yarnColor, config);
    }

    // 5. Draw Individual 2D Realistic Yarn Stitches (Drop Shadows + Helical Strands)
    for (final v in stitches) {
      final relX = (v.x - centerX) * motifScale;
      final relY = (v.y - centerY) * motifScale;
      final rawColorHex = config.roundColors[v.roundIndex] ?? v.fgColor;
      final yarnColor = _parseColor(rawColorHex);

      _draw2DStitch(
        canvas: canvas,
        stitch: v,
        x: relX,
        y: relY,
        color: yarnColor,
        motifScale: motifScale,
        config: config,
        random: random,
      );
    }

    canvas.restore();
  }

  static void _draw2DStarterRing(Canvas canvas, double scale, YarnRenderConfig config) {
    const ringRadius = 22.0;
    final r = ringRadius * scale;
    final thickness = 3.2 * config.thickness * scale;

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..strokeWidth = thickness + 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(const Offset(2, 3), r, shadowPaint);

    // Main Yarn Ring
    final ringPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset.zero, r, ringPaint);

    // Inner twist detail
    final twistPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = thickness * 0.4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset.zero, r * 0.88, twistPaint);
  }

  static void _drawRoundYarnConnections(
    Canvas canvas,
    List<VisualStitch> stitches,
    double centerX,
    double centerY,
    double scale,
    Color color,
    YarnRenderConfig config,
  ) {
    if (stitches.length < 2) return;

    final path = Path();
    for (int i = 0; i < stitches.length; i++) {
      final s = stitches[i];
      final x = (s.x - centerX) * scale;
      final y = (s.y - centerY) * scale;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Connecting Yarn Stroke Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..strokeWidth = (2.2 * config.thickness * scale) + 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path.shift(const Offset(1.5, 2.0)), shadowPaint);

    // Connecting Yarn Stroke
    final yarnPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 2.2 * config.thickness * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, yarnPaint);
  }

  static void _draw2DStitch({
    required Canvas canvas,
    required VisualStitch stitch,
    required double x,
    required double y,
    required Color color,
    required double motifScale,
    required YarnRenderConfig config,
    required math.Random random,
  }) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(stitch.rotation);

    final name = stitch.stitchName.toLowerCase();
    final baseThickness = 2.4 * config.thickness * motifScale;

    // Helper for rendering yarn strand path with drop shadow & multi-ply twist
    void drawYarnStroke(Path path, {double radiusMultiplier = 1.0}) {
      final strokeW = baseThickness * radiusMultiplier;

      // 1. Drop Shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..strokeWidth = strokeW + 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path.shift(const Offset(1.5, 2.5)), shadowPaint);

      // 2. Base Shaded Yarn Stroke
      final basePaint = Paint()
        ..color = color
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, basePaint);

      // 3. Highlight Strand (Top specular ridge)
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..strokeWidth = strokeW * 0.35
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path.shift(const Offset(-0.8, -0.8)), highlightPaint);

      // 4. Yarn Fuzziness (halo hairs)
      if (config.fuzziness > 0.05 && random.nextDouble() < config.fuzziness) {
        final metrics = path.computeMetrics();
        for (final metric in metrics) {
          final len = metric.length;
          for (double t = 0; t < len; t += 12.0) {
            final tangent = metric.getTangentForOffset(t);
            if (tangent != null) {
              final hLen = (2.0 + random.nextDouble() * 4.0) * config.fuzziness * motifScale;
              final hAngle = random.nextDouble() * 2 * math.pi;
              final hairPaint = Paint()
                ..color = color.withValues(alpha: 0.4 * config.fuzziness)
                ..strokeWidth = 0.8;
              canvas.drawLine(
                tangent.position,
                tangent.position + Offset(math.cos(hAngle) * hLen, math.sin(hAngle) * hLen),
                hairPaint,
              );
            }
          }
        }
      }
    }

    // Single Crochet / Double Crochet / Treble / Half Double
    if (name.contains('dc') || name.contains('tr') || name.contains('hdc') || name.contains('sc')) {
      final h = name.contains('tr') ? 32.0 : (name.contains('dc') ? 26.0 : (name.contains('hdc') ? 18.0 : 12.0));
      final scaledH = h * motifScale;

      // Post (vertical leg)
      final postPath = Path()
        ..moveTo(0, scaledH / 2)
        ..lineTo(0, -scaledH / 2);
      drawYarnStroke(postPath);

      // Top V-Head Loop
      final vHeadPath = Path()
        ..moveTo(-8 * motifScale, -scaledH / 2 - 4 * motifScale)
        ..quadraticBezierTo(0, -scaledH / 2, 8 * motifScale, -scaledH / 2 - 4 * motifScale);
      drawYarnStroke(vHeadPath, radiusMultiplier: 0.85);

      // Crossbars for dc/tr
      if (name.contains('dc') || name.contains('tr')) {
        final barPath = Path()
          ..moveTo(-5 * motifScale, -2 * motifScale)
          ..lineTo(5 * motifScale, 2 * motifScale);
        drawYarnStroke(barPath, radiusMultiplier: 0.75);
      }
    }
    // Chain (ch)
    else if (name.contains('ch') || name.contains('chain')) {
      final chPath = Path()
        ..addOval(Rect.fromCenter(
          center: Offset.zero,
          width: 22 * motifScale,
          height: 12 * motifScale,
        ));
      drawYarnStroke(chPath, radiusMultiplier: 0.9);
    }
    // Slip stitch / Default
    else {
      final slPath = Path()
        ..moveTo(-8 * motifScale, 0)
        ..lineTo(8 * motifScale, 0);
      drawYarnStroke(slPath, radiusMultiplier: 0.8);
    }

    canvas.restore();
  }

  static void _drawSurfaceBackground(Canvas canvas, Size size, YarnRenderConfig config) {
    final bgPaint = Paint()..color = _parseColor(config.backgroundColorHex);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final gridPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  static void _drawEmptyPlaceholder(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Motifte gösterilecek ilmek bulunamadı.\n2D kanvasta ilmek çizmeye başlayın.',
        style: TextStyle(color: Color(0xFF64748B), fontSize: 15, height: 1.4),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 40);

    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
    );
  }

  static Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF333333);
  }
}
