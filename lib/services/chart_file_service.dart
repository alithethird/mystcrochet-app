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
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Grafik Aç / İçe Aktar',
        type: FileType.any,
        withData: true,
      );
    } catch (_) {
      // Fallback in case platform requires custom
      result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Grafik Aç / İçe Aktar',
        type: FileType.custom,
        allowedExtensions: ['crochet', 'json'],
        withData: true,
      );
    }

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final picked = result.files.first;
    Uint8List? bytes = picked.bytes;

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
