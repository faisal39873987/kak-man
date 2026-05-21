import 'dart:math' as math;

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../../audio/audio_manifest.dart';

class ReactiveAudioSystem {
  double musicIntensity = 0;
  bool assetPlaybackEnabled = false;
  bool hapticsEnabled = true;
  double masterVolume = 0.82;

  final SoLoud _soloud = SoLoud.instance;
  final Map<AudioCue, AudioSource> _sources = <AudioCue, AudioSource>{};
  final Map<AudioCue, double> _cooldowns = <AudioCue, double>{};

  Future<void> initialize() async {
    FlameAudio.bgm.initialize();
    await _initializeSoLoud();
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
    for (final entry in Map<AudioCue, double>.of(_cooldowns).entries) {
      final next = entry.value - dt;
      if (next <= 0) {
        _cooldowns.remove(entry.key);
      } else {
        _cooldowns[entry.key] = next;
      }
    }
  }

  Future<void> cue(AudioCue cue) async {
    if (_cooldowns.containsKey(cue)) {
      return;
    }
    final mix =
        AudioManifest.cueMixes[cue] ??
        const AudioCueMix(volume: 0.35, cooldown: 0.04);
    _cooldowns[cue] = mix.cooldown;

    await _playHaptic(cue);
    if (_playAsset(cue, mix)) {
      return;
    }
    await _playSystemFallback(cue);
  }

  void setMasterVolume(double value) {
    masterVolume = value.clamp(0, 1).toDouble();
  }

  void setHapticsEnabled({required bool enabled}) {
    hapticsEnabled = enabled;
  }

  Future<void> _initializeSoLoud() async {
    try {
      await _soloud.init(bufferSize: 512);
      for (final entry in AudioManifest.cueAssets.entries) {
        _sources[entry.key] = await _soloud.loadAsset('assets/${entry.value}');
      }
      assetPlaybackEnabled = _sources.isNotEmpty;
    } catch (error, stackTrace) {
      assetPlaybackEnabled = false;
      _sources.clear();
      if (kDebugMode) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'one_shot_nerve_runner.audio',
            context: ErrorDescription('initializing SoLoud audio backend'),
          ),
        );
      }
    }
  }

  Future<void> _playHaptic(AudioCue cue) async {
    if (!hapticsEnabled) {
      return;
    }
    switch (cue) {
      case AudioCue.shot:
      case AudioCue.hit:
      case AudioCue.coverHit:
        await HapticFeedback.selectionClick();
      case AudioCue.kill:
        await HapticFeedback.heavyImpact();
      case AudioCue.dash:
        await HapticFeedback.lightImpact();
      case AudioCue.perfectDodge:
        await HapticFeedback.selectionClick();
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
  }

  bool _playAsset(AudioCue cue, AudioCueMix mix) {
    if (!assetPlaybackEnabled) {
      return false;
    }
    final source = _sources[cue];
    if (source == null) {
      return false;
    }
    try {
      _soloud.play(
        source,
        volume: (mix.volume * masterVolume).clamp(0, 1),
        pan: _panForCue(cue),
      );
      return true;
    } catch (error, stackTrace) {
      assetPlaybackEnabled = false;
      if (kDebugMode) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'one_shot_nerve_runner.audio',
            context: ErrorDescription('playing SoLoud cue ${cue.name}'),
          ),
        );
      }
      return false;
    }
  }

  Future<void> _playSystemFallback(AudioCue cue) async {
    switch (cue) {
      case AudioCue.shot:
      case AudioCue.hit:
      case AudioCue.coverHit:
      case AudioCue.perfectDodge:
      case AudioCue.hazardWarning:
      case AudioCue.rewardSelect:
        await SystemSound.play(SystemSoundType.click);
      case AudioCue.kill:
      case AudioCue.dash:
      case AudioCue.playerHurt:
      case AudioCue.roomClear:
      case AudioCue.bossPhase:
      case AudioCue.weaponOverheat:
        break;
    }
  }

  double _panForCue(AudioCue cue) {
    final wobble = math.sin(musicIntensity * math.pi * 2);
    switch (cue) {
      case AudioCue.shot:
      case AudioCue.hit:
      case AudioCue.coverHit:
        return wobble * 0.08;
      case AudioCue.dash:
      case AudioCue.perfectDodge:
        return wobble * 0.12;
      case AudioCue.kill:
      case AudioCue.playerHurt:
      case AudioCue.roomClear:
      case AudioCue.bossPhase:
      case AudioCue.hazardWarning:
      case AudioCue.weaponOverheat:
      case AudioCue.rewardSelect:
        return 0;
    }
  }
}
