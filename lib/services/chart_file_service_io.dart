import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'platform_file_data.dart';

Future<bool> saveChartPlatform(Uint8List bytes, String fileName) async {
  try {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final xFile = XFile.fromData(
        bytes,
        mimeType: 'application/json',
        name: fileName,
      );
      // ignore: deprecated_member_use
      final result = await Share.shareXFiles(
        [xFile],
        subject: fileName,
        text: 'Crochet Chart pattern file',
      );
      return result.status != ShareResultStatus.dismissed;
    }

    // Desktop platforms (Linux, macOS, Windows)
    final outputFilePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Crochet Chart',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['crochet', 'json', 'CROCHET', 'JSON'],
      bytes: bytes,
    );

    if (outputFilePath != null && outputFilePath.isNotEmpty) {
      final file = File(outputFilePath);
      await file.writeAsBytes(bytes, flush: true);
      return true;
    }
    return false;
  } catch (_) {
    return false;
  }
}

Future<PlatformFileData?> pickAndReadChartPlatform() async {
  FilePickerResult? result;
  try {
    result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Grafik Aç / İçe Aktar',
      type: FileType.any,
      withData: true,
    );
  } catch (_) {
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

  return PlatformFileData(bytes: bytes, fileName: picked.name);
}

Future<Uint8List?> readBytesPlatform(String path) async {
  try {
    final file = File(path.trim());
    if (await file.exists()) {
      return await file.readAsBytes();
    }
  } catch (_) {}
  return null;
}

