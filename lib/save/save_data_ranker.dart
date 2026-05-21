import 'game_save_data.dart';

class SaveDataRanker {
  const SaveDataRanker._();

  static GameSaveData richest(GameSaveData local, GameSaveData remote) {
    if (_score(remote) > _score(local)) {
      return remote;
    }
    return local;
  }

  static int _score(GameSaveData data) {
    return data.totalKills +
        data.bestCombo * 10 +
        data.bestRoom * 100 +
        _metaCurrency(data) +
        _unlockedCount(data) * 500;
  }

  static int _metaCurrency(GameSaveData data) {
    final currency = data.metaProgression['currency'];
    return (currency as num?)?.toInt() ?? 0;
  }

  static int _unlockedCount(GameSaveData data) {
    final unlocked = data.metaProgression['unlocked'];
    return unlocked is Iterable ? unlocked.length : 0;
  }
}
