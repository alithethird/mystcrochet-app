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
