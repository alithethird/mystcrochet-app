import 'dart:convert';
import 'dart:typed_data';
import 'package:crochet_charts/models/chart.dart';
import 'package:crochet_charts/models/guidelines.dart';
import 'package:crochet_charts/models/pattern.dart';
import 'package:crochet_charts/services/chart_file_service.dart';
import 'package:crochet_charts/utils/serialization.dart';
import 'package:crochet_charts/widgets/toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Chart Open & Load Tests', () {
    test('parseChartBytes decodes valid JSON chart correctly', () {
      final original = Chart(
        name: 'Tulip Square',
        style: GuidelinesType.visual,
        guidelines: Guidelines(type: GuidelinesType.visual, visualRounds: 3),
        patternRounds: [
          PatternRound(
            number: 1,
            stitches: [
              PatternStitch(kind: 'stitch', name: 'sc', count: 6),
            ],
          ),
        ],
      );

      final jsonStr = chartToJson(original);
      final bytes = Uint8List.fromList(utf8.encode(jsonStr));

      final loaded = ChartFileService.parseChartBytes(bytes, fileName: 'ignored.crochet');
      expect(loaded.name, 'Tulip Square');
      expect(loaded.patternRounds.length, 1);
      expect(loaded.patternRounds.first.stitches.first.name, 'sc');
    });

    test('parseChartBytes derives name from fileName if chart name is Untitled or empty', () {
      final untitledChart = Chart(
        name: 'Untitled',
        guidelines: Guidelines(type: GuidelinesType.visual),
      );

      final bytes = Uint8List.fromList(utf8.encode(chartToJson(untitledChart)));

      final loadedCrochet = ChartFileService.parseChartBytes(
        bytes,
        fileName: 'vintage_doily.crochet',
      );
      expect(loadedCrochet.name, 'vintage_doily');

      final loadedJson = ChartFileService.parseChartBytes(
        bytes,
        fileName: 'mandala_blue.json',
      );
      expect(loadedJson.name, 'mandala_blue');
    });

    test('parseChartBytes throws FormatException on invalid non-JSON data', () {
      final invalidBytes = Uint8List.fromList(utf8.encode('this is not json at all'));

      expect(
        () => ChartFileService.parseChartBytes(invalidBytes, fileName: 'corrupt.crochet'),
        throwsA(isA<FormatException>()),
      );
    });

    test('parseChartBytes throws FormatException when root is not a JSON object', () {
      final arrayBytes = Uint8List.fromList(utf8.encode('[1, 2, 3]'));

      expect(
        () => ChartFileService.parseChartBytes(arrayBytes, fileName: 'array.json'),
        throwsA(isA<FormatException>()),
      );
    });

    testWidgets('AppToolbar Open button fires onOpen callback', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool openFired = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppToolbar(
                onNew: () {},
                onOpen: () => openFired = true,
                onSave: () {},
                onTextView: () {},
                onExportPng: () {},
              ),
            ),
          ),
        ),
      );

      final openButton = find.widgetWithIcon(IconButton, Icons.folder_open);
      expect(openButton, findsOneWidget);

      await tester.tap(openButton);
      await tester.pump();

      expect(openFired, isTrue);
    });
  });
}
