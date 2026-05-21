import 'blueprint_weapon.dart';
import 'weapon.dart';
import 'weapon_blueprint.dart';
import 'weapon_catalog.dart';
import 'weapon_upgrade.dart';

class WeaponFactory {
  const WeaponFactory({this.blueprints = WeaponCatalog.all});

  final List<WeaponBlueprint> blueprints;

  Weapon createDefault({
    WeaponTuning tuning = const WeaponTuning(),
    Iterable<WeaponUpgrade> upgrades = const <WeaponUpgrade>[],
  }) {
    return create(
      WeaponCatalog.defaultWeaponId,
      tuning: tuning,
      upgrades: upgrades,
    );
  }

  Weapon create(
    String id, {
    WeaponTuning tuning = const WeaponTuning(),
    Iterable<WeaponUpgrade> upgrades = const <WeaponUpgrade>[],
  }) {
    return BlueprintWeapon(
      blueprintFor(id),
      tuning: tuning,
      upgrades: upgrades,
    );
  }

  WeaponBlueprint blueprintFor(String id) {
    for (final blueprint in blueprints) {
      if (blueprint.id == id) {
        return blueprint;
      }
    }
    throw ArgumentError.value(id, 'id', 'Unknown weapon blueprint');
  }

  List<String> validateCatalog() {
    final errors = <String>[];
    final ids = <String>{};
    for (final blueprint in blueprints) {
      if (!ids.add(blueprint.id)) {
        errors.add('${blueprint.id}.id is duplicated.');
      }
      errors.addAll(blueprint.validate());
    }
    if (!ids.contains(WeaponCatalog.defaultWeaponId)) {
      errors.add(
        'Default weapon blueprint ${WeaponCatalog.defaultWeaponId} is missing.',
      );
    }
    return errors;
  }
}
