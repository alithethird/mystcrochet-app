import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crochet_charts/models/chart.dart';
import 'package:crochet_charts/models/guidelines.dart';
import 'package:crochet_charts/models/pattern.dart';
import 'package:crochet_charts/models/stitch_record.dart';
import 'package:crochet_charts/providers/chart_provider.dart';
import 'package:crochet_charts/providers/edit_mode_provider.dart';
import 'package:crochet_charts/providers/stitch_provider.dart';
import 'package:crochet_charts/services/stitch_replace_service.dart';
import 'package:crochet_charts/widgets/stitch_palette.dart';
import 'package:crochet_charts/widgets/toolbar.dart';
import 'package:crochet_charts/widgets/visual_chart_view.dart';

void main() {
  group('StitchReplaceService Unit Tests', () {
    test('kindForStitchName correctly classifies stitch kinds', () {
      expect(kindForStitchName('ch'), equals('chain'));
      expect(kindForStitchName('ch-3'), equals('chain'));
      expect(kindForStitchName('sl'), equals('slipStitch'));
      expect(kindForStitchName('slst'), equals('slipStitch'));
      expect(kindForStitchName('sl st'), equals('slipStitch'));
      expect(kindForStitchName('dc'), equals('stitch'));
      expect(kindForStitchName('sc'), equals('stitch'));
      expect(kindForStitchName('popcorn'), equals('stitch'));
    });

    test('Single stitch replacement replaces exact stitch in a multi-count group', () {
      final initialChart = Chart(
        name: 'Test Chart',
        starterStitchName: 'mr',
        guidelines: Guidelines(type: GuidelinesType.visual),
        patternRounds: [
          PatternRound(
            number: 1,
            stitches: [
              PatternStitch(kind: 'stitch', name: 'dc', count: 6),
            ],
          ),
        ],
      );

      // Replace 3rd stitch (index 2 in 0-indexed) with 'sc'
      final result = replaceStitches(
        chart: initialChart,
        newStitchName: 'sc',
        bulk: false,
        targetVisualRoundIdx: 0,
        targetExpandedStitchIdx: 2,
        targetStitchName: 'dc',
      );

      expect(result.replacedCount, equals(1));
      final roundStitches = result.updatedChart.patternRounds[0].stitches;
      // assignConnections expands stitches so each stitch has individual connections
      expect(roundStitches.length, equals(6));
      expect(roundStitches[0].name, equals('dc'));
      expect(roundStitches[1].name, equals('dc'));
      expect(roundStitches[2].name, equals('sc'));
      expect(roundStitches[3].name, equals('dc'));
      expect(roundStitches[4].name, equals('dc'));
      expect(roundStitches[5].name, equals('dc'));
    });

    test('Single stitch replacement replaces exact stitch with count: 1', () {
      final initialChart = Chart(
        name: 'Test Chart',
        starterStitchName: 'mr',
        guidelines: Guidelines(type: GuidelinesType.visual),
        patternRounds: [
          PatternRound(
            number: 1,
            stitches: [
              PatternStitch(kind: 'stitch', name: 'dc', count: 1),
              PatternStitch(kind: 'stitch', name: 'tr', count: 1),
            ],
          ),
        ],
      );

      final result = replaceStitches(
        chart: initialChart,
        newStitchName: 'sc',
        bulk: false,
        targetVisualRoundIdx: 0,
        targetExpandedStitchIdx: 1, // 'tr'
        targetStitchName: 'tr',
      );

      expect(result.replacedCount, equals(1));
      final roundStitches = result.updatedChart.patternRounds[0].stitches;
      expect(roundStitches.length, equals(2));
      expect(roundStitches[0].name, equals('dc'));
      expect(roundStitches[1].name, equals('sc'));
    });

    test('Bulk replacement updates all matching stitches across all rounds', () {
      final initialChart = Chart(
        name: 'Test Chart',
        starterStitchName: 'mr',
        guidelines: Guidelines(type: GuidelinesType.visual),
        patternRounds: [
          PatternRound(
            number: 1,
            stitches: [
              PatternStitch(kind: 'stitch', name: 'dc', count: 6),
              PatternStitch(kind: 'stitch', name: 'sc', count: 2),
            ],
          ),
          PatternRound(
            number: 2,
            stitches: [
              PatternStitch(kind: 'stitch', name: 'dc', count: 12),
            ],
          ),
        ],
      );

      // Bulk replace all 'dc' with 'popcorn'
      final result = replaceStitches(
        chart: initialChart,
        newStitchName: 'popcorn',
        bulk: true,
        targetStitchName: 'dc',
      );

      expect(result.replacedCount, equals(18));
      final r1 = result.updatedChart.patternRounds[0].stitches;
      final r2 = result.updatedChart.patternRounds[1].stitches;

      // 6 popcorn + 2 sc
      expect(r1.length, equals(8));
      expect(r1.where((s) => s.name == 'popcorn').length, equals(6));
      expect(r1.where((s) => s.name == 'sc').length, equals(2));

      // 12 popcorn
      expect(r2.length, equals(12));
      expect(r2.every((s) => s.name == 'popcorn'), isTrue);
    });
  });

  group('Replace Stitch UI & Widget Tests', () {
    testWidgets('AppToolbar shows "Değiştir" button and switches editMode to EditMode.replace',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: AppToolbar(
                onNew: () {},
                onOpen: () {},
                onSave: () {},
                onTextView: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Find "Değiştir" button
      final degistirButtonFinder = find.text('Değiştir');
      expect(degistirButtonFinder, findsOneWidget);

      // Initially in EditMode.stitch
      expect(container.read(editModeProvider).mode, equals(EditMode.stitch));

      // Tap "Değiştir"
      await tester.tap(degistirButtonFinder);
      await tester.pump();

      // Now in EditMode.replace
      expect(container.read(editModeProvider).mode, equals(EditMode.replace));
    });

    testWidgets('In EditMode.replace, banner is displayed with guide instructions and checkbox',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      final chartNotifier = container.read(chartProvider.notifier);
      final editModeNotifier = container.read(editModeProvider.notifier);

      chartNotifier.setChart(
        Chart(
          name: 'Banner Test Chart',
          starterStitchName: 'mr',
        guidelines: Guidelines(type: GuidelinesType.visual),
          patternRounds: [
            PatternRound(
              number: 1,
              stitches: [
                PatternStitch(kind: 'stitch', name: 'dc', count: 4),
              ],
            ),
          ],
        ),
        recordUndo: false,
      );

      // Switch to replace mode
      editModeNotifier.setMode(EditMode.replace);

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

      // Verify instruction banner is shown
      expect(find.text('1. Grafikten değiştirmek istediğiniz ilmeğe dokunun'), findsOneWidget);
      expect(find.text('Toplu Değiştir'), findsOneWidget);

      // Toggle checkbox
      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsOneWidget);
      await tester.tap(checkboxFinder);
      await tester.pump();
      expect(container.read(editModeProvider).bulkReplace, isTrue);

      // Simulate stitch selection
      editModeNotifier.setReplaceTarget(
        roundIdx: 0,
        stitchIdx: 0,
        stitchName: 'dc',
        matchCount: 4,
      );
      await tester.pump();

      // Verify banner text changes to guide user to select from palette
      expect(find.text('Seçilen: dc • 2. Paletten yeni ilmeği seçin'), findsOneWidget);
      expect(find.text('Toplu Değiştir (4 adet)'), findsOneWidget);

      // Tap close button on banner to cancel
      final closeButtonFinder = find.byIcon(Icons.close);
      expect(closeButtonFinder, findsOneWidget);
      await tester.tap(closeButtonFinder);
      await tester.pump();

      // Returns to EditMode.stitch
      expect(container.read(editModeProvider).mode, equals(EditMode.stitch));
    });

    testWidgets('Tapping stitch in StitchPalette in EditMode.replace replaces the target stitch and supports undo',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final stitchNotifier = StitchStoreNotifier();
      stitchNotifier.setStitches([
        StitchRecord(
          name: 'dc',
          description: 'Double crochet',
          category: ['Basic'],
          wrongSide: '',
          svgContent: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/></svg>',
        ),
        StitchRecord(
          name: 'sc',
          description: 'Single crochet',
          category: ['Basic'],
          wrongSide: '',
          svgContent: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/></svg>',
        ),
      ]);

      final container = ProviderContainer(
        overrides: [
          stitchStoreProvider.overrideWith((ref) => stitchNotifier),
        ],
      );
      final chartNotifier = container.read(chartProvider.notifier);
      final editModeNotifier = container.read(editModeProvider.notifier);

      chartNotifier.setChart(
        Chart(
          name: 'Replace Test Chart',
          starterStitchName: 'mr',
          guidelines: Guidelines(type: GuidelinesType.visual),
          patternRounds: [
            PatternRound(
              number: 1,
              stitches: [
                PatternStitch(kind: 'stitch', name: 'dc', count: 1),
                PatternStitch(kind: 'stitch', name: 'tr', count: 1),
              ],
            ),
          ],
        ),
        recordUndo: true,
      );

      // In replace mode
      editModeNotifier.setMode(EditMode.replace);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  SizedBox(width: 240, child: StitchPalette()),
                  Expanded(child: VisualChartView()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // If user taps palette before selecting target:
      final scTileFinder = find.text('sc');
      expect(scTileFinder, findsWidgets);
      await tester.tap(scTileFinder.first);
      await tester.pump();

      // Warning snackbar shown
      expect(find.text('Lütfen önce grafikten değiştirmek istediğiniz ilmeğe dokunun.'), findsOneWidget);

      // Now set target (selecting dc at index 0)
      editModeNotifier.setReplaceTarget(
        roundIdx: 0,
        stitchIdx: 0,
        stitchName: 'dc',
        matchCount: 1,
      );
      await tester.pump();

      // Tap 'sc' in palette to replace
      await tester.tap(scTileFinder.first);
      await tester.pump();

      // Target was replaced!
      final updatedRounds = container.read(chartProvider).chart.patternRounds;
      expect(updatedRounds[0].stitches[0].name, equals('sc'));
      expect(find.text('İlmek "sc" ile değiştirildi.'), findsOneWidget);

      // Undo reverts it back to 'dc'
      container.read(chartProvider.notifier).undo();
      await tester.pump();
      final revertedRounds = container.read(chartProvider).chart.patternRounds;
      expect(revertedRounds[0].stitches[0].name, equals('dc'));
    });
  });
}
