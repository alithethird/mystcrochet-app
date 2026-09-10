import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crochet_charts/widgets/mobile_app_bar.dart';
import 'package:crochet_charts/widgets/toolbar.dart';
import 'package:crochet_charts/utils/pwa_utils.dart';

void main() {
  group('Mobile Status Bar & Safe Area Tests', () {
    test('isStandalonePwa returns boolean on current platform', () {
      expect(isStandalonePwa(), isFalse);
    });

    testWidgets(
        'MobileAppBar respects status bar padding without overflow (notch / notification bar)',
        (WidgetTester tester) async {
      const topPadding = 48.0; // Typical Android / iOS notch height
      const screenSize = Size(390, 844); // Standard mobile phone size

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: screenSize,
                padding: EdgeInsets.only(top: topPadding),
                viewPadding: EdgeInsets.only(top: topPadding),
              ),
              child: Scaffold(
                appBar: MobileAppBar(
                  onNew: () {},
                  onOpen: () {},
                  onSave: () {},
                  onSavedDesigns: () {},
                  onExportPng: () {},
                  onTextView: () {},
                  onOpenDrawer: () {},
                ),
                body: const Center(child: Text('Body Content')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Ensure no flutter layout error/overflow occurred
      expect(tester.takeException(), isNull);

      // Verify the hamburger menu icon position is below topPadding
      final menuFinder = find.byIcon(Icons.menu);
      expect(menuFinder, findsOneWidget);
      final menuTopLeft = tester.getTopLeft(menuFinder);
      expect(menuTopLeft.dy, greaterThanOrEqualTo(topPadding));

      // Verify overflow menu icon is also below topPadding
      final moreFinder = find.byIcon(Icons.more_vert);
      expect(moreFinder, findsOneWidget);
      final moreTopLeft = tester.getTopLeft(moreFinder);
      expect(moreTopLeft.dy, greaterThanOrEqualTo(topPadding));

      // Verify bottom chips are rendered properly
      expect(find.text('Seç'), findsOneWidget);
      expect(find.text('Değiştir'), findsOneWidget);
      expect(find.text('Sil'), findsOneWidget);
      expect(find.text('Taşı'), findsOneWidget);
      expect(find.text('Kaydır'), findsOneWidget);
    });

    testWidgets(
        'AppToolbar wrapped in SafeArea respects top padding in tablet/landscape',
        (WidgetTester tester) async {
      const topPadding = 32.0;
      const screenSize = Size(1024, 768);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: screenSize,
                padding: EdgeInsets.only(top: topPadding),
                viewPadding: EdgeInsets.only(top: topPadding),
              ),
              child: Scaffold(
                body: Column(
                  children: [
                    SafeArea(
                      bottom: false,
                      child: AppToolbar(
                        onNew: () {},
                        onOpen: () {},
                        onSave: () {},
                        onTextView: () {},
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      final toolFinder = find.text('İlmek');
      expect(toolFinder, findsOneWidget);
      final toolTopLeft = tester.getTopLeft(toolFinder);
      expect(toolTopLeft.dy, greaterThanOrEqualTo(topPadding));
    });
  });
}
