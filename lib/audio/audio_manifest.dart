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

  static const Map<AudioCue, AudioCueMix> cueMixes = <AudioCue, AudioCueMix>{
    AudioCue.shot: AudioCueMix(volume: 0.34, cooldown: 0.018),
    AudioCue.hit: AudioCueMix(volume: 0.28, cooldown: 0.025),
    AudioCue.coverHit: AudioCueMix(volume: 0.24, cooldown: 0.035),
    AudioCue.kill: AudioCueMix(volume: 0.52, cooldown: 0.06),
    AudioCue.dash: AudioCueMix(volume: 0.42, cooldown: 0.05),
    AudioCue.perfectDodge: AudioCueMix(volume: 0.48, cooldown: 0.08),
    AudioCue.playerHurt: AudioCueMix(volume: 0.5, cooldown: 0.08),
    AudioCue.roomClear: AudioCueMix(volume: 0.44, cooldown: 0.18),
    AudioCue.bossPhase: AudioCueMix(volume: 0.58, cooldown: 0.2),
    AudioCue.hazardWarning: AudioCueMix(volume: 0.32, cooldown: 0.12),
    AudioCue.weaponOverheat: AudioCueMix(volume: 0.36, cooldown: 0.16),
    AudioCue.rewardSelect: AudioCueMix(volume: 0.32, cooldown: 0.08),
  };
}

class AudioCueMix {
  const AudioCueMix({required this.volume, required this.cooldown});

  final double volume;
  final double cooldown;
}
