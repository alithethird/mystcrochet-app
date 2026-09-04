import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crochet_charts/models/chart.dart';
import 'package:crochet_charts/models/pattern.dart';
import 'package:crochet_charts/providers/chart_provider.dart';
import 'package:crochet_charts/providers/edit_mode_provider.dart';
import 'package:crochet_charts/providers/stitch_provider.dart';
import 'package:crochet_charts/widgets/visual_chart_view.dart';

void main() {
  testWidgets('Dragging a stitch records only a single undo checkpoint',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final round = PatternRound(
      number: 1,
      stitches: [
        for (int i = 0; i < 6; i++)
          PatternStitch(kind: 'stitch', name: 'sc', count: 1),
      ],
    );
    final initialChart = Chart.defaultChart().copyWith(
      patternRounds: [round],
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
    await tester.pump();

    final stitchFinder = find.text('sc').first;
    expect(stitchFinder, findsOneWidget);
    final stitchCenter = tester.getCenter(stitchFinder);

    final gesture = await tester.startGesture(stitchCenter);
    await tester.pump();

    for (int i = 1; i <= 10; i++) {
      await gesture.moveBy(const Offset(10, 10));
      await tester.pump();
    }

    await gesture.up();
    await tester.pump();

    final draggedChart = container.read(chartProvider).chart;
    final draggedStitch0 = draggedChart.patternRounds[0].stitches[0];
    expect(draggedStitch0.pinnedAngle, isNotNull);

    // One single undo must restore to initial null pinnedAngle
    chartNotifier.undo();
    await tester.pump();

    final revertedChart = container.read(chartProvider).chart;
    final revertedStitch0 = revertedChart.patternRounds[0].stitches[0];
    expect(revertedStitch0.pinnedAngle, isNull,
        reason: 'A single undo must directly restore to pre-drag state');

    // One single redo must restore dragged pinnedAngle
    chartNotifier.redo();
    await tester.pump();

    final redoneChart = container.read(chartProvider).chart;
    final redoneStitch0 = redoneChart.patternRounds[0].stitches[0];
    expect(redoneStitch0.pinnedAngle, equals(draggedStitch0.pinnedAngle),
        reason: 'A single redo must restore dropped position');
  });
}
