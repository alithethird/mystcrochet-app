import 'dart:typed_data';
import 'export_service_stub.dart'
    if (dart.library.html) 'export_service_web.dart'
    if (dart.library.io) 'export_service_io.dart';

abstract class ExportService {
  /// Saves or shares the provided PNG bytes across Web, Mobile, and Desktop platforms.
  static Future<bool> savePng(Uint8List bytes, String fileName) {
    String finalName = fileName.trim();
    if (!finalName.toLowerCase().endsWith('.png')) {
      finalName = '$finalName.png';
    }
    return savePngPlatform(bytes, finalName);
  }
}
