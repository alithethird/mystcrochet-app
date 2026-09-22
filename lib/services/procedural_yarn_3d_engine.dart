import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/chart.dart';
import '../models/visual_stitch.dart';
import '../models/yarn_render_config.dart';
import 'procedural_yarn_2d_engine.dart';

/// Represents a point in 3D space
class Point3D {
  final double x;
  final double y;
  final double z;

  const Point3D(this.x, this.y, this.z);

  Point3D operator +(Point3D other) => Point3D(x + other.x, y + other.y, z + other.z);
  Point3D operator -(Point3D other) => Point3D(x - other.x, y - other.y, z - other.z);
  Point3D operator *(double scale) => Point3D(x * scale, y * scale, z * scale);

  double get length => math.sqrt(x * x + y * y + z * z);

  Point3D normalized() {
    final len = length;
    if (len < 1e-6) return const Point3D(0, 0, 1);
    return Point3D(x / len, y / len, z / len);
  }

  static double dot(Point3D a, Point3D b) => a.x * b.x + a.y * b.y + a.z * b.z;

  static Point3D cross(Point3D a, Point3D b) {
    return Point3D(
      a.y * b.z - a.z * b.y,
      a.z * b.x - a.x * b.z,
      a.x * b.y - a.y * b.x,
    );
  }
}

/// A segment of yarn tube in 3D space with lighting & color metadata
class YarnStrandSegment {
  final Point3D start;
  final Point3D end;
  final Point3D normal;
  final Color color;
  final double radius;
  final int strandIndex;
  final double depth; // Projected Z depth for sorting

  YarnStrandSegment({
    required this.start,
    required this.end,
    required this.normal,
    required this.color,
    required this.radius,
    required this.strandIndex,
    required this.depth,
  });
}

/// Engine that procedurally converts 2D Chart stitches into 3D realistic yarn curves and renders them.
class ProceduralYarn3DEngine {
  /// Render the chart in 3D on a Canvas within [size].
  static void render(
    Canvas canvas,
    Size size,
    Chart chart,
    YarnRenderConfig config,
  ) {
    final stitches = extractStitchesFromChart(chart);

    if (stitches.isEmpty && (chart.starterStitchName == null || chart.starterStitchName!.isEmpty)) {
      _drawEmptyPlaceholder(canvas, size);
      return;
    }

    // 1. Draw background grid/table surface if enabled
    if (config.showBackgroundGrid) {
      _drawSurfaceBackground(canvas, size, config);
    }

    // 2. Compute 2D bounds to center the motif
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
    final boundsWidth = math.max(100.0, maxX - minX);
    final boundsHeight = math.max(100.0, maxY - minY);
    final motifScale = (math.min(size.width, size.height) * 0.7) / math.max(boundsWidth, boundsHeight) * config.cameraZoom;

    // 3. Build 3D Yarn Curves for all stitches in the chart
    final segments = <YarnStrandSegment>[];
    final random = math.Random(42); // Deterministic seed for fiber fuzziness

    // Center point in 3D
    final center3D = Point3D(size.width / 2, size.height / 2, 0);

    // Directional light vector calculated from lightAngle
    final lightRad = config.lightAngle * math.pi / 180.0;
    final lightVector = Point3D(math.cos(lightRad), -math.sin(lightRad), 1.2).normalized();

    // Starter Ring (Magic Ring) if present
    if (chart.starterStitchName != null && chart.starterStitchName!.isNotEmpty) {
      _generateStarterRingSegments(
        segments: segments,
        center3D: center3D,
        radius: 18.0 * motifScale,
        config: config,
      );
    }

    // Sort stitches by round index & layer to construct yarn connections
    final sortedStitches = List<VisualStitch>.from(stitches);
    sortedStitches.sort((a, b) {
      if (a.roundIndex != b.roundIndex) return a.roundIndex.compareTo(b.roundIndex);
      return a.layer.compareTo(b.layer);
    });

    // Generate 3D yarn curves per stitch
    for (int i = 0; i < sortedStitches.length; i++) {
      final v = sortedStitches[i];

      // Convert 2D canvas coords to 3D centered space
      final relX = (v.x - centerX) * motifScale;
      final relY = (v.y - centerY) * motifScale;

      // Z depth layering: higher rounds/layers sit slightly above lower ones
      final zDepth = (v.roundIndex + 1) * 8.0 + (v.layer * 4.0);

      // Determine yarn color for this stitch (check round color overrides)
      final rawColorHex = config.roundColors[v.roundIndex] ?? v.fgColor;
      final yarnColor = _parseColor(rawColorHex);

      // Generate 3D curves based on stitch type
      _generateStitchYarnCurves(
        segments: segments,
        stitch: v,
        relX: relX,
        relY: relY,
        zDepth: zDepth,
        color: yarnColor,
        motifScale: motifScale,
        config: config,
        allStitches: sortedStitches,
        currentIndex: i,
      );
    }

    // 4. Transform all segments with 3D Camera Rotation (Pitch & Yaw)
    final transformedSegments = <YarnStrandSegment>[];
    final cosP = math.cos(config.cameraPitch);
    final sinP = math.sin(config.cameraPitch);
    final cosY = math.cos(config.cameraYaw);
    final sinY = math.sin(config.cameraYaw);

    for (final seg in segments) {
      final p1 = _transformPoint(seg.start, center3D, cosP, sinP, cosY, sinY);
      final p2 = _transformPoint(seg.end, center3D, cosP, sinP, cosY, sinY);
      final norm = _rotateVector(seg.normal, cosP, sinP, cosY, sinY);

      final avgZ = (p1.z + p2.z) / 2.0;

      transformedSegments.add(YarnStrandSegment(
        start: p1,
        end: p2,
        normal: norm,
        color: seg.color,
        radius: seg.radius,
        strandIndex: seg.strandIndex,
        depth: avgZ,
      ));
    }

    // 5. Depth Sort: Render furthest segments first (Painter's Algorithm)
    transformedSegments.sort((a, b) => a.depth.compareTo(b.depth));

    // 6. Render Segments onto Canvas with Shading & Highlights
    for (final seg in transformedSegments) {
      _renderSegment(canvas, seg, lightVector, config, random);
    }
  }

