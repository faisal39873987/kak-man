import 'package:flame/components.dart';

import '../entities/projectiles/bullet_projectile.dart';
import 'weapon_upgrade.dart';

class WeaponTuning {
  const WeaponTuning({
    this.heatPerShotMultiplier = 1,
    this.coolingMultiplier = 1,
  });

  final double heatPerShotMultiplier;
  final double coolingMultiplier;
}

class WeaponFireContext {
  const WeaponFireContext({
    required this.origin,
    required this.direction,
    required this.damageScale,
    required this.spawn,
  });

  final Vector2 origin;
  final Vector2 direction;
  final double damageScale;
  final void Function(BulletProjectile projectile) spawn;
}

abstract class Weapon {
  String get id;
  String get name;
  double get heat;
  bool get overheated;
  WeaponTuning get tuning;
  set tuning(WeaponTuning value);
  Set<WeaponUpgrade> get upgrades;

  void update(double dt);
  bool tryFire(WeaponFireContext context);
  void addUpgrade(WeaponUpgrade upgrade);
}
