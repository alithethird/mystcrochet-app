import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crochet_charts/dialogs/welcome_tutorial_dialog.dart';
import 'package:crochet_charts/widgets/mobile_app_bar.dart';
import 'package:crochet_charts/widgets/toolbar.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WelcomeTutorialDialog Tests (Task #45)', () {
    test('static shouldShow and markSeen work correctly with SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await WelcomeTutorialDialog.shouldShow(), isTrue);

      await WelcomeTutorialDialog.markSeen(seen: true);
      expect(await WelcomeTutorialDialog.shouldShow(), isFalse);

      await WelcomeTutorialDialog.markSeen(seen: false);
      expect(await WelcomeTutorialDialog.shouldShow(), isTrue);
    });

    testWidgets('renders first slide with title, highlights, counter, and navigation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WelcomeTutorialDialog(initialDontShowAgain: false),
          ),
        ),
      );
      await tester.pump();

      // Check header counter
      expect(find.text('1 / 4'), findsOneWidget);
      // Check title
      expect(find.text("MystCrochet'e Hoş Geldiniz!"), findsOneWidget);
      // Check buttons
      expect(find.byKey(const ValueKey('welcome_tutorial_skip_button')), findsOneWidget);
      expect(find.text('Geç'), findsOneWidget);
      expect(find.byKey(const ValueKey('welcome_tutorial_next_button')), findsOneWidget);
      expect(find.text('İleri'), findsOneWidget);
      // Geri button should not be shown on first slide
      expect(find.byKey(const ValueKey('welcome_tutorial_prev_button')), findsNothing);
      // Checkbox is present
      expect(find.text('Bir daha otomatik gösterme'), findsOneWidget);
    });

    testWidgets('navigates through all slides with İleri and Geri',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WelcomeTutorialDialog(initialDontShowAgain: true),
          ),
        ),
      );
      await tester.pump();

      // Slide 1: Welcome
      expect(find.text('1 / 4'), findsOneWidget);
      expect(find.text("MystCrochet'e Hoş Geldiniz!"), findsOneWidget);

      // Tap İleri -> Slide 2
      await tester.tap(find.byKey(const ValueKey('welcome_tutorial_next_button')));
      await tester.pumpAndSettle();
      expect(find.text('2 / 4'), findsOneWidget);
      expect(find.text('Başlangıç ve İlmek Ekleme'), findsOneWidget);
      expect(find.byKey(const ValueKey('welcome_tutorial_prev_button')), findsOneWidget);
      expect(find.text('Geri'), findsOneWidget);

      // Tap İleri -> Slide 3
      await tester.tap(find.byKey(const ValueKey('welcome_tutorial_next_button')));
      await tester.pumpAndSettle();
      expect(find.text('3 / 4'), findsOneWidget);
      expect(find.text('Turlar ve Geometrik Şekiller'), findsOneWidget);

      // Tap İleri -> Slide 4
      await tester.tap(find.byKey(const ValueKey('welcome_tutorial_next_button')));
      await tester.pumpAndSettle();
      expect(find.text('4 / 4'), findsOneWidget);
      expect(find.text('Doğal Kaydırma & Düzenleme'), findsOneWidget);
      expect(find.text('Hemen Başla'), findsOneWidget);

      // Tap Geri -> Back to Slide 3
      await tester.tap(find.byKey(const ValueKey('welcome_tutorial_prev_button')));
      await tester.pumpAndSettle();
      expect(find.text('3 / 4'), findsOneWidget);
      expect(find.text('Turlar ve Geometrik Şekiller'), findsOneWidget);

      // Tap İleri again to return to Slide 4
      await tester.tap(find.byKey(const ValueKey('welcome_tutorial_next_button')));
      await tester.pumpAndSettle();
      expect(find.text('4 / 4'), findsOneWidget);

      // Tap Hemen Başla on the last slide to finish
      await tester.tap(find.byKey(const ValueKey('welcome_tutorial_next_button')));
      await tester.pumpAndSettle();

      // SharedPreferences should have saved seen: true
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(WelcomeTutorialDialog.prefsKey), isTrue);
    });

    testWidgets('skip button closes dialog and marks seen if checkbox is checked',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => WelcomeTutorialDialog.show(context),
                  child: const Text('Aç'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();

      expect(find.text("MystCrochet'e Hoş Geldiniz!"), findsOneWidget);

      // Tap 'Geç' button
      await tester.tap(find.byKey(const ValueKey('welcome_tutorial_skip_button')));
      await tester.pumpAndSettle();

      expect(find.text("MystCrochet'e Hoş Geldiniz!"), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(WelcomeTutorialDialog.prefsKey), isTrue);
    });

    testWidgets('close icon button closes dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => WelcomeTutorialDialog.show(context),
                  child: const Text('Aç'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();

      expect(find.text("MystCrochet'e Hoş Geldiniz!"), findsOneWidget);

      // Tap close button
      await tester.tap(find.byKey(const ValueKey('welcome_tutorial_close_button')));
      await tester.pumpAndSettle();

      expect(find.text("MystCrochet'e Hoş Geldiniz!"), findsNothing);
    });

    testWidgets('MobileAppBar menu contains Kullanım Rehberi and invokes onTutorial',
        (WidgetTester tester) async {
      bool tutorialCalled = false;
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              appBar: MobileAppBar(
                onNew: () {},
                onOpen: () {},
                onSave: () {},
                onSavedDesigns: () {},
                onExportPng: () {},
                onTextView: () {},
                onOpenDrawer: () {},
                onTutorial: () => tutorialCalled = true,
              ),
              body: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Open overflow popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Kullanım Rehberi'), findsOneWidget);

      // Tap 'Kullanım Rehberi'
      await tester.tap(find.text('Kullanım Rehberi'));
      await tester.pumpAndSettle();

      expect(tutorialCalled, isTrue);
    });

    testWidgets('AppToolbar contains Kullanım Rehberi button and invokes onTutorial',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 800);
      addTearDown(() => tester.view.resetPhysicalSize());

      bool tutorialCalled = false;
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: AppToolbar(
                onNew: () {},
                onOpen: () {},
                onSave: () {},
                onTextView: () {},
                onTutorial: () => tutorialCalled = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('toolbar_tutorial')), findsOneWidget);

      await tester.ensureVisible(find.byKey(const ValueKey('toolbar_tutorial')));
      await tester.tap(find.byKey(const ValueKey('toolbar_tutorial')));
      await tester.pumpAndSettle();

      expect(tutorialCalled, isTrue);
    });
  });
}
