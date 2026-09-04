import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/pattern.dart';
import '../providers/chart_provider.dart';
import '../providers/edit_mode_provider.dart';
import '../providers/stitch_provider.dart';
import '../utils/svg.dart';
import '../utils/polygon.dart' as pg;

const stitchScale = 0.35;

const _hoverFg = '#16A34A';
const _hoverBg = '#86EFAC';
const _hoverFgColor = Color(0xFF16A34A);
const _hoverBgColor = Color(0xFF86EFAC);

const _selectedFg = '#2563EB';
const _selectedBg = '#BFDBFE';
const _selectedFgColor = Color(0xFF2563EB);
const _selectedBgColor = Color(0xFFBFDBFE);

class PosStitch {
  final double x, y, angle, radius;
  final PatternStitch stitch;
  // When non-null, overrides `angle` for SVG rendering (e.g. stitches that
  // should visually "look at" their anchor instead of standing tangent to the
  // ring). Layout math (drag hit-testing, connections) still uses `angle`.
  final double? renderAngle;
  // Perimeter arclength on a polygonal round. For circle (sides<3) this is
  // unused (set to 0). Set when the round shape is a polygon so that drag and
  // tap-slot operations can move along true perimeter length.
  final double perimeterS;
  const PosStitch({required this.x, required this.y, required this.angle, required this.stitch, required this.radius, this.renderAngle, this.perimeterS = 0});
}
typedef _PosStitch = PosStitch;

double _roundSpacing(PatternRound round, StitchStoreNotifier notifier) {
  double maxH = 0.0;
  for (final s in round.stitches) {
    final name = s.name ?? s.kind;
    final rec = notifier.getStitch(name);
    int extra = 1;
    if (name == 'ch') {
      extra = s.count ?? 2;
    }
    double h;
    if (rec != null && rec.svgContent.isNotEmpty) {
      final dim = _svgDim(rec.svgContent);
      h = dim.$2 * stitchScale * extra;
    } else {
      final geo = STITCH_GEOMETRY[name];
      if (geo == null) {
        h = 12.0 * stitchScale;
      } else {
        h = geo.height * stitchScale * extra;
      }
    }
    if (h > maxH) maxH = h;
  }
  if (maxH == 0) {
    // Empty round (no stitches yet): default the spacing to the height of a
    // double crochet so the guide circle sits a reasonable distance out.
    final dc = notifier.getStitch('dc');
    if (dc != null && dc.svgContent.isNotEmpty) {
      final dim = _svgDim(dc.svgContent);
      maxH = dim.$2 * stitchScale;
    } else {
      final geo = STITCH_GEOMETRY['dc'];
      maxH = geo != null ? geo.height * stitchScale : 36.0 * stitchScale;
    }
  }
  return maxH + 5;
}

double symW(PatternStitch s, double chainW, double chainH, double chainFan) {
  if (s.kind == 'chain') {
    return (s.modifiers?.contains('sameStitch') ?? false) ? chainH : chainW;
  }
  if (s.kind == 'slipStitch') return 5.0;
  final geo = STITCH_GEOMETRY[s.name ?? s.kind];
  return geo != null ? geo.width * stitchScale : 7.0;
}

double groupW(List<PatternStitch> g, double chainW, double chainH, double chainFan, {bool isLead = false}) {
  if (g.length == 1) {
    final s = g[0];
    if (s.kind == 'chain') {
      if (isLead) return chainH;
      final c = s.count ?? 1;
      return (c - 1) * chainFan + chainW;
    }
    return symW(s, chainW, chainH, chainFan);
  }
  double maxW = 0;
  for (final s in g) {
    final w = symW(s, chainW, chainH, chainFan);
    if (w > maxW) maxW = w;
  }
  return (g.length - 1) * 6 + maxW;
}

