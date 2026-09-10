import '../models/stitch_record.dart';

/// Normalizes text by lowercasing, replacing Turkish diacritics, and stripping punctuation.
String normalizeSearchText(String input) {
  var s = input.toLowerCase();
  s = s
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');
  s = s.replaceAll(RegExp(r'[^a-z0-9]'), ' ');
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Computes Damerau-Levenshtein distance between [source] and [target],
/// accounting for insertions, deletions, substitutions, and adjacent transpositions.
int damerauLevenshteinDistance(String source, String target) {
  if (source == target) return 0;
  if (source.isEmpty) return target.length;
  if (target.isEmpty) return source.length;

  final srcLen = source.length;
  final tgtLen = target.length;
  final d = List.generate(srcLen + 1, (_) => List.filled(tgtLen + 1, 0));

  for (int i = 0; i <= srcLen; i++) {
    d[i][0] = i;
  }
  for (int j = 0; j <= tgtLen; j++) {
    d[0][j] = j;
  }

  for (int i = 1; i <= srcLen; i++) {
    for (int j = 1; j <= tgtLen; j++) {
      final cost = source[i - 1] == target[j - 1] ? 0 : 1;
      int minVal = d[i - 1][j] + 1; // deletion
      final insertion = d[i][j - 1] + 1;
      if (insertion < minVal) minVal = insertion;
      final substitution = d[i - 1][j - 1] + cost;
      if (substitution < minVal) minVal = substitution;

      // Transposition
      if (i > 1 &&
          j > 1 &&
          source[i - 1] == target[j - 2] &&
          source[i - 2] == target[j - 1]) {
        final transposition = d[i - 2][j - 2] + cost;
        if (transposition < minVal) minVal = transposition;
      }

      d[i][j] = minVal;
    }
  }

  return d[srcLen][tgtLen];
}

/// Checks if [query] is a subsequence of [target].
bool isSubsequence(String query, String target) {
  if (query.isEmpty) return true;
  if (target.length < query.length) return false;
  int qIdx = 0;
  for (int tIdx = 0; tIdx < target.length; tIdx++) {
    if (target[tIdx] == query[qIdx]) {
      qIdx++;
      if (qIdx == query.length) return true;
    }
  }
  return false;
}

/// Computes an acronym from words in [text], e.g. "single crochet" -> "sc".
String getAcronym(String text) {
  final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  return words.map((w) => w[0]).join();
}

/// Scores how well [record] matches the [rawQuery].
/// Returns 0.0 if not considered a match.
double scoreStitchMatch(StitchRecord record, String rawQuery) {
  final query = normalizeSearchText(rawQuery);
  if (query.isEmpty) return 1.0;

  final normName = normalizeSearchText(record.name);
  final normDesc = normalizeSearchText(record.description);
  final nameNoSpace = normName.replaceAll(' ', '');
  final descNoSpace = normDesc.replaceAll(' ', '');
  final queryNoSpace = query.replaceAll(' ', '');

  double totalScore = 0.0;

  // 1. Direct exact or whole-string matches
  if (normName == query || nameNoSpace == queryNoSpace) {
    totalScore += 1000.0;
  } else if (normDesc == query || descNoSpace == queryNoSpace) {
    totalScore += 700.0;
  } else if (normName.startsWith(query)) {
    totalScore += 500.0;
  } else if (nameNoSpace.startsWith(queryNoSpace)) {
    totalScore += 450.0;
  } else if (normName.contains(query)) {
    totalScore += 350.0;
  } else if (normDesc.startsWith(query)) {
    totalScore += 300.0;
  } else if (normDesc.contains(query)) {
    totalScore += 200.0;
  }

  // 2. Acronym match (e.g. "sc" -> "single crochet", "slst" -> "slip stitch")
  final descAcronym = getAcronym(normDesc);
  final nameAcronym = getAcronym(normName);
  if (descAcronym == queryNoSpace || nameAcronym == queryNoSpace) {
    totalScore += 400.0;
  } else if (descAcronym.startsWith(queryNoSpace) || nameAcronym.startsWith(queryNoSpace)) {
    totalScore += 200.0;
  }

  // 3. Whole query fuzzy distance against name or nameNoSpace
  final nameDist = damerauLevenshteinDistance(queryNoSpace, nameNoSpace);
  final maxAllowedDist = queryNoSpace.length >= 5 ? 2 : (queryNoSpace.length >= 3 ? 1 : 0);
  if (nameDist <= maxAllowedDist && maxAllowedDist > 0) {
    totalScore += (1.0 - (nameDist / nameNoSpace.length.clamp(1, 100))) * 300.0;
  }

  // 4. Token-by-token evaluation
  final queryTokens = query.split(' ').where((t) => t.isNotEmpty).toList();
  final targetWords = [
    ...normName.split(' '),
    ...normDesc.split(' '),
  ].where((w) => w.isNotEmpty).toSet().toList();

  int matchedTokensCount = 0;
  double tokensScoreSum = 0.0;

  for (final qToken in queryTokens) {
    double bestTokenScore = 0.0;

    for (final word in targetWords) {
      if (word == qToken) {
        bestTokenScore = bestTokenScore < 100.0 ? 100.0 : bestTokenScore;
        continue;
      }
      if (word.startsWith(qToken)) {
        const score = 80.0;
        if (score > bestTokenScore) bestTokenScore = score;
        continue;
      }
      if (word.contains(qToken)) {
        const score = 50.0;
        if (score > bestTokenScore) bestTokenScore = score;
        continue;
      }

      // Approximate / Damerau-Levenshtein
      final tokenLen = qToken.length;
      final allowedDist = tokenLen >= 5 ? 2 : (tokenLen >= 3 ? 1 : 0);
      if (allowedDist > 0) {
        final dist = damerauLevenshteinDistance(qToken, word);
        if (dist <= allowedDist) {
          final score = (1.0 - (dist / word.length.clamp(1, 100))) * 60.0;
          if (score > bestTokenScore) bestTokenScore = score;
        }
      }

      // Subsequence check (e.g. "popcrn" in "popcorn")
      if (tokenLen >= 3 && isSubsequence(qToken, word)) {
        const score = 40.0;
        if (score > bestTokenScore) bestTokenScore = score;
      }
    }

    // Also check qToken against the full nameNoSpace if no word matched
    if (bestTokenScore == 0.0) {
      if (nameNoSpace.contains(qToken)) {
        bestTokenScore = 45.0;
      } else if (qToken.length >= 3) {
        final dist = damerauLevenshteinDistance(qToken, nameNoSpace);
        final allowedDist = qToken.length >= 5 ? 2 : 1;
        if (dist <= allowedDist) {
          bestTokenScore = (1.0 - (dist / nameNoSpace.length.clamp(1, 100))) * 50.0;
        }
      }
    }

    if (bestTokenScore > 0.0) {
      matchedTokensCount++;
      tokensScoreSum += bestTokenScore;
    }
  }

  // All query tokens must match something for a multi-token query
  if (queryTokens.isNotEmpty && matchedTokensCount < queryTokens.length) {
    if (totalScore < 300.0) {
      return 0.0;
    }
  } else {
    totalScore += tokensScoreSum;
  }

  // Length disparity penalty: closer lengths rank higher
  final lenDiff = (normName.length - query.length).abs();
  totalScore -= (lenDiff * 0.5);

  return totalScore > 0 ? totalScore : 0.0;
}

/// Searches and ranks [stitches] matching [query] with category filtering.
List<StitchRecord> searchStitches({
  required List<StitchRecord> stitches,
  required String query,
  String? activeCategory,
}) {
  var pool = stitches;
  if (activeCategory != null) {
    pool = pool.where((s) => s.category.contains(activeCategory)).toList();
  }

  final trimmed = query.trim();
  if (trimmed.isEmpty) {
    return pool;
  }

  final scored = <MapEntry<StitchRecord, double>>[];
  for (final stitch in pool) {
    final score = scoreStitchMatch(stitch, trimmed);
    if (score > 0.0) {
      scored.add(MapEntry(stitch, score));
    }
  }

  // Sort descending by score
  scored.sort((a, b) {
    final cmp = b.value.compareTo(a.value);
    if (cmp != 0) return cmp;
    return a.key.name.compareTo(b.key.name);
  });

  return scored.map((e) => e.key).toList();
}
