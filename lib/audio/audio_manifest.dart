enum AudioCue {
  shot,
  hit,
  coverHit,
  kill,
  dash,
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
    AudioCue.playerHurt: 'audio/player_hurt.wav',
    AudioCue.roomClear: 'audio/room_clear.wav',
    AudioCue.bossPhase: 'audio/boss_phase.wav',
    AudioCue.hazardWarning: 'audio/hazard_warning.wav',
    AudioCue.weaponOverheat: 'audio/weapon_overheat.wav',
    AudioCue.rewardSelect: 'audio/reward_select.wav',
  };
}