List<List<_PosStitch>> _layout(List<PatternRound> rounds, double ringRadius, double chainW, double chainH, double chainFan, StitchStoreNotifier notifier, {required int sides, required double cornerRatio}) {
  final result = <List<_PosStitch>>[];
  if (rounds.isEmpty) return result;
  final polygonMode = sides >= 3;
  double curR = ringRadius;
  const pad = 5.0;
  final chainGeo = STITCH_GEOMETRY['ch'];
  final chainInset = chainGeo != null ? chainGeo.height * stitchScale : 4.2;
  List<double>? prevAngles;
  double? prevRadius;

  for (final round in rounds) {
    final real = round.stitches.where((s) => s.kind != 'magicRing').toList();
    // Skip only rounds that contain nothing but magic-ring stitches — these are
    // implicit starter rounds, not user-added empty rounds. Empty rounds still
    // reserve a positioned slot and advance the radius so the guide circle and
    // any later stitches line up correctly.
    final magicOnly = real.isEmpty && round.stitches.isNotEmpty;
    if (magicOnly) continue;
    final spacing = _roundSpacing(round, notifier) + (round.radiusOffset ?? 0);
    final radius = result.isEmpty
        ? (ringRadius + (round.radiusOffset ?? 0))
        : (curR += spacing);
    curR = radius;
    final cr = polygonMode
        ? pg.polygonCornerRadius(radius, sides, cornerRatio)
        : 0.0;
    if (real.isEmpty) {
      // Empty round: reserve an index-aligned slot but place no stitches.
      // prevAngles / prevRadius refer to the last non-empty round, so the next
      // non-empty round anchors to that round's positioned stitches / radius.
      result.add([]);
      continue;
    }
    final expanded = expandStitches(real);
    final groups = groupStitches(expanded);
    final pos = <_PosStitch>[];
    final curAngles = List<double>.filled(expanded.length, 0.0);

    // Determine anchored group angles from previous round connections
    bool hasPreviousConnections = false;
    final groupAngles = List<double?>.filled(groups.length, null);
    if (prevAngles != null) {
      for (int gi = 0; gi < groups.length; gi++) {
        final g = groups[gi];
        int? conn;
        for (final s in g) {
          if (s.connectsTo != null) {
            conn = s.connectsTo;
            break;
          }
        }
        if (conn != null && conn >= 0 && conn < prevAngles.length) {
          groupAngles[gi] = prevAngles[conn];
          hasPreviousConnections = true;
        }
      }
    }

    // Apply user-pinned anchors.
    // In rounds with previous connections (round 1+), pins can override or add anchors.
    // In unanchored rounds (like round 0), we leave anchored = false so the round
    // is laid out via width-proportional placement where each pinned stitch sits
    // at its pinned position while other stitches remain evenly distributed.
    if (hasPreviousConnections) {
      for (int gi = 0; gi < groups.length; gi++) {
        final g = groups[gi];
        for (final s in g) {
          if (polygonMode && s.pinnedPerimeter != null) {
            groupAngles[gi] =
                pg.polygonDirectionFromPerimeter(radius, sides, cr, s.pinnedPerimeter!);
            break; // first pin in the group wins
          } else if (s.pinnedAngle != null) {
            groupAngles[gi] = s.pinnedAngle;
            break; // first pin in the group wins
          }
        }
      }
    }

    final anchored = hasPreviousConnections;

    if (anchored) {
      // Find all indices that have an anchor or pin angle
      final anchorIndices = <int>[
        for (int i = 0; i < groups.length; i++)
          if (groupAngles[i] != null) i,
      ];

      if (anchorIndices.isNotEmpty && anchorIndices.length < groups.length) {
        // Interpolate each span of unanchored groups evenly between its anchor neighbors
        for (int aIdx = 0; aIdx < anchorIndices.length; aIdx++) {
          final startAnchor = anchorIndices[aIdx];
          final endAnchor = anchorIndices[(aIdx + 1) % anchorIndices.length];
          final prevA = groupAngles[startAnchor]!;
          var nA = groupAngles[endAnchor]!;

          // Moving clockwise (decreasing angle)
          if (anchorIndices.length == 1) {
            nA = prevA - 2 * pi;
          } else {
            while (nA >= prevA) {
              nA -= 2 * pi;
            }
            while (prevA - nA > 2 * pi) {
              nA += 2 * pi;
            }
          }

          final spanLength = (endAnchor - startAnchor - 1 + groups.length) % groups.length;
          for (int k = 1; k <= spanLength; k++) {
            final gi = (startAnchor + k) % groups.length;
            final fraction = k / (spanLength + 1);
            groupAngles[gi] = prevA + (nA - prevA) * fraction;
          }
        }
      }

      // Place all groups in order.
      // Groups sharing the same anchor are centered around the anchor's radial
      // line and spread out by 18 px per group so they don't overlap. The slot
      // each group takes is determined by its order among same-anchor groups
      // in the expanded list — _placeStitch inserts new stitches at the list
      // position matching the click, so a tap "between" two existing stitches
      // lands between them.
      final Map<int, int> anchorCount = {};
      for (final g in groups) {
        int? conn;
        for (final s in g) {
          if (s.connectsTo != null) { conn = s.connectsTo; break; }
        }
        if (conn != null) anchorCount[conn] = (anchorCount[conn] ?? 0) + 1;
      }
      final Map<int, int> anchorRepeat = {};
      int expIdx = 0;
      for (int gi = 0; gi < groups.length; gi++) {
        final g = groups[gi];
        final baseA = groupAngles[gi]!;
        double a = baseA;
        int? conn;
        for (final s in g) {
          if (s.connectsTo != null) { conn = s.connectsTo; break; }
        }
        double spreadPx = 0;
        if (conn != null) {
          final k = (anchorRepeat[conn] ?? 0);
          final n = anchorCount[conn] ?? 1;
          // Center the cluster around the anchor: for N groups sharing an
          // anchor, offsets are -(N-1)/2 .. +(N-1)/2 stepped by 18 px.
          if (polygonMode) {
            spreadPx = (k - (n - 1) / 2) * 18;
          } else {
            a += (k - (n - 1) / 2) * 18 / radius;
          }
          anchorRepeat[conn] = k + 1;
        }
        for (int i = 0; i < g.length; i++) {
          final st = g[i];
          final off = g.length > 1 ? (i - (g.length - 1) / 2) * 6 : 0;
          final isCh = st.kind == 'chain';
          final r = radius - (isCh ? chainInset : 0);
          final proj = _projectStitch(r, sides, cornerRatio, a,
              pinnedAngleFor: polygonMode ? null : st.pinnedAngle,
              pinnedPerimFor: polygonMode ? st.pinnedPerimeter : null,
              offsetRad: polygonMode ? 0 : (st.angleOffset ?? 0),
              offsetPx: polygonMode ? spreadPx + off + (st.perimeterOffset ?? 0) : 0);
          final nx = proj.x;
          final ny = proj.y;
          // Stitches anchored to a previous-round stitch tilt so their bottoms point
          // at the anchor's position: the SVG's head axis (renderAngle) points
          // away from the anchor. For a single-anchor stitch lying on the
          // anchor radial, this collapses to baseA (the pre-tilt behavior), so
          // single stitches are unchanged; cluster stitches on either side tilt
          // inward toward the anchor.
          double? renderAngle;
          if (st.connectsTo != null && prevRadius != null) {
            double ax, ay;
            if (polygonMode) {
              final (ap, _) = pg.polygonPointAt(prevRadius, sides, cr,
                  pg.polygonPerimeterFromDirection(prevRadius, sides, cr, baseA));
              ax = ap.dx; ay = ap.dy;
            } else {
              ax = prevRadius * cos(baseA);
              ay = prevRadius * sin(baseA);
            }
            // Direction from stitch to anchor; head points the opposite way.
            renderAngle = atan2(ay - ny, ax - nx) - pi;
          }
          final paDir = proj.dir;
          pos.add(_PosStitch(
              x: nx, y: ny, angle: paDir, stitch: st, radius: radius,
              renderAngle: renderAngle, perimeterS: proj.s));
          curAngles[expIdx + i] = paDir;
        }
        expIdx += g.length;
      }
    } else {
      // Width-proportional placement (first round / fallback)
      final total = groups.fold<double>(0, (a, g) => a + (g[0].kind == 'slipStitch' ? 0 : groupW(g, chainW, chainH, chainFan, isLead: identical(g, groups.first)) + pad));
      if (polygonMode) {
        // Distribute stitches' total pixel width evenly around the polygon's
        // perimeter. Each group's arclength is groupW (px); conversion to a
        // perimeter position is direct.
        final perimeterDense = pg.polygonPerimeter(radius, sides, cr);
        final px2perim = perimeterDense / max(total, 1);
        double cum = 0;
        int expIdx = 0;
        for (int gi = 0; gi < groups.length; gi++) {
          final g = groups[gi];
          if (g[0].kind == 'slipStitch') {
            final s = (cum - pad / 2) * px2perim;
            for (int i = 0; i < g.length; i++) {
              final st = g[i];
              final proj = _projectStitch(radius, sides, cornerRatio, 0,
                  pinnedPerimFor: st.pinnedPerimeter ?? (s + (st.perimeterOffset ?? 0)),
                  offsetPx: 0);
              pos.add(_PosStitch(
                  x: proj.x, y: proj.y, angle: proj.dir,
                  stitch: st, radius: radius, perimeterS: proj.s));
              curAngles[expIdx + i] = proj.dir;
            }
            expIdx += g.length;
            continue;
          }
          final w = groupW(g, chainW, chainH, chainFan, isLead: identical(g, groups.first));
          final s = (cum + w / 2) * px2perim;
          cum += w + pad;
          for (int i = 0; i < g.length; i++) {
            final st = g[i];
            final off = g.length > 1 ? (i - (g.length - 1) / 2) * 6 : 0;
            final isCh = st.kind == 'chain';
            final r = radius - (isCh ? chainInset : 0);
            final proj = _projectStitch(r, sides, cornerRatio, 0,
                pinnedPerimFor: st.pinnedPerimeter ?? (s + off + (st.perimeterOffset ?? 0)),
                offsetPx: 0);
            pos.add(_PosStitch(
                x: proj.x, y: proj.y, angle: proj.dir,
                stitch: st, radius: radius, perimeterS: proj.s));
            curAngles[expIdx + i] = proj.dir;
          }
          expIdx += g.length;
        }
      } else {
        final px2rad = (2 * pi) / max(total, 1);
        double cum = 0;
        int expIdx = 0;
        for (int gi = 0; gi < groups.length; gi++) {
          final g = groups[gi];
          if (g[0].kind == 'slipStitch') {
            final a = -((cum - pad / 2) * px2rad) - pi / 2;
            for (int i = 0; i < g.length; i++) {
              final pa = g[i].pinnedAngle ?? (a + (g[i].angleOffset ?? 0));
              pos.add(_PosStitch(x: radius * cos(pa), y: radius * sin(pa), angle: pa, stitch: g[i], radius: radius));
              curAngles[expIdx + i] = pa;
            }
            expIdx += g.length;
            continue;
          }
          final w = groupW(g, chainW, chainH, chainFan, isLead: identical(g, groups.first));
          final a = -((cum + w / 2) * px2rad) - pi / 2;
          cum += w + pad;
          for (int i = 0; i < g.length; i++) {
            final st = g[i];
            final off = g.length > 1 ? (i - (g.length - 1) / 2) * 6 : 0;
            final pa = st.pinnedAngle ?? (a + off * px2rad + (st.angleOffset ?? 0));
            final isCh = st.kind == 'chain';
            final r = radius - (isCh ? chainInset : 0);
            pos.add(_PosStitch(x: r * cos(pa), y: r * sin(pa), angle: pa, stitch: st, radius: radius));
            curAngles[expIdx + i] = pa;
          }
          expIdx += g.length;
        }
      }
    }
result.add(pos);
     prevAngles = curAngles;
     prevRadius = radius;
   }
   return result;
}

List<List<PosStitch>> layoutChart(
  List<PatternRound> rounds,
  double ringRadius,
  double chainW,
  double chainH,
  double chainFan,
  StitchStoreNotifier notifier, {
  required int sides,
  required double cornerRatio,
}) =>
    _layout(rounds, ringRadius, chainW, chainH, chainFan, notifier,
        sides: sides, cornerRatio: cornerRatio);

