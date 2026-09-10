import 'package:flutter_test/flutter_test.dart';
import 'package:crochet_charts/models/stitch_record.dart';
import 'package:crochet_charts/utils/approximate_search.dart';

void main() {
  group('Text normalization & Damerau-Levenshtein', () {
    test('normalizes Turkish characters and punctuation', () {
      expect(normalizeSearchText('İlmek-Örneği, Çift 3-dc!'), equals('ilmek ornegi cift 3 dc'));
      expect(normalizeSearchText('Şapka / Ağız'), equals('sapka agiz'));
    });

    test('computes Damerau-Levenshtein distance correctly including transpositions', () {
      expect(damerauLevenshteinDistance('popcorn', 'popcorn'), equals(0));
      expect(damerauLevenshteinDistance('popocorn', 'popcorn'), equals(1)); // insertion
      expect(damerauLevenshteinDistance('chian', 'chain'), equals(1)); // transposition
      expect(damerauLevenshteinDistance('singel', 'single'), equals(1)); // transposition
      expect(damerauLevenshteinDistance('trebel', 'treble'), equals(1)); // transposition
      expect(damerauLevenshteinDistance('duble', 'double'), equals(1)); // deletion
    });

    test('subsequence check works', () {
      expect(isSubsequence('popcrn', 'popcorn'), isTrue);
      expect(isSubsequence('ch', 'chain'), isTrue);
      expect(isSubsequence('xyz', 'chain'), isFalse);
    });

    test('getAcronym produces initials', () {
      expect(getAcronym('single crochet'), equals('sc'));
      expect(getAcronym('half double crochet'), equals('hdc'));
      expect(getAcronym('slip stitch'), equals('ss'));
    });
  });

  group('searchStitches', () {
    final sampleStitches = [
      StitchRecord(
        name: 'sl st',
        description: 'slip stitch',
        category: ['Basic'],
        wrongSide: 'sl st',
        svgContent: '<svg></svg>',
      ),
      StitchRecord(
        name: 'ch',
        description: 'chain',
        category: ['Basic'],
        wrongSide: 'ch',
        svgContent: '<svg></svg>',
      ),
      StitchRecord(
        name: 'sc',
        description: 'single crochet',
        category: ['Basic'],
        wrongSide: 'sc',
        svgContent: '<svg></svg>',
      ),
      StitchRecord(
        name: 'hdc',
        description: 'half double crochet',
        category: ['Basic'],
        wrongSide: 'hdc',
        svgContent: '<svg></svg>',
      ),
      StitchRecord(
        name: 'dc',
        description: 'double crochet',
        category: ['Basic'],
        wrongSide: 'dc',
        svgContent: '<svg></svg>',
      ),
      StitchRecord(
        name: 'tr',
        description: 'treble crochet',
        category: ['Basic'],
        wrongSide: 'tr',
        svgContent: '<svg></svg>',
      ),
      StitchRecord(
        name: '3-dc popcorn',
        description: '3 double crochet popcorn',
        category: ['Special'],
        wrongSide: '3-dc popcorn',
        svgContent: '<svg></svg>',
      ),
      StitchRecord(
        name: '5-dc popcorn',
        description: '5 double crochet popcorn',
        category: ['Special'],
        wrongSide: '5-dc popcorn',
        svgContent: '<svg></svg>',
      ),
      StitchRecord(
        name: 'FPdc',
        description: 'front post double crochet',
        category: ['Post'],
        wrongSide: 'BPdc',
        svgContent: '<svg></svg>',
      ),
      StitchRecord(
        name: 'BPdc',
        description: 'back post double crochet',
        category: ['Post'],
        wrongSide: 'FPdc',
        svgContent: '<svg></svg>',
      ),
    ];

    test('empty query returns full list or category-filtered list', () {
      final all = searchStitches(stitches: sampleStitches, query: '');
      expect(all.length, equals(sampleStitches.length));

      final special = searchStitches(
        stitches: sampleStitches,
        query: '   ',
        activeCategory: 'Special',
      );
      expect(special.length, equals(2));
      expect(special.map((s) => s.name), containsAll(['3-dc popcorn', '5-dc popcorn']));
    });

    test('exact match ranks highest', () {
      final results = searchStitches(stitches: sampleStitches, query: 'ch');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.name, equals('ch'));

      final dcResults = searchStitches(stitches: sampleStitches, query: 'dc');
      expect(dcResults.first.name, equals('dc'));
    });

    test('finds stitches with typos (approximate search)', () {
      // "popocorn" -> 3-dc popcorn & 5-dc popcorn
      final popcornResults = searchStitches(stitches: sampleStitches, query: 'popocorn');
      final names = popcornResults.map((s) => s.name).toList();
      expect(names, contains('3-dc popcorn'));
      expect(names, contains('5-dc popcorn'));

      // "chian" -> chain (ch)
      final chainResults = searchStitches(stitches: sampleStitches, query: 'chian');
      expect(chainResults.isNotEmpty, isTrue);
      expect(chainResults.map((s) => s.name), contains('ch'));

      // "singel" -> single crochet (sc)
      final scResults = searchStitches(stitches: sampleStitches, query: 'singel');
      expect(scResults.isNotEmpty, isTrue);
      expect(scResults.first.name, equals('sc'));

      // "trebel" -> treble crochet (tr)
      final trResults = searchStitches(stitches: sampleStitches, query: 'trebel');
      expect(trResults.isNotEmpty, isTrue);
      expect(trResults.first.name, equals('tr'));

      // "duble" -> double crochet (dc)
      final dcResults = searchStitches(stitches: sampleStitches, query: 'duble');
      expect(dcResults.isNotEmpty, isTrue);
      expect(dcResults.map((s) => s.name), contains('dc'));
    });

    test('finds stitches with abbreviations and no-space names', () {
      // "slst" -> sl st
      final slstResults = searchStitches(stitches: sampleStitches, query: 'slst');
      expect(slstResults.isNotEmpty, isTrue);
      expect(slstResults.first.name, equals('sl st'));

      // "fpdc" -> FPdc
      final fpdcResults = searchStitches(stitches: sampleStitches, query: 'fpdc');
      expect(fpdcResults.isNotEmpty, isTrue);
      expect(fpdcResults.first.name, equals('FPdc'));
    });

    test('handles multi-token queries', () {
      final results = searchStitches(stitches: sampleStitches, query: '3 pop');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.name, equals('3-dc popcorn'));

      final postResults = searchStitches(stitches: sampleStitches, query: 'front post');
      expect(postResults.isNotEmpty, isTrue);
      expect(postResults.first.name, equals('FPdc'));
    });

    test('respects activeCategory filter while performing approximate search', () {
      final results = searchStitches(
        stitches: sampleStitches,
        query: 'popocorn',
        activeCategory: 'Special',
      );
      expect(results.length, equals(2));

      final emptyResults = searchStitches(
        stitches: sampleStitches,
        query: 'popocorn',
        activeCategory: 'Basic',
      );
      expect(emptyResults.isEmpty, isTrue);
    });
  });
}
