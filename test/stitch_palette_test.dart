import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crochet_charts/models/stitch_record.dart';
import 'package:crochet_charts/providers/edit_mode_provider.dart';
import 'package:crochet_charts/providers/stitch_provider.dart';
import 'package:crochet_charts/widgets/stitch_palette.dart';

void main() {
  testWidgets('Selecting a stitch in StitchPalette automatically switches to EditMode.stitch',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final notifier = StitchStoreNotifier();
    notifier.setStitches([
      StitchRecord(
        name: 'single crochet',
        description: 'Single crochet stitch',
        category: ['Basic'],
        wrongSide: '',
        svgContent: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/></svg>',
      ),
      StitchRecord(
        name: 'double crochet',
        description: 'Double crochet stitch',
        category: ['Basic'],
        wrongSide: '',
        svgContent: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/></svg>',
      ),
    ]);

    final container = ProviderContainer(
      overrides: [
        stitchStoreProvider.overrideWith((ref) => notifier),
      ],
    );

    // Start in Pan mode
    container.read(editModeProvider.notifier).setMode(EditMode.pan);
    expect(container.read(editModeProvider).mode, equals(EditMode.pan));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: StitchPalette(),
          ),
        ),
      ),
    );
    await tester.pump();

    // Find and tap 'double crochet'
    final dcFinder = find.text('double crochet');
    expect(dcFinder, findsOneWidget);

    await tester.tap(dcFinder);
    await tester.pump();

    // Verify mode switched from Pan to Stitch mode
    expect(container.read(editModeProvider).mode, equals(EditMode.stitch));
    expect(container.read(stitchStoreProvider).activeStitchName, equals('double crochet'));

    // Switch to Move mode
    container.read(editModeProvider.notifier).setMode(EditMode.move);
    expect(container.read(editModeProvider).mode, equals(EditMode.move));

    // Tap 'single crochet'
    final scFinder = find.text('single crochet');
    expect(scFinder, findsOneWidget);

    await tester.tap(scFinder);
    await tester.pump();

    // Verify mode switched from Move to Stitch mode
    expect(container.read(editModeProvider).mode, equals(EditMode.stitch));
    expect(container.read(stitchStoreProvider).activeStitchName, equals('single crochet'));
  });

  testWidgets('Clear button next to search box clears query and restores stitch list',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final notifier = StitchStoreNotifier();
    notifier.setStitches([
      StitchRecord(
        name: 'single crochet',
        description: 'Single crochet stitch',
        category: ['Basic'],
        wrongSide: '',
        svgContent: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/></svg>',
      ),
      StitchRecord(
        name: 'double crochet',
        description: 'Double crochet stitch',
        category: ['Basic'],
        wrongSide: '',
        svgContent: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/></svg>',
      ),
    ]);

    final container = ProviderContainer(
      overrides: [
        stitchStoreProvider.overrideWith((ref) => notifier),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: StitchPalette(),
          ),
        ),
      ),
    );
    await tester.pump();

    // Both stitches initially visible
    expect(find.text('single crochet'), findsOneWidget);
    expect(find.text('double crochet'), findsOneWidget);

    // Clear button should initially be disabled (null onPressed)
    final clearButtonFinder = find.byKey(const ValueKey('clear_search_button'));
    expect(clearButtonFinder, findsOneWidget);
    final IconButton initialButton = tester.widget(clearButtonFinder);
    expect(initialButton.onPressed, isNull);

    // Enter search text "double"
    await tester.enterText(find.byType(TextField), 'double');
    await tester.pump();

    // Only 'double crochet' visible
    expect(find.text('single crochet'), findsNothing);
    expect(find.text('double crochet'), findsOneWidget);
    expect(container.read(stitchStoreProvider).store.searchText, equals('double'));

    // Clear button should now be enabled
    final IconButton enabledButton = tester.widget(clearButtonFinder);
    expect(enabledButton.onPressed, isNotNull);

    // Tap clear button
    await tester.tap(clearButtonFinder);
    await tester.pump();

    // Search query cleared and both stitches visible again
    expect(container.read(stitchStoreProvider).store.searchText, equals(''));
    final TextField textField = tester.widget(find.byType(TextField));
    expect(textField.controller?.text, equals(''));
    expect(find.text('single crochet'), findsOneWidget);
    expect(find.text('double crochet'), findsOneWidget);

    // Clear button should be disabled again
    final IconButton finalButton = tester.widget(clearButtonFinder);
    expect(finalButton.onPressed, isNull);
  });
}

