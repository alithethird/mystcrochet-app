import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crochet_charts/providers/version_provider.dart';
import 'package:crochet_charts/widgets/build_version_badge.dart';

void main() {
  group('Build Version Badge Tests', () {
    testWidgets('BuildVersionBadge displays default or fallback version', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: BuildVersionBadge(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BuildVersionBadge), findsOneWidget);
      expect(find.text(kDefaultVersion), findsOneWidget);
    });

    testWidgets('BuildVersionBadge displays overridden version from provider', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appVersionProvider.overrideWith((ref) => Future.value('v1.2.3+42')),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: BuildVersionBadge(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BuildVersionBadge), findsOneWidget);
      expect(find.text('v1.2.3+42'), findsOneWidget);
    });
  });
}