  static Point3D _transformPoint(
    Point3D p,
    Point3D center,
    double cosP,
    double sinP,
    double cosY,
    double sinY,
  ) {
    // Translate relative to center
    double dx = p.x - center.x;
    double dy = p.y - center.y;
    double dz = p.z;

    // Yaw rotation around Y axis
    double x1 = dx * cosY + dz * sinY;
    double y1 = dy;
    double z1 = -dx * sinY + dz * cosY;

    // Pitch rotation around X axis
    double x2 = x1;
    double y2 = y1 * cosP - z1 * sinP;
    double z2 = y1 * sinP + z1 * cosP;

    return Point3D(center.x + x2, center.y + y2, z2);
  }

  static Point3D _rotateVector(
    Point3D v,
    double cosP,
    double sinP,
    double cosY,
    double sinY,
  ) {
    double x1 = v.x * cosY + v.z * sinY;
    double y1 = v.y;
    double z1 = -v.x * sinY + v.z * cosY;

    double x2 = x1;
    double y2 = y1 * cosP - z1 * sinP;
    double z2 = y1 * sinP + z1 * cosP;

    return Point3D(x2, y2, z2);
  }

  static void _generateStitchYarnCurves({
    required List<YarnStrandSegment> segments,
    required VisualStitch stitch,
    required double relX,
    required double relY,
    required double zDepth,
    required Color color,
    required double motifScale,
    required YarnRenderConfig config,
    required List<VisualStitch> allStitches,
    required int currentIndex,
  }) {
    final name = stitch.stitchName.toLowerCase();
    final rot = stitch.rotation;
    final baseRadius = 2.4 * config.thickness;

    final cosR = math.cos(rot);
    final sinR = math.sin(rot);

    // Helper to rotate local stitch points by stitch.rotation
    Point3D localToWorld(double lx, double ly, double lz) {
      final wx = relX + (lx * cosR - ly * sinR) * motifScale;
      final wy = relY + (lx * sinR + ly * cosR) * motifScale;
      final wz = zDepth + lz * motifScale;
      return Point3D(wx, wy, wz);
    }

    // 1. Double Crochet (dc) / Treble (tr) / Half Double (hdc) / Single (sc)
    if (name.contains('dc') || name.contains('tr') || name.contains('hdc') || name.contains('sc')) {
      final isTall = name.contains('dc') || name.contains('tr');
      final height = name.contains('tr') ? 36.0 : (name.contains('dc') ? 28.0 : (name.contains('hdc') ? 20.0 : 14.0));

      // Post 3D Curve (Main Leg)
      final bottom = localToWorld(0, height / 2, 0);
      final top = localToWorld(0, -height / 2, 4);

      _buildHelicalStrandTube(
        segments: segments,
        start: bottom,
        end: top,
        color: color,
        radius: baseRadius,
        numStrands: 3,
        config: config,
      );

      // Top V-Loop (Stitch Head)
      final topVLeft = localToWorld(-10, -height / 2 - 4, 6);
      final topVRight = localToWorld(10, -height / 2 - 4, 6);

      _buildHelicalStrandTube(
        segments: segments,
        start: top,
        end: topVLeft,
        color: color,
        radius: baseRadius * 0.9,
        numStrands: 2,
        config: config,
      );
      _buildHelicalStrandTube(
        segments: segments,
        start: top,
        end: topVRight,
        color: color,
        radius: baseRadius * 0.9,
        numStrands: 2,
        config: config,
      );

      // Horizontal Crossbars for dc/tr
      if (isTall) {
        final mid1 = localToWorld(-6, -2, 2);
        final mid2 = localToWorld(6, 2, 3);
        _buildHelicalStrandTube(
          segments: segments,
          start: mid1,
          end: mid2,
          color: color.withValues(alpha: 0.9),
          radius: baseRadius * 0.8,
          numStrands: 2,
          config: config,
        );
      }
    }
    // 2. Chain (ch)
    else if (name.contains('ch') || name.contains('chain')) {
      // Loop ellipse
      final pLeft = localToWorld(-12, 0, 2);
      final pTop = localToWorld(0, -6, 4);
      final pRight = localToWorld(12, 0, 2);
      final pBottom = localToWorld(0, 6, 0);

      _buildHelicalStrandTube(segments: segments, start: pLeft, end: pTop, color: color, radius: baseRadius, numStrands: 2, config: config);
      _buildHelicalStrandTube(segments: segments, start: pTop, end: pRight, color: color, radius: baseRadius, numStrands: 2, config: config);
      _buildHelicalStrandTube(segments: segments, start: pRight, end: pBottom, color: color, radius: baseRadius, numStrands: 2, config: config);
      _buildHelicalStrandTube(segments: segments, start: pBottom, end: pLeft, color: color, radius: baseRadius, numStrands: 2, config: config);
    }
    // 3. Slip Stitch (sl st) / General Default
    else {
      final p1 = localToWorld(-8, 0, 1);
      final p2 = localToWorld(8, 0, 1);
      _buildHelicalStrandTube(
        segments: segments,
        start: p1,
        end: p2,
        color: color,
        radius: baseRadius * 0.85,
        numStrands: 2,
        config: config,
      );
    }
  }

