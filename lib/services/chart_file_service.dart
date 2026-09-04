import 'dart:convert';
import 'dart:typed_data';
import '../models/chart.dart';
import 'chart_file_service_stub.dart'
    if (dart.library.html) 'chart_file_service_web.dart'
    if (dart.library.io) 'chart_file_service_io.dart';

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
}
