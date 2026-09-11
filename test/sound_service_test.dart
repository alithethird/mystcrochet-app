import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crochet_charts/l10n/app_strings.dart';
import 'package:crochet_charts/providers/locale_provider.dart';
import 'package:crochet_charts/services/sound_service.dart';
import 'package:crochet_charts/widgets/mobile_app_bar.dart';
import 'package:crochet_charts/widgets/toolbar.dart';

void main() {
  group('SoundService & Sound Effects Tests (Task #49)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('SoundEffectsNotifier defaults to true and toggles / persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(soundEffectsEnabledProvider), isTrue);

      await container.read(soundEffectsEnabledProvider.notifier).toggle();
      expect(container.read(soundEffectsEnabledProvider), isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('sound_effects_enabled'), isFalse);

      await container.read(soundEffectsEnabledProvider.notifier).setEnabled(true);
      expect(container.read(soundEffectsEnabledProvider), isTrue);
      expect(prefs.getBool('sound_effects_enabled'), isTrue);
    });

    test('SoundService can be called safely without throwing errors in test environment', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final soundService = container.read(soundServiceProvider);
      expect(soundService, isNotNull);

      // Should complete without throwing in test environment
      for (final effect in SoundEffect.values) {
        await expectLater(soundService.play(effect), completes);
      }

      // Disabled state
      await container.read(soundEffectsEnabledProvider.notifier).setEnabled(false);
      for (final effect in SoundEffect.values) {
        await expectLater(soundService.play(effect), completes);
      }
    });

    test('AppStrings provides correct sound effect translations for all supported languages', () {
      const tr = AppStrings('tr');
      expect(tr.soundEffects, 'Ses Efektleri');
      expect(tr.soundOn, 'Açık');
      expect(tr.soundOff, 'Kapalı');

      const en = AppStrings('en');
      expect(en.soundEffects, 'Sound Effects');
      expect(en.soundOn, 'On');
      expect(en.soundOff, 'Off');

      const de = AppStrings('de');
      expect(de.soundEffects, 'Soundeffekte');
      expect(de.soundOn, 'Ein');
      expect(de.soundOff, 'Aus');

      const es = AppStrings('es');
      expect(es.soundEffects, 'Efectos de sonido');
      expect(es.soundOn, 'Activado');
      expect(es.soundOff, 'Desactivado');
    });

    testWidgets('AppToolbar Settings menu contains Sound Effects item and toggles state',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

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
      await tester.pumpAndSettle();

      // Open Settings popup menu
      await tester.tap(find.byKey(const ValueKey('toolbar_settings')));
      await tester.pumpAndSettle();

      // Verify Sound Effects menu item is present with "Açık"
      expect(find.byKey(const ValueKey('toolbar_sound_effects')), findsOneWidget);
      expect(find.text('Ses Efektleri: Açık'), findsOneWidget);

      // Tap sound effects menu item to toggle off
      await tester.tap(find.byKey(const ValueKey('toolbar_sound_effects')));
      await tester.pumpAndSettle();

      expect(container.read(soundEffectsEnabledProvider), isFalse);

      // Re-open settings menu to verify it now displays "Kapalı"
      await tester.tap(find.byKey(const ValueKey('toolbar_settings')));
      await tester.pumpAndSettle();
      expect(find.text('Ses Efektleri: Kapalı'), findsOneWidget);
    });

    testWidgets('MobileAppBar overflow menu contains Sound Effects item and toggles state',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MobileAppBar(
                onNew: () {},
                onOpen: () {},
                onSave: () {},
                onSavedDesigns: () {},
                onExportPng: () {},
                onTextView: () {},
                onOpenDrawer: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open overflow menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Verify sound effects option is present
      expect(find.byKey(const ValueKey('mobile_sound_effects')), findsOneWidget);
      expect(find.text('Ses Efektleri: Açık'), findsOneWidget);

      // Toggle sound off
      await tester.tap(find.byKey(const ValueKey('mobile_sound_effects')));
      await tester.pumpAndSettle();

      expect(container.read(soundEffectsEnabledProvider), isFalse);

      // Re-open menu to verify "Kapalı"
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      expect(find.text('Ses Efektleri: Kapalı'), findsOneWidget);
    });

    testWidgets('Sound effects label updates when language is changed',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

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
      await tester.pumpAndSettle();

      // Switch language to English
      container.read(localeProvider.notifier).state = 'en';
      await tester.pumpAndSettle();

      // Open Settings popup
      await tester.tap(find.byKey(const ValueKey('toolbar_settings')));
      await tester.pumpAndSettle();

      expect(find.text('Sound Effects: On'), findsOneWidget);
    });
  });
}
