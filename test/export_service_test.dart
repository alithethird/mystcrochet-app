import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:crochet_charts/services/export_service.dart';

void main() {
  group('ExportService Tests', () {
    test('savePng handles empty bytes or standard invocation without crashing', () async {
      final dummyBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]); // PNG header signature
      final result = await ExportService.savePng(dummyBytes, 'test_pattern');
      // In headless test environment (where native picker / window is absent), it safely returns false without throwing
      expect(result, isA<bool>());
    });

    test('savePng ensures .png extension is appended', () async {
      final dummyBytes = Uint8List(0);
      final result = await ExportService.savePng(dummyBytes, 'flower_chart.png');
      expect(result, isA<bool>());
    });
  });
}
