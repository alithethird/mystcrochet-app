import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/pattern.dart';
import '../providers/chart_provider.dart';
import '../providers/edit_mode_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/stitch_provider.dart';
import '../services/stitch_replace_service.dart' as stitch_service;
import '../services/sound_service.dart';
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

const _deleteHoverFg = '#DC2626';
const _deleteHoverBg = '#FECACA';
const _deleteHoverFgColor = Color(0xFFDC2626);
const _deleteHoverBgColor = Color(0xFFFECACA);

const _replaceHoverFg = '#D97706';
const _replaceHoverBg = '#FEF3C7';
const _replaceHoverFgColor = Color(0xFFD97706);
const _replaceHoverBgColor = Color(0xFFFEF3C7);

const _replaceSelectedFg = '#7C3AED';
const _replaceSelectedBg = '#EDE9FE';
const _replaceSelectedFgColor = Color(0xFF7C3AED);
const _replaceSelectedBgColor = Color(0xFFEDE9FE);

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
  final int sides;
  final double cornerRatio;
  const PosStitch({
    required this.x,
    required this.y,
    required this.angle,
    required this.stitch,
    required this.radius,
    this.renderAngle,
    this.perimeterS = 0,
    this.sides = 0,
    this.cornerRatio = 0.15,
  });
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
  double baseR = ringRadius;
  const pad = 5.0;
  final chainGeo = STITCH_GEOMETRY['ch'];
  final chainInset = chainGeo != null ? chainGeo.height * stitchScale : 4.2;
  List<double>? prevAngles;
  double? prevRadius;
  int? prevSides;
  double? prevCornerRatio;

  for (final round in rounds) {
    final roundSides = round.sides ?? sides;
    final roundCornerRatio = round.cornerRatio ?? cornerRatio;
    final roundPolygonMode = roundSides >= 3;
    final real = round.stitches.where((s) => s.kind != 'magicRing').toList();
    // Skip only rounds that contain nothing but magic-ring stitches — these are
    // implicit starter rounds, not user-added empty rounds. Empty rounds still
    // reserve a positioned slot and advance the radius so the guide circle and
    // any later stitches line up correctly.
    final magicOnly = real.isEmpty && round.stitches.isNotEmpty;
    if (magicOnly) continue;
    final baseSpacing = _roundSpacing(round, notifier);
    if (result.isNotEmpty) {
      baseR += baseSpacing;
    }
    final radius = baseR + (round.radiusOffset ?? 0);
    final cr = roundPolygonMode
        ? pg.polygonCornerRadius(radius, roundSides, roundCornerRatio)
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
          if (roundPolygonMode && s.pinnedPerimeter != null) {
            groupAngles[gi] =
                pg.polygonDirectionFromPerimeter(radius, roundSides, cr, s.pinnedPerimeter!);
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
          if (roundPolygonMode) {
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
          final proj = _projectStitch(r, roundSides, roundCornerRatio, a,
              pinnedAngleFor: roundPolygonMode ? null : st.pinnedAngle,
              pinnedPerimFor: roundPolygonMode ? st.pinnedPerimeter : null,
              offsetRad: roundPolygonMode ? 0 : (st.angleOffset ?? 0),
              offsetPx: roundPolygonMode ? spreadPx + off + (st.perimeterOffset ?? 0) : 0);
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
            if (prevSides != null && prevSides >= 3) {
              final prevCr = pg.polygonCornerRadius(prevRadius, prevSides, prevCornerRatio ?? cornerRatio);
              final (ap, _) = pg.polygonPointAt(prevRadius, prevSides, prevCr,
                  pg.polygonPerimeterFromDirection(prevRadius, prevSides, prevCr, baseA));
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
              renderAngle: renderAngle, perimeterS: proj.s,
              sides: roundSides, cornerRatio: roundCornerRatio));
          curAngles[expIdx + i] = paDir;
        }
        expIdx += g.length;
      }
    } else {
      // Width-proportional placement (first round / fallback)
      final total = groups.fold<double>(0, (a, g) => a + (g[0].kind == 'slipStitch' ? 0 : groupW(g, chainW, chainH, chainFan, isLead: identical(g, groups.first)) + pad));
      if (roundPolygonMode) {
        // Distribute stitches' total pixel width evenly around the polygon's
        // perimeter. Each group's arclength is groupW (px); conversion to a
        // perimeter position is direct.
        final perimeterDense = pg.polygonPerimeter(radius, roundSides, cr);
        final px2perim = perimeterDense / max(total, 1);
        double cum = 0;
        int expIdx = 0;
        for (int gi = 0; gi < groups.length; gi++) {
          final g = groups[gi];
          if (g[0].kind == 'slipStitch') {
            final s = (cum - pad / 2) * px2perim;
            for (int i = 0; i < g.length; i++) {
              final st = g[i];
              final proj = _projectStitch(radius, roundSides, roundCornerRatio, 0,
                  pinnedPerimFor: st.pinnedPerimeter ?? (s + (st.perimeterOffset ?? 0)),
                  offsetPx: 0);
              pos.add(_PosStitch(
                  x: proj.x, y: proj.y, angle: proj.dir,
                  stitch: st, radius: radius, perimeterS: proj.s,
                  sides: roundSides, cornerRatio: roundCornerRatio));
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
            final proj = _projectStitch(r, roundSides, roundCornerRatio, 0,
                pinnedPerimFor: st.pinnedPerimeter ?? (s + off + (st.perimeterOffset ?? 0)),
                offsetPx: 0);
            pos.add(_PosStitch(
                x: proj.x, y: proj.y, angle: proj.dir,
                stitch: st, radius: radius, perimeterS: proj.s,
                sides: roundSides, cornerRatio: roundCornerRatio));
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
              pos.add(_PosStitch(
                  x: radius * cos(pa), y: radius * sin(pa), angle: pa,
                  stitch: g[i], radius: radius,
                  sides: roundSides, cornerRatio: roundCornerRatio));
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
            pos.add(_PosStitch(
                x: r * cos(pa), y: r * sin(pa), angle: pa,
                stitch: st, radius: radius,
                sides: roundSides, cornerRatio: roundCornerRatio));
            curAngles[expIdx + i] = pa;
          }
          expIdx += g.length;
        }
      }
    }
    result.add(pos);
    prevAngles = curAngles;
    prevRadius = radius;
    prevSides = roundSides;
    prevCornerRatio = roundCornerRatio;
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
  TransformationController get transformationController => _transform;
  final GlobalKey _viewKey = GlobalKey();
  final GlobalKey _chartRepaintKey = GlobalKey();
  bool _isExporting = false;
  bool _exportIncludeGuidelines = true;
  bool _exportTransparent = false;
  // Mapping from visual round index to chart round index
  final Map<int, int> _visualToChartRound = {};

  /// Rebuild [_visualToChartRound] so drag helpers map visual indices to chart
  /// round indices correctly, even after a round-radius change.
  void _refreshVisualToChartMap(List<List<_PosStitch>> positioned, List<PatternRound> rounds) {
    _visualToChartRound.clear();
    int visualRi = 0;
    for (int i = 0; i < rounds.length; i++) {
      final real = rounds[i].stitches.where((s) => s.kind != 'magicRing').toList();
      final magicOnly = real.isEmpty && rounds[i].stitches.isNotEmpty;
      if (magicOnly) continue;
      _visualToChartRound[visualRi] = i;
      visualRi++;
    }
  }

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

  // Mobile multi-touch pinch zoom & natural canvas pan state (Task #33)
  final Map<int, Offset> _activePointers = {};
  int? _canvasPanPointer;
  Offset? _canvasPanStart;
  Offset? _canvasPanLast;
  bool _hasCanvasPanned = false;
  double? _pinchLastDistance;
  Offset? _pinchLastMidpoint;
  bool _isPinching = false;

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
      ref.read(soundServiceProvider).play(SoundEffect.stitchPop);
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
      final prevRound = rounds.isNotEmpty ? rounds.last : null;
      rounds.add(PatternRound(
        number: rounds.length + 1,
        stitches: [newStitch],
        radiusOffset: prevRound?.radiusOffset,
        sides: prevRound?.sides,
        cornerRatio: prevRound?.cornerRatio,
      ));
    }

    final connected = assignConnections(rounds);
    notifier.setChart(chart.copyWith(patternRounds: connected));
    ref.read(soundServiceProvider).play(SoundEffect.stitchPop);
    setState(() {
      _selectedRoundIdx = null;
      _selectedStitchIdx = null;
      _hoverRoundIdx = null;
      _hoverStitchIdx = null;
    });
  }

  void _newRound() {
    ref.read(soundServiceProvider).play(SoundEffect.addRound);
    final notifier = ref.read(chartProvider.notifier);
    final chart = notifier.chart;
    final rounds = List<PatternRound>.from(chart.patternRounds);
    final prevRound = rounds.isNotEmpty ? rounds.last : null;
    rounds.add(PatternRound(
      number: rounds.length + 1,
      stitches: [],
      radiusOffset: prevRound?.radiusOffset,
      sides: prevRound?.sides,
      cornerRatio: prevRound?.cornerRatio,
    ));
    notifier.setChart(chart.copyWith(patternRounds: assignConnections(rounds)));
    setState(() {
      _selectedRoundIdx = null;
      _selectedStitchIdx = null;
      _hoverRoundIdx = null;
      _hoverStitchIdx = null;
    });
    ref.read(editModeProvider.notifier).clearSelection();
  }

  void _adjustRoundRadius(int roundIdx, double delta) {
    ref.read(soundServiceProvider).play(SoundEffect.click);
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

  void _setRoundSides(int roundIdx, int? newSides) {
    ref.read(soundServiceProvider).play(SoundEffect.click);
    final notifier = ref.read(chartProvider.notifier);
    final chart = notifier.chart;
    if (roundIdx < 0 || roundIdx >= chart.patternRounds.length) return;
    final updatedRounds = List<PatternRound>.from(chart.patternRounds);
    updatedRounds[roundIdx] = updatedRounds[roundIdx].copyWith(
      sides: newSides,
      clearSides: newSides == null,
    );
    notifier.setChart(chart.copyWith(patternRounds: updatedRounds), recordUndo: true);
  }

  void _deleteLastRound() {
    ref.read(soundServiceProvider).play(SoundEffect.delete);
    final notifier = ref.read(chartProvider.notifier);
    final chart = notifier.chart;
    if (chart.patternRounds.isEmpty) return;
    final updatedRounds = List<PatternRound>.from(chart.patternRounds);
    final removed = updatedRounds.removeLast();
    final connected = assignConnections(updatedRounds);
    notifier.setChart(chart.copyWith(patternRounds: connected), recordUndo: true);
    setState(() {
      _selectedRoundIdx = null;
      _selectedStitchIdx = null;
      _hoverRoundIdx = null;
      _hoverStitchIdx = null;
    });
    final strings = ref.read(stringsProvider);
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text('${strings.round} ${removed.number} ${strings.roundDeleted}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  (int, int)? _findNearestStitch(Offset content, double svgSize, List<List<_PosStitch>> positioned, {double maxDist = 32.0}) {
    final half = svgSize / 2;
    final cx = content.dx - half;
    final cy = content.dy - half;
    double bestDist = maxDist;
    int? hitRi;
    int? hitSi;
    for (int ri = 0; ri < positioned.length; ri++) {
      for (int si = 0; si < positioned[ri].length; si++) {
        final p = positioned[ri][si];
        double d = sqrt((p.x - cx) * (p.x - cx) + (p.y - cy) * (p.y - cy));
        if (p.stitch.kind == 'chain') {
          final c = p.stitch.count ?? 1;
          if (c > 1) {
            final tx = -sin(p.angle);
            final ty = cos(p.angle);
            const linkStep = 10.0;
            for (int i = 0; i < c; i++) {
              final off = (i - (c - 1) / 2) * linkStep;
              final lx = p.x + tx * off;
              final ly = p.y + ty * off;
              final ld = sqrt((lx - cx) * (lx - cx) + (ly - cy) * (ly - cy));
              if (ld < d) d = ld;
            }
          }
        }
        if (d < bestDist) {
          bestDist = d;
          hitRi = ri;
          hitSi = si;
        }
      }
    }
    if (hitRi != null && hitSi != null) {
      return (hitRi, hitSi);
    }
    return null;
  }

  void _deleteStitchAt(Offset content, double svgSize, List<List<_PosStitch>>? positioned) {
    final half = svgSize / 2;
    if (positioned != null) {
      final hit = _findNearestStitch(content, svgSize, positioned, maxDist: 32.0);
      if (hit != null) {
        debugPrint('[DELETE_STITCH] ri=${hit.$1} si=${hit.$2}');
        _deleteStitch(hit.$1, hit.$2);
        return;
      }
    }

    // Check if starter stitch in center was tapped
    final notifier = ref.read(chartProvider.notifier);
    final chart = notifier.chart;
    if (chart.starterStitchName != null) {
      final centerDist = sqrt((content.dx - half) * (content.dx - half) +
          (content.dy - half) * (content.dy - half));
      if (centerDist < 28.0) {
        final hasStitches = chart.patternRounds.any(
            (r) => r.stitches.any((s) => s.kind != 'magicRing'));
        if (!hasStitches) {
          debugPrint('[DELETE_STITCH] clearing starter stitch');
          notifier.setChart(
            chart.copyWith(starterStitchName: null, clearStarterStitch: true, patternRounds: []),
            recordUndo: true,
          );
          setState(() {
            _hoverRoundIdx = null;
            _hoverStitchIdx = null;
            _selectedRoundIdx = null;
            _selectedStitchIdx = null;
          });
        }
      }
    }
  }

  void _deleteStitch(int positionedRi, int expandedSi) {
    final notifier = ref.read(chartProvider.notifier);
    final chart = notifier.chart;
    final rounds = List<PatternRound>.from(chart.patternRounds);
    final int? chartRi = _visualToChartRound[positionedRi];
    if (chartRi == null || chartRi < 0 || chartRi >= rounds.length) return;

    final real = rounds[chartRi].stitches.where((s) => s.kind != 'magicRing').toList();
    int expCount = 0;
    for (int j = 0; j < real.length; j++) {
      final s = real[j];
      final c = s.kind == 'stitch' ? (s.count ?? 1) : 1;
      if (expCount + c > expandedSi) {
        final sts = List<PatternStitch>.from(rounds[chartRi].stitches);
        final rawIdx = sts.indexOf(s);
        if (rawIdx != -1) {
          if (c > 1) {
            sts[rawIdx] = s.copyWith(count: c - 1);
          } else {
            sts.removeAt(rawIdx);
          }
        }
        rounds[chartRi] = rounds[chartRi].copyWith(stitches: sts);

        // Trim trailing empty rounds if any
        while (rounds.length > 1 && rounds.last.stitches.isEmpty) {
          rounds.removeLast();
        }

        final connected = assignConnections(rounds);
        notifier.setChart(chart.copyWith(patternRounds: connected), recordUndo: true);
        ref.read(soundServiceProvider).play(SoundEffect.delete);
        setState(() {
          _hoverRoundIdx = null;
          _hoverStitchIdx = null;
          _selectedRoundIdx = null;
          _selectedStitchIdx = null;
        });
        return;
      }
      expCount += c;
    }
  }

  void deleteSelectedStitch() {
    if (_selectedRoundIdx != null && _selectedStitchIdx != null) {
      _deleteStitch(_selectedRoundIdx!, _selectedStitchIdx!);
    }
  }

  void deleteSelectedStitches() {
    final selected = ref.read(editModeProvider).selectedStitchKeys;
    if (selected.isEmpty) {
      deleteSelectedStitch();
      return;
    }
    final chartNotifier = ref.read(chartProvider.notifier);
    final chart = chartNotifier.chart;
    final result = stitch_service.deleteSelectedStitches(chart: chart, selectedKeys: selected);
    chartNotifier.setChart(result.updatedChart, recordUndo: true);
    ref.read(soundServiceProvider).play(SoundEffect.delete);
    ref.read(editModeProvider.notifier).clearSelection();
    setState(() {
      _hoverRoundIdx = null;
      _hoverStitchIdx = null;
      _selectedRoundIdx = null;
      _selectedStitchIdx = null;
    });
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text('${result.deletedCount} ilmek silindi'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleSelectionAt(Offset content, double svgSize, List<List<_PosStitch>>? positioned) {
    if (positioned == null) return;
    final hit = _findNearestStitch(content, svgSize, positioned, maxDist: 32.0);
    if (hit != null) {
      ref.read(soundServiceProvider).play(SoundEffect.click);
      ref.read(editModeProvider.notifier).toggleStitchSelection(hit.$1, hit.$2);
    }
  }

  void _selectReplaceTargetAt(Offset content, double svgSize, List<List<_PosStitch>>? positioned) {
    if (positioned == null) return;
    final hit = _findNearestStitch(content, svgSize, positioned, maxDist: 32.0);
    if (hit != null) {
      ref.read(soundServiceProvider).play(SoundEffect.click);
      final hitRi = hit.$1;
      final hitSi = hit.$2;
      final pStitch = positioned[hitRi][hitSi];
      final stitchName = pStitch.stitch.name ?? pStitch.stitch.kind;
      final chart = ref.read(chartProvider).chart;
      int matchCount = 0;
      for (final r in chart.patternRounds) {
        for (final s in r.stitches) {
          final sName = s.name ?? s.kind;
          if (sName == stitchName && s.kind != 'magicRing') {
            matchCount += (s.kind == 'stitch' ? (s.count ?? 1) : 1);
          }
        }
      }
      ref.read(editModeProvider.notifier).setReplaceTarget(
        roundIdx: hitRi,
        stitchIdx: hitSi,
        stitchName: stitchName,
        matchCount: matchCount,
      );
    }
  }

  void _setStitchOffset(int positionedRi, int expandedSi, double value,
      {required bool polygonMode, required bool pinned, bool recordUndo = true}) {
    final notifier = ref.read(chartProvider.notifier);
    final chart = notifier.chart;
    final rounds = List<PatternRound>.from(chart.patternRounds);
    // Use precomputed visual-to-chart round mapping
    final int? chartRi = _visualToChartRound[positionedRi];
    if (chartRi == null) return; // no matching round
    final real = rounds[chartRi].stitches.where((s) => s.kind != 'magicRing').toList();
    int expCount = 0;
    for (int j = 0; j < real.length; j++) {
      final s = real[j];
      final c = s.kind == "stitch" ? (s.count ?? 1) : 1;
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
        final sts = List<PatternStitch>.from(rounds[chartRi].stitches);
        final rawIdx = sts.indexOf(s);
        if (rawIdx != -1) {
          sts[rawIdx] = updated;
        }
        rounds[chartRi] = rounds[chartRi].copyWith(stitches: sts);
        notifier.setChart(chart.copyWith(patternRounds: assignConnections(rounds)), recordUndo: recordUndo);
        return;
      }
      expCount += c;
    }
  }

  void _setStitchAnchor(int positionedRi, int expandedSi, int? anchor, {bool recordUndo = true}) {
    final notifier = ref.read(chartProvider.notifier);
    final chart = notifier.chart;
    final rounds = List<PatternRound>.from(chart.patternRounds);
    final int? chartRi = _visualToChartRound[positionedRi];
    if (chartRi == null) return;
    final real = rounds[chartRi].stitches.where((s) => s.kind != 'magicRing').toList();
    int expCount = 0;
    for (int j = 0; j < real.length; j++) {
      final s = real[j];
      final c = s.kind == 'stitch' ? (s.count ?? 1) : 1;
      if (expCount + c > expandedSi) {
        final sts = List<PatternStitch>.from(rounds[chartRi].stitches);
        final rawIdx = sts.indexOf(s);
        if (rawIdx != -1) {
          sts[rawIdx] = s.copyWith(connectsTo: anchor);
        }
        rounds[chartRi] = rounds[chartRi].copyWith(
          stitches: sts,
        );
        notifier.setChart(chart.copyWith(patternRounds: assignConnections(rounds)), recordUndo: recordUndo);
        return;
      }
      expCount += c;
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

  bool _startDrag(Offset globalPos, double svgSize, List<List<_PosStitch>> positioned,
      {required int sides, required double cornerRatio}) {
    debugPrint('STARTDRAG');
    final content = _contentLocal(globalPos);
    if (content == null) return false;
    _dragRoundIdx = null;
    _dragStitchIdx = null;
    _hasRecordedDragUndo = false;
    final hit = _findNearestStitch(content, svgSize, positioned, maxDist: 32.0);
    if (hit != null) {
      _dragRoundIdx = hit.$1;
      _dragStitchIdx = hit.$2;
    }
    if (_dragRoundIdx != null) {
      final dragged = positioned[_dragRoundIdx!][_dragStitchIdx!];
      final stSides = dragged.sides;
      final stCornerRatio = dragged.cornerRatio;
      _dragSides = stSides;
      _dragCornerRatio = stCornerRatio;
      _dragPinned = dragged.stitch.connectsTo == null;
      debugPrint('STARTDRAG grabbed ri=$_dragRoundIdx si=$_dragStitchIdx pinned=$_dragPinned angle=${dragged.angle}');
      if (stSides >= 3) {
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
      return true;
    } else {
      if (_selectedRoundIdx != null || _selectedStitchIdx != null) {
        setState(() {
          _selectedRoundIdx = null;
          _selectedStitchIdx = null;
        });
      }
      return false;
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

  double _computeOuterRadius(List<List<PosStitch>>? positioned, double effectiveRingRadius) {
    double maxR = 0.0;
    if (positioned != null) {
      for (final roundStitches in positioned) {
        for (final s in roundStitches) {
          if (s.radius > maxR) maxR = s.radius;
        }
      }
    }
    return maxR > 0 ? maxR : (effectiveRingRadius + 40.0);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(chartProvider.select((s) => s.loadId), (prev, next) {
      if (prev != null && prev != next) {
        _transform.value = Matrix4.identity();
        setState(() {
          _selectedRoundIdx = null;
          _selectedStitchIdx = null;
        });
      }
    });

    final chartState = ref.watch(chartProvider);
    final editState = ref.watch(editModeProvider);
    final stitchNotifier = ref.watch(stitchStoreProvider);
    final strings = ref.watch(stringsProvider);
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
        ? _layout(rounds, effectiveRingRadius, chainW, chainH, chainFan, stitchNotifier,
            sides: sides, cornerRatio: cornerRatio)
        : null;
    // Refresh visual-to-chart mapping after layout
    if (positioned != null) {
      _refreshVisualToChartMap(positioned, rounds);
    }
    final roundStarts = <double>[effectiveRingRadius];
    double baseR = effectiveRingRadius;
    bool firstRound = true;
    for (final round in rounds) {
      final real = round.stitches.where((s) => s.kind != 'magicRing').toList();
      // Match _layout: skip only magic-only rounds, reserve an entry for empty ones.
      final magicOnly = real.isEmpty && round.stitches.isNotEmpty;
      if (magicOnly) continue;
      final baseSpacing = _roundSpacing(round, stitchNotifier);
      if (!firstRound) {
        baseR += baseSpacing;
      }
      final rStart = baseR + (round.radiusOffset ?? 0);
      roundStarts.add(rStart);
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
          _activePointers[event.pointer] = event.position;

          if (_activePointers.length >= 2) {
            // Two-finger pinch / pan gesture starts
            _dragPointer = null;
            _dragRoundIdx = null;
            _dragStitchIdx = null;
            _canvasPanPointer = null;

            final p1 = _activePointers.values.elementAt(0);
            final p2 = _activePointers.values.elementAt(1);
            _pinchLastDistance = (p1 - p2).distance;
            _pinchLastMidpoint = (p1 + p2) / 2;
            _isPinching = true;
            _hasCanvasPanned = true;
            return;
          }

          if (event.buttons == kPrimaryButton || event.kind == ui.PointerDeviceKind.touch) {
            bool grabbed = false;
            if (editState.mode == EditMode.move && positioned != null) {
              grabbed = _startDrag(event.position, svgSize, positioned, sides: sides, cornerRatio: cornerRatio);
              if (grabbed) {
                _dragPointer = event.pointer;
              }
            }

            if (!grabbed) {
              final matrix = _transform.value;
              final inverse = Matrix4.identity()..copyInverse(matrix);
              final content = MatrixUtils.transformPoint(inverse, event.localPosition);
              final distFromCenter = (content - Offset(half, half)).distance;
              final outerRadius = _computeOuterRadius(positioned, effectiveRingRadius);
              final isFarFromRounds = distFromCenter > (outerRadius + 25.0);

              if (isFarFromRounds || editState.mode == EditMode.pan) {
                _canvasPanPointer = event.pointer;
                _canvasPanStart = event.position;
                _canvasPanLast = event.position;
                _hasCanvasPanned = false;
              }
            }
          } else if (event.buttons == kMiddleMouseButton) {
            _middleDragPointer = event.pointer;
            _middleDragLast = event.position;
          }
        },
        onPointerMove: (event) {
          _activePointers[event.pointer] = event.position;

          // Two-finger pinch zoom and pan (Task #33)
          if (_isPinching && _activePointers.length >= 2) {
            final p1 = _activePointers.values.elementAt(0);
            final p2 = _activePointers.values.elementAt(1);
            final newDistance = (p1 - p2).distance;
            final newMidpoint = (p1 + p2) / 2;

            if (_pinchLastDistance != null && _pinchLastDistance! > 0 && _pinchLastMidpoint != null) {
              final scaleDelta = newDistance / _pinchLastDistance!;
              final panDelta = newMidpoint - _pinchLastMidpoint!;

              final currentScale = _transform.value.getMaxScaleOnAxis();
              final targetScale = (currentScale * scaleDelta).clamp(0.25, 6.0);
              final effectiveScaleRatio = targetScale / currentScale;

              _transform.value.translateByDouble(panDelta.dx / currentScale, panDelta.dy / currentScale, 0, 1);

              if ((effectiveScaleRatio - 1.0).abs() > 0.0005) {
                final localMidpoint = MatrixUtils.transformPoint(
                  Matrix4.identity()..copyInverse(_transform.value),
                  newMidpoint,
                );
                _transform.value.translateByDouble(localMidpoint.dx, localMidpoint.dy, 0, 1);
                _transform.value.scaleByDouble(effectiveScaleRatio, effectiveScaleRatio, 1, 1);
                _transform.value.translateByDouble(-localMidpoint.dx, -localMidpoint.dy, 0, 1);
              }
              setState(() {});
            }
            _pinchLastDistance = newDistance;
            _pinchLastMidpoint = newMidpoint;
            _hasCanvasPanned = true;
            return;
          }

          if (event.pointer == _dragPointer) {
            if (editState.mode == EditMode.move && positioned != null) {
              _updateDrag(event.position, svgSize, positioned);
            }
            return;
          }

          // Natural canvas pan when dragging outside rounds or in pan mode
          if (event.pointer == _canvasPanPointer && _canvasPanLast != null) {
            final delta = event.position - _canvasPanLast!;
            if ((event.position - _canvasPanStart!).distance > 4.0) {
              _hasCanvasPanned = true;
            }
            final scale = _transform.value.getMaxScaleOnAxis();
            _transform.value.translateByDouble(delta.dx / scale, delta.dy / scale, 0, 1);
            _canvasPanLast = event.position;
            setState(() {});
            return;
          }

          if (event.pointer == _middleDragPointer && _middleDragLast != null) {
            if (event.buttons == kMiddleMouseButton) {
              final scale = _transform.value.getMaxScaleOnAxis();
              final dx = event.position.dx - _middleDragLast!.dx;
              final dy = event.position.dy - _middleDragLast!.dy;
              _transform.value.translateByDouble(
                  dx / scale, dy / scale, 0, 1);
              _middleDragLast = event.position;
              setState(() {});
            }
          }
        },
        onPointerUp: (event) {
          _activePointers.remove(event.pointer);
          if (_activePointers.length < 2) {
            _isPinching = false;
            _pinchLastDistance = null;
            _pinchLastMidpoint = null;
          }
          if (event.pointer == _canvasPanPointer) {
            _canvasPanPointer = null;
            _canvasPanLast = null;
          }
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
        onPointerCancel: (event) {
          _activePointers.remove(event.pointer);
          if (_activePointers.length < 2) {
            _isPinching = false;
            _pinchLastDistance = null;
            _pinchLastMidpoint = null;
          }
          if (event.pointer == _canvasPanPointer) {
            _canvasPanPointer = null;
            _canvasPanLast = null;
          }
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
          if (_dragPointer != null || _dragRoundIdx != null) return;
          if (event is PointerScrollEvent) {
            final scale = _transform.value.getMaxScaleOnAxis();
            if (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed) {
              final zoomFactor = event.scrollDelta.dy < 0 ? 1.1 : 0.9;
              final newScale = (scale * zoomFactor).clamp(0.25, 6.0);
              final ratio = newScale / scale;
              final localPoint = MatrixUtils.transformPoint(
                Matrix4.identity()..copyInverse(_transform.value),
                event.localPosition,
              );
              _transform.value.translateByDouble(localPoint.dx, localPoint.dy, 0, 1);
              _transform.value.scaleByDouble(ratio, ratio, 1, 1);
              _transform.value.translateByDouble(-localPoint.dx, -localPoint.dy, 0, 1);
              setState(() {});
            } else {
              _transform.value.translateByDouble(
                -event.scrollDelta.dx / scale,
                -event.scrollDelta.dy / scale,
                0, 1,
              );
              setState(() {});
            }
          }
        },
        child: MouseRegion(
          cursor: (editState.mode == EditMode.move || editState.mode == EditMode.delete || editState.mode == EditMode.replace || editState.mode == EditMode.select)
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onHover: (event) {
            if (_dragRoundIdx != null) return;
            if ((editState.mode != EditMode.move && editState.mode != EditMode.delete && editState.mode != EditMode.replace && editState.mode != EditMode.select) || positioned == null) {
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
            final hit = _findNearestStitch(content, svgSize, positioned, maxDist: 32.0);
            final hitRi = hit?.$1;
            final hitSi = hit?.$2;
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
            if (_hasCanvasPanned) {
              _hasCanvasPanned = false;
              return;
            }
            debugPrint('TAPUP mode=${editState.mode}');
            final matrix = _transform.value;
            final inverse = Matrix4.identity()..copyInverse(matrix);
            final content = MatrixUtils.transformPoint(inverse, details.localPosition);
            if (editState.mode == EditMode.stitch) {
              _placeStitch(content, svgSize, positioned, sides: sides, cornerRatio: cornerRatio);
            } else if (editState.mode == EditMode.delete) {
              _deleteStitchAt(content, svgSize, positioned);
            } else if (editState.mode == EditMode.replace) {
              _selectReplaceTargetAt(content, svgSize, positioned);
            } else if (editState.mode == EditMode.select) {
              _toggleSelectionAt(content, svgSize, positioned);
            }
          },
          child: InteractiveViewer(
            transformationController: _transform,
            minScale: 0.25,
            maxScale: 6,
            panEnabled: false,
            scaleEnabled: false,
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
                          selectedRoundIdx: _isExporting
                              ? null
                              : (editState.mode == EditMode.replace
                                  ? editState.replaceRoundIdx
                                  : _selectedRoundIdx),
                          selectedStitchIdx: _isExporting
                              ? null
                              : (editState.mode == EditMode.replace
                                  ? editState.replaceStitchIdx
                                  : _selectedStitchIdx),
                          selectedKeys: _isExporting ? null : editState.selectedStitchKeys,
                          isDeleteMode: editState.mode == EditMode.delete,
                          isReplaceMode: editState.mode == EditMode.replace || editState.mode == EditMode.select,
                        ),

                    // Hint text when empty (omitted during export)
                    if (!_isExporting && chart.starterStitchName == null)
                      if (!activeIsStarter)
                        Positioned(
                          left: 0, right: 0, top: 0, bottom: 0,
                          child: Center(child: Text(strings.hintSelectStarter, style: hintStyle, textAlign: TextAlign.center)),
                        )
                      else
                        Positioned(
                          left: 0, right: 0, top: 0, bottom: 0,
                          child: Center(child: Text(strings.hintTapCenter, style: hintStyle, textAlign: TextAlign.center)),
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
              left: MediaQuery.sizeOf(context).width < 750 ? 12.0 : 50.0,
              top: 6.0,
              child: Builder(
                builder: (context) {
                  final isMobile = MediaQuery.sizeOf(context).width < 750;
                  final mappedSelected = _selectedRoundIdx != null ? _visualToChartRound[_selectedRoundIdx!] : null;
                  final activeIdx = (mappedSelected != null && mappedSelected < rounds.length)
                      ? mappedSelected
                      : (_selectedRoundIdx != null && _selectedRoundIdx! < rounds.length
                          ? _selectedRoundIdx!
                          : (rounds.isNotEmpty ? rounds.length - 1 : 0));
                  final activeRound = (rounds.isNotEmpty && activeIdx < rounds.length)
                      ? rounds[activeIdx]
                      : null;
                  final currentOffset = activeRound?.radiusOffset ?? 0.0;
                  return Container(
                    constraints: BoxConstraints(
                      maxWidth: max(80.0, MediaQuery.sizeOf(context).width - (isMobile ? 64.0 : 100.0)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFDDDDDD)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${strings.round} ${activeRound != null ? activeRound.number : (rounds.isEmpty ? 1 : rounds.length)} (${activeRound != null ? activeRound.stitches.length : 0} ${strings.roundStitchesCount})',
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
                          Text('${strings.size}:', style: const TextStyle(fontSize: 10, color: Color(0xFF666666))),
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
                          const SizedBox(width: 8),
                          Container(
                            height: 12,
                            width: 1,
                            color: const Color(0xFFCCCCCC),
                          ),
                          const SizedBox(width: 6),
                          Text('${strings.shape}:', style: const TextStyle(fontSize: 10, color: Color(0xFF666666))),
                          const SizedBox(width: 4),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<int?>(
                              key: const ValueKey('canvas_round_shape_dropdown'),
                              value: activeRound.sides,
                              isDense: true,
                              style: const TextStyle(fontSize: 10, color: Color(0xFF333333)),
                              items: [
                                DropdownMenuItem(value: null, child: Text(strings.categoryDefault, style: const TextStyle(fontSize: 10))),
                                DropdownMenuItem(value: 0, child: Text(strings.circle, style: const TextStyle(fontSize: 10))),
                                DropdownMenuItem(value: 3, child: Text(strings.triangle, style: const TextStyle(fontSize: 10))),
                                DropdownMenuItem(value: 4, child: Text(strings.square, style: const TextStyle(fontSize: 10))),
                                DropdownMenuItem(value: 5, child: Text(strings.pentagon, style: const TextStyle(fontSize: 10))),
                                DropdownMenuItem(value: 6, child: Text(strings.hexagon, style: const TextStyle(fontSize: 10))),
                                DropdownMenuItem(value: 8, child: Text(strings.octagon, style: const TextStyle(fontSize: 10))),
                              ],
                              onChanged: (val) => _setRoundSides(activeIdx, val),
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
                            child: Text(strings.addRound, style: const TextStyle(fontSize: 10, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          key: const ValueKey('canvas_delete_last_round_button'),
                          onTap: rounds.isNotEmpty ? _deleteLastRound : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: rounds.isNotEmpty
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFFCCCCCC),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.delete_outline, size: 12, color: Colors.white),
                                const SizedBox(width: 2),
                                Text(strings.deleteLastRound, style: const TextStyle(fontSize: 10, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                },
              ),
            ),
          if (!_isExporting && editState.selectedStitchKeys.isNotEmpty)
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.checklist, size: 18, color: Color(0xFF7C3AED)),
                        const SizedBox(width: 8),
                        Text(
                          '${editState.selectedStitchKeys.length} ${strings.selectedStitchesCount}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                        ),
                        const SizedBox(width: 10),
                        Container(height: 16, width: 1, color: Colors.grey.shade300),
                        const SizedBox(width: 6),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: const Color(0xFF7C3AED),
                          ),
                          icon: const Icon(Icons.swap_horiz, size: 16),
                          label: Text(strings.replaceFromPalette, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          onPressed: () {
                            ref.read(soundServiceProvider).play(SoundEffect.click);
                            ref.read(editModeProvider.notifier).setMode(EditMode.replace);
                          },
                        ),
                        const SizedBox(width: 6),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: const Color(0xFFDC2626),
                          ),
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: Text(strings.delete, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          onPressed: deleteSelectedStitches,
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          tooltip: strings.clearSelection,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            ref.read(soundServiceProvider).play(SoundEffect.click);
                            ref.read(editModeProvider.notifier).clearSelection();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (!_isExporting && editState.mode == EditMode.select && editState.selectedStitchKeys.isEmpty)
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.checklist, size: 18, color: Color(0xFF7C3AED)),
                        const SizedBox(width: 8),
                        Text(
                          strings.selectionMultiHint,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          tooltip: strings.cancel,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            ref.read(editModeProvider.notifier).setMode(EditMode.stitch);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (!_isExporting && editState.mode == EditMode.replace && editState.selectedStitchKeys.isEmpty)
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.swap_horiz, size: 18, color: Color(0xFF7C3AED)),
                        const SizedBox(width: 8),
                        if (editState.replaceStitchName == null) ...[
                          Text(
                            strings.replaceStep1,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                          ),
                        ] else ...[
                          Text(
                            '${strings.replaceStep2Selected}: ${editState.replaceStitchName} • ${strings.replaceStep2Choose}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED)),
                          ),
                        ],
                        const SizedBox(width: 12),
                        Container(height: 16, width: 1, color: Colors.grey.shade300),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            ref.read(editModeProvider.notifier).setBulkReplace(!editState.bulkReplace);
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: editState.bulkReplace,
                                  onChanged: (val) {
                                    ref.read(editModeProvider.notifier).setBulkReplace(val ?? false);
                                  },
                                  activeColor: const Color(0xFF7C3AED),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                editState.replaceStitchName != null && editState.bulkReplace
                                    ? strings.bulkReplaceWithCount(editState.replaceMatchCount ?? 0)
                                    : strings.bulkReplace,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: editState.bulkReplace ? FontWeight.bold : FontWeight.normal,
                                  color: editState.bulkReplace ? const Color(0xFF7C3AED) : const Color(0xFF374151),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          tooltip: strings.cancel,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            ref.read(editModeProvider.notifier).setMode(EditMode.stitch);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildRound(
    List<_PosStitch> round,
    int roundIndex,
    double half,
    StitchStoreNotifier notifier,
    double ringRadius,
    List<double> roundStarts, {
    int? hoverRoundIdx,
    int? hoverStitchIdx,
    int? selectedRoundIdx,
    int? selectedStitchIdx,
    Set<String>? selectedKeys,
    bool isDeleteMode = false,
    bool isReplaceMode = false,
  }) {
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
      final isLeadKeySelected = selectedKeys != null && selectedKeys.contains('$roundIndex:0');
      final leadSelected = (inSelected && selectedRoundIdx == roundIndex && selectedStitchIdx == 0) || isLeadKeySelected;
      final leadReplace = isReplaceMode || isLeadKeySelected;
      for (int i = 0; i < lc; i++) {
        final r = startR + (i + 0.5) * linkH;
        widgets.add(_chainSymbol(half + r * cos(a), half + r * sin(a), a, notifier, tangent: false, hovered: leadHovered, selected: leadSelected, isDelete: isDeleteMode, isReplace: leadReplace));
      }
    }

    final fanStep = _chainLinkWidth(notifier);
    for (int si = leadCh; si < round.length; si++) {
      final p = round[si];
      final s = p.stitch;
      final hovered = inMoveHover && hoverRoundIdx == roundIndex && hoverStitchIdx == si;
      final isKeySelected = selectedKeys != null && selectedKeys.contains('$roundIndex:$si');
      final selected = (inSelected && selectedRoundIdx == roundIndex && selectedStitchIdx == si) || isKeySelected;
      final isReplace = isReplaceMode || isKeySelected;
      if (s.kind == 'slipStitch') {
        widgets.add(_slipStitchSymbol(half + p.x, half + p.y, p.angle, s, notifier, hovered: hovered, selected: selected, isDelete: isDeleteMode, isReplace: isReplace));
      } else if (s.kind == 'chain') {
        final c = s.count ?? 1;
        final tx = -sin(p.angle);
        final ty = cos(p.angle);
        for (int i = 0; i < c; i++) {
          final off = (i - (c - 1) / 2) * fanStep;
          widgets.add(_chainSymbol(half + p.x + tx * off, half + p.y + ty * off, p.angle, notifier, hovered: hovered, selected: selected, isDelete: isDeleteMode, isReplace: isReplace));
        }
      } else {
        widgets.add(_svgStitch(p, half, notifier, hovered: hovered, selected: selected, isDelete: isDeleteMode, isReplace: isReplace));
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

  Widget _slipStitchSymbol(double cx, double cy, double angle, PatternStitch stitch, StitchStoreNotifier notifier, {bool hovered = false, bool selected = false, bool isDelete = false, bool isReplace = false}) {
    final record = notifier.getStitch(stitch.name ?? 'sl st') ?? notifier.getStitch('sl st');
    if (record == null || record.svgContent.isEmpty) {
      return _circle(cx, cy, hovered: hovered, selected: selected, isDelete: isDelete, isReplace: isReplace);
    }
    final dim = _svgDim(record.svgContent);
    final sw = dim.$1 * stitchScale;
    final sh = dim.$2 * stitchScale;
    final hFg = isReplace ? _replaceHoverFg : (isDelete ? _deleteHoverFg : _hoverFg);
    final hBg = isReplace ? _replaceHoverBg : (isDelete ? _deleteHoverBg : _hoverBg);
    final sFg = isReplace ? _replaceSelectedFg : _selectedFg;
    final sBg = isReplace ? _replaceSelectedBg : _selectedBg;
    final svg = substituteColors(record.svgContent,
        selected ? sFg : (hovered ? hFg : '#333333'),
        selected ? sBg : (hovered ? hBg : '#ffffff'));
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

  Widget _chainSymbol(double cx, double cy, double angle, StitchStoreNotifier notifier, {bool tangent = true, bool hovered = false, bool selected = false, bool isDelete = false, bool isReplace = false}) {
    final rot = tangent ? angle + pi / 2 : angle;
    final record = notifier.getStitch('ch');
    if (record == null || record.svgContent.isEmpty) {
      return _chainLink(cx, cy, rot, 4.2, hovered: hovered, selected: selected, isDelete: isDelete, isReplace: isReplace);
    }
    final dim = _svgDim(record.svgContent);
    final sw = dim.$1 * stitchScale;
    final sh = dim.$2 * stitchScale;
    final hFg = isReplace ? _replaceHoverFg : (isDelete ? _deleteHoverFg : _hoverFg);
    final hBg = isReplace ? _replaceHoverBg : (isDelete ? _deleteHoverBg : _hoverBg);
    final sFg = isReplace ? _replaceSelectedFg : _selectedFg;
    final sBg = isReplace ? _replaceSelectedBg : _selectedBg;
    final svg = substituteColors(record.svgContent,
        selected ? sFg : (hovered ? hFg : '#333333'),
        selected ? sBg : (hovered ? hBg : '#ffffff'));
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

  Widget _chainLink(double cx, double cy, double angle, double chainH, {bool hovered = false, bool selected = false, bool isDelete = false, bool isReplace = false}) {
    final linkW = chainH;
    final linkH = chainH * 0.7;
    final hFgColor = isReplace ? _replaceHoverFgColor : (isDelete ? _deleteHoverFgColor : _hoverFgColor);
    final hBgColor = isReplace ? _replaceHoverBgColor : (isDelete ? _deleteHoverBgColor : _hoverBgColor);
    final sFgColor = isReplace ? _replaceSelectedFgColor : _selectedFgColor;
    final sBgColor = isReplace ? _replaceSelectedBgColor : _selectedBgColor;
    final color = selected
        ? sFgColor
        : hovered
            ? hFgColor
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
                ? sBgColor
                : hovered
                    ? hBgColor
                    : null,
            borderRadius: BorderRadius.circular(linkW / 2),
          ),
        ),
      ),
    );
  }

  Widget _circle(double cx, double cy, {bool hovered = false, bool selected = false, bool isDelete = false, bool isReplace = false}) {
    final hFgColor = isReplace ? _replaceHoverFgColor : (isDelete ? _deleteHoverFgColor : _hoverFgColor);
    final sFgColor = isReplace ? _replaceSelectedFgColor : _selectedFgColor;
    final color = selected
        ? sFgColor
        : hovered
            ? hFgColor
            : const Color(0xFF666666);
    return Positioned(
      left: cx - 2.5,
      top: cy - 2.5,
      child: Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    );
  }

  Widget _svgStitch(_PosStitch p, double half, StitchStoreNotifier notifier, {bool hovered = false, bool selected = false, bool isDelete = false, bool isReplace = false}) {
    final name = p.stitch.name ?? p.stitch.kind;
    if (selected) debugPrint('SVGSTITCH selected name=$name x=${p.x.toStringAsFixed(1)} y=${p.y.toStringAsFixed(1)}');
    final record = notifier.getStitch(name);
    final hFgColor = isReplace ? _replaceHoverFgColor : (isDelete ? _deleteHoverFgColor : _hoverFgColor);
    final sFgColor = isReplace ? _replaceSelectedFgColor : _selectedFgColor;
    if (record == null || record.svgContent.isEmpty) {
      return Positioned(left: half + p.x - 6, top: half + p.y - 4, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 12, height: 8, decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2), border: Border.all(color: selected ? sFgColor : (hovered ? hFgColor : const Color(0xFF999999)), width: 0.5))),
        Text(name, style: const TextStyle(fontSize: 6, color: Color(0xFF999999))),
      ]));
    }
    final dim = _svgDim(record.svgContent);
    final sw = dim.$1 * stitchScale;
    final sh = dim.$2 * stitchScale;
    final hFg = isReplace ? _replaceHoverFg : (isDelete ? _deleteHoverFg : _hoverFg);
    final hBg = isReplace ? _replaceHoverBg : (isDelete ? _deleteHoverBg : _hoverBg);
    final sFg = isReplace ? _replaceSelectedFg : _selectedFg;
    final sBg = isReplace ? _replaceSelectedBg : _selectedBg;
    final svg = substituteColors(record.svgContent,
        selected ? sFg : (hovered ? hFg : '#333333'),
        selected ? sBg : (hovered ? hBg : '#ffffff'));
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
    int ri = 0;
    for (int i = 0; i < rounds.length; i++) {
      // Skip only rounds that contain nothing but magic-ring stitches; empty
      // user-added rounds still get a guide circle.
      final magicOnly = rounds[i].stitches.isNotEmpty && rounds[i].stitches.every((s) => s.kind == 'magicRing');
      if (magicOnly) continue;
      ri++;
      final r = roundStarts[ri];
      final roundSides = rounds[i].sides ?? sides;
      final roundCornerRatio = rounds[i].cornerRatio ?? cornerRatio;
      final roundPolygonMode = roundSides >= 3;
      final Path path;
      final double labelY;
      if (roundPolygonMode) {
        final cr = pg.polygonCornerRadius(r, roundSides, roundCornerRatio);
        path = pg.polygonPath(r, roundSides, cr);
        labelY = -pg.polygonApothem(r, roundSides) - 6;
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
