import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crochet_charts/dialogs/language_selection_dialog.dart';
import 'package:crochet_charts/dialogs/welcome_tutorial_dialog.dart';
import 'package:crochet_charts/models/stitch_record.dart';
import 'package:crochet_charts/l10n/app_strings.dart';
import 'package:crochet_charts/providers/locale_provider.dart';
import 'package:crochet_charts/providers/stitch_provider.dart';
import 'package:crochet_charts/widgets/mobile_app_bar.dart';
import 'package:crochet_charts/widgets/panels.dart';
import 'package:crochet_charts/widgets/stitch_palette.dart';
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

    testWidgets('StitchPalette updates strings when locale changes',
        (WidgetTester tester) async {
      final notifier = StitchStoreNotifier();
      notifier.setStitches([
        StitchRecord(
          name: 'sc',
          description: 'Single crochet',
          category: ['default'],
          wrongSide: '',
          svgContent: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/></svg>',
        ),
        StitchRecord(
          name: 'mr',
          description: 'Magic Ring',
          category: ['starters'],
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

      // Turkish default
      expect(find.text('İlmekler'), findsOneWidget);
      expect(find.text('Tümü', skipOffstage: false), findsOneWidget);
      expect(find.text('Standart', skipOffstage: false), findsOneWidget);
      expect(find.text('Başlangıç', skipOffstage: false), findsOneWidget);

      // Change locale to English
      container.read(localeProvider.notifier).state = 'en';
      await tester.pump();

      expect(find.text('Stitches'), findsOneWidget);
      expect(find.text('All', skipOffstage: false), findsOneWidget);
      expect(find.text('Default', skipOffstage: false), findsOneWidget);
      expect(find.text('Starters', skipOffstage: false), findsOneWidget);

      // Change locale to German
      container.read(localeProvider.notifier).state = 'de';
      await tester.pump();

      expect(find.text('Maschen'), findsOneWidget);
      expect(find.text('Alle', skipOffstage: false), findsOneWidget);
      expect(find.text('Standard', skipOffstage: false), findsOneWidget);
      expect(find.text('Anfang', skipOffstage: false), findsOneWidget);

      // Change locale to Spanish
      container.read(localeProvider.notifier).state = 'es';
      await tester.pump();

      expect(find.text('Puntos'), findsOneWidget);
      expect(find.text('Todos', skipOffstage: false), findsOneWidget);
      expect(find.text('Predeterminado', skipOffstage: false), findsOneWidget);
      expect(find.text('Iniciales', skipOffstage: false), findsOneWidget);
    });

    testWidgets('PropertiesPanel and ShapePanel update strings when locale changes',
        (WidgetTester tester) async {
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    PropertiesPanel(),
                    ShapePanel(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Turkish default
      expect(find.text('Ad'), findsOneWidget);
      expect(find.text('Stil'), findsOneWidget);
      expect(find.text('Tur Sayısı'), findsOneWidget);
      expect(find.text('Turlar:'), findsOneWidget);
      expect(find.text('Tur Şekli'), findsOneWidget);

      // Switch to English
      container.read(localeProvider.notifier).state = 'en';
      await tester.pump();

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Style'), findsOneWidget);
      expect(find.text('Round Count'), findsOneWidget);
      expect(find.text('Rounds:'), findsOneWidget);
      expect(find.text('Round Shape'), findsOneWidget);

      // Switch to German
      container.read(localeProvider.notifier).state = 'de';
      await tester.pump();

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Stil'), findsOneWidget);
      expect(find.text('Rundenzahl'), findsOneWidget);
      expect(find.text('Runden:'), findsOneWidget);
      expect(find.text('Rundenform'), findsOneWidget);

      // Switch to Spanish
      container.read(localeProvider.notifier).state = 'es';
      await tester.pump();

      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('Estilo'), findsOneWidget);
      expect(find.text('Número de vueltas'), findsOneWidget);
      expect(find.text('Vueltas:'), findsOneWidget);
      expect(find.text('Forma de la vuelta'), findsOneWidget);
    });

    testWidgets('WelcomeTutorialDialog updates strings when locale changes',
        (WidgetTester tester) async {
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: WelcomeTutorialDialog(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Turkish default
      expect(find.text("MystCrochet'e Hoş Geldiniz!"), findsOneWidget);
      expect(find.text('Geç'), findsOneWidget);
      expect(find.text('İleri'), findsOneWidget);
      expect(find.text('Bir daha otomatik gösterme'), findsOneWidget);

      // Switch to English
      container.read(localeProvider.notifier).state = 'en';
      await tester.pump();

      expect(find.text('Welcome to MystCrochet!'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Do not show automatically again'), findsOneWidget);

      // Switch to German
      container.read(localeProvider.notifier).state = 'de';
      await tester.pump();

      expect(find.text('Willkommen bei MystCrochet!'), findsOneWidget);
      expect(find.text('Überspringen'), findsOneWidget);
      expect(find.text('Weiter'), findsOneWidget);
      expect(find.text('Nicht mehr automatisch anzeigen'), findsOneWidget);

      // Switch to Spanish
      container.read(localeProvider.notifier).state = 'es';
      await tester.pump();

      expect(find.text('¡Bienvenido a MystCrochet!'), findsOneWidget);
      expect(find.text('Omitir'), findsOneWidget);
      expect(find.text('Siguiente'), findsOneWidget);
      expect(find.text('No mostrar automáticamente de nuevo'), findsOneWidget);
    });
  });
}
