import '../models/chart.dart';
import '../models/pattern.dart';

String kindForStitchName(String name) {
  final lower = name.toLowerCase();
  if (lower.startsWith('ch')) return 'chain';
  if (lower == 'sl' || lower == 'slst' || lower == 'sl st') return 'slipStitch';
  return 'stitch';
}

int countForStitchName(String name) {
  final m = RegExp(r'ch[- ]?(\d+)', caseSensitive: false).firstMatch(name);
  if (m != null) return int.parse(m.group(1)!);
  return 1;
}

int? getChartRoundIndex(List<PatternRound> rounds, int visualRi) {
  int curVisualRi = 0;
  for (int i = 0; i < rounds.length; i++) {
    final real = rounds[i].stitches.where((s) => s.kind != 'magicRing').toList();
    final magicOnly = real.isEmpty && rounds[i].stitches.isNotEmpty;
    if (magicOnly) continue;
    if (curVisualRi == visualRi) return i;
    curVisualRi++;
  }
  return null;
}

class ReplaceStitchResult {
  final Chart updatedChart;
  final int replacedCount;

  ReplaceStitchResult({required this.updatedChart, required this.replacedCount});
}

ReplaceStitchResult replaceStitches({
  required Chart chart,
  required String newStitchName,
  required bool bulk,
  int? targetVisualRoundIdx,
  int? targetExpandedStitchIdx,
  String? targetStitchName,
}) {
  final newKind = kindForStitchName(newStitchName);
  final newCount = countForStitchName(newStitchName);

  if (bulk) {
    if (targetStitchName == null || targetStitchName.isEmpty) {
      return ReplaceStitchResult(updatedChart: chart, replacedCount: 0);
    }
    int totalReplaced = 0;
    final updatedRounds = <PatternRound>[];
    for (final round in chart.patternRounds) {
      final newStitches = <PatternStitch>[];
      for (final s in round.stitches) {
        final sName = s.name ?? s.kind;
        if (sName == targetStitchName && s.kind != 'magicRing') {
          final count = s.kind == 'stitch' ? (s.count ?? 1) : 1;
          totalReplaced += count;
          newStitches.add(s.copyWith(
            kind: newKind,
            name: newStitchName,
            count: newKind == 'chain' ? (s.count ?? newCount) : (s.count ?? 1),
          ));
        } else {
          newStitches.add(s);
        }
      }
      updatedRounds.add(round.copyWith(stitches: newStitches));
    }
    final connected = assignConnections(updatedRounds);
    return ReplaceStitchResult(
      updatedChart: chart.copyWith(patternRounds: connected),
      replacedCount: totalReplaced,
    );
  } else {
    if (targetVisualRoundIdx == null || targetExpandedStitchIdx == null) {
      return ReplaceStitchResult(updatedChart: chart, replacedCount: 0);
    }
    final chartRi = getChartRoundIndex(chart.patternRounds, targetVisualRoundIdx);
    if (chartRi == null || chartRi < 0 || chartRi >= chart.patternRounds.length) {
      return ReplaceStitchResult(updatedChart: chart, replacedCount: 0);
    }

    final rounds = List<PatternRound>.from(chart.patternRounds);
    final targetRound = rounds[chartRi];
    final real = targetRound.stitches.where((s) => s.kind != 'magicRing').toList();

    int expCount = 0;
    int totalReplaced = 0;

    for (int j = 0; j < real.length; j++) {
      final s = real[j];
      final c = s.kind == 'stitch' ? (s.count ?? 1) : 1;
      if (expCount + c > targetExpandedStitchIdx) {
        final sts = List<PatternStitch>.from(targetRound.stitches);
        final rawIdx = sts.indexOf(s);
        if (rawIdx != -1) {
          final subIdx = targetExpandedStitchIdx - expCount;
          final replacedItem = s.copyWith(
            kind: newKind,
            name: newStitchName,
            count: newKind == 'chain' ? newCount : 1,
          );

          if (c == 1) {
            sts[rawIdx] = replacedItem;
          } else {
            final parts = <PatternStitch>[];
            if (subIdx > 0) {
              parts.add(s.copyWith(count: subIdx));
            }
            parts.add(replacedItem);
            if (c - 1 - subIdx > 0) {
              parts.add(s.copyWith(count: c - 1 - subIdx));
            }
            sts.replaceRange(rawIdx, rawIdx + 1, parts);
          }
          rounds[chartRi] = targetRound.copyWith(stitches: sts);
          totalReplaced = 1;
        }
        break;
      }
      expCount += c;
    }

    if (totalReplaced > 0) {
      final connected = assignConnections(rounds);
      return ReplaceStitchResult(
        updatedChart: chart.copyWith(patternRounds: connected),
        replacedCount: totalReplaced,
      );
    }
    return ReplaceStitchResult(updatedChart: chart, replacedCount: 0);
  }
}

