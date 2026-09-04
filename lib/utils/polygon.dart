import 'dart:math';
import 'dart:ui';

/// Polygon geometry helpers for layout/painting.
///
/// All polygons are **flat-bottom oriented**: one horizontal side sits at the
/// bottom (screen-down, +y), centered. The polygon is inscribed in a circle of
/// circumscribed radius `r` (distance from center to each vertex). Corners
/// are rounded with radius `cr`.
///
/// Coordinate convention matches `visual_chart_view.dart`: angle is
/// `atan2(y, x)` with +y pointing screen-down. Math angle π/2 = downward.

/// Length of one straight side (vertex to vertex, before corner rounding).
double polygonSideLength(double r, int sides) => 2 * r * sin(pi / sides);

/// Distance from center to a side's midpoint (the inradius).
double polygonApothem(double r, int sides) => r * cos(pi / sides);

/// Corner radius capped so adjacent corner arcs never overlap.
double polygonCornerRadius(double r, int sides, double ratio) {
  if (sides < 3) return 0;
  final s = polygonSideLength(r, sides);
  // 2·d ≤ sideLen, where d = cr·tan(π/n) is how much each side shrinks at the
  // arc tangent point.
  final maxCr = s / 2 / tan(pi / sides) * 0.95;
  return (ratio * s).clamp(0.0, maxCr);
}

/// Length `d` along each side that's replaced by a corner-arc tangent point.
double _cornerInset(double cr, int sides) => cr * tan(pi / sides);

/// Total outline length of the rounded polygon.
double polygonPerimeter(double r, int sides, double cr) {
  if (sides < 3) return 2 * pi * r;
  final sideLen = polygonSideLength(r, sides);
  final d = _cornerInset(cr, sides);
  final straight = sideLen - 2 * d;
  final arc = cr * 2 * pi / sides;
  return sides * (straight + arc);
}

/// Math angle of vertex k in traversal order. Traversal goes counter-clockwise
/// on screen, starting from the bottom-right vertex.
/// V[0] = bottom-right (math angle π/2 - π/n); V[n-1] = bottom-left.
double _vertexAngle(int k, int sides) =>
    pi / 2 - pi / sides - 2 * pi * k / sides;

Offset _vertex(double r, int k, int sides) {
  final a = _vertexAngle(k, sides);
  return Offset(r * cos(a), r * sin(a));
}

/// Direction of travel (math angle) along side k (from V[k-1] to V[k]).
/// Side 0 (V[n-1] -> V[0], the bottom side) travels in +x direction.
double _sideDirAngle(int k, int sides) => -2 * pi * k / sides;

/// Corner-exit point on side k+1 just past the corner arc at V[k].
Offset _cornerExit(double r, int k, int sides, double d) {
  final outAngle = _sideDirAngle((k + 1) % sides, sides);
  return _vertex(r, k, sides) + Offset(cos(outAngle), sin(outAngle)) * d;
}

/// Corner-entry point on side k just before the corner arc at V[k].
Offset _cornerEntry(double r, int k, int sides, double d) {
  final inAngle = _sideDirAngle(k, sides);
  return _vertex(r, k, sides) - Offset(cos(inAngle), sin(inAngle)) * d;
}

/// Returns `(position, tangent math angle)` at perimeter arclength `s`.
///
/// `s = 0` is the bottom-side midpoint `(0, apothem)`. Increasing `s` walks the
/// outline starting toward V[0] (bottom-right vertex first).
(Offset, double) polygonPointAt(double r, int sides, double cr, double s) {
  if (sides < 3) {
    final perimeter = 2 * pi * r;
    s = ((s % perimeter) + perimeter) % perimeter;
    final a = s / r - pi / 2;
    return (Offset(r * cos(a), r * sin(a)), a + pi / 2);
  }
  final perimeter = polygonPerimeter(r, sides, cr);
  s = ((s % perimeter) + perimeter) % perimeter;

  final d = _cornerInset(cr, sides);
  final straightLen = polygonSideLength(r, sides) - 2 * d;
  final arcLen = cr * 2 * pi / sides;
  final halfStraight = polygonSideLength(r, sides) / 2 - d;

  // Half side 0: bottom-mid -> corner entry at V[0].
  Offset pos = Offset(0, polygonApothem(r, sides));
  double tang = _sideDirAngle(0, sides);
  if (s <= halfStraight) {
    return (pos + Offset(cos(tang) * s, sin(tang) * s), tang);
  }
  pos = pos + Offset(cos(tang) * halfStraight, sin(tang) * halfStraight);
  s -= halfStraight;

  // For each k in [1, sides-1]: arc at V[k-1] then straight portion of side k.
  for (int k = 1; k < sides; k++) {
    final arcMid = _arcAtVertex(r, k - 1, sides, cr, s, arcLen);
    if (arcMid != null) return arcMid;
    s -= arcLen;

    pos = _cornerExit(r, k - 1, sides, d);
    tang = _sideDirAngle(k, sides);
    if (s <= straightLen) {
      return (pos + Offset(cos(tang) * s, sin(tang) * s), tang);
    }
    pos = pos + Offset(cos(tang) * straightLen, sin(tang) * straightLen);
    s -= straightLen;
  }

  // Final arc at V[sides-1] then half side 0 back to bottom-mid.
  final lastArc = _arcAtVertex(r, sides - 1, sides, cr, s, arcLen);
  if (lastArc != null) return lastArc;
  s -= arcLen;

  final exitDir = _sideDirAngle(0, sides);
  pos = _cornerExit(r, sides - 1, sides, d);
  tang = exitDir;
  final t = s.clamp(0.0, halfStraight);
  return (pos + Offset(cos(tang) * t, sin(tang) * t), tang);
}

