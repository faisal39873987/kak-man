class DynamicDifficultySystem {
  double intensity = 0.2;
  double directorPressure = 0;
  int roomsCleared = 0;

  void update({
    required double dt,
    required int playerHealth,
    required double playerAccuracy,
    required int activeEnemies,
    required int combo,
  }) {
    final survivalRelief = playerHealth <= 2 ? -0.22 : 0.04;
    final executionPressure = (playerAccuracy - 0.45).clamp(-0.18, 0.24);
    final comboPressure = (combo / 18).clamp(0, 0.2);
    final crowdRelief = activeEnemies > targetEnemyCount ? -0.12 : 0.04;
    final target =
        (0.28 +
                roomsCleared * 0.055 +
                survivalRelief +
                executionPressure +
                comboPressure +
                crowdRelief)
            .clamp(0.18, 1.45);

    intensity += (target - intensity) * (1 - powDecay(0.06, dt));
    directorPressure = (directorPressure + dt * (0.35 + intensity * 0.2)).clamp(
      0,
      8 + roomsCleared * 1.5,
    );
  }

  int get targetEnemyCount => (3 + roomsCleared * 0.8 + intensity * 3).round();
  double get enemySpeedMultiplier => 0.92 + intensity * 0.22;
  double get enemyHealthMultiplier =>
      0.9 + roomsCleared * 0.08 + intensity * 0.16;
  double get spawnBudget => 4 + roomsCleared * 1.4 + intensity * 4.5;

  void registerRoomClear() {
    roomsCleared += 1;
    directorPressure = 0;
  }

  static double powDecay(double retainPerSecond, double dt) {
    var value = 1.0;
    var remaining = dt;
    while (remaining > 0) {
      final step = remaining > 1 ? 1.0 : remaining;
      value *= 1 - (1 - retainPerSecond) * step;
      remaining -= step;
    }
    return value;
  }
}
