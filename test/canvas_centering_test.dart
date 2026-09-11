import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crochet_charts/models/stitch_record.dart';
import 'package:crochet_charts/providers/chart_provider.dart';
import 'package:crochet_charts/providers/edit_mode_provider.dart';
import 'package:crochet_charts/providers/stitch_provider.dart';
import 'package:crochet_charts/widgets/visual_chart_view.dart';

void main() {
  group('Canvas & Start Hint Centering Tests', () {
    testWidgets('Empty chart start text is centered on desktop (1280x800)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final key = GlobalKey<VisualChartViewState>();
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1280,
                height: 800,
                child: VisualChartView(key: key),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify hint text is rendered
      final hintFinder = find.text('Grafiğinize başlamak için paletten bir başlangıç ilmeği seçin');
      expect(hintFinder, findsOneWidget);

      // Verify hint text is centered in the viewport (near 640, 400)
      final hintCenter = tester.getCenter(hintFinder);
      expect((hintCenter.dx - 640.0).abs(), lessThan(5.0));
      expect((hintCenter.dy - 400.0).abs(), lessThan(5.0));

      // Verify transformation matrix centers the chart origin in the viewport
      final matrix = key.currentState!.transformationController.value;
      // svgSize is 220.0 ((ringRadius 20 + 30 + margin 60) * 2), half is 110.0
      // tx should be 1280/2 - 110 = 530, ty should be 800/2 - 110 = 290
      expect(matrix.getTranslation().x, closeTo(530.0, 1.0));
      expect(matrix.getTranslation().y, closeTo(290.0, 1.0));
    });

    testWidgets('Empty chart start text is centered on mobile (400x800)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final key = GlobalKey<VisualChartViewState>();
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 800,
                child: VisualChartView(key: key),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final hintFinder = find.text('Grafiğinize başlamak için paletten bir başlangıç ilmeği seçin');
      expect(hintFinder, findsOneWidget);

      final hintCenter = tester.getCenter(hintFinder);
      expect((hintCenter.dx - 200.0).abs(), lessThan(5.0));
      expect((hintCenter.dy - 400.0).abs(), lessThan(5.0));

      final matrix = key.currentState!.transformationController.value;
      // tx: 400/2 - 110 = 90, ty: 800/2 - 110 = 290
      expect(matrix.getTranslation().x, closeTo(90.0, 1.0));
      expect(matrix.getTranslation().y, closeTo(290.0, 1.0));
    });

    testWidgets('Tapping center of screen places starter stitch when starter is active', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final key = GlobalKey<VisualChartViewState>();
      final stitchNotifier = StitchStoreNotifier();
      stitchNotifier.setStitches([
        StitchRecord(
          name: 'mr',
          description: 'Magic Ring',
          category: ['starters'],
          wrongSide: '',
          svgContent: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/></svg>',
        ),
      ]);
      stitchNotifier.setActiveStitchName('mr');

      final container = ProviderContainer(
        overrides: [
          stitchStoreProvider.overrideWith((ref) => stitchNotifier),
        ],
      );

      container.read(editModeProvider.notifier).setMode(EditMode.stitch);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: VisualChartView(key: key),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap directly on the hint card
      final hintFinder = find.text('Başlangıç ilmeğini yerleştirmek için merkeze dokunun');
      expect(hintFinder, findsOneWidget);
      await tester.tap(hintFinder);
      await tester.pumpAndSettle();

      // Chart should now have starter stitch set
      final chart = container.read(chartProvider).chart;
      expect(chart.starterStitchName, equals('mr'));
    });

    testWidgets('Round bar is horizontally centered on desktop (1280x800)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      // Set starter stitch and a round so round bar is visible
      final currentChart = container.read(chartProvider).chart;
      container.read(chartProvider.notifier).setChart(
        currentChart.copyWith(
          starterStitchName: 'mr',
          patternRounds: const [],
        ),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1280,
                height: 800,
                child: VisualChartView(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the round bar text
      final roundTextFinder = find.textContaining('Tur 1');
      expect(roundTextFinder, findsOneWidget);

      // Find the container wrapping the round bar inside Positioned top: 6
      final centerFinder = find.ancestor(
        of: roundTextFinder,
        matching: find.byType(Center),
      );
      expect(centerFinder, findsWidgets);

      // The round bar container should be horizontally centered at 640.0
      final roundBarContainer = find.ancestor(
        of: roundTextFinder,
        matching: find.byType(Container),
      ).first;
      final roundBarCenter = tester.getCenter(roundBarContainer);
      expect((roundBarCenter.dx - 640.0).abs(), lessThan(2.0));
    });

    testWidgets('Round bar is horizontally centered on mobile (400x800)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      final currentChart = container.read(chartProvider).chart;
      container.read(chartProvider.notifier).setChart(
        currentChart.copyWith(
          starterStitchName: 'mr',
          patternRounds: const [],
        ),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 800,
                child: VisualChartView(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final roundTextFinder = find.textContaining('Tur 1');
      expect(roundTextFinder, findsOneWidget);

      final roundBarContainer = find.ancestor(
        of: roundTextFinder,
        matching: find.byType(Container),
      ).first;
      final roundBarCenter = tester.getCenter(roundBarContainer);
      expect((roundBarCenter.dx - 200.0).abs(), lessThan(2.0));
    });
  });
}
