import 'dart:ui';

import '../core/theme/game_theme.dart';

enum EnemyBehavior { stalker, cutter, bulwark, boss }

class EnemyArchetype {
  const EnemyArchetype({
    required this.id,
    required this.behavior,
    required this.health,
    required this.speed,
    required this.damage,
    required this.color,
    required this.score,
    required this.attackStartRange,
    required this.attackReach,
    required this.attackWindup,
    required this.attackActiveTime,
    required this.attackRecovery,
    required this.attackCooldown,
    required this.lungeSpeed,
    required this.orbitStrength,
  });

  final String id;
  final EnemyBehavior behavior;
  final double health;
  final double speed;
  final int damage;
  final Color color;
  final int score;
  final double attackStartRange;
  final double attackReach;
  final double attackWindup;
  final double attackActiveTime;
  final double attackRecovery;
  final double attackCooldown;
  final double lungeSpeed;
  final double orbitStrength;

  static const EnemyArchetype stalker = EnemyArchetype(
    id: 'stalker',
    behavior: EnemyBehavior.stalker,
    health: 2,
    speed: 1,
    damage: 1,
    color: GameTheme.magenta,
    score: 100,
    attackStartRange: 1.25,
    attackReach: 1.08,
    attackWindup: 0.36,
    attackActiveTime: 0.08,
    attackRecovery: 0.28,
    attackCooldown: 0.76,
    lungeSpeed: 11.5,
    orbitStrength: 1.1,
  );

  static const EnemyArchetype cutter = EnemyArchetype(
    id: 'cutter',
    behavior: EnemyBehavior.cutter,
    health: 1.35,
    speed: 1.28,
    damage: 1,
    color: GameTheme.warning,
    score: 130,
    attackStartRange: 2.35,
    attackReach: 1.18,
    attackWindup: 0.28,
    attackActiveTime: 0.16,
    attackRecovery: 0.34,
    attackCooldown: 0.92,
    lungeSpeed: 15.8,
    orbitStrength: 3.3,
  );

  static const EnemyArchetype bulwark = EnemyArchetype(
    id: 'bulwark',
    behavior: EnemyBehavior.bulwark,
    health: 4.5,
    speed: 0.72,
    damage: 2,
    color: GameTheme.blood,
    score: 220,
    attackStartRange: 4.7,
    attackReach: 1.34,
    attackWindup: 0.64,
    attackActiveTime: 0.36,
    attackRecovery: 0.58,
    attackCooldown: 1.28,
    lungeSpeed: 17.5,
    orbitStrength: 0.25,
  );
}
