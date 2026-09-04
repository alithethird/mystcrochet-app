import 'package:crochet_charts/models/chart.dart';
import 'package:crochet_charts/models/guidelines.dart';
import 'package:crochet_charts/models/layer.dart';
import 'package:crochet_charts/models/pattern.dart';
import 'package:crochet_charts/models/visual_stitch.dart';
import 'package:crochet_charts/utils/serialization.dart';
import 'package:crochet_charts/services/chart_file_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Chart Serialization Tests', () {
    test('Round-trip serialization preserves all Chart properties', () {
      final originalChart = Chart(
        name: 'Mandala Bloom',
        style: GuidelinesType.visual,
        guidelines: Guidelines(
          type: GuidelinesType.visual,
          visualRounds: 5,
          visualRadialDivisions: 8,
          visualRoundSpacing: 40.0,
        ),
        layers: {
          0: ChartLayer(uid: 0, name: 'Background'),
          1: ChartLayer(uid: 1, name: 'Main Flowers'),
        },
        visualStitches: [
          VisualStitch(
            id: 'vs-1',
            stitchName: 'double crochet',
            x: 100.5,
            y: 150.2,
            roundIndex: 0,
            rotation: 45.0,
            scaleX: 1.2,
            scaleY: 1.2,
            fgColor: '#123456',
            bgColor: '#abcdef',
            layer: 1,
          ),
        ],
        patternRounds: [
          PatternRound(
            number: 1,
            isMagicRing: true,
            radiusOffset: 15.0,
            stitches: [
              PatternStitch(kind: 'stitch', name: 'ch', count: 3),
              PatternStitch(
                kind: 'stitch',
                name: 'dc',
                count: 11,
                connectsTo: 1,
                angleOffset: 12.5,
                pinnedAngle: 30.0,
                perimeterOffset: 5.0,
                pinnedPerimeter: 10.0,
              ),
            ],
          ),
        ],
        starterStitchName: 'sl st',
      );

      final jsonStr = chartToJson(originalChart);
      final restored = chartFromJson(jsonStr);

      expect(restored.name, 'Mandala Bloom');
      expect(restored.style, GuidelinesType.visual);
      expect(restored.guidelines.visualRounds, 5);
      expect(restored.guidelines.visualRadialDivisions, 8);
      expect(restored.guidelines.visualRoundSpacing, 40.0);

      expect(restored.layers.length, 2);
      expect(restored.layers[0]?.name, 'Background');
      expect(restored.layers[1]?.name, 'Main Flowers');

      expect(restored.visualStitches.length, 1);
      final vs = restored.visualStitches.first;
      expect(vs.id, 'vs-1');
      expect(vs.stitchName, 'double crochet');
      expect(vs.x, 100.5);
      expect(vs.y, 150.2);
      expect(vs.rotation, 45.0);
      expect(vs.fgColor, '#123456');

      expect(restored.patternRounds.length, 1);
      final r1 = restored.patternRounds.first;
      expect(r1.number, 1);
      expect(r1.isMagicRing, true);
      expect(r1.radiusOffset, 15.0);
      expect(r1.stitches.length, 2);
      expect(r1.stitches[0].name, 'ch');
      expect(r1.stitches[0].count, 3);
      expect(r1.stitches[1].name, 'dc');
      expect(r1.stitches[1].connectsTo, 1);
      expect(r1.stitches[1].angleOffset, 12.5);
      expect(r1.stitches[1].pinnedAngle, 30.0);

      expect(restored.starterStitchName, 'sl st');
    });

    test('chartFromJson handles envelope format { "chart": { ... } }', () {
      const jsonWithEnvelope = '''
      {
        "chart": {
          "name": "Envelope Chart",
          "style": 104,
          "guidelines": { "type": 104 },
          "layers": {},
          "indicators": [],
          "images": [],
          "groups": [],
          "visualStitches": [],
          "patternRounds": []
        }
      }
      ''';

      final chart = chartFromJson(jsonWithEnvelope);
      expect(chart.name, 'Envelope Chart');
      expect(chart.style, GuidelinesType.visual);
    });

    test('ChartFileService.saveChart executes without unhandled error in test environment', () async {
      final chart = Chart.defaultChart();
      final result1 = await ChartFileService.saveChart(chart, 'test_pattern');
      expect(result1, isA<bool>());

      final result2 = await ChartFileService.saveChart(chart, 'test_pattern.json');
      expect(result2, isA<bool>());
    });
  });
}

