import 'dart:math' as math;

import '../core/config/game_constants.dart';
import '../core/math/vector_math.dart';
import '../entities/projectiles/bullet_projectile.dart';
import 'weapon.dart';
import 'weapon_blueprint.dart';
import 'weapon_upgrade.dart';

class BlueprintWeapon implements Weapon {
  BlueprintWeapon(
    this.blueprint, {
    WeaponTuning tuning = const WeaponTuning(),
    Iterable<WeaponUpgrade> upgrades = const <WeaponUpgrade>[],
  }) : _tuning = tuning {
    for (final upgrade in upgrades) {
      addUpgrade(upgrade);
    }
  }

  final WeaponBlueprint blueprint;
  final Set<WeaponUpgrade> _upgrades = <WeaponUpgrade>{};
  double _cooldown = 0;
  double _heat = 0;
  bool _overheated = false;
  WeaponTuning _tuning;

  @override
  String get id => blueprint.id;

  @override
  String get name => blueprint.name;

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
    final coolingRate =
        (_overheated
            ? blueprint.overheatedCoolingRate
            : blueprint.coolingRate) *
        _tuning.coolingMultiplier;
    _heat = (_heat - dt * coolingRate).clamp(0, 1);
    if (_overheated && _heat <= blueprint.overheatRecoveryThreshold) {
      _overheated = false;
    }
  }

  @override
  bool tryFire(WeaponFireContext context) {
    final cooldown = blueprint.baseCooldown * _upgrades.cooldownMultiplier;
    if (_cooldown > 0 || _overheated || _heat >= 1) {
      if (_heat >= 1) {
        _overheated = true;
      }
      return false;
    }

    _cooldown = cooldown;
    _heat = (_heat + blueprint.heatPerShot * _tuning.heatPerShotMultiplier)
        .clamp(0, 1);
    if (_heat >= 1) {
      _overheated = true;
    }

    final pelletCount = blueprint.pelletCount(_upgrades);
    for (var i = 0; i < pelletCount; i += 1) {
      final radians =
          context.direction.angleRadians() + _spreadOffset(i, pelletCount);
      final direction = fromRadians(radians).normalizedOrZero();
      context.spawn(
        BulletProjectile(
          position:
              context.origin + direction * blueprint.projectile.muzzleOffset,
          direction: direction,
          damage:
              blueprint.projectile.damage *
              context.damageScale *
              _upgrades.damageMultiplier,
          speed:
              GameConstants.bulletSpeed *
              blueprint.projectile.speedMultiplier *
              (1 + math.min(_heat, 0.4) * blueprint.projectile.heatSpeedBonus),
        ),
      );
    }
    return true;
  }

  @override
  void addUpgrade(WeaponUpgrade upgrade) {
    if (!blueprint.supportsUpgrade(upgrade)) {
      return;
    }
    _upgrades.add(upgrade);
  }

  double _spreadOffset(int index, int pelletCount) {
    if (pelletCount <= 1 || blueprint.spreadRadians == 0) {
      return 0;
    }
    final step = (blueprint.spreadRadians * 2) / (pelletCount - 1);
    return -blueprint.spreadRadians + step * index;
  }
}
