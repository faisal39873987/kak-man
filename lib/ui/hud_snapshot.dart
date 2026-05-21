import '../progression/meta_progression.dart';
import '../progression/reward_choice.dart';

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
  bool get choosingReward => rewards.isNotEmpty;

  factory HudSnapshot.initial() => const HudSnapshot(
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
    rewards: <RewardChoice>[],
    progression: MetaProgressionSnapshot(currency: 0, nodes: <MetaNodeState>[]),
    showingProgression: false,
  );
}
