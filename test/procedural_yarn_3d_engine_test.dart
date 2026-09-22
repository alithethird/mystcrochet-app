import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:crochet_charts/models/chart.dart';
import 'package:crochet_charts/models/guidelines.dart';
import 'package:crochet_charts/models/visual_stitch.dart';
import 'package:crochet_charts/models/yarn_render_config.dart';
import 'package:crochet_charts/services/procedural_yarn_3d_engine.dart';
import 'package:crochet_charts/services/procedural_yarn_2d_engine.dart';

void main() {
  group('Procedural Yarn Engine & YarnRenderConfig Tests', () {
    test('YarnMaterialPreset default values', () {
      expect(YarnMaterialPreset.cotton.defaultThickness, equals(1.8));
      expect(YarnMaterialPreset.wool.defaultFuzziness, equals(0.45));
      expect(YarnMaterialPreset.mohair.defaultFuzziness, equals(0.85));
    });

    test('YarnRenderConfig copyWith updates fields correctly', () {
      const config = YarnRenderConfig();
      final updated = config.copyWith(
        materialPreset: YarnMaterialPreset.wool,
        thickness: 2.5,
        fuzziness: 0.5,
        renderDimension: RenderDimensionMode.mode2D,
      );

      expect(updated.materialPreset, equals(YarnMaterialPreset.wool));
      expect(updated.thickness, equals(2.5));
      expect(updated.fuzziness, equals(0.5));
      expect(updated.renderDimension, equals(RenderDimensionMode.mode2D));
    });

    test('ProceduralYarn3DEngine.render executes cleanly without errors', () {
      final chart = Chart(
        name: 'Test Motif',
        guidelines: Guidelines(type: GuidelinesType.visual),
        starterStitchName: 'magic_ring',
        visualStitches: [
          VisualStitch(id: '1', stitchName: 'ch', x: 0, y: 0, roundIndex: 0),
          VisualStitch(id: '2', stitchName: 'sc', x: 20, y: 20, roundIndex: 0),
          VisualStitch(id: '3', stitchName: 'dc', x: 40, y: 40, roundIndex: 1),
        ],
      );

      const config = YarnRenderConfig();
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => ProceduralYarn3DEngine.render(canvas, const Size(500, 500), chart, config),
        returnsNormally,
      );
    });

    test('ProceduralYarn2DEngine.render executes cleanly without errors', () {
      final chart = Chart(
        name: 'Test Motif 2D',
        guidelines: Guidelines(type: GuidelinesType.visual),
        starterStitchName: 'magic_ring',
        visualStitches: [
          VisualStitch(id: '1', stitchName: 'ch', x: 0, y: 0, roundIndex: 0),
          VisualStitch(id: '2', stitchName: 'sc', x: 20, y: 20, roundIndex: 0),
          VisualStitch(id: '3', stitchName: 'dc', x: 40, y: 40, roundIndex: 1),
        ],
      );

      const config = YarnRenderConfig(renderDimension: RenderDimensionMode.mode2D);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => ProceduralYarn2DEngine.render(canvas, const Size(500, 500), chart, config),
        returnsNormally,
      );
    });
  });
}
