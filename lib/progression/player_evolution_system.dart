import '../core/config/game_constants.dart';

enum EvolutionTrait {
  blinkRunner,
  deadeye,
  bloodPressure,
  lastNerve,
  speedChemistry,
}

class PlayerBehaviorProfile {
  int shotsFired = 0;
  int shotsHit = 0;
  int dashes = 0;
  int closeRangeKills = 0;
  int lowHealthSeconds = 0;
  double _lowHealthTime = 0;
  double runTime = 0;
  double distanceTravelled = 0;
  int roomsCleared = 0;

  double get accuracy => shotsFired == 0 ? 0 : shotsHit / shotsFired;
  double get aggression => runTime <= 0 ? 0 : closeRangeKills / runTime;
  double get dashRate => runTime <= 0 ? 0 : dashes / runTime;
  double get pace => runTime <= 0 ? 0 : roomsCleared / runTime;

  Map<String, Object> toJson() => <String, Object>{
    'shotsFired': shotsFired,
    'shotsHit': shotsHit,
    'dashes': dashes,
    'closeRangeKills': closeRangeKills,
    'lowHealthSeconds': lowHealthSeconds,
    'runTime': runTime,
    'distanceTravelled': distanceTravelled,
    'roomsCleared': roomsCleared,
  };

  void absorb(Map<String, Object?> json) {
    shotsFired = (json['shotsFired'] as num?)?.toInt() ?? shotsFired;
    shotsHit = (json['shotsHit'] as num?)?.toInt() ?? shotsHit;
    dashes = (json['dashes'] as num?)?.toInt() ?? dashes;
    closeRangeKills =
        (json['closeRangeKills'] as num?)?.toInt() ?? closeRangeKills;
    lowHealthSeconds =
        (json['lowHealthSeconds'] as num?)?.toInt() ?? lowHealthSeconds;
    _lowHealthTime = lowHealthSeconds.toDouble();
    runTime = (json['runTime'] as num?)?.toDouble() ?? runTime;
    distanceTravelled =
        (json['distanceTravelled'] as num?)?.toDouble() ?? distanceTravelled;
    roomsCleared = (json['roomsCleared'] as num?)?.toInt() ?? roomsCleared;
  }
}

class PlayerEvolutionSystem {
  final PlayerBehaviorProfile profile = PlayerBehaviorProfile();
  final Set<EvolutionTrait> traits = <EvolutionTrait>{};

  double dashCostMultiplier = 1;
  double shotDamageMultiplier = 1;
  double lowHealthDamageReduction = 1;
  double staminaRegenMultiplier = 1;

  void update(double dt, {required int currentHealth, required double speed}) {
    profile.runTime += dt;
    profile.distanceTravelled += speed * dt;
    if (currentHealth <= GameConstants.lowHealthThreshold) {
      profile._lowHealthTime += dt;
      profile.lowHealthSeconds = profile._lowHealthTime.floor();
    }
    _evaluate();
  }

  void registerDash() {
    profile.dashes += 1;
    _evaluate();
  }

  void registerShot() {
    profile.shotsFired += 1;
    _evaluate();
  }

  void registerHit() {
    profile.shotsHit += 1;
    _evaluate();
  }

  void registerKill({required double distanceToPlayer}) {
    if (distanceToPlayer < 3.1) {
      profile.closeRangeKills += 1;
    }
    _evaluate();
  }

  void registerRoomClear() {
    profile.roomsCleared += 1;
    _evaluate();
  }

  void _evaluate() {
    if (profile.dashRate > 0.8 && traits.add(EvolutionTrait.blinkRunner)) {
      dashCostMultiplier = 0.82;
    }
    if (profile.shotsFired >= 12 &&
        profile.accuracy >= 0.62 &&
        traits.add(EvolutionTrait.deadeye)) {
      shotDamageMultiplier = 1.22;
    }
    if (profile.aggression > 0.12 && traits.add(EvolutionTrait.bloodPressure)) {
      staminaRegenMultiplier = 1.18;
    }
    if (profile.lowHealthSeconds >= 8 && traits.add(EvolutionTrait.lastNerve)) {
      lowHealthDamageReduction = 0.72;
    }
    if (profile.roomsCleared >= 2 &&
        profile.pace > 0.012 &&
        traits.add(EvolutionTrait.speedChemistry)) {
      staminaRegenMultiplier = 1.28;
    }
  }

  String get activeTraitLabel {
    if (traits.isEmpty) {
      return 'UNMUTATED';
    }
    return traits.last.name.toUpperCase();
  }

  Map<String, Object> toJson() => <String, Object>{
    'profile': profile.toJson(),
    'traits': traits.map((trait) => trait.name).toList(),
  };

  void absorb(Map<String, Object?> json) {
    final profileJson = json['profile'];
    if (profileJson is Map) {
      profile.absorb(profileJson.cast<String, Object?>());
    }
    final traitNames = json['traits'];
    if (traitNames is List) {
      traits
        ..clear()
        ..addAll(traitNames.whereType<String>().map(_traitFromName).nonNulls);
    }
    _evaluate();
  }

  EvolutionTrait? _traitFromName(String name) {
    for (final trait in EvolutionTrait.values) {
      if (trait.name == name) {
        return trait;
      }
    }
    return null;
  }
}