/// Shape-aware projection of a stitch onto a round's outline.
///
/// For circle (sides < 3): `baseDir` is the math angle, `offsetRad` adds
/// radians; returns position `r·cos/sin`, `dir` = the math angle, `s` = 0
/// (perimeter arclength unused in circle mode).
///
/// For polygon (sides >= 3): `pinnedPerimFor` (if set) overrides the position
/// directly at that arclength; otherwise `baseDir` is converted to a perimeter
/// arclength and `offsetPx` pixels are added; returns position via
/// `pg.polygonPointAt`, `dir` = `atan2(y, x)` of the resolved position (so
/// next-round anchor matching still works), `s` = the resolved arclength.
///
/// `cornerRatio` is the polygon corner-radius ratio (relative to side length);
/// the actual corner radius is recomputed for the given `radius`.
class _Proj {
  final double x, y, dir, s;
  const _Proj(this.x, this.y, this.dir, this.s);
}

_Proj _projectStitch(
  double radius, int sides, double cornerRatio, double baseDir, {
  double? pinnedAngleFor,
  double? pinnedPerimFor,
  double offsetRad = 0.0,
  double offsetPx = 0.0,
}) {
  if (sides >= 3) {
    final cr = pg.polygonCornerRadius(radius, sides, cornerRatio);
    double s;
    if (pinnedPerimFor != null) {
      s = pinnedPerimFor + offsetPx;
    } else {
      s = pg.polygonPerimeterFromDirection(radius, sides, cr, baseDir) + offsetPx;
    }
    final (pos, _) = pg.polygonPointAt(radius, sides, cr, s);
    return _Proj(pos.dx, pos.dy, atan2(pos.dy, pos.dx), s);
  } else {
    final a = (pinnedAngleFor ?? baseDir) + offsetRad;
    return _Proj(radius * cos(a), radius * sin(a), a, 0);
  }
}

String _kindForName(String name) {
  final lower = name.toLowerCase();
  if (lower.startsWith('ch')) return 'chain';
  if (lower == 'sl' || lower == 'slst' || lower == 'sl st') return 'slipStitch';
  return 'stitch';
}

int _countForName(String name) {
  final m = RegExp(r'ch[- ]?(\d+)', caseSensitive: false).firstMatch(name);
  if (m != null) return int.parse(m.group(1)!);
  return 1;
}

double _computeRingRadius(List<PatternRound> rounds, double defaultR, StitchStoreNotifier notifier) {
  if (rounds.isEmpty) return defaultR;
  final real = rounds.first.stitches.where((s) => s.kind != 'magicRing').toList();
  if (real.isEmpty) return defaultR;
  double maxSh = 0;
  for (final s in real) {
    final name = s.name ?? s.kind;
    final rec = notifier.getStitch(name);
    if (rec != null && rec.svgContent.isNotEmpty) {
      final dim = _svgDim(rec.svgContent);
      final h = dim.$2 * stitchScale;
      if (h > maxSh) maxSh = h;
    } else {
      final geo = STITCH_GEOMETRY[name];
      final h = geo != null ? geo.height * stitchScale : 12.0 * stitchScale;
      if (h > maxSh) maxSh = h;
    }
  }
  return defaultR + maxSh;
}

(double, double) _svgDim(String svg) {
  final wm = RegExp(r'width="(\d+(?:\.\d+)?)"').firstMatch(svg);
  final hm = RegExp(r'height="(\d+(?:\.\d+)?)"').firstMatch(svg);
  return (wm != null ? double.parse(wm.group(1)!) : 32.0, hm != null ? double.parse(hm.group(1)!) : 32.0);
}

class VisualChartView extends ConsumerStatefulWidget {
  final double ringRadius;

  const VisualChartView({super.key, this.ringRadius = 20.0});

  @override
  ConsumerState<VisualChartView> createState() => VisualChartViewState();
}

class VisualChartViewState extends ConsumerState<VisualChartView> {
  final TransformationController _transform = TransformationController();
  final GlobalKey _viewKey = GlobalKey();
  final GlobalKey _chartRepaintKey = GlobalKey();
  bool _isExporting = false;
  bool _exportIncludeGuidelines = true;
  bool _exportTransparent = false;

  int? _middleDragPointer;
  Offset? _middleDragLast;
  int? _dragRoundIdx;
  int? _dragStitchIdx;
  int? _dragPointer;
  double _dragBaseAngle = 0;
  // Polygon drag: base perimeter arclength of the dragged stitch at drag start.
  double _dragBasePerim = 0;
  int _dragSides = 0;
  double _dragCornerRatio = 0;
  bool _dragPinned = false;
  bool _hasRecordedDragUndo = false;
  int? _hoverRoundIdx;
  int? _hoverStitchIdx;
  int? _selectedRoundIdx;
  int? _selectedStitchIdx;

  Future<Uint8List?> capturePng({
    double pixelRatio = 2.0,
    bool includeGuidelines = true,
    bool transparent = false,
  }) async {
    setState(() {
      _isExporting = true;
      _exportIncludeGuidelines = includeGuidelines;
      _exportTransparent = transparent;
    });

    try {
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 30));

