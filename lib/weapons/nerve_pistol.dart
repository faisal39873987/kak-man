import 'dart:math' as math;

import '../core/config/game_constants.dart';
import '../core/math/vector_math.dart';
import '../entities/projectiles/bullet_projectile.dart';
import 'weapon.dart';
import 'weapon_upgrade.dart';

class NervePistol implements Weapon {
  final Set<WeaponUpgrade> _upgrades = <WeaponUpgrade>{};
  double _cooldown = 0;
  double _heat = 0;
  bool _overheated = false;
  WeaponTuning _tuning = const WeaponTuning();

  @override
  String get name => 'NERVE-9';

  @override
  double get heat => _heat.clamp(0, 1);

  @override
  bool get overheated => _overheated;

  @override
  WeaponTuning get tuning => _tuning;

  @override
  set tuning(WeaponTuning value) {
    _tuning = value;
  }

  @override
  Set<WeaponUpgrade> get upgrades => _upgrades;

  @override
  void update(double dt) {
    _cooldown = (_cooldown - dt).clamp(0, 10);
    final coolingRate = (_overheated ? 2.7 : 1.9) * _tuning.coolingMultiplier;
    _heat = (_heat - dt * coolingRate).clamp(0, 1);
    if (_overheated && _heat <= 0.58) {
      _overheated = false;
    }
  }

  @override
  bool tryFire(WeaponFireContext context) {
    final cooldown = 0.145 * _upgrades.cooldownMultiplier;
    if (_cooldown > 0 || _overheated || _heat >= 1) {
      if (_heat >= 1) {
        _overheated = true;
      }
      return false;
    }

    _cooldown = cooldown;
    _heat = (_heat + 0.19 * _tuning.heatPerShotMultiplier).clamp(0, 1);
    if (_heat >= 1) {
      _overheated = true;
    }

    final pelletCount = _upgrades.pelletCount;
    for (var i = 0; i < pelletCount; i += 1) {
      final spread = pelletCount == 1 ? 0.0 : (i == 0 ? -0.075 : 0.075);
      final radians = context.direction.angleRadians() + spread;
      final direction = fromRadians(radians).normalizedOrZero();
      context.spawn(
        BulletProjectile(
          position: context.origin + direction * 0.62,
          direction: direction,
          damage: 1.0 * context.damageScale * _upgrades.damageMultiplier,
          speed: GameConstants.bulletSpeed * (1 + math.min(_heat, 0.4) * 0.16),
        ),
      );
    }
    return true;
  }

  @override
  void addUpgrade(WeaponUpgrade upgrade) {
    _upgrades.add(upgrade);
  }
}