  /// Constructs helical 3D multi-strand yarn tubes along a 3D line segment
  static void _buildHelicalStrandTube({
    required List<YarnStrandSegment> segments,
    required Point3D start,
    required Point3D end,
    required Color color,
    required double radius,
    required int numStrands,
    required YarnRenderConfig config,
  }) {
    final dir = (end - start);
    final len = dir.length;
    if (len < 0.5) return;

    final steps = (len / 3.0).clamp(3, 16).toInt();
    final unitDir = dir.normalized();

    // Perpendicular vectors to build tube circle cross section
    Point3D perp1 = Point3D.cross(unitDir, const Point3D(0, 0, 1));
    if (perp1.length < 1e-4) {
      perp1 = Point3D.cross(unitDir, const Point3D(1, 0, 0));
    }
    perp1 = perp1.normalized();
    final perp2 = Point3D.cross(unitDir, perp1).normalized();

    // Multi-ply strand helical winding effect
    const twistRate = 0.8;

    for (int s = 0; s < numStrands; s++) {
      final strandPhase = (s * 2.0 * math.pi / numStrands);

      for (int i = 0; i < steps; i++) {
        final t1 = i / steps;
        final t2 = (i + 1) / steps;

        final p1 = start + (dir * t1);
        final p2 = start + (dir * t2);

        final angle1 = t1 * math.pi * 4.0 * twistRate + strandPhase;
        final angle2 = t2 * math.pi * 4.0 * twistRate + strandPhase;

        final offset1 = (perp1 * math.cos(angle1) + perp2 * math.sin(angle1)) * (radius * 0.4);
        final offset2 = (perp1 * math.cos(angle2) + perp2 * math.sin(angle2)) * (radius * 0.4);

        final strandStart = p1 + offset1;
        final strandEnd = p2 + offset2;

        final norm = (offset1 + offset2).normalized();

        segments.add(YarnStrandSegment(
          start: strandStart,
          end: strandEnd,
          normal: norm,
          color: color,
          radius: radius * 0.65,
          strandIndex: s,
          depth: (strandStart.z + strandEnd.z) / 2.0,
        ));
      }
    }
  }

