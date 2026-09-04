import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

const String kEnvVersion = String.fromEnvironment('APP_VERSION', defaultValue: '');
const String kDefaultVersion = 'v1.0.6+7';

final appVersionProvider = FutureProvider<String>((ref) async {
  if (kEnvVersion.isNotEmpty) {
    return kEnvVersion.startsWith('v') ? kEnvVersion : 'v$kEnvVersion';
  }
  try {
    final info = await PackageInfo.fromPlatform();
    if (info.version.isNotEmpty) {
      if (info.buildNumber.isNotEmpty) {
        return 'v${info.version}+${info.buildNumber}';
      }
      return 'v${info.version}';
    }
  } catch (_) {
    // In tests or environments where platform channel is unavailable, fallback safely
  }
  return kDefaultVersion;
});