class DeleteStitchResult {
  final Chart updatedChart;
  final int deletedCount;

  DeleteStitchResult({required this.updatedChart, required this.deletedCount});
}

DeleteStitchResult deleteSelectedStitches({
  required Chart chart,
  required Set<String> selectedKeys,
}) {
  if (selectedKeys.isEmpty) {
    return DeleteStitchResult(updatedChart: chart, deletedCount: 0);
  }

  final rounds = List<PatternRound>.from(chart.patternRounds);
  int totalDeleted = 0;
  int visualRi = 0;

  for (int i = 0; i < rounds.length; i++) {
    final round = rounds[i];
    final real = round.stitches.where((s) => s.kind != 'magicRing').toList();
    final magicOnly = real.isEmpty && round.stitches.isNotEmpty;
    if (magicOnly) continue;

    final expanded = expandStitches(real);
    final remaining = <PatternStitch>[];
    for (int si = 0; si < expanded.length; si++) {
      final key = '$visualRi:$si';
      if (selectedKeys.contains(key)) {
        totalDeleted++;
      } else {
        remaining.add(expanded[si]);
      }
    }

    final magicStitches = round.stitches.where((s) => s.kind == 'magicRing').toList();
    rounds[i] = round.copyWith(stitches: [...magicStitches, ...remaining]);
    visualRi++;
  }

  // Trim trailing empty rounds if any
  while (rounds.length > 1 && rounds.last.stitches.isEmpty) {
    rounds.removeLast();
  }

  final connected = assignConnections(rounds);
  return DeleteStitchResult(
    updatedChart: chart.copyWith(patternRounds: connected),
    deletedCount: totalDeleted,
  );
}

ReplaceStitchResult replaceSelectedStitches({
  required Chart chart,
  required Set<String> selectedKeys,
  required String newStitchName,
}) {
  if (selectedKeys.isEmpty) {
    return ReplaceStitchResult(updatedChart: chart, replacedCount: 0);
  }

  final newKind = kindForStitchName(newStitchName);
  final newCount = countForStitchName(newStitchName);
  final rounds = List<PatternRound>.from(chart.patternRounds);
  int totalReplaced = 0;
  int visualRi = 0;

  for (int i = 0; i < rounds.length; i++) {
    final round = rounds[i];
    final real = round.stitches.where((s) => s.kind != 'magicRing').toList();
    final magicOnly = real.isEmpty && round.stitches.isNotEmpty;
    if (magicOnly) continue;

    final expanded = expandStitches(real);
    final updatedStitches = <PatternStitch>[];
    for (int si = 0; si < expanded.length; si++) {
      final key = '$visualRi:$si';
      if (selectedKeys.contains(key)) {
        totalReplaced++;
        updatedStitches.add(expanded[si].copyWith(
          kind: newKind,
          name: newStitchName,
          count: newKind == 'chain' ? newCount : 1,
        ));
      } else {
        updatedStitches.add(expanded[si]);
      }
    }

    final magicStitches = round.stitches.where((s) => s.kind == 'magicRing').toList();
    rounds[i] = round.copyWith(stitches: [...magicStitches, ...updatedStitches]);
    visualRi++;
  }

  final connected = assignConnections(rounds);
  return ReplaceStitchResult(
    updatedChart: chart.copyWith(patternRounds: connected),
    replacedCount: totalReplaced,
  );
}
