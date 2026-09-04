import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:crochet_charts/models/stitch_record.dart';

void main() {
  group('Stitches Asset Tests', () {
    late String jsonString;
    late Map<String, dynamic> data;
    late List<StitchRecord> stitches;

    setUpAll(() {
      final file = File('assets/stitches.json');
      expect(file.existsSync(), isTrue, reason: 'assets/stitches.json must exist');
      jsonString = file.readAsStringSync();
      data = json.decode(jsonString) as Map<String, dynamic>;
      final list = data['stitches'] as List;
      stitches = list.map((e) => StitchRecord.fromJson(e as Map<String, dynamic>)).toList();
    });

    test('stitches.json loads and contains stitches', () {
      expect(stitches, isNotEmpty);
      expect(stitches.length, greaterThan(50));
    });

    test('3-dc popcorn stitch is present and valid', () {
      final popcorn3 = stitches.firstWhere(
        (s) => s.name == '3-dc popcorn',
        orElse: () => throw StateError('3-dc popcorn not found'),
      );

      expect(popcorn3.name, equals('3-dc popcorn'));
      expect(popcorn3.description, equals('3 double crochet popcorn'));
      expect(popcorn3.category, contains('Default'));
      expect(popcorn3.wrongSide, equals('3-dc popcorn'));

      // Validate SVG content structure
      expect(popcorn3.svgContent, contains('<svg'));
      expect(popcorn3.svgContent, contains('width="64"'));
      expect(popcorn3.svgContent, contains('height="90"'));
      expect(popcorn3.svgContent, contains('sodipodi:docname="3dc_popcorn.svg"'));
      // Must contain the popcorn arc and the 3 stems
      expect(popcorn3.svgContent, contains('id="path3952"')); // Popcorn top arc
      expect(popcorn3.svgContent, contains('id="path4109-0-0"')); // Center dc stem
      expect(popcorn3.svgContent, contains('id="path4109"')); // Curved dc stem
    });

    test('3 hdc popcorn stitch is present and valid', () {
      final s = stitches.firstWhere(
        (s) => s.name == '3 hdc popcorn',
        orElse: () => throw StateError('3 hdc popcorn not found'),
      );
      expect(s.description, equals('3 stitch half double crochet popcorn'));
      expect(s.category, contains('Default'));
      expect(s.svgContent, contains('<svg'));
      expect(s.svgContent, contains('width="56"'));
      expect(s.svgContent, contains('height="64"'));
      expect(s.svgContent, contains('id="path2993"'));
    });

    test('3 dc popcorn v stitch is present and valid', () {
      final s = stitches.firstWhere(
        (s) => s.name == '3 dc popcorn v',
        orElse: () => throw StateError('3 dc popcorn v not found'),
      );
      expect(s.description, equals('3 double crochet popcorn variation'));
      expect(s.category, contains('Default'));
      expect(s.svgContent, contains('<svg'));
      expect(s.svgContent, contains('width="60"'));
      expect(s.svgContent, contains('height="80"'));
      expect(s.svgContent, contains('id="path2993"'));
    });

    test('3 dc popcorn v2 stitch is present and valid', () {
      final s = stitches.firstWhere(
        (s) => s.name == '3 dc popcorn v2',
        orElse: () => throw StateError('3 dc popcorn v2 not found'),
      );
      expect(s.description, equals('3 double crochet popcorn variation 2'));
      expect(s.category, contains('Default'));
      expect(s.svgContent, contains('<svg'));
      expect(s.svgContent, contains('width="60"'));
      expect(s.svgContent, contains('height="80"'));
      expect(s.svgContent, contains('id="path2993"'));
    });

    test('3 tr popcorn stitch is present and valid', () {
      final s = stitches.firstWhere(
        (s) => s.name == '3 tr popcorn',
        orElse: () => throw StateError('3 tr popcorn not found'),
      );
      expect(s.description, equals('3 treble crochet popcorn'));
      expect(s.category, contains('Default'));
      expect(s.svgContent, contains('<svg'));
      expect(s.svgContent, contains('width="68"'));
      expect(s.svgContent, contains('height="96"'));
      expect(s.svgContent, contains('id="path2993"'));
    });

    test('All stitches have non-empty name and svgContent', () {
      for (final s in stitches) {
        expect(s.name, isNotEmpty, reason: 'Stitch name should not be empty');
        expect(s.svgContent, isNotEmpty, reason: 'Stitch ${s.name} svgContent should not be empty');
      }
    });

    test('All stitch names are unique (no duplicates)', () {
      final names = stitches.map((s) => s.name).toList();
      final uniqueNames = names.toSet();
      expect(names.length, equals(uniqueNames.length),
          reason: 'There should be no duplicate stitch names in stitches.json');
    });
  });
}
