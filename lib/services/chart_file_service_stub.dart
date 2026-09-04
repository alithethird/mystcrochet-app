import 'dart:typed_data';
import 'platform_file_data.dart';

Future<bool> saveChartPlatform(Uint8List bytes, String fileName) async {
  throw UnsupportedError('Cannot save chart on this platform');
}

Future<PlatformFileData?> pickAndReadChartPlatform() async {
  return null;
}

Future<Uint8List?> readBytesPlatform(String path) async {
  return null;
}

