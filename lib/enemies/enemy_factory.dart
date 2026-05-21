import 'dart:math' as math;

import 'package:flame/components.dart';

import '../bosses/nerve_warden_boss.dart';
import '../core/config/game_constants.dart';
import '../systems/difficulty/dynamic_difficulty_system.dart';
import 'adaptive_enemy.dart';
import 'enemy_archetype.dart';

class EnemyFactory {
  EnemyFactory(this.random);

  final math.Random random;

  AdaptiveEnemy create({
    required Vector2 spawn,
    required DynamicDifficultySystem difficulty,
    required int roomSeed,
    bool forceBulwark = false,
    double activationDelay = 0,
  }) {
    final roll = random.nextDouble();
    final archetype = forceBulwark
        ? EnemyArchetype.bulwark
        : roll > 0.82
        ? EnemyArchetype.bulwark
        : roll > 0.52
        ? EnemyArchetype.cutter
        : EnemyArchetype.stalker;
    return AdaptiveEnemy(
      archetype: archetype,
      spawn: spawn,
      difficultyHealth: difficulty.enemyHealthMultiplier,
      roomSeed: roomSeed + random.nextInt(9999),
      activationDelay: activationDelay,
    );
  }

  NerveWardenBoss createBoss({
    required Vector2 spawn,
    required DynamicDifficultySystem difficulty,
    required int roomSeed,
  }) {
    return NerveWardenBoss(
      spawn: spawn,
      difficultyHealth: 1 + difficulty.roomsCleared * 0.12,
      roomSeed: roomSeed,
    );
  }

  bool shouldSpawnBoss(int roomIndex) {
    return roomIndex > 1 && roomIndex % GameConstants.bossRoomInterval == 0;
  }
}
