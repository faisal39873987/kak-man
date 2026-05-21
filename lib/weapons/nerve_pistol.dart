import 'blueprint_weapon.dart';
import 'weapon.dart';
import 'weapon_catalog.dart';
import 'weapon_upgrade.dart';

class NervePistol extends BlueprintWeapon {
  NervePistol({
    WeaponTuning tuning = const WeaponTuning(),
    Iterable<WeaponUpgrade> upgrades = const <WeaponUpgrade>[],
  }) : super(WeaponCatalog.nervePistol, tuning: tuning, upgrades: upgrades);
}