  static void _generateStarterRingSegments({
    required List<YarnStrandSegment> segments,
    required Point3D center3D,
    required double radius,
    required YarnRenderConfig config,
  }) {
    const numPoints = 16;
    const ringColor = Color(0xFFD97706); // Warm Amber yarn color

    for (int i = 0; i < numPoints; i++) {
      final a1 = (i * 2.0 * math.pi / numPoints);
      final a2 = ((i + 1) * 2.0 * math.pi / numPoints);

      final p1 = Point3D(center3D.x + math.cos(a1) * radius, center3D.y + math.sin(a1) * radius, -4);
      final p2 = Point3D(center3D.x + math.cos(a2) * radius, center3D.y + math.sin(a2) * radius, -4);

      _buildHelicalStrandTube(
        segments: segments,
        start: p1,
        end: p2,
        color: ringColor,
        radius: 2.2 * config.thickness,
        numStrands: 3,
        config: config,
      );
    }
  }

  /// Renders individual 3D yarn segment on Canvas with realistic lighting, specular highlights & fuzziness
  static void _renderSegment(
    Canvas canvas,
    YarnStrandSegment seg,
    Point3D lightVector,
    YarnRenderConfig config,
    math.Random random,
  ) {
    // 1. Phong Lighting calculation
    final nDotL = Point3D.dot(seg.normal, lightVector).clamp(0.0, 1.0);
    final diffuse = 0.45 + (0.55 * nDotL);

    // Specular highlight based on material preset shininess
    final shininess = config.materialPreset.shininess;
    final specFactor = math.pow(nDotL, shininess).toDouble() * 0.35;

    // Apply lighting intensity to yarn color
    final curR = (seg.color.r * 255).round();
    final curG = (seg.color.g * 255).round();
    final curB = (seg.color.b * 255).round();
    final curA = (seg.color.a * 255).round();

    final r = (curR * diffuse + 255 * specFactor).clamp(0, 255).toInt();
    final g = (curG * diffuse + 255 * specFactor).clamp(0, 255).toInt();
    final b = (curB * diffuse + 255 * specFactor).clamp(0, 255).toInt();
    final shadedColor = Color.fromARGB(curA, r, g, b);

    // 2. Draw Main Yarn Strand Stroke
    final paint = Paint()
      ..color = shadedColor
      ..strokeWidth = seg.radius * 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawLine(
      Offset(seg.start.x, seg.start.y),
      Offset(seg.end.x, seg.end.y),
      paint,
    );

    // 3. Draw Yarn Fiber Fuzziness (halo hairs) if fuzziness > 0.05
    final fuzz = config.fuzziness;
    if (fuzz > 0.05 && random.nextDouble() < fuzz) {
      final hairPaint = Paint()
        ..color = shadedColor.withValues(alpha: (0.35 * fuzz).clamp(0.1, 0.7))
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round;

      final hairLen = (3.0 + random.nextDouble() * 5.0) * fuzz;
      final angle = random.nextDouble() * 2 * math.pi;

      final midX = (seg.start.x + seg.end.x) / 2;
      final midY = (seg.start.y + seg.end.y) / 2;

      canvas.drawLine(
        Offset(midX, midY),
        Offset(midX + math.cos(angle) * hairLen, midY + math.sin(angle) * hairLen),
        hairPaint,
      );
    }
  }

  static void _drawSurfaceBackground(Canvas canvas, Size size, YarnRenderConfig config) {
    final bgPaint = Paint()..color = _parseColor(config.backgroundColorHex);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Subtle table top grid pattern
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