      final boundary = _chartRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('PNG export capture error: $e');
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

void _placeStitch(Offset localPos, double svgSize, List<List<_PosStitch>>? positioned, {required int sides, required double cornerRatio}) {
     final activeName = ref.read(stitchStoreProvider).activeStitchName;
     if (activeName == null || activeName.isEmpty) return;

     final notifier = ref.read(chartProvider.notifier);
     final chart = notifier.chart;
     final half = svgSize / 2;
     final dx = localPos.dx - half;
     final dy = localPos.dy - half;
     final dist = sqrt(dx * dx + dy * dy);
     final polygonMode = sides >= 3;

    final record = ref.read(stitchStoreProvider).getStitch(activeName);
    final isStarter = record?.category.contains('starters') ?? false;

    // Place / replace starter when close to the center
    if (isStarter && dist < 25) {
      notifier.setChart(chart.copyWith(starterStitchName: activeName));
      return;
    }

    // Need a starter before placing round stitches
    if (chart.starterStitchName == null) return;

    final kind = _kindForName(activeName);
    final count = kind == 'chain' ? _countForName(activeName) : 1;

    // Determine layout index of the previous round so we can hit-test against
    // its positioned stitches. Mirrors the skip logic in _layout: only
    // magic-only rounds are skipped; empty user-added rounds reserve a slot.
    int prevLayoutIdx = -1;
    if (chart.patternRounds.length >= 2) {
      for (int i = 0; i <= chart.patternRounds.length - 2; i++) {
        final real = chart.patternRounds[i].stitches.where((s) => s.kind != 'magicRing').toList();
        final magicOnly = real.isEmpty && chart.patternRounds[i].stitches.isNotEmpty;
        if (magicOnly) continue;
        prevLayoutIdx++;
      }
    }

    int? connectsTo;
    double? pinnedAngle;
    int insertSlot = 0; // target rank among same-anchor stitches in the round
    if (chart.patternRounds.length >= 2 &&
        positioned != null &&
        prevLayoutIdx >= 0 &&
        prevLayoutIdx < positioned.length &&
        positioned[prevLayoutIdx].isNotEmpty) {
      if (kind == 'chain') {
        // Chains never anchor; pin to the click's absolute direction. Both
        // circle and polygon modes use math direction here — `_layout`'s
        // polygon path resolves the direction at the round's actual radius.
        pinnedAngle = atan2(dy, dx);
      } else {
        // Non-chain: snap to the nearest previous-round stitch (regardless of
        // distance — every real stitch has to be worked into something).
        double bestDist = double.infinity;
        int bestSi = 0;
        for (int si = 0; si < positioned[prevLayoutIdx].length; si++) {
          final p = positioned[prevLayoutIdx][si];
          final d2 = (p.x - dx) * (p.x - dx) + (p.y - dy) * (p.y - dy);
          if (d2 < bestDist) {
            bestDist = d2;
            bestSi = si;
          }
        }
        connectsTo = bestSi;
        // Figure out where, among the stitches already worked into this same
        // anchor, the click falls — so we can insert the new stitch there
        // rather than always at the (clockwise) end. _layout spreads
        // same-anchor groups by their order in the expanded list, so the list
        // rank IS the slot around the anchor.
        // Count existing stitches in the last round already anchored here.
        int n = 0;
        if (chart.patternRounds.isNotEmpty) {
          final last = chart.patternRounds.last;
          for (final s in last.stitches) {
            if (s.connectsTo == bestSi && s.kind != 'chain') n++;
          }
        }
        if (polygonMode) {
          // Compute click perimeter on the previous round's polygon and slot
          // ordering using perimeter deltas in pixels (slot stride = 18 px).
          final prevR = positioned[prevLayoutIdx][bestSi].radius;
          final prevCr = pg.polygonCornerRadius(prevR, sides, cornerRatio);
          final anchorPerim = positioned[prevLayoutIdx][bestSi].perimeterS;
          final clickPerim =
              pg.polygonPerimeterFromDirection(prevR, sides, prevCr, atan2(dy, dx));
          var delta = clickPerim - anchorPerim;
          final perim = pg.polygonPerimeter(prevR, sides, prevCr);
          while (delta > perim / 2) {
            delta -= perim;
          }
          while (delta < -perim / 2) {
            delta += perim;
          }
          final m = (delta / 18 + n / 2).round().clamp(0, n);
          insertSlot = m;
        } else {
          final anchorAngle = positioned[prevLayoutIdx][bestSi].angle;
          var delta = (atan2(dy, dx) - anchorAngle);
          while (delta > pi) {
            delta -= 2 * pi;
          }
          while (delta < -pi) {
            delta += 2 * pi;
          }
          // Slot spacing in _layout is 18 px; express the click's angular offset
          // in those units and round to the nearest slot of the (n+1)-cluster.
          final stride = 18 / dist; // radians per slot at the click's radius
          final m = (delta / stride + n / 2).round().clamp(0, n);
          insertSlot = m;
        }
      }
    }

    // Add stitch to the last round, or create the first round
    final rounds = List<PatternRound>.from(chart.patternRounds);
    final roundIdx = rounds.isEmpty ? 0 : rounds.length - 1;
    final newStitch = PatternStitch(
      kind: kind,
      name: activeName,
      count: count,
      connectsTo: connectsTo,
      pinnedAngle: pinnedAngle,
    );
    if (roundIdx < rounds.length) {
      final round = rounds[roundIdx];
      // Insert the new stitch at the position that makes it the insertSlot-th
      // same-anchor stitch, so the symmetric spread in _layout places it where
      // the user clicked (including between existing stitches of the cluster).
      final stitches = List<PatternStitch>.from(round.stitches);
      if (connectsTo == null || kind == 'chain') {
        stitches.add(newStitch);
      } else {
        // Walk the existing stitches, tracking how many share this anchor;
        // insert before the stitch that currently occupies insertSlot.
        int seen = 0;
        int insertAt = stitches.length;
        for (int i = 0; i < stitches.length; i++) {
          final s = stitches[i];
          final sameAnchor = s.connectsTo == connectsTo && s.kind != 'chain';
          if (sameAnchor && seen == insertSlot) {
            insertAt = i;
            break;
          }
          if (sameAnchor) seen++;
        }
        stitches.insert(insertAt, newStitch);
      }
      rounds[roundIdx] = round.copyWith(
        stitches: stitches,
      );
    } else {
      rounds.add(PatternRound(
        number: rounds.length + 1,
        stitches: [newStitch],
      ));
    }

    final connected = assignConnections(rounds);
    notifier.setChart(chart.copyWith(patternRounds: connected));
  }

  void _newRound() {
    final notifier = ref.read(chartProvider.notifier);
    final chart = notifier.chart;
    final rounds = List<PatternRound>.from(chart.patternRounds);
    rounds.add(PatternRound(number: rounds.length + 1, stitches: []));
    notifier.setChart(chart.copyWith(patternRounds: assignConnections(rounds)));
  }

  void _adjustRoundRadius(int roundIdx, double delta) {
    final notifier = ref.read(chartProvider.notifier);
    final chart = notifier.chart;
    if (roundIdx < 0 || roundIdx >= chart.patternRounds.length) return;
    final currentOffset = chart.patternRounds[roundIdx].radiusOffset ?? 0.0;
    final newOffset = currentOffset + delta;
    final updatedRounds = List<PatternRound>.from(chart.patternRounds);
    updatedRounds[roundIdx] = updatedRounds[roundIdx].copyWith(
      radiusOffset: newOffset == 0.0 ? null : newOffset,
      clearRadiusOffset: newOffset == 0.0,
    );
    notifier.setChart(chart.copyWith(patternRounds: updatedRounds));
  }

  void _setStitchOffset(int positionedRi, int expandedSi, double value,
      {required bool polygonMode, required bool pinned, bool recordUndo = true}) {
    final notifier = ref.read(chartProvider.notifier);
    final chart = notifier.chart;
    final rounds = List<PatternRound>.from(chart.patternRounds);
    int chartRi = -1;
    for (int i = 0; i < rounds.length; i++) {
      final real = rounds[i].stitches.where((s) => s.kind != 'magicRing').toList();
      // Match _layout: skip only magic-only rounds; reserve slot for empty ones.
      final magicOnly = real.isEmpty && rounds[i].stitches.isNotEmpty;
      if (magicOnly) continue;
      chartRi++;
      if (real.isEmpty) continue; // empty round has no stitches to offset
      if (chartRi != positionedRi) continue;
      int expCount = 0;
      for (int j = 0; j < real.length; j++) {
        final s = real[j];
        final c = s.kind == 'stitch' ? (s.count ?? 1) : 1;
        if (expCount + c > expandedSi) {
          final PatternStitch updated;
          if (pinned) {
            updated = polygonMode
                ? s.copyWith(pinnedPerimeter: value, perimeterOffset: null)
                : s.copyWith(pinnedAngle: value, angleOffset: null);
          } else {
            updated = polygonMode
                ? s.copyWith(perimeterOffset: value, pinnedPerimeter: null)
                : s.copyWith(angleOffset: value, pinnedAngle: null);
          }
          debugPrint('SETSTITCHOFFSET ri=$positionedRi si=$expandedSi pinned=$pinned mode=$polygonMode kind=${s.kind} value=${value.toStringAsFixed(2)}');
          final sts = List<PatternStitch>.from(rounds[i].stitches);
          final rawIdx = sts.indexOf(s);
          if (rawIdx != -1) {
            sts[rawIdx] = updated;
          }
          rounds[i] = rounds[i].copyWith(
            stitches: sts,
          );
          notifier.setChart(chart.copyWith(patternRounds: assignConnections(rounds)), recordUndo: recordUndo);
          return;
        }
        expCount += c;
      }
    }
  }

  void _setStitchAnchor(int positionedRi, int expandedSi, int? anchor, {bool recordUndo = true}) {
    final notifier = ref.read(chartProvider.notifier);
    final chart = notifier.chart;
    final rounds = List<PatternRound>.from(chart.patternRounds);
    int chartRi = -1;
    for (int i = 0; i < rounds.length; i++) {
      final real = rounds[i].stitches.where((s) => s.kind != 'magicRing').toList();
      final magicOnly = real.isEmpty && rounds[i].stitches.isNotEmpty;
      if (magicOnly) continue;
      chartRi++;
      if (real.isEmpty) continue;
      if (chartRi != positionedRi) continue;
      int expCount = 0;
      for (int j = 0; j < real.length; j++) {
        final s = real[j];
        final c = s.kind == 'stitch' ? (s.count ?? 1) : 1;
        if (expCount + c > expandedSi) {
          final sts = List<PatternStitch>.from(rounds[i].stitches);
          final rawIdx = sts.indexOf(s);
          if (rawIdx != -1) {
            sts[rawIdx] = s.copyWith(connectsTo: anchor);
          }
          rounds[i] = rounds[i].copyWith(
            stitches: sts,
          );
          notifier.setChart(chart.copyWith(patternRounds: assignConnections(rounds)), recordUndo: recordUndo);
          return;
        }
        expCount += c;
      }
    }
  }

