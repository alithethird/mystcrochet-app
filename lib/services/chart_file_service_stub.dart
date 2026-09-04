import 'dart:typed_data';

Future<bool> saveChartPlatform(Uint8List bytes, String fileName) async {
  throw UnsupportedError('Cannot save chart on this platform');
}

Future<Uint8List?> readBytesPlatform(String path) async {
  return null;
}

