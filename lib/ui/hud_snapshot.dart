import '../progression/meta_progression.dart';
import '../progression/reward_choice.dart';
import '../save/save_sync_status.dart';

class HudSnapshot {
  const HudSnapshot({
    required this.health,
    required this.maxHealth,
    required this.stamina,
    required this.combo,
    required this.comboTimer,
    required this.score,
    required this.room,
    required this.kills,
    required this.runNerve,
    required this.bestCombo,
    required this.bestRoom,
    required this.heat,
    required this.weaponOverheated,
    required this.difficulty,
    required this.musicIntensity,
    required this.traitLabel,
    required this.weaponName,
    required this.paused,
    required this.dead,
    required this.rewards,
    required this.progression,
    required this.showingProgression,
    required this.saveSyncStatus,
    required this.runSummary,
  });

  final int health;
  final int maxHealth;
  final double stamina;
  final int combo;
  final double comboTimer;
  final int score;
  final int room;
  final int kills;
  final int runNerve;
  final int bestCombo;
  final int bestRoom;
  final double heat;
  final bool weaponOverheated;
  final double difficulty;
  final double musicIntensity;
  final String traitLabel;
  final String weaponName;
  final bool paused;
  final bool dead;
  final List<RewardChoice> rewards;
  final MetaProgressionSnapshot progression;
  final bool showingProgression;
  final SaveSyncStatus saveSyncStatus;
  final RunSummary runSummary;
  bool get choosingReward => rewards.isNotEmpty;

  HudSnapshot copyWith({
    int? health,
    int? maxHealth,
    double? stamina,
    int? combo,
    double? comboTimer,
    int? score,
    int? room,
    int? kills,
    int? runNerve,
    int? bestCombo,
    int? bestRoom,
    double? heat,
    bool? weaponOverheated,
    double? difficulty,
    double? musicIntensity,
    String? traitLabel,
    String? weaponName,
    bool? paused,
    bool? dead,
    List<RewardChoice>? rewards,
    MetaProgressionSnapshot? progression,
    bool? showingProgression,
    SaveSyncStatus? saveSyncStatus,
    RunSummary? runSummary,
  }) {
    return HudSnapshot(
      health: health ?? this.health,
      maxHealth: maxHealth ?? this.maxHealth,
      stamina: stamina ?? this.stamina,
      combo: combo ?? this.combo,
      comboTimer: comboTimer ?? this.comboTimer,
      score: score ?? this.score,
      room: room ?? this.room,
      kills: kills ?? this.kills,
      runNerve: runNerve ?? this.runNerve,
      bestCombo: bestCombo ?? this.bestCombo,
      bestRoom: bestRoom ?? this.bestRoom,
      heat: heat ?? this.heat,
      weaponOverheated: weaponOverheated ?? this.weaponOverheated,
      difficulty: difficulty ?? this.difficulty,
      musicIntensity: musicIntensity ?? this.musicIntensity,
      traitLabel: traitLabel ?? this.traitLabel,
      weaponName: weaponName ?? this.weaponName,
      paused: paused ?? this.paused,
      dead: dead ?? this.dead,
      rewards: rewards ?? this.rewards,
      progression: progression ?? this.progression,
      showingProgression: showingProgression ?? this.showingProgression,
      saveSyncStatus: saveSyncStatus ?? this.saveSyncStatus,
      runSummary: runSummary ?? this.runSummary,
    );
  }

  factory HudSnapshot.initial() {
    return HudSnapshot(
      health: 5,
      maxHealth: 5,
      stamina: 1,
      combo: 0,
      comboTimer: 0,
      score: 0,
      room: 1,
      kills: 0,
      runNerve: 0,
      bestCombo: 0,
      bestRoom: 1,
      heat: 0,
      weaponOverheated: false,
      difficulty: 0,
      musicIntensity: 0,
      traitLabel: 'UNMUTATED',
      weaponName: 'NERVE-9',
      paused: false,
      dead: false,
      rewards: const <RewardChoice>[],
      progression: MetaProgressionSystem().snapshot(),
      showingProgression: false,
      saveSyncStatus: SaveSyncStatus.localOnly,
      runSummary: RunSummary.initial(),
    );
  }
}

class RunSummary {
  const RunSummary({
    required this.score,
    required this.roomReached,
    required this.kills,
    required this.nerveEarned,
    required this.bestCombo,
    required this.bestRoom,
    required this.secondsSurvived,
    required this.shotsFired,
    required this.shotsHit,
    required this.dashes,
    required this.perfectDodges,
    required this.lowHealthSeconds,
    required this.traitLabel,
  });

  final int score;
  final int roomReached;
  final int kills;
  final int nerveEarned;
  final int bestCombo;
  final int bestRoom;
  final double secondsSurvived;
  final int shotsFired;
  final int shotsHit;
  final int dashes;
  final int perfectDodges;
  final int lowHealthSeconds;
  final String traitLabel;

  int get accuracyPercent =>
      shotsFired <= 0 ? 0 : ((shotsHit / shotsFired) * 100).round();

  static RunSummary initial() {
    return const RunSummary(
      score: 0,
      roomReached: 1,
      kills: 0,
      nerveEarned: 0,
      bestCombo: 0,
      bestRoom: 1,
      secondsSurvived: 0,
      shotsFired: 0,
      shotsHit: 0,
      dashes: 0,
      perfectDodges: 0,
      lowHealthSeconds: 0,
      traitLabel: 'UNMUTATED',
    );
  }
}
