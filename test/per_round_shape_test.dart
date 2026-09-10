import 'package:crochet_charts/models/chart.dart';
import 'package:crochet_charts/models/pattern.dart';
import 'package:crochet_charts/providers/chart_provider.dart';
import 'package:crochet_charts/providers/stitch_provider.dart';
import 'package:crochet_charts/widgets/panels.dart';
import 'package:crochet_charts/widgets/visual_chart_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Per-Round Shape Tests (Task #32)', () {
    test('PatternRound serializes and deserializes sides and cornerRatio', () {
      final round = PatternRound(
        number: 2,
        sides: 4,
        cornerRatio: 0.2,
        stitches: [
          PatternStitch(kind: 'stitch', name: 'dc', count: 16),
        ],
      );

      final json = round.toJson();
      expect(json['sides'], equals(4));
      expect(json['cornerRatio'], equals(0.2));

      final roundFromJson = PatternRound.fromJson(json);
      expect(roundFromJson.sides, equals(4));
      expect(roundFromJson.cornerRatio, equals(0.2));

      final cleared = roundFromJson.copyWith(clearSides: true, clearCornerRatio: true);
      expect(cleared.sides, isNull);
      expect(cleared.cornerRatio, isNull);
    });

    test('layoutChart assigns per-round sides and coordinates properly', () {
      final notifier = StitchStoreNotifier();
      final rounds = [
        PatternRound(
          number: 1,
          sides: 0, // circle
          stitches: [
            PatternStitch(kind: 'stitch', name: 'sc', count: 6),
          ],
        ),
        PatternRound(
          number: 2,
          sides: 4, // square
          stitches: [
            PatternStitch(kind: 'stitch', name: 'dc', count: 12),
          ],
        ),
      ];

      final posRounds = layoutChart(
        rounds,
        20.0,
        12.0,
        12.0,
        1.0,
        notifier,
        sides: 0,
        cornerRatio: 0.15,
      );

      expect(posRounds.length, equals(2));
      expect(posRounds[0].length, equals(6));
      expect(posRounds[1].length, equals(12));

      // Check that round 0 stitches have sides=0 and round 1 stitches have sides=4
      for (final st in posRounds[0]) {
        expect(st.sides, equals(0));
      }
      for (final st in posRounds[1]) {
        expect(st.sides, equals(4));
        // In square layout, perimeter arclength s is tracked
        expect(st.perimeterS, greaterThanOrEqualTo(0));
      }
    });

    testWidgets('Changing round shape in PropertiesPanel updates chart round sides', (tester) async {
      final chartNotifier = ChartNotifier();
      chartNotifier.setChart(
        Chart.defaultChart().copyWith(
          name: 'Test Chart',
          patternRounds: [
            PatternRound(number: 1, stitches: [PatternStitch(kind: 'stitch', name: 'sc', count: 6)]),
            PatternRound(number: 2, stitches: [PatternStitch(kind: 'stitch', name: 'dc', count: 12)]),
          ],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chartProvider.overrideWith((ref) => chartNotifier),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PropertiesPanel(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the round 2 shape dropdown
      final dropdownFinder = find.byKey(const ValueKey('prop_round_shape_2'));
      expect(dropdownFinder, findsOneWidget);

      // Open the dropdown
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Tap "Kare" (square)
      await tester.tap(find.text('Kare').last);
      await tester.pumpAndSettle();

      // Chart round 2 should now have sides=4
      expect(chartNotifier.chart.patternRounds[1].sides, equals(4));
      // Round 1 should still have default (null)
      expect(chartNotifier.chart.patternRounds[0].sides, isNull);
    });
  });
}
