import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/pattern.dart';
import '../providers/chart_provider.dart';
import '../providers/edit_mode_provider.dart';
import '../providers/stitch_provider.dart';
import '../utils/svg.dart';

const stitchScale = 0.35;

class _PosStitch {
  final double x, y, angle, radius;
  final PatternStitch stitch;
  // When non-null, overrides `angle` for SVG rendering (e.g. stitches that
  // should visually "look at" their anchor instead of standing tangent to the
  // ring). Layout math (drag hit-testing, connections) still uses `angle`.
  final double? renderAngle;
  const _PosStitch({required this.x, required this.y, required this.angle, required this.stitch, required this.radius, this.renderAngle});
}

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

List<List<_PosStitch>> _layout(List<PatternRound> rounds, double ringRadius, double chainW, double chainH, double chainFan, StitchStoreNotifier notifier) {
  final result = <List<_PosStitch>>[];
  if (rounds.isEmpty) return result;
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
    final spacing = _roundSpacing(round, notifier);
    final radius = result.isEmpty ? ringRadius : (curR += spacing);
    curR = radius;
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
    bool anchored = false;
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
          anchored = true;
        }
      }
    }

    // Apply user-pinned angles (from tapping to place chains at a specific
    // point on the round). Pins override anchor-inherited angles so a chain
    // can sit freely at its clicked position rather than inheriting a cluster's
    // anchor angle.
    for (int gi = 0; gi < groups.length; gi++) {
      final g = groups[gi];
      for (final s in g) {
        if (s.pinnedAngle != null) {
          groupAngles[gi] = s.pinnedAngle;
          anchored = true;
          break; // first pin in the group wins
        }
      }
    }

    if (anchored) {
      // Interpolate unanchored groups between their anchored neighbors
      double? lastA;
      for (int gi = 0; gi < groups.length; gi++) {
        if (groupAngles[gi] != null) {
          lastA = groupAngles[gi];
          continue;
        }
        double? nextA;
        for (int gj = gi + 1; gj < groups.length; gj++) {
          if (groupAngles[gj] != null) {
            nextA = groupAngles[gj];
            break;
          }
        }
        final prevA = lastA ?? (() {
          for (int gj = groups.length - 1; gj >= 0; gj--) {
            if (groupAngles[gj] != null) return groupAngles[gj]! + 2 * pi;
          }
          return 0.0;
        }());
        double nA = nextA ?? (() {
          for (int gj = 0; gj < groups.length; gj++) {
            if (groupAngles[gj] != null) return groupAngles[gj]!;
          }
          return 0.0;
        }());
        while (nA > prevA) { nA -= 2 * pi; }
        groupAngles[gi] = (prevA + nA) / 2;
        lastA = groupAngles[gi];
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
        if (conn != null) {
          final k = (anchorRepeat[conn] ?? 0);
          final n = anchorCount[conn] ?? 1;
          // Center the cluster around the anchor: for N groups sharing an
          // anchor, offsets are -(N-1)/2 .. +(N-1)/2 stepped by 18 px.
          a += (k - (n - 1) / 2) * 18 / radius;
          anchorRepeat[conn] = k + 1;
        }
        for (int i = 0; i < g.length; i++) {
          final st = g[i];
          final off = g.length > 1 ? (i - (g.length - 1) / 2) * 6 : 0;
          final pa = a + off / radius + (st.angleOffset ?? 0);
          final isCh = st.kind == 'chain';
          final r = radius - (isCh ? chainInset : 0);
          final nx = r * cos(pa);
          final ny = r * sin(pa);
          // Stitches anchored to a previous-round stitch tilt so their bottoms point
          // at the anchor's position: the SVG's head axis (renderAngle) points
          // away from the anchor. For a single-anchor stitch lying on the
          // anchor radial, this collapses to baseA (the pre-tilt behavior), so
          // single stitches are unchanged; cluster stitches on either side tilt
          // inward toward the anchor.
          double? renderAngle;
          if (st.connectsTo != null && prevRadius != null) {
            final ax = prevRadius * cos(baseA);
            final ay = prevRadius * sin(baseA);
            // Direction from stitch to anchor; head points the opposite way.
            renderAngle = atan2(ay - ny, ax - nx) - pi;
          }
          pos.add(_PosStitch(x: nx, y: ny, angle: pa, stitch: st, radius: radius, renderAngle: renderAngle));
          curAngles[expIdx + i] = pa;
        }
        expIdx += g.length;
      }
    } else {
      // Width-proportional placement (first round / fallback)
      final total = groups.fold<double>(0, (a, g) => a + (g[0].kind == 'slipStitch' ? 0 : groupW(g, chainW, chainH, chainFan, isLead: identical(g, groups.first)) + pad));
      final px2rad = (2 * pi) / max(total, 1);
      double cum = 0;
      int expIdx = 0;
      for (int gi = 0; gi < groups.length; gi++) {
        final g = groups[gi];
        if (g[0].kind == 'slipStitch') {
          final a = -((cum - pad / 2) * px2rad) - pi / 2;
          for (int i = 0; i < g.length; i++) {
            final pa = a + (g[i].angleOffset ?? 0);
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
          final pa = a + off * px2rad + (st.angleOffset ?? 0);
          final isCh = st.kind == 'chain';
          final r = radius - (isCh ? chainInset : 0);
          pos.add(_PosStitch(x: r * cos(pa), y: r * sin(pa), angle: pa, stitch: st, radius: radius));
          curAngles[expIdx + i] = pa;
        }
        expIdx += g.length;
      }
    }
    result.add(pos);
    prevAngles = curAngles;
    prevRadius = radius;
  }
  return result;
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
  ConsumerState<VisualChartView> createState() => _VisualChartViewState();
}

