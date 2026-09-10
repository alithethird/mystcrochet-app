import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crochet_charts/providers/edit_mode_provider.dart';
import 'package:crochet_charts/widgets/mobile_app_bar.dart';

void main() {
  group('MobileAppBar Tests (Task #43)', () {
    testWidgets('renders MobileAppBar with title, menu, undo/redo, actions, and tool chips',
        (WidgetTester tester) async {
      bool drawerOpened = false;
      bool newCalled = false;

      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              appBar: MobileAppBar(
                onNew: () => newCalled = true,
                onOpen: () {},
                onSave: () {},
                onSavedDesigns: () {},
                onExportPng: () {},
                onTextView: () {},
                onOpenDrawer: () => drawerOpened = true,
              ),
              body: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Check title and menu button
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.redo), findsOneWidget);

      // Tool chips in bottom row
      expect(find.text('Seç'), findsOneWidget);
      expect(find.text('Değiştir'), findsOneWidget);
      expect(find.text('Sil'), findsOneWidget);
      expect(find.text('Taşı'), findsOneWidget);
      expect(find.text('Kaydır'), findsOneWidget);

      // Tap drawer menu icon
      await tester.tap(find.byIcon(Icons.menu));
      expect(drawerOpened, isTrue);

      // Tap 'Taşı' tool chip switches edit mode
      await tester.tap(find.text('Taşı'));
      await tester.pump();
      expect(container.read(editModeProvider).mode, equals(EditMode.move));

      // Tap 'Kaydır' tool chip switches edit mode
      await tester.tap(find.text('Kaydır'));
      await tester.pump();
      expect(container.read(editModeProvider).mode, equals(EditMode.pan));

      // Open overflow popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Yeni Grafik'), findsOneWidget);
      expect(find.text('Grafik Aç'), findsOneWidget);
      expect(find.text('Grafiği Kaydet'), findsOneWidget);
      expect(find.text('Kayıtlı Tasarımlar'), findsOneWidget);
      expect(find.text('PNG Olarak Dışa Aktar'), findsOneWidget);

      // Tap 'Yeni Grafik' item
      await tester.tap(find.text('Yeni Grafik'));
      await tester.pumpAndSettle();
      expect(newCalled, isTrue);
    });
  });
}
