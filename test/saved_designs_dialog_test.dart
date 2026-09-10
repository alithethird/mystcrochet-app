import 'package:crochet_charts/models/chart.dart';
import 'package:crochet_charts/models/pattern.dart';
import 'package:crochet_charts/providers/chart_provider.dart';
import 'package:crochet_charts/services/local_design_service.dart';
import 'package:crochet_charts/widgets/saved_designs_dialog.dart';
import 'package:crochet_charts/widgets/toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SavedDesignsDialog Tests (Task #34)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('AppToolbar shows "Kayıtlı Tasarımlar" button and invokes callback', (tester) async {
      bool savedDesignsClicked = false;
      final chartNotifier = ChartNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chartProvider.overrideWith((ref) => chartNotifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AppToolbar(
                onNew: () {},
                onOpen: () {},
                onSave: () {},
                onSavedDesigns: () => savedDesignsClicked = true,
                onTextView: () {},
                onExportPng: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final buttonFinder = find.byKey(const ValueKey('toolbar_saved_designs'));
      expect(buttonFinder, findsOneWidget);

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();
      expect(savedDesignsClicked, isTrue);
    });

    testWidgets('SavedDesignsDialog displays empty state and can save current chart', (tester) async {
      final currentChart = Chart.defaultChart().copyWith(name: 'My Flower Chart');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SavedDesignsDialog(
              currentChart: currentChart,
              onSelect: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kayıtlı Tasarımlar'), findsOneWidget);
      expect(find.text('Henüz yerel olarak kaydedilmiş tasarım bulunmuyor.'), findsOneWidget);

      // Tap "Mevcut Grafiği Kaydet"
      final saveCurrentBtn = find.byKey(const ValueKey('saved_designs_save_current_button'));
      expect(saveCurrentBtn, findsOneWidget);
      await tester.tap(saveCurrentBtn);
      await tester.pumpAndSettle();

      // Alert dialog to enter name
      expect(find.text('Tasarımı Yerel Hafızaya Kaydet'), findsOneWidget);
      expect(find.text('Kaydet'), findsOneWidget);
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();

      // Should now list the saved design card
      expect(find.text('My Flower Chart'), findsOneWidget);
    });

    testWidgets('SavedDesignsDialog lists saved designs and selecting one calls onSelect', (tester) async {
      final chart = Chart.defaultChart().copyWith(
        name: 'Retro Granny Square',
        patternRounds: [
          PatternRound(
            number: 1,
            stitches: [PatternStitch(kind: 'stitch', name: 'dc', count: 16)],
          ),
        ],
      );
      final saved = await LocalDesignService.saveDesign(chart);

      Chart? loadedChart;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SavedDesignsDialog(
              currentChart: Chart.defaultChart(),
              onSelect: (c) => loadedChart = c,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Retro Granny Square'), findsOneWidget);
      expect(find.text('1 Tur'), findsOneWidget);
      expect(find.text('16 İlmek'), findsOneWidget);

      // Tap "Yükle"
      final openBtn = find.byKey(ValueKey('saved_design_open_${saved.id}'));
      expect(openBtn, findsOneWidget);
      await tester.tap(openBtn);
      await tester.pumpAndSettle();

      expect(loadedChart, isNotNull);
      expect(loadedChart!.name, equals('Retro Granny Square'));
      expect(loadedChart!.patternRounds.length, equals(1));
    });

    testWidgets('Deleting a design from SavedDesignsDialog removes it from storage and list', (tester) async {
      final chart = Chart.defaultChart().copyWith(name: 'Doily to Delete');
      final saved = await LocalDesignService.saveDesign(chart);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SavedDesignsDialog(
              currentChart: Chart.defaultChart(),
              onSelect: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Doily to Delete'), findsOneWidget);

      // Tap delete icon
      final deleteBtn = find.byKey(ValueKey('saved_design_delete_${saved.id}'));
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Tasarımı Sil'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Sil'));
      await tester.pumpAndSettle();

      // Card should be gone and empty state shown
      expect(find.text('Doily to Delete'), findsNothing);
      expect(find.text('Henüz yerel olarak kaydedilmiş tasarım bulunmuyor.'), findsOneWidget);
    });
  });
}
