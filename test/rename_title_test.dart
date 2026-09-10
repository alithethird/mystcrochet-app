import 'package:crochet_charts/models/chart.dart';
import 'package:crochet_charts/providers/chart_provider.dart';
import 'package:crochet_charts/widgets/toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Rename Title Tests (Task #31)', () {
    testWidgets('Double-clicking chart title in toolbar opens inline text field and updates title',
        (tester) async {
      final chartNotifier = ChartNotifier();
      chartNotifier.setChart(Chart.defaultChart().copyWith(name: 'Initial Pattern Name'));

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
                onTextView: () {},
                onExportPng: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title should initially show as Text
      expect(find.text('Initial Pattern Name'), findsOneWidget);
      expect(find.byKey(const ValueKey('toolbar_chart_name_input')), findsNothing);

      // Double tap title to trigger inline editing
      await tester.tap(find.text('Initial Pattern Name'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Initial Pattern Name'));
      await tester.pumpAndSettle();

      // TextField should now be visible
      expect(find.byKey(const ValueKey('toolbar_chart_name_input')), findsOneWidget);

      // Enter new name and submit
      await tester.enterText(find.byKey(const ValueKey('toolbar_chart_name_input')), 'Renamed Pattern');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Text field should be closed and new title displayed
      expect(find.byKey(const ValueKey('toolbar_chart_name_input')), findsNothing);
      expect(find.text('Renamed Pattern'), findsOneWidget);
      expect(chartNotifier.chart.name, equals('Renamed Pattern'));

      // Test undo restores initial name
      chartNotifier.undo();
      await tester.pumpAndSettle();
      expect(chartNotifier.chart.name, equals('Initial Pattern Name'));
      expect(find.text('Initial Pattern Name'), findsOneWidget);
    });
  });
}
