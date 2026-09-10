// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

bool isStandalonePwa() {
  try {
    final isStandalone =
        html.window.matchMedia('(display-mode: standalone)').matches;
    final isFullscreen =
        html.window.matchMedia('(display-mode: fullscreen)').matches;
    final isMinimalUi =
        html.window.matchMedia('(display-mode: minimal-ui)').matches;
    final dynamic nav = html.window.navigator;
    final isIosStandalone = nav.standalone == true;
    return isStandalone || isFullscreen || isMinimalUi || isIosStandalone;
  } catch (_) {
    return false;
  }
}
