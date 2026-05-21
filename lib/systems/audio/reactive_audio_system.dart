import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';

import '../../audio/audio_manifest.dart';

class ReactiveAudioSystem {
  double musicIntensity = 0;
  bool assetPlaybackEnabled = false;

  Future<void> initialize() async {
    FlameAudio.bgm.initialize();
  }

  void update({
    required double dt,
    required int activeEnemies,
    required int playerHealth,
    required int combo,
  }) {
    final target =
        (activeEnemies * 0.11 + combo * 0.025 + (playerHealth <= 2 ? 0.22 : 0))
            .clamp(0, 1);
    musicIntensity += (target - musicIntensity) * (dt * 3.5).clamp(0, 1);
  }

  Future<void> cue(AudioCue cue) async {
    switch (cue) {
      case AudioCue.shot:
      case AudioCue.hit:
      case AudioCue.coverHit:
        await SystemSound.play(SystemSoundType.click);
      case AudioCue.kill:
        await HapticFeedback.heavyImpact();
      case AudioCue.dash:
        await HapticFeedback.lightImpact();
      case AudioCue.playerHurt:
        await HapticFeedback.mediumImpact();
      case AudioCue.roomClear:
      case AudioCue.rewardSelect:
        await HapticFeedback.mediumImpact();
      case AudioCue.bossPhase:
      case AudioCue.weaponOverheat:
        await HapticFeedback.vibrate();
      case AudioCue.hazardWarning:
        await HapticFeedback.selectionClick();
    }

    if (!assetPlaybackEnabled) {
      return;
    }
    final asset = AudioManifest.cueAssets[cue];
    if (asset != null) {
      await FlameAudio.play(asset);
    }
  }
}
