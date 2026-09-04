import 'package:crochet_charts/dialogs/save_chart_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SaveChartDialog Tests', () {
    testWidgets('Renders with prefilled name and default .crochet format', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SaveChartDialog(
              initialName: 'My Mandala',
              onSave: (_, __) {},
            ),
          ),
        ),
      );

      expect(find.text('Grafiği Kaydet'), findsOneWidget);
      expect(find.text('My Mandala'), findsOneWidget);
      expect(find.text('.crochet (Grafik Deseni)'), findsOneWidget);
      expect(find.text('.json (JSON Verisi)'), findsOneWidget);
      expect(find.text('Çalışma alanındaki grafik başlığını güncelle'), findsOneWidget);
    });

    testWidgets('Defaults Untitled to crochet_pattern', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SaveChartDialog(
              initialName: 'Untitled',
              onSave: (_, __) {},
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'crochet_pattern');
    });

    testWidgets('Submits with .crochet extension and updated name', (tester) async {
      String? savedFileName;
      String? savedUpdatedName;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SaveChartDialog(
              initialName: 'Sunburst',
              onSave: (file, title) {
                savedFileName = file;
                savedUpdatedName = title;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Kaydet'));
      await tester.pumpAndSettle();

      expect(savedFileName, 'Sunburst.crochet');
      expect(savedUpdatedName, 'Sunburst');
    });

    testWidgets('Switching to .json exports with .json extension', (tester) async {
      String? savedFileName;
      String? savedUpdatedName;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SaveChartDialog(
              initialName: 'Flower',
              onSave: (file, title) {
                savedFileName = file;
                savedUpdatedName = title;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('.json (JSON Verisi)'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Kaydet'));
      await tester.pumpAndSettle();

      expect(savedFileName, 'Flower.json');
      expect(savedUpdatedName, 'Flower');
    });

    testWidgets('Unchecking update title returns null for updated name', (tester) async {
      String? savedFileName;
      String? savedUpdatedName;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SaveChartDialog(
              initialName: 'Daisy',
              onSave: (file, title) {
                savedFileName = file;
                savedUpdatedName = title;
              },
            ),
          ),
        ),
      );

      // Tap checkbox to uncheck
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Kaydet'));
      await tester.pumpAndSettle();

      expect(savedFileName, 'Daisy.crochet');
      expect(savedUpdatedName, isNull);
    });
  });
}
