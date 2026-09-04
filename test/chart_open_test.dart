import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crochet_charts/models/chart.dart';
import 'package:crochet_charts/models/guidelines.dart';
import 'package:crochet_charts/models/pattern.dart';
import 'package:crochet_charts/models/stitch_record.dart';
import 'package:crochet_charts/providers/chart_provider.dart';
import 'package:crochet_charts/services/chart_file_service.dart';
import 'package:crochet_charts/providers/stitch_provider.dart';
import 'package:crochet_charts/utils/serialization.dart';
import 'package:crochet_charts/widgets/toolbar.dart';
import 'package:crochet_charts/widgets/visual_chart_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

    test('parseChartBytes can parse user file /home/ali/Downloads/test1.crochet', () async {
      final file = File('/home/ali/Downloads/test1.crochet');
      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        final chart = ChartFileService.parseChartBytes(bytes, fileName: 'test1.crochet');
        expect(chart.name, 'test1');
        expect(chart.patternRounds.length, 2);
        expect(chart.starterStitchName, 'ring');

        // Test layoutChart on this chart
        final stitchNotifier = StitchStoreNotifier();
        stitchNotifier.setStitches([
          StitchRecord(name: 'sc', description: 'sc', category: ['Basic'], wrongSide: '', svgContent: '<svg viewBox="0 0 24 24"/>'),
          StitchRecord(name: 'dc', description: 'dc', category: ['Basic'], wrongSide: '', svgContent: '<svg viewBox="0 0 24 24"/>'),
          StitchRecord(name: 't-ch3', description: 't-ch3', category: ['Basic'], wrongSide: '', svgContent: '<svg viewBox="0 0 24 24"/>'),
          StitchRecord(name: 'ch', description: 'ch', category: ['Basic'], wrongSide: '', svgContent: '<svg viewBox="0 0 24 24"/>'),
          StitchRecord(name: 'ring', description: 'ring', category: ['starters'], wrongSide: '', svgContent: '<svg viewBox="0 0 24 24"/>'),
        ]);
        final positioned = layoutChart(
          chart.patternRounds,
          50.0,
          10.0,
          10.0,
          8.0,
          stitchNotifier,
          sides: chart.guidelines.visualShapeSides,
          cornerRatio: chart.guidelines.visualCornerRatio,
        );
        expect(positioned.length, 2);
        expect(positioned[0].length, 6);
        expect(positioned[1].length, 12);
      }
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

    testWidgets('Setting loaded chart in provider correctly renders in VisualChartView', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final file = File('/home/ali/Downloads/test1.crochet');
      if (!file.existsSync()) return;

      final bytes = file.readAsBytesSync();
      final chart = ChartFileService.parseChartBytes(bytes, fileName: 'test1.crochet');

      final notifier = StitchStoreNotifier();
      notifier.setStitches([
        StitchRecord(
          name: 'sc',
          description: 'Single crochet',
          category: ['Basic'],
          wrongSide: '',
          svgContent: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/></svg>',
        ),
        StitchRecord(
          name: 'dc',
          description: 'Double crochet',
          category: ['Basic'],
          wrongSide: '',
          svgContent: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/></svg>',
        ),
        StitchRecord(
          name: 't-ch3',
          description: 'Turning chain 3',
          category: ['Basic'],
          wrongSide: '',
          svgContent: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/></svg>',
        ),
        StitchRecord(
          name: 'ring',
          description: 'Ring',
          category: ['starters'],
          wrongSide: '',
          svgContent: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/></svg>',
        ),
      ]);

      final container = ProviderContainer(
        overrides: [
          stitchStoreProvider.overrideWith((ref) => notifier),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: VisualChartView(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Initially empty hint
      expect(find.text('Grafiğinize başlamak için paletten bir başlangıç ilmeği seçin'), findsOneWidget);

      // Now load the chart via loadChart
      container.read(chartProvider.notifier).loadChart(chart);
      await tester.pump();

      // Empty hint should be gone
      expect(find.text('Grafiğinize başlamak için paletten bir başlangıç ilmeği seçin'), findsNothing);

      // Stitches and starter are rendered as SvgPicture widgets (1 starter ring + 6 sc + 12 dc/tch3 = 19)
      expect(find.byType(SvgPicture), findsWidgets);
    });

    test('ChartNotifier loadChart resets undo/redo stack and increments loadId', () {
      final notifier = ChartNotifier();
      expect(notifier.state.loadId, 0);
      expect(notifier.state.canUndo, isFalse);

      // Mutate chart to populate undo stack
      notifier.setChart(Chart(
        name: 'Step 1',
        guidelines: Guidelines(type: GuidelinesType.visual),
      ));
      expect(notifier.state.canUndo, isTrue);

      // Call loadChart
      final loadedChart = Chart(
        name: 'Loaded File',
        guidelines: Guidelines(type: GuidelinesType.visual),
      );
      notifier.loadChart(loadedChart);

      expect(notifier.state.chart.name, 'Loaded File');
      expect(notifier.state.loadId, 1);
      expect(notifier.state.canUndo, isFalse);
      expect(notifier.state.canRedo, isFalse);
    });
  });
}
