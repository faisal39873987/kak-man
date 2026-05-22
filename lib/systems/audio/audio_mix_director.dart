import 'dart:math' as math;

import '../../audio/audio_manifest.dart';

class AudioMixDirector {
  AudioMixDirector({double masterVolume = 0.82, math.Random? random})
    : _masterVolume = masterVolume.clamp(0, 1).toDouble(),
      _random = random ?? math.Random();

  static const double _cooldownEpsilon = 0.00001;
  static const double _duckingReleasePerSecond = 2.35;

  final math.Random _random;
  final Map<AudioCue, double> _cooldowns = <AudioCue, double>{};
  final Map<AudioBus, double> _ducking = <AudioBus, double>{};

  double _musicIntensity = 0;
  double _masterVolume;

  double get musicIntensity => _musicIntensity;

  double get masterVolume => _masterVolume;

  set masterVolume(double value) {
    _masterVolume = value.clamp(0, 1).toDouble();
  }

  bool isCoolingDown(AudioCue cue) => _cooldowns.containsKey(cue);

  double cooldownRemaining(AudioCue cue) => _cooldowns[cue] ?? 0;

  double duckingFor(AudioBus bus) => _ducking[bus] ?? 0;

  void update({
    required double dt,
    required int activeEnemies,
    required int playerHealth,
    required int combo,
  }) {
    final safeDt = dt.isFinite ? math.max(0, dt) : 0.0;
    final target = _targetIntensity(
      activeEnemies: activeEnemies,
      playerHealth: playerHealth,
      combo: combo,
    );
    final response = target > _musicIntensity ? 4.4 : 1.9;
    _musicIntensity +=
        (target - _musicIntensity) * (safeDt * response).clamp(0, 1);

    for (final entry in Map<AudioCue, double>.of(_cooldowns).entries) {
      final next = entry.value - safeDt;
      if (next <= _cooldownEpsilon) {
        _cooldowns.remove(entry.key);
      } else {
        _cooldowns[entry.key] = next;
      }
    }

    for (final entry in Map<AudioBus, double>.of(_ducking).entries) {
      final next = entry.value - safeDt * _duckingReleasePerSecond;
      if (next <= 0) {
        _ducking.remove(entry.key);
      } else {
        _ducking[entry.key] = next;
      }
    }
  }

  AudioPlaybackPlan? cue(AudioCue cue) {
    if (isCoolingDown(cue)) {
      return null;
    }
    final asset = AudioManifest.cueAssets[cue];
    final mix = AudioManifest.cueMixes[cue];
    if (asset == null || mix == null) {
      return null;
    }

    _cooldowns[cue] = mix.cooldown;
    final plan = AudioPlaybackPlan(
      cue: cue,
      asset: asset,
      bus: mix.bus,
      volume: _volumeFor(mix),
      pan: _panForCue(cue),
      playbackRate: _playbackRateFor(mix),
      priority: mix.priority,
      protectVoice: mix.priority >= 90,
    );
    _applyDucking(mix);
    return plan;
  }

  double _targetIntensity({
    required int activeEnemies,
    required int playerHealth,
    required int combo,
  }) {
    final lowHealthPressure = playerHealth <= 2 ? 0.24 : 0.0;
    return (activeEnemies * 0.11 + combo * 0.024 + lowHealthPressure).clamp(
      0,
      1,
    );
  }

  double _volumeFor(AudioCueMix mix) {
    final busGain = AudioManifest.busVolumes[mix.bus] ?? 1;
    final duckMultiplier = _duckMultiplierFor(mix.bus);
    final intensityMultiplier = 1 + _musicIntensity * mix.intensityGain;
    return (mix.volume *
            _masterVolume *
            busGain *
            duckMultiplier *
            intensityMultiplier)
        .clamp(0, 1)
        .toDouble();
  }

  double _duckMultiplierFor(AudioBus bus) {
    final amount = duckingFor(bus);
    if (amount <= 0) {
      return 1;
    }
    final depth = bus == AudioBus.ui ? 0.12 : 0.56;
    return (1 - amount * depth).clamp(0.34, 1).toDouble();
  }

  double _playbackRateFor(AudioCueMix mix) {
    if (mix.pitchVariance <= 0) {
      return 1;
    }
    final offset = (_random.nextDouble() * 2 - 1) * mix.pitchVariance;
    return (1 + offset).clamp(0.86, 1.16).toDouble();
  }

  void _applyDucking(AudioCueMix mix) {
    if (mix.ducking <= 0) {
      return;
    }
    for (final bus in AudioBus.values) {
      if (bus == mix.bus || bus == AudioBus.ui) {
        continue;
      }
      final weighted = (mix.ducking * _duckingWeight(mix.bus, bus)).clamp(
        0,
        0.85,
      );
      final current = _ducking[bus] ?? 0;
      if (weighted > current) {
        _ducking[bus] = weighted.toDouble();
      }
    }
  }

  double _duckingWeight(AudioBus source, AudioBus target) {
    if (source == AudioBus.stinger) {
      return target == AudioBus.warning ? 0.45 : 1;
    }
    if (source == AudioBus.impact && target == AudioBus.weapon) {
      return 0.92;
    }
    if (source == AudioBus.warning && target == AudioBus.movement) {
      return 0.55;
    }
    return 0.72;
  }

  double _panForCue(AudioCue cue) {
    final wobble = math.sin(_musicIntensity * math.pi * 2);
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

class AudioPlaybackPlan {
  const AudioPlaybackPlan({
    required this.cue,
    required this.asset,
    required this.bus,
    required this.volume,
    required this.pan,
    required this.playbackRate,
    required this.priority,
    required this.protectVoice,
  });

  final AudioCue cue;
  final String asset;
  final AudioBus bus;
  final double volume;
  final double pan;
  final double playbackRate;
  final int priority;
  final bool protectVoice;
}