  int _prevNonEmptyRound(int ri, List<List<_PosStitch>> positioned) {
    for (int pr = ri - 1; pr >= 0; pr--) {
      if (positioned[pr].isNotEmpty) return pr;
    }
    return -1;
  }

  void _maybeReanchorCircle(double angle, List<List<_PosStitch>> positioned, {bool recordUndo = true}) {
    if (_dragPinned || _dragRoundIdx == null || _dragRoundIdx! <= 0) return;
    final ri = _dragRoundIdx!;
    final si = _dragStitchIdx!;
    final dragged = positioned[ri][si];
    final curAnchor = dragged.stitch.connectsTo;
    if (curAnchor == null) return;
    final prevRi = _prevNonEmptyRound(ri, positioned);
    if (prevRi < 0) return;
    final prev = positioned[prevRi];
    final r = dragged.radius;
    final px = r * cos(angle);
    final py = r * sin(angle);
    int best = -1;
    double bestD = double.infinity;
    double curD = double.infinity;
    bool curFound = false;
    for (int pi = 0; pi < prev.length; pi++) {
      final a = prev[pi];
      if (a.stitch.kind == 'slipStitch') continue;
      final d = (a.x - px) * (a.x - px) + (a.y - py) * (a.y - py);
      if (d < bestD) {
        bestD = d;
        best = pi;
      }
      if (pi == curAnchor && !curFound) {
        curD = d;
        curFound = true;
      }
    }
    if (!curFound || best < 0 || best == curAnchor) return;
    const margin = 12.0;
    if (bestD + margin * margin < curD) {
      _setStitchAnchor(ri, si, best, recordUndo: recordUndo);
      _dragBaseAngle = prev[best].angle;
    }
  }

  void _maybeReanchorPolygon(double clickPerim, List<List<_PosStitch>> positioned, {bool recordUndo = true}) {
    if (_dragPinned || _dragRoundIdx == null || _dragRoundIdx! <= 0) return;
    final ri = _dragRoundIdx!;
    final si = _dragStitchIdx!;
    final dragged = positioned[ri][si];
    final curAnchor = dragged.stitch.connectsTo;
    if (curAnchor == null) return;
    final prevRi = _prevNonEmptyRound(ri, positioned);
    if (prevRi < 0) return;
    final prev = positioned[prevRi];
    final r = dragged.radius;
    final cr = pg.polygonCornerRadius(r, _dragSides, _dragCornerRatio);
    final (pos, _) = pg.polygonPointAt(r, _dragSides, cr, clickPerim);
    final px = pos.dx;
    final py = pos.dy;
    int best = -1;
    double bestD = double.infinity;
    double curD = double.infinity;
    bool curFound = false;
    for (int pi = 0; pi < prev.length; pi++) {
      final a = prev[pi];
      if (a.stitch.kind == 'slipStitch') continue;
      final d = (a.x - px) * (a.x - px) + (a.y - py) * (a.y - py);
      if (d < bestD) {
        bestD = d;
        best = pi;
      }
      if (pi == curAnchor && !curFound) {
        curD = d;
        curFound = true;
      }
    }
    if (!curFound || best < 0 || best == curAnchor) return;
    const margin = 12.0;
    if (bestD + margin * margin < curD) {
      _setStitchAnchor(ri, si, best, recordUndo: recordUndo);
      _dragBasePerim =
          pg.polygonPerimeterFromDirection(r, _dragSides, cr, prev[best].angle);
    }
  }

  Offset? _contentLocal(Offset global) {
    final box = _viewKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final local = box.globalToLocal(global);
    final matrix = _transform.value;
    final inverse = Matrix4.identity()..copyInverse(matrix);
    return MatrixUtils.transformPoint(inverse, local);
  }

  void _startDrag(Offset globalPos, double svgSize, List<List<_PosStitch>> positioned,
      {required int sides, required double cornerRatio}) {
    debugPrint('STARTDRAG');
    final content = _contentLocal(globalPos);
    if (content == null) return;
    final half = svgSize / 2;
    _dragRoundIdx = null;
    _dragStitchIdx = null;
    _hasRecordedDragUndo = false;
    double bestDist = 20;
    for (int ri = 0; ri < positioned.length; ri++) {
      for (int si = 0; si < positioned[ri].length; si++) {
        final p = positioned[ri][si];
        final d = sqrt((p.x - (content.dx - half)) * (p.x - (content.dx - half)) + (p.y - (content.dy - half)) * (p.y - (content.dy - half)));
        if (d < bestDist) {
          bestDist = d;
          _dragRoundIdx = ri;
          _dragStitchIdx = si;
        }
      }
    }
    if (_dragRoundIdx != null) {
      final dragged = positioned[_dragRoundIdx!][_dragStitchIdx!];
      _dragSides = sides;
      _dragCornerRatio = cornerRatio;
      _dragPinned = dragged.stitch.connectsTo == null;
      debugPrint('STARTDRAG grabbed ri=$_dragRoundIdx si=$_dragStitchIdx pinned=$_dragPinned angle=${dragged.angle}');
      if (sides >= 3) {
        final prevPerimOffset = dragged.stitch.perimeterOffset ?? 0;
        _dragBasePerim = dragged.perimeterS - prevPerimOffset;
      } else {
        _dragBaseAngle = dragged.angle - (dragged.stitch.angleOffset ?? 0);
      }
      if (_selectedRoundIdx != _dragRoundIdx || _selectedStitchIdx != _dragStitchIdx) {
        setState(() {
          _selectedRoundIdx = _dragRoundIdx;
          _selectedStitchIdx = _dragStitchIdx;
        });
      }
    } else {
      if (_selectedRoundIdx != null || _selectedStitchIdx != null) {
        setState(() {
          _selectedRoundIdx = null;
          _selectedStitchIdx = null;
        });
      }
    }
  }

