import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crochet_charts/models/chart.dart';
import 'package:crochet_charts/models/pattern.dart';
import 'package:crochet_charts/providers/chart_provider.dart';
import 'package:crochet_charts/providers/stitch_provider.dart';
import 'package:crochet_charts/widgets/panels.dart';
import 'package:crochet_charts/widgets/visual_chart_view.dart';

void main() {
  group('Task #50 & #51 Bug Fix Tests', () {
    test('Task #50: assignConnections preserves round sides and cornerRatio', () {
      final round1 = PatternRound(
        number: 1,
        stitches: [
          PatternStitch(kind: 'stitch', name: 'sc'),
        ],
        sides: 6,
        cornerRatio: 0.2,
      );

      final result = assignConnections([round1]);
      expect(result.length, equals(1));
      expect(result[0].sides, equals(6));
      expect(result[0].cornerRatio, equals(0.2));
    });

    testWidgets('Task #50: Setting round shape to hexagon and adding stitch retains hexagon shape',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final initialChart = Chart.defaultChart().copyWith(
        name: 'Hexagon Round Test',
        starterStitchName: 'magicRing',
        patternRounds: [
          PatternRound(
            number: 1,
            stitches: [
              PatternStitch(kind: 'stitch', name: 'sc'),
            ],
          ),
          PatternRound(
            number: 2,
            stitches: [],
            sides: 6, // User selected hexagon for round 2
          ),
        ],
      );

      final container = ProviderContainer();
      final chartNotifier = container.read(chartProvider.notifier);
      chartNotifier.setChart(initialChart);
      container.read(stitchStoreProvider.notifier).setActiveStitchName('sc');

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

      // Tap canvas to place a stitch into Round 2
      final center = tester.getCenter(find.byType(VisualChartView));
      await tester.tapAt(center + const Offset(85, 0));
      await tester.pumpAndSettle();

      // Round 2 must still have sides: 6 (not reverted to null/circle)
      final updatedRounds = chartNotifier.chart.patternRounds;
      expect(updatedRounds.length, equals(2));
      expect(updatedRounds[1].stitches.isNotEmpty, isTrue);
      expect(updatedRounds[1].sides, equals(6));
    });

    testWidgets('Task #51: Increasing round radius and clicking Yeni Tur inherits radius offset',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final initialChart = Chart.defaultChart().copyWith(
        name: 'Radius Offset Inherit Test',
        starterStitchName: 'magicRing',
        patternRounds: [
          PatternRound(
            number: 1,
            stitches: [
              PatternStitch(kind: 'stitch', name: 'sc'),
            ],
            radiusOffset: 45.0, // Enlarged round
          ),
        ],
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

      // Tap 'Yeni Tur' button on canvas
      final newRoundBtn = find.text('Yeni Tur');
      expect(newRoundBtn, findsOneWidget);
      await tester.tap(newRoundBtn);
      await tester.pumpAndSettle();

      // Verify Round 2 was created with radiusOffset inherited from Round 1 (45.0)
      final rounds = chartNotifier.chart.patternRounds;
      expect(rounds.length, equals(2));
      expect(rounds[0].radiusOffset, equals(45.0));
      expect(rounds[1].radiusOffset, equals(45.0));
    });

    testWidgets('Task #51: Adding round from PropertiesPanel also inherits radius offset',
        (WidgetTester tester) async {
      final initialChart = Chart.defaultChart().copyWith(
        name: 'PropertiesPanel Radius Offset Inherit Test',
        starterStitchName: 'magicRing',
        patternRounds: [
          PatternRound(
            number: 1,
            stitches: [
              PatternStitch(kind: 'stitch', name: 'sc'),
            ],
            radiusOffset: 30.0,
          ),
        ],
      );

      final container = ProviderContainer();
      final chartNotifier = container.read(chartProvider.notifier);
      chartNotifier.setChart(initialChart);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: PropertiesPanel(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap '+' button in PropertiesPanel to increment round count
      final addRoundBtn = find.byIcon(Icons.add);
      expect(addRoundBtn, findsWidgets);
      await tester.tap(addRoundBtn.first);
      await tester.pumpAndSettle();

      final rounds = chartNotifier.chart.patternRounds;
      expect(rounds.length, equals(2));
      expect(rounds[1].radiusOffset, equals(30.0));
    });

    testWidgets('Selecting shape in canvas bar and clicking Yeni Tur inherits that shape',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final initialChart = Chart.defaultChart().copyWith(
        name: 'Bar Shape Inherit Test',
        starterStitchName: 'magicRing',
        patternRounds: [
          PatternRound(
            number: 1,
            stitches: [
              PatternStitch(kind: 'stitch', name: 'sc'),
            ],
            sides: 6, // Hexagon
          ),
        ],
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

      // Tap 'Yeni Tur' button on canvas
      final newRoundBtn = find.text('Yeni Tur');
      expect(newRoundBtn, findsOneWidget);
      await tester.tap(newRoundBtn);
      await tester.pumpAndSettle();

      // Verify Round 2 was created with sides inherited from Round 1 (6 = hexagon)
      final rounds = chartNotifier.chart.patternRounds;
      expect(rounds.length, equals(2));
      expect(rounds[1].sides, equals(6));
    });

    testWidgets('ShapePanel displays same shape options as canvas bar',
        (WidgetTester tester) async {
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ShapePanel(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Shape dropdown
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();

      expect(find.text('Daire'), findsWidgets);
      expect(find.text('Üçgen'), findsWidgets);
      expect(find.text('Kare'), findsWidgets);
      expect(find.text('Beşgen'), findsWidgets);
      expect(find.text('Altıgen'), findsWidgets);
      expect(find.text('Sekizgen'), findsWidgets);
    });
  });
}
