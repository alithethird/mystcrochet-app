import 'package:crochet_charts/main.dart';
import 'package:crochet_charts/widgets/panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Right Panel & Drawer Tests', () {
    testWidgets('Desktop mode: right panel is hidden by default and toggles via tune button', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: CrochetChartsApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that initially PropertiesPanel / ShapePanel are not visible in the tree
      expect(find.byType(PropertiesPanel), findsNothing);
      expect(find.byType(ShapePanel), findsNothing);

      // Locate tune button (Icons.tune) on top right
      final tuneBtn = find.byIcon(Icons.tune);
      expect(tuneBtn, findsOneWidget);

      // Tap tune button to open right panel
      await tester.tap(tuneBtn);
      await tester.pumpAndSettle();

      // PropertiesPanel should now be visible
      expect(find.byType(PropertiesPanel), findsOneWidget);
      expect(find.text('Özellikler'), findsOneWidget);
      expect(find.text('Şekil'), findsOneWidget);

      // Switch to Shape tab
      await tester.tap(find.text('Şekil'));
      await tester.pumpAndSettle();
      expect(find.byType(ShapePanel), findsOneWidget);

      // Tap close button on the right panel
      final closeBtn = find.byTooltip('Kapat');
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      // Panel is hidden again
      expect(find.byType(PropertiesPanel), findsNothing);
      expect(find.byType(ShapePanel), findsNothing);
    });

    testWidgets('Mobile mode: tune button opens endDrawer with right panel', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: CrochetChartsApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Panel not visible initially
      expect(find.byType(PropertiesPanel), findsNothing);

      // There are two tune buttons on mobile: one in MobileAppBar, one on canvas
      final tuneBtns = find.byIcon(Icons.tune);
      expect(tuneBtns, findsNWidgets(2));

      // Tap the canvas tune button
      await tester.tap(tuneBtns.last);
      await tester.pumpAndSettle();

      // endDrawer is opened!
      expect(find.byType(Drawer), findsOneWidget);
      expect(find.byType(PropertiesPanel), findsOneWidget);
      expect(find.text('Özellikler'), findsOneWidget);

      // Close drawer via close button
      final closeBtn = find.byTooltip('Kapat');
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      // Drawer closed
      expect(find.byType(Drawer), findsNothing);

      // Tap the MobileAppBar tune button
      await tester.tap(tuneBtns.first);
      await tester.pumpAndSettle();

      // endDrawer is opened again!
      expect(find.byType(Drawer), findsOneWidget);
      expect(find.byType(PropertiesPanel), findsOneWidget);
    });
  });
}
