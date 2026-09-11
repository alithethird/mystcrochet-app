import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

enum SoundEffect {
  stitchPop('sounds/stitch_pop.wav'),
  delete('sounds/delete.wav'),
  addRound('sounds/add_round.wav'),
  click('sounds/click.wav'),
  success('sounds/success.wav');

  final String assetPath;
  const SoundEffect(this.assetPath);
}

class SoundEffectsNotifier extends StateNotifier<bool> {
  static const String _prefKey = 'sound_effects_enabled';

  SoundEffectsNotifier([super.initial = true]) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_prefKey)) {
        state = prefs.getBool(_prefKey) ?? true;
      }
    } catch (_) {}
  }

  Future<void> toggle() async {
    await setEnabled(!state);
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, enabled);
    } catch (_) {}
  }
}

final soundEffectsEnabledProvider =
    StateNotifierProvider<SoundEffectsNotifier, bool>((ref) {
  return SoundEffectsNotifier();
});

class SoundService {
  final Ref _ref;
  AudioPlayer? _player;

  SoundService(this._ref);

  bool get _isTest {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  Future<void> play(SoundEffect effect) async {
    final enabled = _ref.read(soundEffectsEnabledProvider);
    if (!enabled || _isTest) return;

    try {
      final player = AudioPlayer();
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.play(AssetSource(effect.assetPath));
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (_) {
      // Fallback silently if audio cannot be played
    }
  }

  void dispose() {
    _player?.dispose();
    _player = null;
  }
}

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});
