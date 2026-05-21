import '../progression/player_evolution_system.dart';

class GameSaveData {
  GameSaveData({
    required this.version,
    required this.bestCombo,
    required this.bestRoom,
    required this.totalKills,
    required this.evolution,
    required this.metaProgression,
  });

  final int version;
  final int bestCombo;
  final int bestRoom;
  final int totalKills;
  final Map<String, Object> evolution;
  final Map<String, Object> metaProgression;

  factory GameSaveData.fresh() => GameSaveData(
    version: 1,
    bestCombo: 0,
    bestRoom: 1,
    totalKills: 0,
    evolution: PlayerEvolutionSystem().toJson(),
    metaProgression: const <String, Object>{
      'currency': 0,
      'unlocked': <String>[],
    },
  );

  factory GameSaveData.fromJson(Map<String, Object?> json) => GameSaveData(
    version: (json['version'] as num?)?.toInt() ?? 1,
    bestCombo: (json['bestCombo'] as num?)?.toInt() ?? 0,
    bestRoom: (json['bestRoom'] as num?)?.toInt() ?? 1,
    totalKills: (json['totalKills'] as num?)?.toInt() ?? 0,
    evolution:
        (json['evolution'] as Map?)?.cast<String, Object>() ??
        PlayerEvolutionSystem().toJson(),
    metaProgression:
        (json['metaProgression'] as Map?)?.cast<String, Object>() ??
        const <String, Object>{'currency': 0, 'unlocked': <String>[]},
  );

  Map<String, Object> toJson() => <String, Object>{
    'version': version,
    'bestCombo': bestCombo,
    'bestRoom': bestRoom,
    'totalKills': totalKills,
    'evolution': evolution,
    'metaProgression': metaProgression,
  };

  GameSaveData mergeRun({
    required int combo,
    required int room,
    required int kills,
    required PlayerEvolutionSystem evolutionSystem,
    required Map<String, Object> metaProgression,
  }) {
    return GameSaveData(
      version: version,
      bestCombo: combo > bestCombo ? combo : bestCombo,
      bestRoom: room > bestRoom ? room : bestRoom,
      totalKills: totalKills + kills,
      evolution: evolutionSystem.toJson(),
      metaProgression: metaProgression,
    );
  }
}
