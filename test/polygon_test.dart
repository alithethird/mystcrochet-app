import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:crochet_charts/utils/polygon.dart' as pg;

void main() {
  group('polygon geometry', () {
    test('sideLength and apothem match formulas', () {
      expect(pg.polygonSideLength(10, 4), closeTo(14.142, 0.01));
      expect(pg.polygonApothem(10, 4), closeTo(7.071, 0.01));
      expect(pg.polygonSideLength(10, 6), closeTo(10.0, 0.01));
      expect(pg.polygonApothem(10, 6), closeTo(8.66, 0.01));
    });

    test('perimeter equals n * (straight + arc)', () {
      final p = pg.polygonPerimeter(10, 6, 1.0);
      expect(p, closeTo(59.36, 0.5));
    });

    test('flat-bottom: bottom midpoint at s=0 is (0, apothem)', () {
      final cr = pg.polygonCornerRadius(20, 4, 0.15);
      final (pos, _) = pg.polygonPointAt(20, 4, cr, 0);
      expect(pos.dx, closeTo(0, 0.001));
      expect(pos.dy, closeTo(pg.polygonApothem(20, 4), 0.001));
    });

    test('flat-bottom square: V[0] at s=sideLen/2', () {
      final cr = pg.polygonCornerRadius(20, 4, 0.0);
      final sl = pg.polygonSideLength(20, 4);
      final (v0, _) = pg.polygonPointAt(20, 4, cr, sl / 2);
      expect(v0.dx, closeTo(14.142, 0.01));
      expect(v0.dy, closeTo(14.142, 0.01));
      final perimeter = pg.polygonPerimeter(20, 4, cr);
      final (backToStart, _) = pg.polygonPointAt(20, 4, cr, perimeter - 0.001);
      expect(backToStart.dx, closeTo(0, 0.1));
      expect(backToStart.dy, closeTo(pg.polygonApothem(20, 4), 0.1));
    });

    test('direction lookup round-trips through perimeter for hexagon', () {
      const r = 30.0;
      const sides = 6;
      final cr = pg.polygonCornerRadius(r, sides, 0.15);
      for (double dir = -3.14; dir < 3.14; dir += 0.3) {
        final s = pg.polygonPerimeterFromDirection(r, sides, cr, dir);
        final (pos, _) = pg.polygonPointAt(r, sides, cr, s);
        final a = math.atan2(pos.dy, pos.dx);
        var delta = (a - dir);
        delta = ((delta + math.pi) % (2 * math.pi)) - math.pi;
        expect(delta.abs(), lessThan(0.06),
            reason: 'dir=$dir resolved to a=$a, delta=$delta');
      }
    });

    test('polygonPath length matches polygonPerimeter (no rogue arcs)', () {
      // Regression: the last-corner wrap bug added a near-full tiny arc to the
      // path, blowing path length up far beyond `polygonPerimeter`. Verify the
      // path length now tracks the formula within ~5% (some slack for the
      // implicit closing segment and Flutter's float precision).
      for (final sides in [3, 4, 5, 6, 8, 12]) {
        const r = 100.0;
        final cr = pg.polygonCornerRadius(r, sides, 0.15);
        final path = pg.polygonPath(r, sides, cr);
        // Materialize metrics once — `computeMetrics()` returns a re-iterable
        // but inside `expect(metrics.length, ...)` plus `metrics.single` we
        // need a stable copy.
        final metricsList = path.computeMetrics().toList();
        expect(metricsList.length, 1,
            reason: 'polygonPath should be a single contour for sides=$sides');
        final pathLen = metricsList.single.length;
        final expected = pg.polygonPerimeter(r, sides, cr);
        expect(pathLen, closeTo(expected, expected * 0.05),
            reason:
                'sides=$sides cr=$cr pathLen=$pathLen expected=$expected');
      }
    });
  });
}