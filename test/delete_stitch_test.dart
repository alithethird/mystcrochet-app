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
import 'package:crochet_charts/widgets/toolbar.dart';
import 'package:crochet_charts/widgets/visual_chart_view.dart';

void main() {
  group('Delete Stitch Feature Tests', () {
    testWidgets('AppToolbar shows "Sil" button and switches editMode to EditMode.delete',
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

      // Find "Sil" button
      final silButtonFinder = find.text('Sil');
      expect(silButtonFinder, findsOneWidget);

      // Initially in EditMode.stitch
      expect(container.read(editModeProvider).mode, equals(EditMode.stitch));

      // Tap "Sil"
      await tester.tap(silButtonFinder);
      await tester.pump();

      // Now in EditMode.delete
      expect(container.read(editModeProvider).mode, equals(EditMode.delete));
    });

    testWidgets('Tapping a stitch in EditMode.delete removes the stitch and supports undo',
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
      ]);

      final initialChart = Chart(
        name: 'Test Chart',
        style: GuidelinesType.visual,
        guidelines: Guidelines(type: GuidelinesType.visual, visualRounds: 2),
        patternRounds: [
          PatternRound(
            number: 1,
            stitches: [
              PatternStitch(kind: 'stitch', name: 'dc', count: 1, pinnedAngle: 0.0),
              PatternStitch(kind: 'stitch', name: 'dc', count: 1, pinnedAngle: 1.57),
              PatternStitch(kind: 'stitch', name: 'dc', count: 1, pinnedAngle: 3.14),
            ],
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          stitchStoreProvider.overrideWith((ref) => stitchNotifier),
        ],
      );
      container.read(chartProvider.notifier).loadChart(initialChart);
      container.read(editModeProvider.notifier).setMode(EditMode.delete);

      final chartKey = GlobalKey<VisualChartViewState>();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: VisualChartView(key: chartKey),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final currentChart = container.read(chartProvider).chart;
      expect(currentChart.patternRounds.first.stitches.length, equals(3));

      // Find the stitch SVG pictures
      final svgFinders = find.byType(SvgPicture);
      expect(svgFinders, findsWidgets);

      // Tap on the center of the first rendered stitch
      final firstStitchCenter = tester.getCenter(svgFinders.first);
      await tester.tapAt(firstStitchCenter);
      await tester.pumpAndSettle();

      // Check that a stitch was deleted
      final updatedChart = container.read(chartProvider).chart;
      expect(updatedChart.patternRounds.first.stitches.length, equals(2));

      // Test Undo
      expect(container.read(chartProvider).canUndo, isTrue);
      container.read(chartProvider.notifier).undo();
      await tester.pumpAndSettle();

      final restoredChart = container.read(chartProvider).chart;
      expect(restoredChart.patternRounds.first.stitches.length, equals(3));
    });

    testWidgets('deleteSelectedStitch deletes the currently selected stitch',
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
      ]);

      final initialChart = Chart(
        name: 'Test Chart',
        style: GuidelinesType.visual,
        guidelines: Guidelines(type: GuidelinesType.visual, visualRounds: 1),
        patternRounds: [
          PatternRound(
            number: 1,
            stitches: [
              PatternStitch(kind: 'stitch', name: 'dc', count: 1, pinnedAngle: 0.0),
              PatternStitch(kind: 'stitch', name: 'dc', count: 1, pinnedAngle: 1.57),
            ],
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          stitchStoreProvider.overrideWith((ref) => stitchNotifier),
        ],
      );
      container.read(chartProvider.notifier).loadChart(initialChart);
      container.read(editModeProvider.notifier).setMode(EditMode.move);

      final chartKey = GlobalKey<VisualChartViewState>();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: VisualChartView(key: chartKey),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the first stitch in Move mode to select it
      final svgFinders = find.byType(SvgPicture);
      final stitchCenter = tester.getCenter(svgFinders.first);

      // Pan slightly to select the stitch
      final gesture = await tester.startGesture(stitchCenter);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Invoke deleteSelectedStitch
      chartKey.currentState?.deleteSelectedStitch();
      await tester.pumpAndSettle();

      final chartAfterDelete = container.read(chartProvider).chart;
      expect(chartAfterDelete.patternRounds.first.stitches.length, equals(1));
    });
  });
}
