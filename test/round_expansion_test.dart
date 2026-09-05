import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crochet_charts/models/chart.dart';
import 'package:crochet_charts/models/pattern.dart';
import 'package:crochet_charts/providers/chart_provider.dart';
import 'package:crochet_charts/providers/edit_mode_provider.dart';
import 'package:crochet_charts/widgets/panels.dart';
import 'package:crochet_charts/widgets/visual_chart_view.dart';

void main() {
  group('Manual Round Expansion Tests', () {
    testWidgets('Expanding round in PropertiesPanel increases radiusOffset and pushes layout radius',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final round1 = PatternRound(
        number: 1,
        stitches: [
          PatternStitch(kind: 'stitch', name: 'sc'),
          PatternStitch(kind: 'stitch', name: 'sc'),
        ],
      );
      final round2 = PatternRound(
        number: 2,
        stitches: [
          PatternStitch(kind: 'stitch', name: 'dc', connectsTo: 0),
          PatternStitch(kind: 'stitch', name: 'dc', connectsTo: 1),
        ],
      );

      final initialChart = Chart.defaultChart().copyWith(
        name: 'Expansion Test',
        starterStitchName: 'magicRing',
        patternRounds: [round1, round2],
      );

      final container = ProviderContainer();
      final chartNotifier = container.read(chartProvider.notifier);
      chartNotifier.setChart(initialChart);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Expanded(child: VisualChartView()),
                  SizedBox(height: 350, child: SingleChildScrollView(child: PropertiesPanel())),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial offsets are 0
      expect(chartNotifier.chart.patternRounds[0].radiusOffset, isNull);
      expect(chartNotifier.chart.patternRounds[1].radiusOffset, isNull);

      // Find expand button for Round 1 in PropertiesPanel
      final expandR1Finder = find.byKey(const ValueKey('prop_expand_round_1'));
      expect(expandR1Finder, findsOneWidget);

      // Tap expand on Round 1
      await tester.tap(expandR1Finder);
      await tester.pumpAndSettle();

      expect(chartNotifier.chart.patternRounds[0].radiusOffset, equals(5.0));

      // Tap expand again on Round 1
      await tester.tap(expandR1Finder);
      await tester.pumpAndSettle();

      expect(chartNotifier.chart.patternRounds[0].radiusOffset, equals(10.0));

      // Verify Round 1 label shows +10 px
      expect(find.text('+10 px'), findsWidgets);

      // Verify reset button appears for Round 1
      final resetR1Finder = find.byKey(const ValueKey('prop_reset_round_1'));
      expect(resetR1Finder, findsOneWidget);

      // Expand Round 2
      final expandR2Finder = find.byKey(const ValueKey('prop_expand_round_2'));
      await tester.tap(expandR2Finder);
      await tester.pumpAndSettle();

      expect(chartNotifier.chart.patternRounds[1].radiusOffset, equals(5.0));

      // Test undoing round expansion
      chartNotifier.undo();
      await tester.pumpAndSettle();
      expect(chartNotifier.chart.patternRounds[1].radiusOffset, isNull);

      // Reset Round 1
      await tester.tap(resetR1Finder);
      await tester.pumpAndSettle();
      expect(chartNotifier.chart.patternRounds[0].radiusOffset, isNull);
    });

    testWidgets('Canvas overlay buttons expand and contract the active round',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final round1 = PatternRound(
        number: 1,
        stitches: [
          PatternStitch(kind: 'stitch', name: 'sc'),
        ],
      );

      final initialChart = Chart.defaultChart().copyWith(
        name: 'Canvas Expansion Test',
        starterStitchName: 'magicRing',
        patternRounds: [round1],
      );

      final container = ProviderContainer();
      final chartNotifier = container.read(chartProvider.notifier);
      chartNotifier.setChart(initialChart);

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
      await tester.pumpAndSettle();

      // Find canvas expand button
      final canvasExpandFinder = find.byKey(const ValueKey('canvas_expand_round_button'));
      expect(canvasExpandFinder, findsOneWidget);

      await tester.tap(canvasExpandFinder);
      await tester.pumpAndSettle();

      expect(chartNotifier.chart.patternRounds[0].radiusOffset, equals(5.0));
      expect(find.text('+5px'), findsOneWidget);

      // Contract via canvas contract button
      final canvasContractFinder = find.byKey(const ValueKey('canvas_contract_round_button'));
      expect(canvasContractFinder, findsOneWidget);

      await tester.tap(canvasContractFinder);
      await tester.pumpAndSettle();

      expect(chartNotifier.chart.patternRounds[0].radiusOffset, isNull);
      expect(find.text('0px'), findsOneWidget);
    });

    testWidgets('Moving a stitch after expanding a round modifies the correct round and does not drop to round 0',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final round1 = PatternRound(
        number: 1,
        stitches: [
          PatternStitch(kind: 'stitch', name: 'sc', count: 1),
          PatternStitch(kind: 'stitch', name: 'sc', count: 1),
        ],
      );
      final round2 = PatternRound(
        number: 2,
        stitches: [
          PatternStitch(kind: 'stitch', name: 'dc', count: 1, connectsTo: 0),
          PatternStitch(kind: 'stitch', name: 'dc', count: 1, connectsTo: 1),
        ],
      );

      final initialChart = Chart.defaultChart().copyWith(
        name: 'Multi Round Expansion Drag Test',
        starterStitchName: 'magicRing',
        patternRounds: [round1, round2],
      );

      final container = ProviderContainer();
      final chartNotifier = container.read(chartProvider.notifier);
      chartNotifier.setChart(initialChart);
      container.read(editModeProvider.notifier).setMode(EditMode.move);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: VisualChartView(ringRadius: 50.0),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expand round 2
      final canvasExpandFinder = find.byKey(const ValueKey('canvas_expand_round_button'));
      expect(canvasExpandFinder, findsOneWidget);
      await tester.tap(canvasExpandFinder);
      await tester.pumpAndSettle();

      expect(chartNotifier.chart.patternRounds[1].radiusOffset, equals(5.0));
      expect(chartNotifier.chart.patternRounds[0].radiusOffset, isNull);

      // Locate a stitch in round 2 ('dc')
      final dcFinder = find.text('dc').first;
      expect(dcFinder, findsOneWidget);
      final dcCenter = tester.getCenter(dcFinder);

      // Drag the dc stitch
      final gesture = await tester.startGesture(dcCenter);
      await tester.pump();
      await gesture.moveBy(const Offset(25, 25));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final updatedChart = container.read(chartProvider).chart;

      // Verify Round 1 stitches remain completely untouched (no angleOffset / pinnedAngle)
      expect(updatedChart.patternRounds[0].stitches[0].angleOffset, isNull);
      expect(updatedChart.patternRounds[0].stitches[0].pinnedAngle, isNull);
      expect(updatedChart.patternRounds[0].stitches[1].angleOffset, isNull);
      expect(updatedChart.patternRounds[0].stitches[1].pinnedAngle, isNull);

      // Verify Round 2 stitch was the one updated with offset/pin
      final r2Stitch0 = updatedChart.patternRounds[1].stitches[0];
      final r2Stitch1 = updatedChart.patternRounds[1].stitches[1];
      final r2Modified = (r2Stitch0.angleOffset != null || r2Stitch0.pinnedAngle != null) ||
          (r2Stitch1.angleOffset != null || r2Stitch1.pinnedAngle != null);
      expect(r2Modified, isTrue, reason: 'Round 2 stitch should have received the movement offset');

      // Verify Round 2 retains its expansion radiusOffset
      expect(updatedChart.patternRounds[1].radiusOffset, equals(5.0));
    });

    testWidgets('Task 27: Expanding Round 1 does not shift Round 2 stitches radius or position',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final round1 = PatternRound(
        number: 1,
        stitches: [
          PatternStitch(kind: 'stitch', name: 'sc'),
        ],
      );
      final round2 = PatternRound(
        number: 2,
        stitches: [
          PatternStitch(kind: 'stitch', name: 'dc', connectsTo: 0),
        ],
      );

      final initialChart = Chart.defaultChart().copyWith(
        name: 'Radius Isolation Test',
        starterStitchName: 'magicRing',
        patternRounds: [round1, round2],
      );

      final container = ProviderContainer();
      final chartNotifier = container.read(chartProvider.notifier);
      chartNotifier.setChart(initialChart);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: VisualChartView(ringRadius: 50.0),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find initial position of dc stitch (in Round 2)
      final dcFinder = find.text('dc');
      expect(dcFinder, findsOneWidget);
      final initialDcPos = tester.getCenter(dcFinder);

      // Now expand Round 1 via chart notifier
      final rounds = List<PatternRound>.from(chartNotifier.chart.patternRounds);
      rounds[0] = rounds[0].copyWith(radiusOffset: 30.0);
      chartNotifier.setChart(chartNotifier.chart.copyWith(patternRounds: rounds));
      await tester.pumpAndSettle();

      // Verify Round 1 offset is 30.0 and Round 2 offset is null
      expect(chartNotifier.chart.patternRounds[0].radiusOffset, equals(30.0));
      expect(chartNotifier.chart.patternRounds[1].radiusOffset, isNull);

      // Verify Round 2 dc stitch position has NOT changed
      final newDcPos = tester.getCenter(dcFinder);
      expect(newDcPos.dx, closeTo(initialDcPos.dx, 0.01));
      expect(newDcPos.dy, closeTo(initialDcPos.dy, 0.01));
    });

    testWidgets('Task 28: Son Turu Sil button deletes the last round and supports undo',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final round1 = PatternRound(
        number: 1,
        stitches: [
          PatternStitch(kind: 'stitch', name: 'sc'),
        ],
      );
      final round2 = PatternRound(
        number: 2,
        stitches: [
          PatternStitch(kind: 'stitch', name: 'dc', connectsTo: 0),
        ],
      );

      final initialChart = Chart.defaultChart().copyWith(
        name: 'Delete Last Round Test',
        starterStitchName: 'magicRing',
        patternRounds: [round1, round2],
      );

      final container = ProviderContainer();
      final chartNotifier = container.read(chartProvider.notifier);
      chartNotifier.setChart(initialChart);

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
      await tester.pumpAndSettle();

      expect(chartNotifier.chart.patternRounds.length, equals(2));

      // Find 'Son Turu Sil' button
      final deleteBtnFinder = find.byKey(const ValueKey('canvas_delete_last_round_button'));
      expect(deleteBtnFinder, findsOneWidget);

      // Tap 'Son Turu Sil'
      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      // Round 2 should be removed, leaving only 1 round
      expect(chartNotifier.chart.patternRounds.length, equals(1));
      expect(chartNotifier.chart.patternRounds[0].number, equals(1));

      // Undo should restore Round 2
      chartNotifier.undo();
      await tester.pumpAndSettle();
      expect(chartNotifier.chart.patternRounds.length, equals(2));
    });

    testWidgets('Task 29: Dragging a stitch in move mode does not pan the canvas',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final round1 = PatternRound(
        number: 1,
        stitches: [
          PatternStitch(kind: 'stitch', name: 'sc'),
        ],
      );

      final initialChart = Chart.defaultChart().copyWith(
        name: 'No Pan on Drag Test',
        starterStitchName: 'magicRing',
        patternRounds: [round1],
      );

      final container = ProviderContainer();
      final chartNotifier = container.read(chartProvider.notifier);
      chartNotifier.setChart(initialChart);
      container.read(editModeProvider.notifier).setMode(EditMode.move);

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
      await tester.pumpAndSettle();

      // Find InteractiveViewer
      final ivFinder = find.byType(InteractiveViewer);
      expect(ivFinder, findsOneWidget);
      final ivWidgetBefore = tester.widget<InteractiveViewer>(ivFinder);
      final matrixBefore = ivWidgetBefore.transformationController!.value.clone();

      // Locate stitch
      final scFinder = find.text('sc');
      expect(scFinder, findsOneWidget);
      final scCenter = tester.getCenter(scFinder);

      // Drag stitch
      final gesture = await tester.startGesture(scCenter);
      await tester.pump();
      await gesture.moveBy(const Offset(30, 30));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // InteractiveViewer transformation matrix should be identical (no canvas panning)
      final ivWidgetAfter = tester.widget<InteractiveViewer>(ivFinder);
      final matrixAfter = ivWidgetAfter.transformationController!.value;
      expect(matrixAfter, equals(matrixBefore));
    });
  });
}
