import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../models/chart.dart';
import '../utils/serialization.dart';
import 'chart_file_service_stub.dart'
    if (dart.library.html) 'chart_file_service_web.dart'
    if (dart.library.io) 'chart_file_service_io.dart';

class ChartLoadResult {
  final Chart chart;
  final String fileName;

  const ChartLoadResult({required this.chart, required this.fileName});
}

abstract class ChartFileService {
  /// Serializes and saves [chart] to a file with [fileName].
  ///
  /// Supports both `.crochet` and `.json` extensions. Defaults to `.crochet`.
  static Future<bool> saveChart(Chart chart, String fileName) {
    String finalName = fileName.trim();
    if (finalName.isEmpty) {
      finalName = 'crochet_pattern.crochet';
    }
    if (!finalName.toLowerCase().endsWith('.crochet') &&
        !finalName.toLowerCase().endsWith('.json')) {
      finalName = '$finalName.crochet';
    }

    final jsonString = const JsonEncoder.withIndent('  ').convert(chart.toJson());
    final bytes = Uint8List.fromList(utf8.encode(jsonString));
    return saveChartPlatform(bytes, finalName);
  }

  /// Parses a [Chart] from UTF-8 [bytes]. If [fileName] is provided and the chart
  /// name is empty or 'Untitled', it derives the name from [fileName].
  static Chart parseChartBytes(Uint8List bytes, {String? fileName}) {
    final jsonStr = utf8.decode(bytes);
    final chart = chartFromJson(jsonStr);
    if (fileName != null && fileName.isNotEmpty && (chart.name.trim().isEmpty || chart.name == 'Untitled')) {
      final fallbackName = fileName.replaceAll(RegExp(r'\.(crochet|json)$', caseSensitive: false), '');
      return chart.copyWith(name: fallbackName);
    }
    return chart;
  }

  /// Picks and loads a chart file (.crochet or .json) from the user's system.
  /// Returns [ChartLoadResult] or null if cancelled.
  static Future<ChartLoadResult?> openChart() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Open Crochet Chart',
      type: FileType.custom,
      allowedExtensions: ['crochet', 'json', 'CROCHET', 'JSON'],
      withData: true,
      withReadStream: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final picked = result.files.first;
    Uint8List? bytes = picked.bytes;

    if ((bytes == null || bytes.isEmpty) && picked.readStream != null) {
      try {
        final chunks = <int>[];
        await for (final chunk in picked.readStream!) {
          chunks.addAll(chunk);
        }
        if (chunks.isNotEmpty) {
          bytes = Uint8List.fromList(chunks);
        }
      } catch (_) {}
    }

    if ((bytes == null || bytes.isEmpty) && picked.path != null && picked.path!.isNotEmpty) {
      bytes = await readBytesPlatform(picked.path!);
    }

    if (bytes == null || bytes.isEmpty) {
      throw FormatException('"${picked.name}" dosyası okunamadı veya dosya boş.');
    }

    final chart = parseChartBytes(bytes, fileName: picked.name);
    return ChartLoadResult(chart: chart, fileName: picked.name);
  }
}
