import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';
import '../providers/locale_provider.dart';

class TutorialStep {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final List<String> highlights;

  const TutorialStep({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.highlights,
  });
}

class WelcomeTutorialDialog extends StatefulWidget {
  final bool initialDontShowAgain;

  const WelcomeTutorialDialog({
    super.key,
    this.initialDontShowAgain = true,
  });

  static const String prefsKey = 'crochet_charts_has_seen_welcome_tutorial';

  static Future<bool> shouldShow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(prefsKey) ?? false);
    } catch (_) {
      return true;
    }
  }

  static Future<void> markSeen({bool seen = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefsKey, seen);
    } catch (_) {}
  }

  static Future<void> showIfFirstTime(BuildContext context) async {
    final needsShow = await shouldShow();
    if (needsShow && context.mounted) {
      await show(context);
    }
  }

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const WelcomeTutorialDialog(),
    );
  }

  @override
  State<WelcomeTutorialDialog> createState() => _WelcomeTutorialDialogState();
}

class _WelcomeTutorialDialogState extends State<WelcomeTutorialDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late bool _dontShowAgain;

  @override
  void initState() {
    super.initState();
    _dontShowAgain = widget.initialDontShowAgain;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() {
    if (_dontShowAgain) {
      WelcomeTutorialDialog.markSeen(seen: true);
    }
    Navigator.of(context).pop();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasScope = false;
    try {
      ProviderScope.containerOf(context, listen: false);
      hasScope = true;
    } catch (_) {}

    if (hasScope) {
      return Consumer(
        builder: (context, ref, _) {
          final strings = ref.watch(stringsProvider);
          return _buildDialog(context, strings);
        },
      );
    }
    return _buildDialog(context, const AppStrings('tr'));
  }

  Widget _buildDialog(BuildContext context, AppStrings strings) {
    final steps = [
      TutorialStep(
        icon: Icons.auto_awesome,
        iconColor: const Color(0xFF8B5CF6),
        title: strings.tutorialWelcomeTitle,
        description: strings.tutorialWelcomeDesc,
        highlights: [
          strings.tutorialWelcomeH1,
          strings.tutorialWelcomeH2,
          strings.tutorialWelcomeH3,
        ],
      ),
      TutorialStep(
        icon: Icons.touch_app_outlined,
        iconColor: const Color(0xFF3B82F6),
        title: strings.tutorialStep2Title,
        description: strings.tutorialStep2Desc,
        highlights: [
          strings.tutorialStep2H1,
          strings.tutorialStep2H2,
          strings.tutorialStep2H3,
        ],
      ),
      TutorialStep(
        icon: Icons.hexagon_outlined,
        iconColor: const Color(0xFF10B981),
        title: strings.tutorialStep3Title,
        description: strings.tutorialStep3Desc,
        highlights: [
          strings.tutorialStep3H1,
          strings.tutorialStep3H2,
          strings.tutorialStep3H3,
        ],
      ),
      TutorialStep(
        icon: Icons.pinch_outlined,
        iconColor: const Color(0xFFF59E0B),
        title: strings.tutorialStep4Title,
        description: strings.tutorialStep4Desc,
        highlights: [
          strings.tutorialStep4H1,
          strings.tutorialStep4H2,
          strings.tutorialStep4H3,
        ],
      ),
    ];
    final isLast = _currentPage == steps.length - 1;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 440,
          maxHeight: 520,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: Step counter & Close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: steps[_currentPage].iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentPage + 1} / ${steps.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: steps[_currentPage].iconColor,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('welcome_tutorial_close_button'),
                    icon: const Icon(Icons.close, size: 20, color: Color(0xFF666666)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: _finish,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // PageView Content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemCount: steps.length,
                  itemBuilder: (context, index) {
                    final step = steps[index];
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: step.iconColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(step.icon, size: 36, color: step.iconColor),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            step.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            step.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF475569),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: step.highlights
                                  .map(
                                    (h) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('• ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF3B82F6))),
                                          Expanded(
                                            child: Text(
                                              h,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF334155),
                                                height: 1.35,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Page Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(steps.length, (index) {
                  final active = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? steps[_currentPage].iconColor
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),

              // "Bir daha gösterme" checkbox
              InkWell(
                onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _dontShowAgain,
                          onChanged: (v) =>
                              setState(() => _dontShowAgain = v ?? true),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          strings.tutorialDontShowAgain,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Bottom buttons row: Geri / Geç / İleri / Başla
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      key: const ValueKey('welcome_tutorial_prev_button'),
                      onPressed: _prevPage,
                      child: Text(strings.tutorialBack),
                    )
                  else
                    TextButton(
                      key: const ValueKey('welcome_tutorial_skip_button'),
                      onPressed: _finish,
                      child: Text(strings.tutorialSkip, style: const TextStyle(color: Color(0xFF94A3B8))),
                    ),
                  ElevatedButton(
                    key: const ValueKey('welcome_tutorial_next_button'),
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    child: Text(
                      isLast ? strings.tutorialStart : strings.tutorialNext,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