(Offset, double)? _arcAtVertex(
    double r, int k, int sides, double cr, double s, double arcLen) {
  if (s > arcLen) return null;
  if (arcLen == 0) {
    // No rounding: corner collapses to the vertex.
    final p = _vertex(r, k, sides);
    final a = atan2(p.dy, p.dx);
    return (p, a);
  }
  final frac = s / arcLen;
  final inAngle = _sideDirAngle(k, sides);
  // Chain the outgoing angle rather than wrapping via `% sides`, otherwise the
  // last corner's sweep silently gains +2π (a near-full tiny circle at V[n-1]).
  final outAngle = inAngle - 2 * pi / sides;
  final va = _vertexAngle(k, sides);
  // Corner arc center is on the vertex radial at distance (r - cr/cos(π/n)) —
  // NOT (r - cr). The (r - cr) formula places the center too close to the
  // origin so the tangent point doesn't match the side's perpendicular offset,
  // causing Flutter's arcTo to insert a correction line.
  final centerDist = r - cr / cos(pi / sides);
  final center = Offset(centerDist * cos(va), centerDist * sin(va));
  final startFromCenter = inAngle + pi / 2;
  final endFromCenter = outAngle + pi / 2;
  final phi = startFromCenter + (endFromCenter - startFromCenter) * frac;
  final p = center + Offset(cr * cos(phi), cr * sin(phi));
  final tangHere = inAngle + (outAngle - inAngle) * frac;
  return (p, tangHere);
}

/// Math angle (atan2 of position) of the outline point at perimeter `s`.
double polygonDirectionFromPerimeter(double r, int sides, double cr, double s) {
  final (pos, _) = polygonPointAt(r, sides, cr, s);
  return atan2(pos.dy, pos.dx);
}

/// Perimeter arclength where a ray from origin in direction `dir` meets the
/// outline. Convex centered polygons have exactly one such hit per outward
/// direction. Circle (sides<3): s measured CCW-screen from bottom-mid.
double polygonPerimeterFromDirection(double r, int sides, double cr, double dir) {
  if (sides < 3) {
    var delta = pi / 2 - dir;
    delta = ((delta % (2 * pi)) + 2 * pi) % (2 * pi);
    return r * delta;
  }
  // Sample the perimeter finely and pick the point whose atan2 matches `dir`.
  final perimeter = polygonPerimeter(r, sides, cr);
  const steps = 360;
  double bestS = 0;
  double bestDelta = double.infinity;
  for (int i = 0; i <= steps; i++) {
    final s = perimeter * i / steps;
    final (pos, _) = polygonPointAt(r, sides, cr, s);
    final a = atan2(pos.dy, pos.dx);
    var delta = (a - dir);
    delta = ((delta + pi) % (2 * pi)) - pi;
    if (delta.abs() < bestDelta) {
      bestDelta = delta.abs();
      bestS = s;
    }
  }
  return bestS;
}

/// Builds a Flutter `Path` for the rounded flat-bottom polygon.
Path polygonPath(double r, int sides, double cr) {
  if (sides < 3) {
    return Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r));
  }
  final d = _cornerInset(cr, sides);
  final path = Path();
  final start = Offset(0, polygonApothem(r, sides));
  path.moveTo(start.dx, start.dy);

  // Half-of-side 0 to corner entry at V[0].
  final entry0 = _cornerEntry(r, 0, sides, d);
  path.lineTo(entry0.dx, entry0.dy);

  for (int k = 0; k < sides; k++) {
    final inAngle = _sideDirAngle(k, sides);
    // Chain the outgoing angle rather than wrapping via `% sides`; otherwise
    // the last corner's sweep silently gains +2π (a near-full tiny circle at
    // the bottom-left vertex V[n-1]).
    final outAngle = inAngle - 2 * pi / sides;
    final va = _vertexAngle(k, sides);
    // Corner arc center on the vertex radial at distance (r - cr/cos(π/n)) so
    // the arc's tangent points align with the perpendicular distance `cr` from
    // each adjacent side. (Using `r - cr` here would misplace the center and
    // make Flutter's `arcTo` insert a correction line at every corner.)
    final centerDist = r - cr / cos(pi / sides);
    final center = Offset(centerDist * cos(va), centerDist * sin(va));
    final startFromCenter = inAngle + pi / 2;
    final sweep = (outAngle + pi / 2) - startFromCenter; // exterior turn angle
    path.arcTo(
      Rect.fromCircle(center: center, radius: cr),
      startFromCenter,
      sweep,
      false,
    );
    if (k < sides - 1) {
      final nextEntry = _cornerEntry(r, k + 1, sides, d);
      path.lineTo(nextEntry.dx, nextEntry.dy);
    } else {
      path.lineTo(start.dx, start.dy);
    }
  }
  path.close();
  return path;
}