import 'dart:convert';
import 'dart:typed_data';
import '../models/chart.dart';
import '../models/stitch_record.dart';
import '../providers/stitch_provider.dart';
import '../utils/serialization.dart';
import 'chart_file_service_stub.dart'
    if (dart.library.html) 'chart_file_service_web.dart'
    if (dart.library.io) 'chart_file_service_io.dart';
export 'platform_file_data.dart';

class ChartLoadResult {
  final Chart chart;
  final String fileName;

  const ChartLoadResult({required this.chart, required this.fileName});
}

abstract class ChartFileService {
  /// Prepares [chart] by embedding definitions for all stitches used in it.
  static Chart prepareChartWithUsedStitches(Chart chart, [StitchStoreNotifier? stitchStore]) {
    final usedNames = <String>{};
    if (chart.starterStitchName != null && chart.starterStitchName!.isNotEmpty) {
      usedNames.add(chart.starterStitchName!);
    }
    for (final r in chart.patternRounds) {
      for (final s in r.stitches) {
        final name = s.name ?? s.kind;
        if (name.isNotEmpty && name != 'magicRing') {
          usedNames.add(name);
        }
      }
    }
    for (final v in chart.visualStitches) {
      if (v.stitchName.isNotEmpty) usedNames.add(v.stitchName);
    }

    final embedded = <StitchRecord>[];
    final seen = <String>{};
    if (chart.embeddedStitches != null) {
      for (final s in chart.embeddedStitches!) {
        embedded.add(s);
        seen.add(s.name);
      }
    }
    if (stitchStore != null) {
      for (final name in usedNames) {
        if (!seen.contains(name)) {
          final rec = stitchStore.getStitch(name);
          if (rec != null) {
            embedded.add(rec);
            seen.add(name);
          }
        }
      }
    }
    return chart.copyWith(embeddedStitches: embedded.isNotEmpty ? embedded : null);
  }

  /// Serializes and saves [chart] to a file with [fileName].
  ///
  /// Supports both `.crochet` and `.json` extensions. Defaults to `.crochet`.
  /// Automatically embeds definitions for all stitches used in the chart if [stitchStore] is provided.
  static Future<bool> saveChart(Chart chart, String fileName, {StitchStoreNotifier? stitchStore}) {
    String finalName = fileName.trim();
    if (finalName.isEmpty) {
      finalName = 'crochet_pattern.crochet';
    }
    if (!finalName.toLowerCase().endsWith('.crochet') &&
        !finalName.toLowerCase().endsWith('.json')) {
      finalName = '$finalName.crochet';
    }

    final chartToSave = prepareChartWithUsedStitches(chart, stitchStore);
    final jsonString = const JsonEncoder.withIndent('  ').convert(chartToSave.toJson());
    final bytes = Uint8List.fromList(utf8.encode(jsonString));
    return saveChartPlatform(bytes, finalName);
  }

  /// Parses a [Chart] from UTF-8 [bytes]. If [fileName] is provided and the chart
  /// name is empty or 'Untitled', it derives the name from [fileName].
  static Chart parseChartBytes(Uint8List bytes, {String? fileName}) {
    try {
      final jsonStr = utf8.decode(bytes);
      return parseChartJson(jsonStr, name: fileName);
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Dosya çözümlenemedi: $e');
    }
  }

  /// Parses a [Chart] directly from a JSON string.
  static Chart parseChartJson(String jsonStr, {String? name}) {
    final trimmed = jsonStr.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Boş grafik verisi.');
    }
    try {
      final chart = chartFromJson(trimmed);
      if (name != null && name.isNotEmpty && (chart.name.trim().isEmpty || chart.name == 'Untitled')) {
        final fallbackName = name.replaceAll(RegExp(r'\.(crochet|json)$', caseSensitive: false), '');
        return chart.copyWith(name: fallbackName);
      }
      return chart;
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Geçersiz grafik JSON verisi: $e');
    }
  }

  /// Picks and loads a chart file (.crochet or .json) from the user's system.
  /// Returns [ChartLoadResult] or null if cancelled.
  static Future<ChartLoadResult?> openChart() async {
    final fileData = await pickAndReadChartPlatform();
    if (fileData == null) {
      return null;
    }

    final chart = parseChartBytes(fileData.bytes, fileName: fileData.fileName);
    return ChartLoadResult(chart: chart, fileName: fileData.fileName);
  }
}
