import 'weapon_blueprint.dart';
import 'weapon_upgrade.dart';

class WeaponCatalog {
  const WeaponCatalog._();

  static const defaultWeaponId = nervePistolId;
  static const nervePistolId = 'nerve_pistol';
  static const ionStitcherId = 'ion_stitcher';
  static const voltLanceId = 'volt_lance';

  static const _allUpgrades = <WeaponUpgrade>{
    WeaponUpgrade.overpressure,
    WeaponUpgrade.splitCapacitor,
    WeaponUpgrade.nerveRail,
    WeaponUpgrade.bloodRefund,
  };

  static const nervePistol = WeaponBlueprint(
    id: nervePistolId,
    name: 'NERVE-9',
    baseCooldown: 0.145,
    heatPerShot: 0.19,
    coolingRate: 1.9,
    overheatedCoolingRate: 2.7,
    overheatRecoveryThreshold: 0.58,
    basePelletCount: 1,
    splitCapacitorBonusPellets: 1,
    spreadRadians: 0.075,
    projectile: ProjectileBlueprint(
      damage: 1,
      speedMultiplier: 1,
      muzzleOffset: 0.62,
      heatSpeedBonus: 0.16,
    ),
    supportedUpgrades: _allUpgrades,
  );

  static const ionStitcher = WeaponBlueprint(
    id: ionStitcherId,
    name: 'ION STITCHER',
    baseCooldown: 0.105,
    heatPerShot: 0.155,
    coolingRate: 2.15,
    overheatedCoolingRate: 2.95,
    overheatRecoveryThreshold: 0.54,
    basePelletCount: 2,
    splitCapacitorBonusPellets: 1,
    spreadRadians: 0.055,
    projectile: ProjectileBlueprint(
      damage: 0.72,
      speedMultiplier: 1.08,
      muzzleOffset: 0.58,
      heatSpeedBonus: 0.12,
    ),
    supportedUpgrades: _allUpgrades,
  );

  static const voltLance = WeaponBlueprint(
    id: voltLanceId,
    name: 'VOLT LANCE',
    baseCooldown: 0.245,
    heatPerShot: 0.28,
    coolingRate: 1.45,
    overheatedCoolingRate: 2.35,
    overheatRecoveryThreshold: 0.5,
    basePelletCount: 1,
    splitCapacitorBonusPellets: 1,
    spreadRadians: 0.045,
    projectile: ProjectileBlueprint(
      damage: 1.75,
      speedMultiplier: 1.34,
      muzzleOffset: 0.68,
      heatSpeedBonus: 0.08,
    ),
    supportedUpgrades: _allUpgrades,
  );

  static const all = <WeaponBlueprint>[nervePistol, ionStitcher, voltLance];

  static WeaponBlueprint byId(String id) {
    for (final blueprint in all) {
      if (blueprint.id == id) {
        return blueprint;
      }
    }
    throw ArgumentError.value(id, 'id', 'Unknown weapon blueprint');
  }

  static List<String> validate() {
    final errors = <String>[];
    final ids = <String>{};
    for (final blueprint in all) {
      if (!ids.add(blueprint.id)) {
        errors.add('${blueprint.id}.id is duplicated.');
      }
      errors.addAll(blueprint.validate());
    }
    if (!ids.contains(defaultWeaponId)) {
      errors.add('Default weapon blueprint $defaultWeaponId is missing.');
    }
    return errors;
  }
}
