import 'package:crochet_charts/models/chart.dart';
import 'package:crochet_charts/models/pattern.dart';
import 'package:crochet_charts/models/stitch_record.dart';
import 'package:crochet_charts/providers/stitch_provider.dart';
import 'package:crochet_charts/services/chart_file_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Embedded Stitches Tests (Task #30)', () {
    test('prepareChartWithUsedStitches embeds stitch records from stitchStore', () {
      final store = StitchStoreNotifier();
      store.registerStitches([
        StitchRecord(
          name: 'my_custom_puff',
          category: ['Puff'],
          wrongSide: '',
          description: 'A special custom puff stitch',
          svgContent: '<svg><circle cx="5" cy="5" r="5"/></svg>',
        ),
        StitchRecord(
          name: 'dc',
          category: ['Basic'],
          wrongSide: '',
          description: 'Double crochet',
          svgContent: '<svg><path d="M0 0"/></svg>',
        ),
      ]);

      final chart = Chart.defaultChart().copyWith(
        patternRounds: [
          PatternRound(
            number: 1,
            stitches: [
              PatternStitch(kind: 'stitch', name: 'my_custom_puff', count: 6),
              PatternStitch(kind: 'stitch', name: 'dc', count: 12),
            ],
          ),
        ],
      );

      final prepared = ChartFileService.prepareChartWithUsedStitches(chart, store);
      expect(prepared.embeddedStitches, isNotNull);
      final names = prepared.embeddedStitches!.map((s) => s.name).toSet();
      expect(names, contains('my_custom_puff'));
      expect(names, contains('dc'));

      final customStitch = prepared.embeddedStitches!.firstWhere((s) => s.name == 'my_custom_puff');
      expect(customStitch.description, equals('A special custom puff stitch'));
      expect(customStitch.svgContent, contains('<circle'));
    });

    test('toJson and fromJson preserve embedded stitches under stitches key', () {
      final stitch = StitchRecord(
        name: 'star_stitch',
        category: ['Decorative'],
        wrongSide: '',
        description: 'Star stitch description',
        svgContent: '<svg><path d="M0 0 L10 10"/></svg>',
      );

      final chart = Chart.defaultChart().copyWith(
        name: 'Star Doily',
        embeddedStitches: [stitch],
        patternRounds: [],
      );

      final jsonMap = chart.toJson();
      expect(jsonMap['stitches'], isA<List>());
      final stitchesList = jsonMap['stitches'] as List;
      expect(stitchesList.length, equals(1));
      expect(stitchesList[0]['name'], equals('star_stitch'));
      expect(stitchesList[0]['svgContent'], contains('path'));

      // Deserialization
      final deserialized = Chart.fromJson(jsonMap);
      expect(deserialized.embeddedStitches, isNotNull);
      expect(deserialized.embeddedStitches!.length, equals(1));
      expect(deserialized.embeddedStitches![0].name, equals('star_stitch'));
      expect(deserialized.embeddedStitches![0].description, equals('Star stitch description'));
    });

    test('registerStitches populates StitchStoreNotifier on chart load', () {
      final store = StitchStoreNotifier();
      expect(store.getStitch('unknown_imported_stitch'), isNull);

      final List<StitchRecord> newStitches = [
        StitchRecord(
          name: 'unknown_imported_stitch',
          category: ['Custom'],
          wrongSide: '',
          description: 'Loaded from file',
          svgContent: '<svg></svg>',
        ),
      ];

      store.registerStitches(newStitches);
      final retrieved = store.getStitch('unknown_imported_stitch');
      expect(retrieved, isNotNull);
      expect(retrieved!.description, equals('Loaded from file'));
    });
  });
}
