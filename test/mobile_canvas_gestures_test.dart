import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crochet_charts/models/chart.dart';
import 'package:crochet_charts/models/guidelines.dart';
import 'package:crochet_charts/models/pattern.dart';
import 'package:crochet_charts/providers/chart_provider.dart';
import 'package:crochet_charts/providers/edit_mode_provider.dart';
import 'package:crochet_charts/widgets/visual_chart_view.dart';

void main() {
  group('Mobile Canvas Gestures Tests (Task #33)', () {
    testWidgets('Dragging outside rounds naturally pans the canvas without requiring pan mode',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final key = GlobalKey<VisualChartViewState>();
      final container = ProviderContainer();
      final chartNotifier = container.read(chartProvider.notifier);

      chartNotifier.setChart(
        Chart(
          name: 'Mobile Gestures Chart',
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
        ),
      );

      // Start in EditMode.stitch (NOT EditMode.pan)
      container.read(editModeProvider.notifier).setMode(EditMode.stitch);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 800,
                child: VisualChartView(key: key),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final initialMatrix = key.currentState?.transformationController.value.clone() ?? Matrix4.identity();

      // Touch way outside rounds (near bottom-left: (50, 700)) and drag by (100, 50)
      final gesture = await tester.startGesture(const Offset(50, 700), kind: PointerDeviceKind.touch);
      await tester.pump();

      await gesture.moveBy(const Offset(100, 50));
      await tester.pump();

      await gesture.up();
      await tester.pump();

      final updatedMatrix = key.currentState?.transformationController.value ?? Matrix4.identity();

      // Verify that translation occurred (canvas panned)
      final dx = updatedMatrix.getTranslation().x - initialMatrix.getTranslation().x;
      final dy = updatedMatrix.getTranslation().y - initialMatrix.getTranslation().y;
      expect(dx != 0 || dy != 0, isTrue);
    });

    testWidgets('Two pointers pinch gesture scales the canvas',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final key = GlobalKey<VisualChartViewState>();
      final container = ProviderContainer();
      final chartNotifier = container.read(chartProvider.notifier);

      chartNotifier.setChart(
        Chart(
          name: 'Pinch Zoom Chart',
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
        ),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 800,
                child: VisualChartView(key: key),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final initialScale = key.currentState?.transformationController.value.getMaxScaleOnAxis() ?? 1.0;

      // Two pointer pinch spread gesture
      final touch1 = await tester.startGesture(const Offset(350, 400), kind: PointerDeviceKind.touch);
      final touch2 = await tester.startGesture(const Offset(450, 400), kind: PointerDeviceKind.touch);
      await tester.pump();

      // Spread apart
      await touch1.moveBy(const Offset(-80, 0));
      await touch2.moveBy(const Offset(80, 0));
      await tester.pump();

      await touch1.up();
      await touch2.up();
      await tester.pump();

      final updatedScale = key.currentState?.transformationController.value.getMaxScaleOnAxis() ?? 1.0;
      expect(updatedScale > initialScale, isTrue);
    });
  });
}
