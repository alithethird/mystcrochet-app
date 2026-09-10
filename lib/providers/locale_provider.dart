import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';

const String kAppLanguagePrefKey = 'app_language';

class LocaleNotifier extends StateNotifier<String> {
  LocaleNotifier([super.initialLocale = 'tr']) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString(kAppLanguagePrefKey);
      if (savedLang != null && ['tr', 'en', 'de', 'es'].contains(savedLang)) {
        state = savedLang;
      }
    } catch (_) {}
  }

  Future<void> setLocale(String languageCode) async {
    if (!['tr', 'en', 'de', 'es'].contains(languageCode)) return;
    state = languageCode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kAppLanguagePrefKey, languageCode);
    } catch (_) {}
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, String>((ref) {
  return LocaleNotifier();
});

final stringsProvider = Provider<AppStrings>((ref) {
  final lang = ref.watch(localeProvider);
  return AppStrings(lang);
});
