import 'weapon_upgrade.dart';

class ProjectileBlueprint {
  const ProjectileBlueprint({
    required this.damage,
    required this.speedMultiplier,
    required this.muzzleOffset,
    required this.heatSpeedBonus,
  });

  final double damage;
  final double speedMultiplier;
  final double muzzleOffset;
  final double heatSpeedBonus;

  List<String> validate(String ownerId) {
    final errors = <String>[];
    _requirePositive(errors, ownerId, 'projectile.damage', damage);
    _requirePositive(
      errors,
      ownerId,
      'projectile.speedMultiplier',
      speedMultiplier,
    );
    _requireNonNegative(
      errors,
      ownerId,
      'projectile.muzzleOffset',
      muzzleOffset,
    );
    _requireNonNegative(
      errors,
      ownerId,
      'projectile.heatSpeedBonus',
      heatSpeedBonus,
    );
    return errors;
  }
}

class WeaponBlueprint {
  const WeaponBlueprint({
    required this.id,
    required this.name,
    required this.baseCooldown,
    required this.heatPerShot,
    required this.coolingRate,
    required this.overheatedCoolingRate,
    required this.overheatRecoveryThreshold,
    required this.basePelletCount,
    required this.splitCapacitorBonusPellets,
    required this.spreadRadians,
    required this.projectile,
    required this.supportedUpgrades,
  });

  final String id;
  final String name;
  final double baseCooldown;
  final double heatPerShot;
  final double coolingRate;
  final double overheatedCoolingRate;
  final double overheatRecoveryThreshold;
  final int basePelletCount;
  final int splitCapacitorBonusPellets;
  final double spreadRadians;
  final ProjectileBlueprint projectile;
  final Set<WeaponUpgrade> supportedUpgrades;

  int pelletCount(Set<WeaponUpgrade> upgrades) {
    final splitBonus = upgrades.contains(WeaponUpgrade.splitCapacitor)
        ? splitCapacitorBonusPellets
        : 0;
    return basePelletCount + splitBonus;
  }

  bool supportsUpgrade(WeaponUpgrade upgrade) {
    return supportedUpgrades.contains(upgrade);
  }

  List<String> validate() {
    final errors = <String>[];
    if (id.trim().isEmpty) {
      errors.add('Weapon blueprint id is required.');
    } else if (!RegExp(r'^[a-z0-9_]+$').hasMatch(id)) {
      errors.add('$id.id must use lowercase snake_case.');
    }
    if (name.trim().isEmpty) {
      errors.add('$id.name is required.');
    }
    _requirePositive(errors, id, 'baseCooldown', baseCooldown);
    _requirePositive(errors, id, 'heatPerShot', heatPerShot);
    _requirePositive(errors, id, 'coolingRate', coolingRate);
    _requirePositive(
      errors,
      id,
      'overheatedCoolingRate',
      overheatedCoolingRate,
    );
    if (!overheatRecoveryThreshold.isFinite ||
        overheatRecoveryThreshold < 0 ||
        overheatRecoveryThreshold > 1) {
      errors.add('$id.overheatRecoveryThreshold must be between 0 and 1.');
    }
    if (basePelletCount < 1) {
      errors.add('$id.basePelletCount must be at least 1.');
    }
    if (splitCapacitorBonusPellets < 0) {
      errors.add('$id.splitCapacitorBonusPellets cannot be negative.');
    }
    _requireNonNegative(errors, id, 'spreadRadians', spreadRadians);
    if (supportedUpgrades.isEmpty) {
      errors.add('$id.supportedUpgrades must include at least one upgrade.');
    }
    errors.addAll(projectile.validate(id));
    return errors;
  }
}

void _requirePositive(
  List<String> errors,
  String ownerId,
  String field,
  double value,
) {
  if (!value.isFinite || value <= 0) {
    errors.add('$ownerId.$field must be positive.');
  }
}

void _requireNonNegative(
  List<String> errors,
  String ownerId,
  String field,
  double value,
) {
  if (!value.isFinite || value < 0) {
    errors.add('$ownerId.$field cannot be negative.');
  }
}
