import 'dart:typed_data';

class PlatformFileData {
  final Uint8List bytes;
  final String fileName;

  const PlatformFileData({required this.bytes, required this.fileName});
}
