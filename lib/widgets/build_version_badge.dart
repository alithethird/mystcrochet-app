import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/version_provider.dart';

class BuildVersionBadge extends ConsumerWidget {
  const BuildVersionBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(appVersionProvider);
    final version = versionAsync.valueOrNull ?? kDefaultVersion;

    return Tooltip(
      message: 'Crochet Charts $version',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xD9FFFFFF),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFDDDDDD)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          version,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Color(0xFF777777),
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
