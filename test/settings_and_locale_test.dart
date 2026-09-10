import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crochet_charts/dialogs/language_selection_dialog.dart';
import 'package:crochet_charts/l10n/app_strings.dart';
import 'package:crochet_charts/providers/locale_provider.dart';
import 'package:crochet_charts/widgets/mobile_app_bar.dart';
import 'package:crochet_charts/widgets/toolbar.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Settings Menu & Localization Tests', () {
    test('AppStrings supports tr, en, de, es and fallback', () {
      const tr = AppStrings('tr');
      const en = AppStrings('en');
      const de = AppStrings('de');
      const es = AppStrings('es');

      expect(tr.settings, equals('Ayarlar'));
      expect(en.settings, equals('Settings'));
      expect(de.settings, equals('Einstellungen'));
      expect(es.settings, equals('Configuración'));

      expect(tr.language, equals('Dil'));
      expect(en.language, equals('Language'));
      expect(de.language, equals('Sprache'));
      expect(es.language, equals('Idioma'));

      expect(tr.newChart, equals('Yeni Grafik'));
      expect(en.newChart, equals('New Chart'));
      expect(de.newChart, equals('Neues Diagramm'));
      expect(es.newChart, equals('Nuevo gráfico'));
    });

    testWidgets(
        'AppToolbar displays Settings menu and items (New, Open, Save, Data View, Language, Help)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool newCalled = false;
      bool openCalled = false;
      bool saveCalled = false;
      bool textViewCalled = false;
      bool tutorialCalled = false;

      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: AppToolbar(
                onNew: () => newCalled = true,
                onOpen: () => openCalled = true,
                onSave: () => saveCalled = true,
                onTextView: () => textViewCalled = true,
                onTutorial: () => tutorialCalled = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Settings button is visible on toolbar
      final settingsFinder = find.byKey(const ValueKey('toolbar_settings'));
      expect(settingsFinder, findsOneWidget);

      // Open Settings popup
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();

      expect(find.text('Yeni Grafik'), findsOneWidget);
      expect(find.text('Grafik Aç'), findsOneWidget);
      expect(find.text('Grafiği Kaydet'), findsOneWidget);
      expect(find.text('Veri Görünümü'), findsOneWidget);
      expect(find.text('Dil: Türkçe'), findsOneWidget);
      expect(find.text('Kullanım Rehberi'), findsOneWidget);

      // Tap 'Yeni Grafik'
      await tester.tap(find.text('Yeni Grafik'));
      await tester.pumpAndSettle();
      expect(newCalled, isTrue);

      // Reopen and tap 'Grafik Aç'
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Grafik Aç'));
      await tester.pumpAndSettle();
      expect(openCalled, isTrue);

      // Reopen and tap 'Grafiği Kaydet'
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Grafiği Kaydet'));
      await tester.pumpAndSettle();
      expect(saveCalled, isTrue);

      // Reopen and tap 'Veri Görünümü'
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Veri Görünümü'));
      await tester.pumpAndSettle();
      expect(textViewCalled, isTrue);

      // Reopen and tap 'Kullanım Rehberi'
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kullanım Rehberi'));
      await tester.pumpAndSettle();
      expect(tutorialCalled, isTrue);
    });

    testWidgets('Language selection dialog switches language and updates UI',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('İlmek'), findsOneWidget);
      expect(find.text('Seç'), findsOneWidget);

      // Open Settings menu
      final settingsFinder = find.byKey(const ValueKey('toolbar_settings'));
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();

      // Tap Language menu item
      await tester.tap(find.text('Dil: Türkçe'));
      await tester.pumpAndSettle();

      // LanguageSelectionDialog is now visible
      expect(find.byType(LanguageSelectionDialog), findsOneWidget);
      expect(find.text('Dil Seçin'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Deutsch'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);

      // Select English
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // Dialog is closed and language changed to English
      expect(container.read(localeProvider), equals('en'));
      expect(find.text('Stitch'), findsOneWidget);
      expect(find.text('Select'), findsOneWidget);

      // Open Settings menu again to check English strings
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();
      expect(find.text('New Chart'), findsOneWidget);
      expect(find.text('Open Chart'), findsOneWidget);
      expect(find.text('Save Chart'), findsOneWidget);
      expect(find.text('Language: English'), findsOneWidget);

      // Switch to Deutsch
      await tester.tap(find.text('Language: English'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deutsch'));
      await tester.pumpAndSettle();
      expect(container.read(localeProvider), equals('de'));
      expect(find.text('Masche'), findsOneWidget);
      expect(find.text('Auswählen'), findsOneWidget);

      // Switch to Español
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sprache: Deutsch'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Español'));
      await tester.pumpAndSettle();
      expect(container.read(localeProvider), equals('es'));
      expect(find.text('Punto'), findsOneWidget);
      expect(find.text('Seleccionar'), findsOneWidget);
    });

    testWidgets('MobileAppBar overflow menu contains Language option',
        (WidgetTester tester) async {
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
              ),
              body: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Open overflow menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Dil: Türkçe'), findsOneWidget);

      // Tap language option
      await tester.tap(find.text('Dil: Türkçe'));
      await tester.pumpAndSettle();

      expect(find.byType(LanguageSelectionDialog), findsOneWidget);
    });
  });
}
