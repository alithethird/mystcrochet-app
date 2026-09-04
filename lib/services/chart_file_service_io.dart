import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

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
      allowedExtensions: ['crochet', 'json'],
      bytes: bytes,
    );

    if (outputFilePath != null && outputFilePath.isNotEmpty) {
      final file = File(outputFilePath);
      if (!await file.exists() || (await file.length()) == 0) {
        await file.writeAsBytes(bytes);
      }
      return true;
    }
    return false;
  } catch (_) {
    return false;
  }
}

Future<Uint8List?> readBytesPlatform(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
  } catch (_) {}
  return null;
}

