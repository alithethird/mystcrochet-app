import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:crochet_charts/models/pattern.dart';
import 'package:crochet_charts/providers/stitch_provider.dart';
import 'package:crochet_charts/widgets/visual_chart_view.dart';

void main() {
  final notifier = StitchStoreNotifier();

  group('First Round Stitch Dragging & Layout Tests', () {
    test('Round 0 unpinned stitches are distributed around the ring', () {
      final round0 = PatternRound(
        number: 1,
        stitches: [
          for (int i = 0; i < 6; i++)
            PatternStitch(kind: 'stitch', name: 'sc', count: 1),
        ],
      );

      final layout = layoutChart(
        [round0],
        50.0, // ringRadius
        12.0, // chainW
        16.0, // chainH
        9.6,  // chainFan
        notifier,
        sides: 0,
        cornerRatio: 0.0,
      );

      expect(layout.length, equals(1));
      final placed = layout[0];
      expect(placed.length, equals(6));

      // Check all angles are distinct
      for (int i = 0; i < placed.length; i++) {
        for (int j = i + 1; j < placed.length; j++) {
          final diff = (placed[i].angle - placed[j].angle).abs();
          expect(diff > 0.1, isTrue,
              reason: 'Stitches $i and $j should not have the same angle');
        }
      }
    });

    test('Round 0 with 1 pinned stitch DOES NOT collapse the other stitches', () {
      // Stitch 0 has pinnedAngle set (as happens when dragging in first round)
      final round0 = PatternRound(
        number: 1,
        stitches: [
          PatternStitch(kind: 'stitch', name: 'sc', count: 1, pinnedAngle: 0.0),
          for (int i = 1; i < 6; i++)
            PatternStitch(kind: 'stitch', name: 'sc', count: 1),
        ],
      );

      final layout = layoutChart(
        [round0],
        50.0,
        12.0,
        16.0,
        9.6,
        notifier,
        sides: 0,
        cornerRatio: 0.0,
      );

      expect(layout.length, equals(1));
      final placed = layout[0];
      expect(placed.length, equals(6));

      // Pinned stitch 0 must be at angle 0.0
      expect(placed[0].angle, closeTo(0.0, 0.001));

      // CRITICAL ASSERTION: The remaining 5 stitches must NOT all be collapsed to angle 0.0!
      for (int i = 1; i < placed.length; i++) {
        final distFromPinned = (placed[i].angle - placed[0].angle).abs();
        expect(distFromPinned > 0.1, isTrue,
            reason: 'Stitch $i collapsed onto stitch 0 at angle ${placed[i].angle}');
      }

      // All 6 stitches must have distinct positions
      for (int i = 0; i < placed.length; i++) {
        for (int j = i + 1; j < placed.length; j++) {
          final dx = placed[i].x - placed[j].x;
          final dy = placed[i].y - placed[j].y;
          final d = sqrt(dx * dx + dy * dy);
          expect(d > 5.0, isTrue,
              reason: 'Stitches $i and $j are too close (distance: $d)');
        }
      }
    });

    test('Round 0 in polygon mode with 1 pinnedPerimeter does not collapse', () {
      final round0 = PatternRound(
        number: 1,
        stitches: [
          PatternStitch(kind: 'stitch', name: 'sc', count: 1, pinnedPerimeter: 25.0),
          for (int i = 1; i < 6; i++)
            PatternStitch(kind: 'stitch', name: 'sc', count: 1),
        ],
      );

      final layout = layoutChart(
        [round0],
        60.0,
        12.0,
        16.0,
        9.6,
        notifier,
        sides: 4, // square
        cornerRatio: 0.0,
      );

      expect(layout.length, equals(1));
      final placed = layout[0];
      expect(placed.length, equals(6));

      // Pinned stitch must have perimeterS == 25.0
      expect(placed[0].perimeterS, closeTo(25.0, 0.1));

      // All stitches must have distinct perimeterS
      for (int i = 0; i < placed.length; i++) {
        for (int j = i + 1; j < placed.length; j++) {
          final diff = (placed[i].perimeterS - placed[j].perimeterS).abs();
          expect(diff > 1.0, isTrue,
              reason: 'Stitches $i and $j collapsed on perimeter ($diff)');
        }
      }
    });

    test('Anchored round with unanchored stitches divides angular span evenly', () {
      // Round 0: 2 anchor stitches at opposite sides (0 and -pi)
      final round0 = PatternRound(
        number: 1,
        stitches: [
          PatternStitch(kind: 'stitch', name: 'sc', count: 1, pinnedAngle: 0.0),
          PatternStitch(kind: 'stitch', name: 'sc', count: 1, pinnedAngle: -pi),
        ],
      );

      // Round 1: connects to anchor 0, then 2 unanchored chains, then anchor 1, then 2 unanchored chains
      final round1 = PatternRound(
        number: 2,
        stitches: [
          PatternStitch(kind: 'stitch', name: 'dc', count: 1, connectsTo: 0),
          PatternStitch(kind: 'chain', name: 'ch', count: 1),
          PatternStitch(kind: 'chain', name: 'ch', count: 1),
          PatternStitch(kind: 'stitch', name: 'dc', count: 1, connectsTo: 1),
          PatternStitch(kind: 'chain', name: 'ch', count: 1),
          PatternStitch(kind: 'chain', name: 'ch', count: 1),
        ],
      );

      final layout = layoutChart(
        [round0, round1],
        50.0,
        12.0,
        16.0,
        9.6,
        notifier,
        sides: 0,
        cornerRatio: 0.0,
      );

      expect(layout.length, equals(2));
      final r1Placed = layout[1];
      expect(r1Placed.length, equals(6));

      // Anchor 0 is at 0.0 rad
      expect(r1Placed[0].angle, closeTo(0.0, 0.01));
      // Two chains should be evenly spaced between 0.0 and -pi: -pi/3 (-60 deg) and -2*pi/3 (-120 deg)
      expect(r1Placed[1].angle, closeTo(-pi / 3, 0.05));
      expect(r1Placed[2].angle, closeTo(-2 * pi / 3, 0.05));
      // Anchor 1 is at -pi rad (-180 deg)
      expect(r1Placed[3].angle, closeTo(-pi, 0.01));
    });

    test('Anchored round with only 1 anchor distributes unanchored stitches across full circle', () {
      final round0 = PatternRound(
        number: 1,
        stitches: [
          PatternStitch(kind: 'stitch', name: 'sc', count: 1, pinnedAngle: 0.0),
        ],
      );

      // Round 1 has 1 anchored stitch and 3 unanchored chains
      final round1 = PatternRound(
        number: 2,
        stitches: [
          PatternStitch(kind: 'stitch', name: 'dc', count: 1, connectsTo: 0),
          PatternStitch(kind: 'chain', name: 'ch', count: 1),
          PatternStitch(kind: 'chain', name: 'ch', count: 1),
          PatternStitch(kind: 'chain', name: 'ch', count: 1),
        ],
      );

      final layout = layoutChart(
        [round0, round1],
        50.0,
        12.0,
        16.0,
        9.6,
        notifier,
        sides: 0,
        cornerRatio: 0.0,
      );

      final r1Placed = layout[1];
      expect(r1Placed.length, equals(4));

      // Should be evenly spaced across 360 degrees (~90 degrees each)
      expect(r1Placed[0].angle, closeTo(0.0, 0.05));
      expect(r1Placed[1].angle, closeTo(-pi / 2, 0.05));
      expect(r1Placed[2].angle, closeTo(-pi, 0.05));
      expect(r1Placed[3].angle, closeTo(-3 * pi / 2, 0.05));
    });
  });
}
