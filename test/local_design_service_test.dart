import 'package:crochet_charts/models/chart.dart';
import 'package:crochet_charts/models/pattern.dart';
import 'package:crochet_charts/services/local_design_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocalDesignService Tests (Task #34)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('getSavedDesigns returns empty list initially', () async {
      final designs = await LocalDesignService.getSavedDesigns();
      expect(designs, isEmpty);
    });

    test('saveDesign saves chart and retrieves it with correct metadata', () async {
      final chart = Chart.defaultChart().copyWith(
        name: 'Mandala Design',
        patternRounds: [
          PatternRound(
            number: 1,
            stitches: [
              PatternStitch(kind: 'stitch', name: 'sc', count: 6),
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

      final saved = await LocalDesignService.saveDesign(chart);
      expect(saved.id, isNotEmpty);
      expect(saved.name, equals('Mandala Design'));
      expect(saved.roundCount, equals(2));
      expect(saved.stitchCount, equals(18));

      final all = await LocalDesignService.getSavedDesigns();
      expect(all.length, equals(1));
      expect(all.first.id, equals(saved.id));
      expect(all.first.name, equals('Mandala Design'));

      final retrievedChart = all.first.toChart();
      expect(retrievedChart.name, equals('Mandala Design'));
      expect(retrievedChart.patternRounds.length, equals(2));
    });

    test('saveDesign updates existing design when ID is specified', () async {
      final chart1 = Chart.defaultChart().copyWith(name: 'Draft V1');
      final saved1 = await LocalDesignService.saveDesign(chart1);

      final chart2 = chart1.copyWith(name: 'Draft V2');
      final saved2 = await LocalDesignService.saveDesign(chart2, id: saved1.id);

      expect(saved2.id, equals(saved1.id));
      expect(saved2.name, equals('Draft V2'));

      final all = await LocalDesignService.getSavedDesigns();
      expect(all.length, equals(1));
      expect(all.first.name, equals('Draft V2'));
    });

    test('deleteDesign removes design by ID', () async {
      final chartA = Chart.defaultChart().copyWith(name: 'Design A');
      final chartB = Chart.defaultChart().copyWith(name: 'Design B');

      final savedA = await LocalDesignService.saveDesign(chartA);
      final savedB = await LocalDesignService.saveDesign(chartB);

      var all = await LocalDesignService.getSavedDesigns();
      expect(all.length, equals(2));

      final deleted = await LocalDesignService.deleteDesign(savedA.id);
      expect(deleted, isTrue);

      all = await LocalDesignService.getSavedDesigns();
      expect(all.length, equals(1));
      expect(all.first.id, equals(savedB.id));

      final deletedAgain = await LocalDesignService.deleteDesign(savedA.id);
      expect(deletedAgain, isFalse);
    });

    test('saveActiveDraft, loadActiveDraft, and clearActiveDraft operate correctly', () async {
      expect(await LocalDesignService.loadActiveDraft(), isNull);

      final chart = Chart.defaultChart().copyWith(name: 'Active In-Progress');
      await LocalDesignService.saveActiveDraft(chart);

      final loaded = await LocalDesignService.loadActiveDraft();
      expect(loaded, isNotNull);
      expect(loaded!.name, equals('Active In-Progress'));

      await LocalDesignService.clearActiveDraft();
      expect(await LocalDesignService.loadActiveDraft(), isNull);
    });
  });
}