class _VisualChartViewState extends ConsumerState<VisualChartView> {
  final TransformationController _transform = TransformationController();
  int? _middleDragPointer;
  Offset? _middleDragLast;
  int? _dragRoundIdx;
  int? _dragStitchIdx;
  double _dragBaseAngle = 0;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _placeStitch(Offset localPos, double svgSize, List<List<_PosStitch>>? positioned) {
    final activeName = ref.read(stitchStoreProvider).activeStitchName;
    if (activeName == null || activeName.isEmpty) return;

    final notifier = ref.read(chartProvider.notifier);
    final chart = notifier.chart;
    final half = svgSize / 2;
    final dx = localPos.dx - half;
    final dy = localPos.dy - half;
    final dist = sqrt(dx * dx + dy * dy);

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
        // Chains never anchor; pin to the click's absolute angle.
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
        final anchorAngle = positioned[prevLayoutIdx][bestSi].angle;
        var delta = (atan2(dy, dx) - anchorAngle);
        while (delta > pi) {
          delta -= 2 * pi;
        }
        while (delta < -pi) {
          delta += 2 * pi;
        }
        // Count existing stitches in the last round already anchored here.
        int n = 0;
        if (chart.patternRounds.isNotEmpty) {
          final last = chart.patternRounds.last;
          for (final s in last.stitches) {
            if (s.connectsTo == bestSi && s.kind != 'chain') n++;
          }
        }
        // Slot spacing in _layout is 18 px; express the click's angular offset
        // in those units and round to the nearest slot of the (n+1)-cluster.
        final stride = 18 / dist; // radians per slot at the click's radius
        final m = (delta / stride + n / 2).round().clamp(0, n);
        insertSlot = m;
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
      rounds[roundIdx] = PatternRound(
        number: round.number,
        stitches: stitches,
        isMagicRing: round.isMagicRing,
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

  void _setStitchAngleOffset(int positionedRi, int expandedSi, double offset) {
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
          final updated = s.copyWith(angleOffset: offset);
          final sts = List<PatternStitch>.from(rounds[i].stitches);
          sts[j] = updated;
          rounds[i] = PatternRound(
            number: rounds[i].number,
            stitches: sts,
            isMagicRing: rounds[i].isMagicRing,
          );
          notifier.setChart(chart.copyWith(patternRounds: assignConnections(rounds)));
          return;
        }
        expCount += c;
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
    final positioned = rounds.isNotEmpty ? _layout(rounds, effectiveRingRadius, chainW, chainH, chainFan, stitchNotifier) : null;
    final roundStarts = <double>[effectiveRingRadius];
    bool firstRound = true;
    for (final round in rounds) {
      final real = round.stitches.where((s) => s.kind != 'magicRing').toList();
      // Match _layout: skip only magic-only rounds, reserve an entry for empty ones.
      final magicOnly = real.isEmpty && round.stitches.isNotEmpty;
      if (magicOnly) continue;
      final next = firstRound ? roundStarts.last : roundStarts.last + _roundSpacing(round, stitchNotifier);
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
      color: Colors.white,
      child: Listener(
        onPointerDown: (event) {
          if (event.buttons != kPrimaryButton) {
            _middleDragPointer = event.pointer;
            _middleDragLast = event.position;
          }
        },
        onPointerMove: (event) {
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
        child: GestureDetector(
          onTapUp: (details) {
            final matrix = _transform.value;
            final inverse = Matrix4.identity()..copyInverse(matrix);
            final content = MatrixUtils.transformPoint(inverse, details.localPosition);
            _placeStitch(content, svgSize, positioned);
          },
          onPanStart: (details) {
            if (editState.mode != EditMode.stitch || positioned == null) return;
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
              _dragBaseAngle = positioned[_dragRoundIdx!][_dragStitchIdx!].angle
                  - (positioned[_dragRoundIdx!][_dragStitchIdx!].stitch.angleOffset ?? 0);
            }
          },
          onPanUpdate: (details) {
            if (_dragRoundIdx == null || _dragStitchIdx == null) return;
            final matrix = _transform.value;
            final inverse = Matrix4.identity()..copyInverse(matrix);
            final content = MatrixUtils.transformPoint(inverse, details.localPosition);
            final half = svgSize / 2;
            final dx = content.dx - half;
            final dy = content.dy - half;
            final angle = atan2(dy, dx);
            _setStitchAngleOffset(_dragRoundIdx!, _dragStitchIdx!, angle - _dragBaseAngle);
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
            child: SizedBox(
              width: svgSize,
              height: svgSize,
              child: Stack(
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: Size(svgSize, svgSize),
                  painter: _GuidePainter(
                    rounds: rounds,
                    half: half,
                    ringRadius: effectiveRingRadius,
                    roundStarts: roundStarts,
                    drawRing: false,
                  ),
                ),
                starterWidget ?? const SizedBox(),
                if (positioned != null)
                  for (int ri = 0; ri < positioned.length; ri++)
                    ..._buildRound(positioned[ri], ri, half, stitchNotifier, effectiveRingRadius, roundStarts),

                // Hint text when empty
                if (chart.starterStitchName == null)
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

                // Round indicator + New Round button
                if (chart.starterStitchName != null)
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFDDDDDD)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('R${
                              rounds.isEmpty ? 1 : rounds.length
                          }  (${rounds.isEmpty ? 0 : rounds.last.stitches.length} sts)',
                              style: const TextStyle(fontSize: 11)),
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
                    ),
                  ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRound(List<_PosStitch> round, int roundIndex, double half, StitchStoreNotifier notifier, double ringRadius, List<double> roundStarts) {
    final widgets = <Widget>[];

    int leadCh = round.isNotEmpty && round[0].stitch.kind == 'chain' ? 1 : 0;

    if (leadCh > 0 && leadCh < round.length) {
      final first = round[leadCh];
      final startR = roundStarts[roundIndex];
      final li = round[0].stitch;
      final lc = li.count ?? leadCh;
      final totalSpan = first.radius - startR;
      final linkH = totalSpan / lc;
      final a = round[0].angle;
      for (int i = 0; i < lc; i++) {
        final r = startR + (i + 0.5) * linkH;
        widgets.add(_chainSymbol(half + r * cos(a), half + r * sin(a), a, notifier, tangent: false));
      }
    }

    final fanStep = _chainLinkWidth(notifier);
    for (int si = leadCh; si < round.length; si++) {
      final p = round[si];
      final s = p.stitch;
      if (s.kind == 'slipStitch') {
        widgets.add(_slipStitchSymbol(half + p.x, half + p.y, p.angle, s, notifier));
      } else if (s.kind == 'chain') {
        final c = s.count ?? 1;
        final tx = -sin(p.angle);
        final ty = cos(p.angle);
        for (int i = 0; i < c; i++) {
          final off = (i - (c - 1) / 2) * fanStep;
          widgets.add(_chainSymbol(half + p.x + tx * off, half + p.y + ty * off, p.angle, notifier));
        }
      } else {
        widgets.add(_svgStitch(p, half, notifier));
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

  Widget _slipStitchSymbol(double cx, double cy, double angle, PatternStitch stitch, StitchStoreNotifier notifier) {
    final record = notifier.getStitch(stitch.name ?? 'sl st') ?? notifier.getStitch('sl st');
    if (record == null || record.svgContent.isEmpty) {
      return _circle(cx, cy);
    }
    final dim = _svgDim(record.svgContent);
    final sw = dim.$1 * stitchScale;
    final sh = dim.$2 * stitchScale;
    final svg = substituteColors(record.svgContent, '#333333', '#ffffff');
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

  Widget _chainSymbol(double cx, double cy, double angle, StitchStoreNotifier notifier, {bool tangent = true}) {
    final rot = tangent ? angle + pi / 2 : angle;
    final record = notifier.getStitch('ch');
    if (record == null || record.svgContent.isEmpty) {
      return _chainLink(cx, cy, rot, 4.2);
    }
    final dim = _svgDim(record.svgContent);
    final sw = dim.$1 * stitchScale;
    final sh = dim.$2 * stitchScale;
    final svg = substituteColors(record.svgContent, '#333333', '#ffffff');
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

  Widget _chainLink(double cx, double cy, double angle, double chainH) {
    final linkW = chainH;
    final linkH = chainH * 0.7;
    return Positioned(
      left: cx - linkW / 2,
      top: cy - linkH / 2,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: linkW,
          height: linkH,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF999999), width: 1.2),
            borderRadius: BorderRadius.circular(linkW / 2),
          ),
        ),
      ),
    );
  }

  Widget _circle(double cx, double cy) {
    return Positioned(
      left: cx - 2.5,
      top: cy - 2.5,
      child: Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFF666666), shape: BoxShape.circle)),
    );
  }

  Widget _svgStitch(_PosStitch p, double half, StitchStoreNotifier notifier) {
    final name = p.stitch.name ?? p.stitch.kind;
    final record = notifier.getStitch(name);
    if (record == null || record.svgContent.isEmpty) {
      return Positioned(left: half + p.x - 6, top: half + p.y - 4, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 12, height: 8, decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2), border: Border.all(color: const Color(0xFF999999), width: 0.5))),
        Text(name, style: const TextStyle(fontSize: 6, color: Color(0xFF999999))),
      ]));
    }
    final dim = _svgDim(record.svgContent);
    final sw = dim.$1 * stitchScale;
    final sh = dim.$2 * stitchScale;
    final svg = substituteColors(record.svgContent, '#333333', '#ffffff');
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
  _GuidePainter({required this.rounds, required this.half, required this.ringRadius, required this.roundStarts, this.drawRing = true});

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
      final path = Path();
      path.addOval(Rect.fromCircle(center: Offset.zero, radius: r));
      final metric = path.computeMetrics().single;
      double dist = 0;
      while (dist < metric.length) {
        final end = (dist + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(dist, end), guide);
        dist = end + gap;
      }
      final tp = TextPainter(text: TextSpan(text: 'R${rounds[i].number}', style: const TextStyle(color: Color(0xFF999999), fontSize: 9)), textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(-tp.width / 2, -r - 6 - tp.height));
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
