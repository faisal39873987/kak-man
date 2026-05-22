import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../../audio/audio_manifest.dart';
import 'audio_mix_director.dart';

class ReactiveAudioSystem {
  ReactiveAudioSystem({AudioMixDirector? director})
    : _director = director ?? AudioMixDirector();

  bool assetPlaybackEnabled = false;
  bool hapticsEnabled = true;

  final AudioMixDirector _director;
  final SoLoud _soloud = SoLoud.instance;
  final Map<AudioCue, AudioSource> _sources = <AudioCue, AudioSource>{};
  final Map<AudioBus, Bus> _buses = <AudioBus, Bus>{};

  double get musicIntensity => _director.musicIntensity;

  double get masterVolume => _director.masterVolume;

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
    _director.update(
      dt: dt,
      activeEnemies: activeEnemies,
      playerHealth: playerHealth,
      combo: combo,
    );
  }

  Future<void> cue(AudioCue cue) async {
    final plan = _director.cue(cue);
    if (plan == null) {
      return;
    }

    await _playHaptic(cue);
    if (_playAsset(plan)) {
      return;
    }
    await _playSystemFallback(cue);
  }

  void setMasterVolume(double value) {
    _director.masterVolume = value;
  }

  void setHapticsEnabled({required bool enabled}) {
    hapticsEnabled = enabled;
  }

  Future<void> _initializeSoLoud() async {
    try {
      await _soloud.init(bufferSize: 512);
      _soloud.setMaxActiveVoiceCount(32);
      _initializeBuses();
      for (final entry in AudioManifest.cueAssets.entries) {
        _sources[entry.key] = await _soloud.loadAsset('assets/${entry.value}');
      }
      assetPlaybackEnabled = _sources.isNotEmpty;
    } catch (error, stackTrace) {
      assetPlaybackEnabled = false;
      _sources.clear();
      _buses.clear();
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

  void _initializeBuses() {
    _buses.clear();
    for (final bus in AudioBus.values) {
      final mixBus = Bus(name: 'nerve_${bus.name}');
      final handle = mixBus.playOnEngine();
      _soloud.setProtectVoice(handle, true);
      _buses[bus] = mixBus;
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

  bool _playAsset(AudioPlaybackPlan plan) {
    if (!assetPlaybackEnabled) {
      return false;
    }
    final source = _sources[plan.cue];
    if (source == null) {
      return false;
    }
    try {
      final bus = _buses[plan.bus];
      final handle = bus == null
          ? _soloud.play(source, volume: plan.volume, pan: plan.pan)
          : bus.play(source, volume: plan.volume, pan: plan.pan);
      if (plan.playbackRate != 1) {
        _soloud.setRelativePlaySpeed(handle, plan.playbackRate);
      }
      if (plan.protectVoice) {
        _soloud.setProtectVoice(handle, true);
      }
      return true;
    } catch (error, stackTrace) {
      assetPlaybackEnabled = false;
      if (kDebugMode) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'one_shot_nerve_runner.audio',
            context: ErrorDescription('playing SoLoud cue ${plan.cue.name}'),
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
}
