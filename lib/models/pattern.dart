class PatternStitch {
  final String kind;
  final String? name;
  final int? count;
  final int? stitchCount;
  final List<String>? modifiers;

  /// Index into the previous round's expanded stitch list identifying the
  /// stitch this one is worked into. Null = no connection (chains, slips,
  /// first round).
  final int? connectsTo;

  /// Manual angle offset in radians, applied on top of the computed angle.
  /// Used for dragging stitches along the ring.
  final double? angleOffset;

  /// Absolute angle (radians) at which this stitch sits on its round, as chosen
  /// by the user tapping at a specific point. When non-null, _layout uses this
  /// angle directly instead of computing one from anchors / width distribution.
  /// Currently only honored for stitches added from round 2 onwards (the first
  /// round always auto-aligns).
  final double? pinnedAngle;

  /// Manual offset along the polygon perimeter (px), applied on top of the
  /// computed perimeter position. Used for dragging stitches along a
  /// polygonal round. Only read when the chart shape is a polygon.
  final double? perimeterOffset;

  /// Absolute perimeter arclength (px) at which this stitch sits on a
  /// polygonal round, as chosen by the user tapping at a specific point. When
  /// non-null, _layout uses this position directly. Only honored for polygon
  /// shapes (circle uses pinnedAngle instead).
  final double? pinnedPerimeter;

  PatternStitch({
    required this.kind,
    this.name,
    this.count,
    this.stitchCount,
    this.modifiers,
    this.connectsTo,
    this.angleOffset,
    this.pinnedAngle,
    this.perimeterOffset,
    this.pinnedPerimeter,
  });

  factory PatternStitch.fromJson(Map<String, dynamic> json) {
    return PatternStitch(
      kind: json['kind'] as String? ?? 'stitch',
      name: json['name'] as String?,
      count: json['count'] as int?,
      stitchCount: json['stitchCount'] as int?,
      modifiers: (json['modifiers'] as List?)?.map((e) => e as String).toList(),
      connectsTo: json['connectsTo'] as int?,
      angleOffset: (json['angleOffset'] as num?)?.toDouble(),
      pinnedAngle: (json['pinnedAngle'] as num?)?.toDouble(),
      perimeterOffset: (json['perimeterOffset'] as num?)?.toDouble(),
      pinnedPerimeter: (json['pinnedPerimeter'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kind': kind,
      if (name != null) 'name': name,
      if (count != null) 'count': count,
      if (stitchCount != null) 'stitchCount': stitchCount,
      if (modifiers != null) 'modifiers': modifiers,
      if (connectsTo != null) 'connectsTo': connectsTo,
      if (angleOffset != null) 'angleOffset': angleOffset,
      if (pinnedAngle != null) 'pinnedAngle': pinnedAngle,
      if (perimeterOffset != null) 'perimeterOffset': perimeterOffset,
      if (pinnedPerimeter != null) 'pinnedPerimeter': pinnedPerimeter,
    };
  }

  PatternStitch copyWith({
    String? kind,
    String? name,
    int? count,
    int? stitchCount,
    List<String>? modifiers,
    int? connectsTo,
    double? angleOffset,
    double? pinnedAngle,
    double? perimeterOffset,
    double? pinnedPerimeter,
  }) {
    return PatternStitch(
      kind: kind ?? this.kind,
      name: name ?? this.name,
      count: count ?? this.count,
      stitchCount: stitchCount ?? this.stitchCount,
      modifiers: modifiers ?? this.modifiers,
      connectsTo: connectsTo ?? this.connectsTo,
      angleOffset: angleOffset ?? this.angleOffset,
      pinnedAngle: pinnedAngle ?? this.pinnedAngle,
      perimeterOffset: perimeterOffset ?? this.perimeterOffset,
      pinnedPerimeter: pinnedPerimeter ?? this.pinnedPerimeter,
    );
  }
}

class PatternRound {
  final int number;
  final List<PatternStitch> stitches;
  final bool isMagicRing;

  PatternRound({
    required this.number,
    required this.stitches,
    this.isMagicRing = false,
  });

  factory PatternRound.fromJson(Map<String, dynamic> json) {
    return PatternRound(
      number: json['number'] as int? ?? 0,
      stitches: (json['stitches'] as List?)
              ?.map((e) => PatternStitch.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isMagicRing: json['isMagicRing'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'stitches': stitches.map((s) => s.toJson()).toList(),
      'isMagicRing': isMagicRing,
    };
  }
}

class ParsedPattern {
  final List<PatternRound> rounds;

  ParsedPattern({required this.rounds});

  factory ParsedPattern.fromJson(Map<String, dynamic> json) {
    return ParsedPattern(
      rounds: (json['rounds'] as List?)
              ?.map((e) => PatternRound.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rounds': rounds.map((r) => r.toJson()).toList(),
    };
  }
}

const Map<String, StitchGeometry> STITCH_GEOMETRY = {
  'sl st': StitchGeometry(height: 8, width: 8, isChain: false),
  'slst': StitchGeometry(height: 8, width: 8, isChain: false),
  'sl': StitchGeometry(height: 8, width: 8, isChain: false),
  'ch': StitchGeometry(height: 12, width: 12, isChain: true),
  'sc': StitchGeometry(height: 20, width: 16, isChain: false),
  'hdc': StitchGeometry(height: 28, width: 18, isChain: false),
  'dc': StitchGeometry(height: 36, width: 20, isChain: false),
  'tr': StitchGeometry(height: 44, width: 22, isChain: false),
  'dtr': StitchGeometry(height: 52, width: 24, isChain: false),
  'ttr': StitchGeometry(height: 60, width: 26, isChain: false),
  'edc': StitchGeometry(height: 32, width: 20, isChain: false),
  'FPdc': StitchGeometry(height: 36, width: 20, isChain: false),
  'BPdc': StitchGeometry(height: 36, width: 20, isChain: false),
  'FPtr': StitchGeometry(height: 44, width: 22, isChain: false),
  'BPtr': StitchGeometry(height: 44, width: 22, isChain: false),
  'picot': StitchGeometry(height: 12, width: 12, isChain: true),
};

class StitchGeometry {
  final int height;
  final int width;
  final bool isChain;

  const StitchGeometry({
    required this.height,
    required this.width,
    required this.isChain,
  });
}

final _knownStitches = RegExp(
  r'\b(?:sl\.?\s*st|slst|sl|ch|sc|hdc|dc|tr|dtr|ttr|edc|FPdc|BPdc|FPtr|BPtr|picot|inc|dec|sp|st|loop|shell|cl|mr|magic)\b',
  caseSensitive: false,
);

final _countSuffix = RegExp(r'\[(\d+)\]');

PatternRound? parseRoundLine(String line) {
  line = line.trim();
  if (line.isEmpty) return null;

  final roundMatch = RegExp(r'^(?:R|Round|Rd)\s*(\d+)', caseSensitive: false).firstMatch(line);
  if (roundMatch == null) return null;

  final number = int.parse(roundMatch.group(1)!);
  final isMagicRing = line.toLowerCase().contains('magic ring') || line.toLowerCase().contains('magic circle');

  final afterLabel = line.substring(roundMatch.end).replaceAll(RegExp(r'^[\s:;,.]+'), '');
  final noTotal = afterLabel.replaceAll(_countSuffix, '');
  final expanded = _expandBracketRepeats(noTotal);

  final stitches = <PatternStitch>[];
  final segments = _splitWithParens(expanded);

  for (final seg in segments) {
    final trimmed = seg.trim();
    if (trimmed.isEmpty) continue;

    if (trimmed.startsWith('(') && trimmed.endsWith(')')) {
      final inner = trimmed.substring(1, trimmed.length - 1);
      for (final innerSeg in inner.split(',')) {
        stitches.addAll(_parseStitch(innerSeg, sameStitch: true));
      }
    } else {
      stitches.addAll(_parseStitch(trimmed));
    }
  }

  if (stitches.isEmpty) return null;

  return PatternRound(number: number, stitches: stitches, isMagicRing: isMagicRing);
}

List<PatternStitch> _parseStitch(String text, {bool sameStitch = false}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return [];
  final raw = _extractKind(trimmed);
  if (raw == null) return [];
  final abbr = raw.toLowerCase().replaceAll('.', '');
  final count = _extractCount(trimmed);
  String kind;
  switch (abbr) {
    case 'ch':
      kind = 'chain';
      break;
    case 'sl':
    case 'slst':
    case 'sl st':
      kind = 'slipStitch';
      break;
    case 'mr':
    case 'magic':
      kind = 'magicRing';
      break;
    default:
      kind = 'stitch';
  }
  final mods = sameStitch ? ['sameStitch'] : <String>[];
  return [PatternStitch(kind: kind, count: count, name: abbr, modifiers: mods)];
}

String _expandBracketRepeats(String text) {
  final re = RegExp(r'\[([^\[\]]+)\]\s*[×x]\s*(\d+)');
  while (true) {
    final m = re.firstMatch(text);
    if (m == null) break;
    var contents = m.group(1)!;
    contents = contents.replaceAll(RegExp(r',\s*$'), '');
    final count = int.parse(m.group(2)!);
    final replacement = List.generate(count, (_) => contents).join(',');
    text = text.replaceFirst(m.group(0)!, replacement);
  }
  return text;
}

List<String> _splitWithParens(String text) {
  final result = <String>[];
  int depth = 0;
  int bracketDepth = 0;
  int start = 0;
  for (int i = 0; i < text.length; i++) {
    if (text[i] == '(') depth++;
    if (text[i] == ')') depth--;
    if (text[i] == '[') bracketDepth++;
    if (text[i] == ']') bracketDepth--;
    if (text[i] == ',' && depth == 0 && bracketDepth == 0) {
      result.add(text.substring(start, i));
      start = i + 1;
    }
  }
  result.add(text.substring(start));
  return result;
}

int? _extractCount(String segment) {
  // "3 ch" or "Ch 10"
  final beforeMatch = RegExp(r'^(\d+)\s*[×x*]?\s*', caseSensitive: false).firstMatch(segment.trim());
  if (beforeMatch != null) return int.parse(beforeMatch.group(1)!);
  // "Ch×3" or "ch x 3"
  final afterMatch = RegExp(r'[×x*]\s*(\d+)', caseSensitive: false).firstMatch(segment.trim());
  if (afterMatch != null) return int.parse(afterMatch.group(1)!);
  // "(10)" 
  final parenMatch = RegExp(r'\((\d+)\)').firstMatch(segment);
  if (parenMatch != null) return int.parse(parenMatch.group(1)!);
  return null;
}

String? _extractKind(String segment) {
  // Normalize dots to spaces: "sl.st" -> "sl st"
  final normalized = segment.replaceAll('.', ' ');
  final m = _knownStitches.firstMatch(normalized.toLowerCase());
  if (m != null) {
    var kind = m.group(0)!;
    // Strip dots for consistent output
    kind = kind.replaceAll('.', '');
    return kind;
  }
  return null;
}

List<PatternRound> parsePattern(String text) {
  final lines = text.split('\n');
  final rounds = <PatternRound>[];
  for (final line in lines) {
    final parsed = parseRoundLine(line);
    if (parsed != null) {
      rounds.add(parsed);
    }
  }
  return rounds;
}

/// Expands counted stitches (kind == 'stitch') into individual stitches.
/// Chains and slip stitches keep their count on a single entry.
List<PatternStitch> expandStitches(List<PatternStitch> stitches) {
  final expanded = <PatternStitch>[];
  for (final s in stitches) {
    if (s.kind == 'stitch') {
      final c = s.count ?? 1;
      for (int i = 0; i < c; i++) {
        expanded.add(s.copyWith(count: 1));
      }
    } else {
      expanded.add(s);
    }
  }
  return expanded;
}

/// Groups expanded stitches: stitches marked 'sameStitch' accumulate into the
/// current group; everything else forms its own single-stitch group.
///
/// Chains ('chain') and slip stitches ('slipStitch') are never bundled into a
/// sameStitch cluster even when the pattern text marks them as such — they
/// always form their own standalone groups so they layout between the dc/regular
/// anchor slots instead of being crammed into a cluster.
List<List<PatternStitch>> groupStitches(List<PatternStitch> expanded) {
  final groups = <List<PatternStitch>>[];
  List<PatternStitch> cur = [];
  for (final s in expanded) {
    final isSameStitch = (s.modifiers?.contains('sameStitch') ?? false);
    final separable = s.kind == 'chain' || s.kind == 'slipStitch';
    if (isSameStitch && !separable) {
      cur.add(s);
    } else {
      if (cur.isNotEmpty) {
        groups.add(cur);
        cur = [];
      }
      groups.add([s]);
    }
  }
  if (cur.isNotEmpty) groups.add(cur);
  return groups;
}

/// Returns rounds in expanded form (counted stitches become individual
/// stitches) with [PatternStitch.connectsTo] set for every stitch that is
/// worked into the previous round. Chains and slip stitches get no
/// connection; they are laid out between their anchored neighbours.
///
/// Anchoring heuristic: groups containing at least one non-chain, non-slip
/// stitch consume stitches of the previous round in order, distributed
/// evenly over the previous round's non-slip stitches.
List<PatternRound> assignConnections(List<PatternRound> rounds) {
  if (rounds.isEmpty) return rounds;
  final out = <PatternRound>[];
  List<PatternStitch>? prevExpanded;
  for (final round in rounds) {
    final mr = round.stitches.where((s) => s.kind == 'magicRing').toList();
    final real = round.stitches.where((s) => s.kind != 'magicRing').toList();
    final expanded = expandStitches(real);
    if (expanded.isEmpty) {
      out.add(round);
      continue;
    }
    var connected = expanded;
    if (prevExpanded != null && prevExpanded.isNotEmpty) {
      final prev = prevExpanded;
      final targets = <int>[
        for (int i = 0; i < prev.length; i++)
          if (prev[i].kind != 'slipStitch') i,
      ];
      final groups = groupStitches(expanded);
      // Preserve user-set connectsTo values (placed by tapping near an anchor).
      // Only honor indices that still point at a valid previous-round stitch.
      final conn = List<int?>.filled(expanded.length, null);
      for (int i = 0; i < expanded.length; i++) {
        final c = expanded[i].connectsTo;
        if (c != null && c >= 0 && c < prev.length) {
          conn[i] = c;
        }
      }
      // Auto-anchor only the anchor groups that have no user-set connectsTo.
      final autoAnchorGroups = groups
          .where((g) => g.any((s) => s.kind != 'chain' && s.kind != 'slipStitch'))
          .where((g) => !g.any((s) {
                final c = s.connectsTo;
                return c != null && c >= 0 && c < prev.length;
              }))
          .toList();
      if (targets.isNotEmpty && autoAnchorGroups.isNotEmpty) {
        int ai = 0;
        int idx = 0;
        for (final g in groups) {
          final isAnchor = g.any((s) => s.kind != 'chain' && s.kind != 'slipStitch');
          final hasUserAnchor = g.any((s) {
            final c = s.connectsTo;
            return c != null && c >= 0 && c < prev.length;
          });
          if (isAnchor && !hasUserAnchor) {
            final t = targets[(ai * targets.length) ~/ autoAnchorGroups.length];
            for (int k = 0; k < g.length; k++) {
              final st = g[k];
              if (st.kind == 'chain' || st.kind == 'slipStitch') continue;
              conn[idx + k] = t;
            }
            ai++;
          }
          idx += g.length;
        }
      }
      final hasAny = conn.any((c) => c != null);
      if (hasAny) {
        connected = [
          for (int i = 0; i < expanded.length; i++)
            conn[i] == null ? expanded[i] : expanded[i].copyWith(connectsTo: conn[i]),
        ];
      }
    }
    out.add(PatternRound(number: round.number, stitches: [...mr, ...connected], isMagicRing: round.isMagicRing));
    prevExpanded = connected;
  }
  return out;
}