  void _updateDrag(Offset globalPos, double svgSize, List<List<_PosStitch>> positioned) {
    if (_dragRoundIdx == null || _dragStitchIdx == null) return;
    final content = _contentLocal(globalPos);
    if (content == null) return;

    // Save undo checkpoint once before the first move of this drag
    if (!_hasRecordedDragUndo) {
      ref.read(chartProvider.notifier).saveUndoCheckpoint();
      _hasRecordedDragUndo = true;
    }

    final half = svgSize / 2;
    final dx = content.dx - half;
    final dy = content.dy - half;
    if (_dragSides >= 3) {
      final dragged = positioned[_dragRoundIdx!][_dragStitchIdx!];
      final r = dragged.radius;
      final cr = pg.polygonCornerRadius(r, _dragSides, _dragCornerRatio);
      final clickPerim = pg.polygonPerimeterFromDirection(r, _dragSides, cr, atan2(dy, dx));
      if (_dragPinned) {
        _setStitchOffset(_dragRoundIdx!, _dragStitchIdx!, clickPerim, polygonMode: true, pinned: true, recordUndo: false);
      } else {
        _maybeReanchorPolygon(clickPerim, positioned, recordUndo: false);
        var delta = clickPerim - _dragBasePerim;
        final perim = pg.polygonPerimeter(r, _dragSides, cr);
        while (delta > perim / 2) {
          delta -= perim;
        }
        while (delta < -perim / 2) {
          delta += perim;
        }
        _setStitchOffset(_dragRoundIdx!, _dragStitchIdx!, delta, polygonMode: true, pinned: false, recordUndo: false);
      }
    } else {
      final angle = atan2(dy, dx);
      if (_dragPinned) {
        _setStitchOffset(_dragRoundIdx!, _dragStitchIdx!, angle, polygonMode: false, pinned: true, recordUndo: false);
      } else {
        _maybeReanchorCircle(angle, positioned, recordUndo: false);
        _setStitchOffset(_dragRoundIdx!, _dragStitchIdx!, angle - _dragBaseAngle, polygonMode: false, pinned: false, recordUndo: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chartState = ref.watch(chartProvider);
    final editState = ref.watch(editModeProvider);
    final stitchNotifier = ref.watch(stitchStoreProvider);
    final chart = chartState.chart;
    final rounds = chart.patternRounds;
    final activeName = stitchNotifier.activeStitchName;
    final activeRecord = activeName != null ? stitchNotifier.getStitch(activeName) : null;
    final activeIsStarter = activeRecord?.category.contains('starters') ?? false;

    final chainSize = _chainSymbolSize(stitchNotifier);
    final chainW = chainSize.$1;
    final chainH = chainSize.$2;
    final chainFan = chainW * 0.8;
    final effectiveRingRadius = _computeRingRadius(rounds, widget.ringRadius, stitchNotifier);
    final sides = chart.guidelines.visualShapeSides;
    final cornerRatio = chart.guidelines.visualCornerRatio;
    final positioned = rounds.isNotEmpty
        ? _layout(rounds, effectiveRingRadius, chainW, chainH, chainFan, stitchNotifier, sides: sides, cornerRatio: cornerRatio)
        : null;
    final roundStarts = <double>[effectiveRingRadius];
    bool firstRound = true;
    for (final round in rounds) {
      final real = round.stitches.where((s) => s.kind != 'magicRing').toList();
      // Match _layout: skip only magic-only rounds, reserve an entry for empty ones.
      final magicOnly = real.isEmpty && round.stitches.isNotEmpty;
      if (magicOnly) continue;
      final spacing = _roundSpacing(round, stitchNotifier) + (round.radiusOffset ?? 0);
      final next = firstRound
          ? roundStarts.last + (round.radiusOffset ?? 0)
          : roundStarts.last + spacing;
      roundStarts.add(next);
      firstRound = false;
    }
    double maxR = effectiveRingRadius + 30;
    if (positioned != null) {
      for (final r in positioned) {
        for (final s in r) {
          final d = sqrt(s.x * s.x + s.y * s.y);
          if (d > maxR) maxR = d;
        }
      }
    }
    const margin = 60.0;
    final svgSize = max(200.0, (maxR + margin) * 2);
    final half = svgSize / 2;
    const hintStyle = TextStyle(color: Color(0xFF999999), fontSize: 13);

    // Starter SVG if placed
    Widget? starterWidget;
    if (chart.starterStitchName != null) {
      final rec = stitchNotifier.getStitch(chart.starterStitchName!);
      if (rec != null && rec.svgContent.isNotEmpty) {
        final dim = _svgDim(rec.svgContent);
        const s = 32.0;
        final scale = s / max(dim.$1, dim.$2);
        final sw = dim.$1 * scale;
        final sh = dim.$2 * scale;
        starterWidget = Positioned(
          left: half - sw / 2,
          top: half - sh / 2,
          child: SizedBox(
            width: sw,
            height: sh,
            child: SvgPicture.string(substituteColors(rec.svgContent, '#333333', '#ffffff'),
                width: sw, height: sh, fit: BoxFit.contain),
          ),
        );
      }
    }

    return Container(
      key: _viewKey,
      color: Colors.white,
      child: Stack(
        children: [
          Positioned.fill(
            child: Listener(
        onPointerDown: (event) {
          if (event.buttons == kPrimaryButton) {
            if (editState.mode == EditMode.move && positioned != null) {
              _startDrag(event.position, svgSize, positioned, sides: sides, cornerRatio: cornerRatio);
              _dragPointer = event.pointer;
            }
          } else {
            _middleDragPointer = event.pointer;
            _middleDragLast = event.position;
          }
        },
        onPointerMove: (event) {
          if (event.pointer == _dragPointer) {
            if (editState.mode == EditMode.move && positioned != null) {
              _updateDrag(event.position, svgSize, positioned);
            }
            return;
          }
          if (event.pointer == _middleDragPointer && _middleDragLast != null) {
            if (event.buttons != kPrimaryButton) {
              final scale = _transform.value.getMaxScaleOnAxis();
              final dx = event.position.dx - _middleDragLast!.dx;
              final dy = event.position.dy - _middleDragLast!.dy;
              _transform.value.translateByDouble(
                  dx / scale, dy / scale, 0, 1);
              _middleDragLast = event.position;
            }
          }
        },
        onPointerUp: (event) {
          if (event.pointer == _dragPointer) {
            _dragPointer = null;
            _dragRoundIdx = null;
            _dragStitchIdx = null;
            _hasRecordedDragUndo = false;
          }
          if (event.pointer == _middleDragPointer) {
            _middleDragPointer = null;
            _middleDragLast = null;
          }
        },
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            final scale = _transform.value.getMaxScaleOnAxis();
            _transform.value.translateByDouble(
              -event.scrollDelta.dx / scale,
              -event.scrollDelta.dy / scale,
              0, 1,
            );
          }
        },
        child: MouseRegion(
          cursor: editState.mode == EditMode.move
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onHover: (event) {
            if (_dragRoundIdx != null) return;
            if (editState.mode != EditMode.move || positioned == null) {
              if (_hoverRoundIdx != null || _hoverStitchIdx != null) {
                setState(() {
                  _hoverRoundIdx = null;
                  _hoverStitchIdx = null;
                });
              }
              return;
            }
            final matrix = _transform.value;
            final inverse = Matrix4.identity()..copyInverse(matrix);
            final content = MatrixUtils.transformPoint(inverse, event.localPosition);
            final half = svgSize / 2;
            double bestDist = 20;
            int? hitRi;
            int? hitSi;
            for (int ri = 0; ri < positioned.length; ri++) {
              for (int si = 0; si < positioned[ri].length; si++) {
                final p = positioned[ri][si];
                final d = sqrt((p.x - (content.dx - half)) * (p.x - (content.dx - half)) + (p.y - (content.dy - half)) * (p.y - (content.dy - half)));
                if (d < bestDist) {
                  bestDist = d;
                  hitRi = ri;
                  hitSi = si;
                }
              }
            }
            if (hitRi != _hoverRoundIdx || hitSi != _hoverStitchIdx) {
              setState(() {
                _hoverRoundIdx = hitRi;
                _hoverStitchIdx = hitSi;
              });
            }
          },
          onExit: (_) {
            setState(() {
              _hoverRoundIdx = null;
              _hoverStitchIdx = null;
            });
          },
          child: GestureDetector(
          onTapUp: (details) {
            debugPrint('TAPUP mode=${editState.mode}');
            final matrix = _transform.value;
            final inverse = Matrix4.identity()..copyInverse(matrix);
            final content = MatrixUtils.transformPoint(inverse, details.localPosition);
            if (editState.mode != EditMode.stitch) return;
            _placeStitch(content, svgSize, positioned, sides: sides, cornerRatio: cornerRatio);
          },
          onPanStart: (details) {
            debugPrint('PANSTART mode=${editState.mode} positioned=${positioned != null}');
            if (editState.mode != EditMode.move || positioned == null) return;
            final matrix = _transform.value;
            final inverse = Matrix4.identity()..copyInverse(matrix);
            final content = MatrixUtils.transformPoint(inverse, details.localPosition);
            final half = svgSize / 2;
            double bestDist = 20;
            for (int ri = 0; ri < positioned.length; ri++) {
              for (int si = 0; si < positioned[ri].length; si++) {
                final p = positioned[ri][si];
                final d = sqrt((p.x - (content.dx - half)) * (p.x - (content.dx - half)) + (p.y - (content.dy - half)) * (p.y - (content.dy - half)));
                if (d < bestDist) {
                  bestDist = d;
                  _dragRoundIdx = ri;
                  _dragStitchIdx = si;
                }
              }
            }
            if (_dragRoundIdx != null) {
              final dragged = positioned[_dragRoundIdx!][_dragStitchIdx!];
              _dragSides = sides;
              _dragCornerRatio = cornerRatio;
              // Unanchored stitches (first round, no connectsTo) are pinned to
              // an absolute position on drag so they stay where the user drops
              // them even when more stitches are added later. Anchored stitches
              // use a relative offset from their anchor.
              _dragPinned = dragged.stitch.connectsTo == null;
              debugPrint('PANSTART grabbed ri=$_dragRoundIdx si=$_dragStitchIdx pinned=$_dragPinned angle=${dragged.angle}');
              setState(() {
                _selectedRoundIdx = _dragRoundIdx;
                _selectedStitchIdx = _dragStitchIdx;
              });
              if (sides >= 3) {
                final prevPerimOffset = dragged.stitch.perimeterOffset ?? 0;
                _dragBasePerim = dragged.perimeterS - prevPerimOffset;
              } else {
                _dragBaseAngle = dragged.angle
                    - (dragged.stitch.angleOffset ?? 0);
              }
            }
          },
          onPanUpdate: (details) {
            debugPrint('PANUPDATE dragRi=$_dragRoundIdx');
            if (_dragRoundIdx == null || _dragStitchIdx == null) return;
            final matrix = _transform.value;
            final inverse = Matrix4.identity()..copyInverse(matrix);
            final content = MatrixUtils.transformPoint(inverse, details.localPosition);
            final half = svgSize / 2;
            final dx = content.dx - half;
            final dy = content.dy - half;
            if (_dragSides >= 3) {
              final dragged = positioned![_dragRoundIdx!][_dragStitchIdx!];
              final r = dragged.radius;
              final cr = pg.polygonCornerRadius(r, _dragSides, _dragCornerRatio);
              final clickPerim =
                  pg.polygonPerimeterFromDirection(r, _dragSides, cr, atan2(dy, dx));
              if (_dragPinned) {
                // Absolute pin: the click perimeter IS the new pinned position.
                _setStitchOffset(_dragRoundIdx!, _dragStitchIdx!, clickPerim,
                    polygonMode: true, pinned: true);
              } else {
                _maybeReanchorPolygon(clickPerim, positioned);
                var delta = clickPerim - _dragBasePerim;
                final perim = pg.polygonPerimeter(r, _dragSides, cr);
                while (delta > perim / 2) {
                  delta -= perim;
                }
                while (delta < -perim / 2) {
                  delta += perim;
                }
                _setStitchOffset(_dragRoundIdx!, _dragStitchIdx!, delta,
                    polygonMode: true, pinned: false);
              }
            } else {
              final angle = atan2(dy, dx);
              if (_dragPinned) {
                _setStitchOffset(_dragRoundIdx!, _dragStitchIdx!, angle,
                    polygonMode: false, pinned: true);
              } else {
                _maybeReanchorCircle(angle, positioned!);
                _setStitchOffset(_dragRoundIdx!, _dragStitchIdx!, angle - _dragBaseAngle,
                    polygonMode: false, pinned: false);
              }
            }
          },
          onPanEnd: (_) {
            _dragRoundIdx = null;
            _dragStitchIdx = null;
          },
          child: InteractiveViewer(
            transformationController: _transform,
            minScale: 0.25,
            maxScale: 6,
            panEnabled: editState.mode == EditMode.pan,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            child: RepaintBoundary(
              key: _chartRepaintKey,
              child: Container(
                color: (_isExporting && _exportTransparent) ? Colors.transparent : Colors.white,
                width: svgSize,
                height: svgSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (!_isExporting || _exportIncludeGuidelines)
                      CustomPaint(
                        size: Size(svgSize, svgSize),
                        painter: _GuidePainter(
                          rounds: rounds,
                          half: half,
                          ringRadius: effectiveRingRadius,
                          roundStarts: roundStarts,
                          drawRing: false,
                          sides: sides,
                          cornerRatio: cornerRatio,
                        ),
                      ),
                    starterWidget ?? const SizedBox(),
                    if (positioned != null)
                      for (int ri = 0; ri < positioned.length; ri++)
                        ..._buildRound(
                          positioned[ri],
                          ri,
                          half,
                          stitchNotifier,
                          effectiveRingRadius,
                          roundStarts,
                          hoverRoundIdx: _isExporting ? null : _hoverRoundIdx,
                          hoverStitchIdx: _isExporting ? null : _hoverStitchIdx,
                          selectedRoundIdx: _isExporting ? null : _selectedRoundIdx,
                          selectedStitchIdx: _isExporting ? null : _selectedStitchIdx,
                        ),

                    // Hint text when empty (omitted during export)
                    if (!_isExporting && chart.starterStitchName == null)
                      if (!activeIsStarter)
                        const Positioned(
                          left: 0, right: 0, top: 0, bottom: 0,
                          child: Center(child: Text('Select a starter stitch from the palette\nto begin your chart', style: hintStyle, textAlign: TextAlign.center)),
                        )
                      else
                        const Positioned(
                          left: 0, right: 0, top: 0, bottom: 0,
                          child: Center(child: Text('Tap the center to place the starter', style: hintStyle, textAlign: TextAlign.center)),
                        ),
                  ],
                ),
              ),
            ),
            ),
          ),
        ),
      ),
    ),
          if (chart.starterStitchName != null)
            Positioned(
              left: 6,
              top: 6,
              child: Builder(
                builder: (context) {
                  final activeIdx = (_selectedRoundIdx != null && _selectedRoundIdx! < rounds.length)
                      ? _selectedRoundIdx!
                      : (rounds.isNotEmpty ? rounds.length - 1 : 0);
                  final activeRound = (rounds.isNotEmpty && activeIdx < rounds.length)
                      ? rounds[activeIdx]
                      : null;
                  final currentOffset = activeRound?.radiusOffset ?? 0.0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFDDDDDD)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'R${activeRound != null ? activeRound.number : (rounds.isEmpty ? 1 : rounds.length)} (${activeRound != null ? activeRound.stitches.length : 0} sts)',
                          style: const TextStyle(fontSize: 11),
                        ),
                        if (activeRound != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            height: 12,
                            width: 1,
                            color: const Color(0xFFCCCCCC),
                          ),
                          const SizedBox(width: 6),
                          const Text('Size:', style: TextStyle(fontSize: 10, color: Color(0xFF666666))),
                          const SizedBox(width: 4),
                          InkWell(
                            key: const ValueKey('canvas_contract_round_button'),
                            onTap: () => _adjustRoundRadius(activeIdx, -5.0),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEEEEE),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Icon(Icons.remove, size: 12, color: Color(0xFF333333)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '${currentOffset > 0 ? '+' : ''}${currentOffset.round()}px',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                          InkWell(
                            key: const ValueKey('canvas_expand_round_button'),
                            onTap: () => _adjustRoundRadius(activeIdx, 5.0),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEEEEE),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Icon(Icons.add, size: 12, color: Color(0xFF333333)),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: rounds.isNotEmpty && rounds.last.stitches.isNotEmpty ? _newRound : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: rounds.isNotEmpty && rounds.last.stitches.isNotEmpty
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFFCCCCCC),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text('New Round', style: TextStyle(fontSize: 10, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildRound(List<_PosStitch> round, int roundIndex, double half, StitchStoreNotifier notifier, double ringRadius, List<double> roundStarts, {int? hoverRoundIdx, int? hoverStitchIdx, int? selectedRoundIdx, int? selectedStitchIdx}) {
    final widgets = <Widget>[];
    final inMoveHover = hoverRoundIdx != null && hoverStitchIdx != null;
    final inSelected = selectedRoundIdx != null && selectedStitchIdx != null;

    int leadCh = round.isNotEmpty && round[0].stitch.kind == 'chain' ? 1 : 0;

    if (leadCh > 0 && leadCh < round.length) {
      final first = round[leadCh];
      final startR = roundStarts[roundIndex];
      final li = round[0].stitch;
      final lc = li.count ?? leadCh;
      final totalSpan = first.radius - startR;
      final linkH = totalSpan / lc;
      final a = round[0].angle;
      final leadHovered = inMoveHover && hoverRoundIdx == roundIndex && hoverStitchIdx == 0;
      final leadSelected = inSelected && selectedRoundIdx == roundIndex && selectedStitchIdx == 0;
      for (int i = 0; i < lc; i++) {
        final r = startR + (i + 0.5) * linkH;
        widgets.add(_chainSymbol(half + r * cos(a), half + r * sin(a), a, notifier, tangent: false, hovered: leadHovered, selected: leadSelected));
      }
    }

    final fanStep = _chainLinkWidth(notifier);
    for (int si = leadCh; si < round.length; si++) {
      final p = round[si];
      final s = p.stitch;
      final hovered = inMoveHover && hoverRoundIdx == roundIndex && hoverStitchIdx == si;
      final selected = inSelected && selectedRoundIdx == roundIndex && selectedStitchIdx == si;
      if (s.kind == 'slipStitch') {
        widgets.add(_slipStitchSymbol(half + p.x, half + p.y, p.angle, s, notifier, hovered: hovered, selected: selected));
      } else if (s.kind == 'chain') {
        final c = s.count ?? 1;
        final tx = -sin(p.angle);
        final ty = cos(p.angle);
        for (int i = 0; i < c; i++) {
          final off = (i - (c - 1) / 2) * fanStep;
          widgets.add(_chainSymbol(half + p.x + tx * off, half + p.y + ty * off, p.angle, notifier, hovered: hovered, selected: selected));
        }
      } else {
        widgets.add(_svgStitch(p, half, notifier, hovered: hovered, selected: selected));
      }
    }
    return widgets;
  }

  (double, double) _chainSymbolSize(StitchStoreNotifier notifier) {
    final record = notifier.getStitch('ch');
    if (record == null || record.svgContent.isEmpty) return (11.2, 5.6);
    final dim = _svgDim(record.svgContent);
    return (dim.$1 * stitchScale, dim.$2 * stitchScale);
  }

  double _chainLinkWidth(StitchStoreNotifier notifier) => _chainSymbolSize(notifier).$1 * 0.8;

  Widget _slipStitchSymbol(double cx, double cy, double angle, PatternStitch stitch, StitchStoreNotifier notifier, {bool hovered = false, bool selected = false}) {
    final record = notifier.getStitch(stitch.name ?? 'sl st') ?? notifier.getStitch('sl st');
    if (record == null || record.svgContent.isEmpty) {
      return _circle(cx, cy, hovered: hovered, selected: selected);
    }
    final dim = _svgDim(record.svgContent);
    final sw = dim.$1 * stitchScale;
    final sh = dim.$2 * stitchScale;
    final svg = substituteColors(record.svgContent,
        selected ? _selectedFg : (hovered ? _hoverFg : '#333333'),
        selected ? _selectedBg : (hovered ? _hoverBg : '#ffffff'));
    return Positioned(
      left: cx - sw / 2,
      top: cy - sh / 2,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..rotateZ(angle + pi / 2),
        child: SizedBox(
          width: sw,
          height: sh,
          child: SvgPicture.string(svg, width: sw, height: sh, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _chainSymbol(double cx, double cy, double angle, StitchStoreNotifier notifier, {bool tangent = true, bool hovered = false, bool selected = false}) {
    final rot = tangent ? angle + pi / 2 : angle;
    final record = notifier.getStitch('ch');
    if (record == null || record.svgContent.isEmpty) {
      return _chainLink(cx, cy, rot, 4.2, hovered: hovered, selected: selected);
    }
    final dim = _svgDim(record.svgContent);
    final sw = dim.$1 * stitchScale;
    final sh = dim.$2 * stitchScale;
    final svg = substituteColors(record.svgContent,
        selected ? _selectedFg : (hovered ? _hoverFg : '#333333'),
        selected ? _selectedBg : (hovered ? _hoverBg : '#ffffff'));
    return Positioned(
      left: cx - sw / 2,
      top: cy - sh / 2,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..rotateZ(rot),
        child: SizedBox(
          width: sw,
          height: sh,
          child: SvgPicture.string(svg, width: sw, height: sh, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _chainLink(double cx, double cy, double angle, double chainH, {bool hovered = false, bool selected = false}) {
    final linkW = chainH;
    final linkH = chainH * 0.7;
    final color = selected
        ? _selectedFgColor
        : hovered
            ? _hoverFgColor
            : const Color(0xFF999999);
    return Positioned(
      left: cx - linkW / 2,
      top: cy - linkH / 2,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: linkW,
          height: linkH,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 1.2),
            color: selected
                ? _selectedBgColor
                : hovered
                    ? _hoverBgColor
                    : null,
            borderRadius: BorderRadius.circular(linkW / 2),
          ),
        ),
      ),
    );
  }

  Widget _circle(double cx, double cy, {bool hovered = false, bool selected = false}) {
    final color = selected
        ? _selectedFgColor
        : hovered
            ? _hoverFgColor
            : const Color(0xFF666666);
    return Positioned(
      left: cx - 2.5,
      top: cy - 2.5,
      child: Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    );
  }

  Widget _svgStitch(_PosStitch p, double half, StitchStoreNotifier notifier, {bool hovered = false, bool selected = false}) {
    final name = p.stitch.name ?? p.stitch.kind;
    if (selected) debugPrint('SVGSTITCH selected name=$name x=${p.x.toStringAsFixed(1)} y=${p.y.toStringAsFixed(1)}');
    final record = notifier.getStitch(name);
    if (record == null || record.svgContent.isEmpty) {
      return Positioned(left: half + p.x - 6, top: half + p.y - 4, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 12, height: 8, decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2), border: Border.all(color: selected ? _selectedFgColor : (hovered ? _hoverFgColor : const Color(0xFF999999)), width: 0.5))),
        Text(name, style: const TextStyle(fontSize: 6, color: Color(0xFF999999))),
      ]));
    }
    final dim = _svgDim(record.svgContent);
    final sw = dim.$1 * stitchScale;
    final sh = dim.$2 * stitchScale;
    final svg = substituteColors(record.svgContent,
        selected ? _selectedFg : (hovered ? _hoverFg : '#333333'),
        selected ? _selectedBg : (hovered ? _hoverBg : '#ffffff'));
    final ra = p.renderAngle ?? p.angle;
    final ax = p.x - (sh / 2) * cos(ra);
    final ay = p.y - (sh / 2) * sin(ra);
    return Positioned(
      left: half + ax - sw / 2,
      top: half + ay - sh / 2,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..rotateZ(ra + pi / 2),
        child: SizedBox(width: sw, height: sh, child: SvgPicture.string(svg, width: sw, height: sh, fit: BoxFit.contain)),
      ),
    );
  }
}

class _GuidePainter extends CustomPainter {
  final List<PatternRound> rounds;
  final double half;
  final double ringRadius;
  final List<double> roundStarts;
  final bool drawRing;
  final int sides;
  final double cornerRatio;
  _GuidePainter({required this.rounds, required this.half, required this.ringRadius, required this.roundStarts, this.drawRing = true, this.sides = 0, this.cornerRatio = 0.15});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(half, half);
    final guide = Paint();
    guide.color = const Color.fromARGB(255, 118, 241, 56);
    guide.strokeWidth = 0.8;
    guide.style = PaintingStyle.stroke;
    const dash = 3.0;
    const gap = 5.0;
    final polygonMode = sides >= 3;
    int ri = 0;
    for (int i = 0; i < rounds.length; i++) {
      // Skip only rounds that contain nothing but magic-ring stitches; empty
      // user-added rounds still get a guide circle.
      final magicOnly = rounds[i].stitches.isNotEmpty && rounds[i].stitches.every((s) => s.kind == 'magicRing');
      if (magicOnly) continue;
      ri++;
      final r = roundStarts[ri];
      final Path path;
      final double labelY;
      if (polygonMode) {
        final cr = pg.polygonCornerRadius(r, sides, cornerRatio);
        path = pg.polygonPath(r, sides, cr);
        labelY = -pg.polygonApothem(r, sides) - 6;
      } else {
        path = Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r));
        labelY = -r - 6;
      }
      final metric = path.computeMetrics().single;
      double dist = 0;
      while (dist < metric.length) {
        final end = (dist + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(dist, end), guide);
        dist = end + gap;
      }
      final tp = TextPainter(text: TextSpan(text: 'R${rounds[i].number}', style: const TextStyle(color: Color(0xFF999999), fontSize: 9)), textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(-tp.width / 2, labelY - tp.height));
    }
    if (drawRing) {
      canvas.drawCircle(Offset.zero, ringRadius, Paint()..color = const Color(0xFF999999)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      final mr = TextPainter(text: const TextSpan(text: 'MR', style: TextStyle(color: Color(0xFF999999), fontSize: 8)), textDirection: TextDirection.ltr);
      mr.layout();
      mr.paint(canvas, Offset(-mr.width / 2, -ringRadius - 4 - mr.height));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GuidePainter old) => true;
}
