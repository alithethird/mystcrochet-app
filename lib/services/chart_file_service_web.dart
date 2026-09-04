// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'platform_file_data.dart';

Future<bool> saveChartPlatform(Uint8List bytes, String fileName) async {
  try {
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
    return true;
  } catch (_) {
    return false;
  }
}

Future<PlatformFileData?> pickAndReadChartPlatform() async {
  final completer = Completer<PlatformFileData?>();
  final uploadInput = html.FileUploadInputElement();
  uploadInput.accept = '.crochet,.json,application/json,*/*';

  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }

    final file = files[0];
    final reader = html.FileReader();

    reader.onLoadEnd.listen((e) {
      try {
        final result = reader.result;
        Uint8List bytes;
        if (result is Uint8List) {
          bytes = result;
        } else if (result is ByteBuffer) {
          bytes = result.asUint8List();
        } else if (result is List<int>) {
          bytes = Uint8List.fromList(result);
        } else {
          bytes = Uint8List.fromList(utf8.encode(result.toString()));
        }
        if (!completer.isCompleted) {
          completer.complete(PlatformFileData(bytes: bytes, fileName: file.name));
        }
      } catch (err) {
        if (!completer.isCompleted) completer.completeError(err);
      }
    });

    reader.onError.listen((err) {
      if (!completer.isCompleted) {
        completer.completeError(FormatException('"${file.name}" dosyası okunamadı.'));
      }
    });

    reader.readAsArrayBuffer(file);
  });

  uploadInput.click();
  return completer.future;
}

Future<Uint8List?> readBytesPlatform(String path) async {
  return null;
}

