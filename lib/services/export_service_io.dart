import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

Future<bool> savePngPlatform(Uint8List bytes, String fileName) async {
  try {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final xFile = XFile.fromData(
        bytes,
        mimeType: 'image/png',
        name: fileName,
      );
      // ignore: deprecated_member_use
      final result = await Share.shareXFiles(
        [xFile],
        subject: fileName,
        text: 'Exported from Crochet Charts',
      );
      return result.status != ShareResultStatus.dismissed;
    }

    // Desktop platforms (Linux, macOS, Windows)
    final outputFilePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Chart as PNG',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['png'],
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
