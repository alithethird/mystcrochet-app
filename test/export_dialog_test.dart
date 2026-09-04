import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crochet_charts/dialogs/export_dialog.dart';
import 'package:crochet_charts/widgets/toolbar.dart';

void main() {
  group('Export as PNG Feature Tests', () {
    testWidgets('ExportDialog renders with default values and submits options', (tester) async {
      ExportDialogOptions? capturedOptions;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportDialog(
              initialName: 'My Awesome Mandala',
              onExport: (options) {
                capturedOptions = options;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('PNG Olarak Dışa Aktar'), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals('My_Awesome_Mandala.png'));

      // Verify default resolution (2x) is present in tree
      expect(find.text('2x - Yüksek Kalite (Baskı/HD)'), findsOneWidget);

      // Verify checkboxes exist
      expect(find.text('Kılavuz Çizgilerini Dahil Et'), findsOneWidget);
      expect(find.text('Saydam Arka Plan'), findsOneWidget);

      // Tap Export PNG button
      final exportButton = find.widgetWithText(FilledButton, 'PNG Dışa Aktar');
      expect(exportButton, findsOneWidget);
      await tester.tap(exportButton);
      await tester.pumpAndSettle();

      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.fileName, equals('My_Awesome_Mandala.png'));
      expect(capturedOptions!.pixelRatio, equals(2.0));
      expect(capturedOptions!.includeGuidelines, isTrue);
      expect(capturedOptions!.transparent, isFalse);
    });

    testWidgets('ExportDialog ensures .png extension even if user omits it', (tester) async {
      ExportDialogOptions? capturedOptions;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportDialog(
              initialName: 'Untitled',
              onExport: (options) {
                capturedOptions = options;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter a custom name without .png extension
      await tester.enterText(find.byType(TextField), 'summer_coaster');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'PNG Dışa Aktar'));
      await tester.pumpAndSettle();

      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.fileName, equals('summer_coaster.png'));
    });

    testWidgets('AppToolbar includes Export as PNG button and fires callback', (tester) async {
      bool exportTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppToolbar(
                onNew: () {},
                onOpen: () {},
                onSave: () {},
                onTextView: () {},
                onExportPng: () {
                  exportTapped = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final exportButton = find.byKey(const ValueKey('toolbar_export_png'));
      expect(exportButton, findsOneWidget);

      await tester.ensureVisible(exportButton);
      await tester.tap(exportButton);
      await tester.pumpAndSettle();

      expect(exportTapped, isTrue);
    });
  });
}
