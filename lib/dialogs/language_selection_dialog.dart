// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_strings.dart';
import '../providers/locale_provider.dart';

class LanguageSelectionDialog extends ConsumerWidget {
  const LanguageSelectionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const LanguageSelectionDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(localeProvider);
    final strings = ref.watch(stringsProvider);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.language, size: 22, color: Color(0xFF3B82F6)),
          const SizedBox(width: 8),
          Text(
            strings.selectLanguage,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: AppStrings.supportedLanguages.map((lang) {
          final isSelected = lang['code'] == currentLang;
          return RadioListTile<String>(
            value: lang['code']!,
            groupValue: currentLang,
            activeColor: const Color(0xFF3B82F6),
            title: Text(
              lang['name']!,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFF3B82F6) : Colors.black87,
              ),
            ),
            onChanged: (val) {
              if (val != null) {
                ref.read(localeProvider.notifier).setLocale(val);
                Navigator.of(context).pop();
              }
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.close),
        ),
      ],
    );
  }
}
