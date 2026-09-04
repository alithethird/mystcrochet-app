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
}
