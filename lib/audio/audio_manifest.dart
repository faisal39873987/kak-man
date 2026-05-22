enum AudioCue {
  shot,
  hit,
  coverHit,
  kill,
  dash,
  perfectDodge,
  playerHurt,
  roomClear,
  bossPhase,
  hazardWarning,
  weaponOverheat,
  rewardSelect,
}

enum AudioBus { weapon, impact, movement, stinger, warning, ui }

class AudioManifest {
  const AudioManifest._();

  static const Map<AudioCue, String> cueAssets = <AudioCue, String>{
    AudioCue.shot: 'audio/shot_snap.wav',
    AudioCue.hit: 'audio/hit_spark.wav',
    AudioCue.coverHit: 'audio/cover_ricochet.wav',
    AudioCue.kill: 'audio/kill_drop.wav',
    AudioCue.dash: 'audio/dash_burn.wav',
    AudioCue.perfectDodge: 'audio/perfect_dodge.wav',
    AudioCue.playerHurt: 'audio/player_hurt.wav',
    AudioCue.roomClear: 'audio/room_clear.wav',
    AudioCue.bossPhase: 'audio/boss_phase.wav',
    AudioCue.hazardWarning: 'audio/hazard_warning.wav',
    AudioCue.weaponOverheat: 'audio/weapon_overheat.wav',
    AudioCue.rewardSelect: 'audio/reward_select.wav',
  };

  static const Map<AudioBus, double> busVolumes = <AudioBus, double>{
    AudioBus.weapon: 0.9,
    AudioBus.impact: 0.92,
    AudioBus.movement: 0.82,
    AudioBus.stinger: 0.96,
    AudioBus.warning: 0.78,
    AudioBus.ui: 0.62,
  };

  static const Map<AudioCue, AudioCueMix> cueMixes = <AudioCue, AudioCueMix>{
    AudioCue.shot: AudioCueMix(
      volume: 0.34,
      cooldown: 0.018,
      bus: AudioBus.weapon,
      priority: 70,
      pitchVariance: 0.018,
      intensityGain: 0.08,
    ),
    AudioCue.hit: AudioCueMix(
      volume: 0.28,
      cooldown: 0.025,
      bus: AudioBus.impact,
      priority: 76,
      pitchVariance: 0.025,
      intensityGain: 0.14,
    ),
    AudioCue.coverHit: AudioCueMix(
      volume: 0.24,
      cooldown: 0.035,
      bus: AudioBus.impact,
      priority: 58,
      pitchVariance: 0.035,
      intensityGain: 0.08,
    ),
    AudioCue.kill: AudioCueMix(
      volume: 0.52,
      cooldown: 0.06,
      bus: AudioBus.stinger,
      priority: 92,
      pitchVariance: 0.014,
      intensityGain: 0.18,
      ducking: 0.22,
    ),
    AudioCue.dash: AudioCueMix(
      volume: 0.42,
      cooldown: 0.05,
      bus: AudioBus.movement,
      priority: 68,
      pitchVariance: 0.02,
      intensityGain: 0.1,
    ),
    AudioCue.perfectDodge: AudioCueMix(
      volume: 0.48,
      cooldown: 0.08,
      bus: AudioBus.movement,
      priority: 86,
      pitchVariance: 0.012,
      intensityGain: 0.16,
      ducking: 0.12,
    ),
    AudioCue.playerHurt: AudioCueMix(
      volume: 0.5,
      cooldown: 0.08,
      bus: AudioBus.impact,
      priority: 96,
      pitchVariance: 0.01,
      intensityGain: 0.18,
      ducking: 0.34,
    ),
    AudioCue.roomClear: AudioCueMix(
      volume: 0.44,
      cooldown: 0.18,
      bus: AudioBus.stinger,
      priority: 90,
      pitchVariance: 0.008,
      intensityGain: 0.12,
      ducking: 0.3,
    ),
    AudioCue.bossPhase: AudioCueMix(
      volume: 0.58,
      cooldown: 0.2,
      bus: AudioBus.stinger,
      priority: 100,
      pitchVariance: 0.006,
      intensityGain: 0.22,
      ducking: 0.42,
    ),
    AudioCue.hazardWarning: AudioCueMix(
      volume: 0.32,
      cooldown: 0.12,
      bus: AudioBus.warning,
      priority: 88,
      pitchVariance: 0.01,
      intensityGain: 0.16,
      ducking: 0.08,
    ),
    AudioCue.weaponOverheat: AudioCueMix(
      volume: 0.36,
      cooldown: 0.16,
      bus: AudioBus.warning,
      priority: 82,
      pitchVariance: 0.012,
      intensityGain: 0.12,
      ducking: 0.16,
    ),
    AudioCue.rewardSelect: AudioCueMix(
      volume: 0.32,
      cooldown: 0.08,
      bus: AudioBus.ui,
      priority: 54,
      pitchVariance: 0.01,
      intensityGain: 0.04,
    ),
  };
}

class AudioCueMix {
  const AudioCueMix({
    required this.volume,
    required this.cooldown,
    required this.bus,
    required this.priority,
    this.pitchVariance = 0,
    this.intensityGain = 0,
    this.ducking = 0,
  });

  final double volume;
  final double cooldown;
  final AudioBus bus;
  final int priority;
  final double pitchVariance;
  final double intensityGain;
  final double ducking;
}
