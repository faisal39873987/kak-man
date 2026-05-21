import 'package:flame/components.dart';
import 'package:one_shot_nerve_runner/core/config/game_constants.dart';
import 'package:one_shot_nerve_runner/entities/projectiles/bullet_projectile.dart';
import 'package:one_shot_nerve_runner/weapons/nerve_pistol.dart';
import 'package:one_shot_nerve_runner/weapons/weapon.dart';
import 'package:one_shot_nerve_runner/weapons/weapon_catalog.dart';
import 'package:one_shot_nerve_runner/weapons/weapon_factory.dart';
import 'package:one_shot_nerve_runner/weapons/weapon_upgrade.dart';
import 'package:test/test.dart';

void main() {
  test('weapon catalog contains valid concrete blueprints', () {
    const factory = WeaponFactory();
    final ids = WeaponCatalog.all.map((blueprint) => blueprint.id).toList();

    expect(WeaponCatalog.validate(), isEmpty);
    expect(factory.validateCatalog(), isEmpty);
    expect(WeaponCatalog.all, hasLength(greaterThanOrEqualTo(3)));
    expect(
      ids,
      containsAll(<String>[
        WeaponCatalog.nervePistolId,
        WeaponCatalog.ionStitcherId,
        WeaponCatalog.voltLanceId,
      ]),
    );
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('factory creates every catalog weapon from blueprint data', () {
    const factory = WeaponFactory();

    for (final blueprint in WeaponCatalog.all) {
      final weapon = factory.create(blueprint.id);
      final spawned = _fire(weapon);

      expect(weapon.name, blueprint.name);
      expect(spawned, hasLength(blueprint.basePelletCount));
    }
  });

  test('factory rejects unknown weapon ids', () {
    const factory = WeaponFactory();

    expect(() => factory.create('missing_weapon'), throwsArgumentError);
    expect(() => WeaponCatalog.byId('missing_weapon'), throwsArgumentError);
  });

  test('default NervePistol keeps legacy firing behavior', () {
    final weapon = NervePistol();
    final spawned = _fire(weapon);

    expect(weapon.name, 'NERVE-9');
    expect(weapon.heat, closeTo(0.19, 0.000001));
    expect(spawned, hasLength(1));
    expect(spawned.single.damage, closeTo(1, 0.000001));
    expect(
      spawned.single.speed,
      closeTo(GameConstants.bulletSpeed * (1 + 0.19 * 0.16), 0.000001),
    );
    expect(_tryFire(weapon), isFalse);
  });

  test('factory applies weapon upgrades to created weapons', () {
    const factory = WeaponFactory();
    final weapon = factory.create(
      WeaponCatalog.defaultWeaponId,
      upgrades: const <WeaponUpgrade>[
        WeaponUpgrade.overpressure,
        WeaponUpgrade.splitCapacitor,
      ],
    );
    final spawned = _fire(weapon, damageScale: 2);

    expect(weapon.upgrades, contains(WeaponUpgrade.overpressure));
    expect(weapon.upgrades, contains(WeaponUpgrade.splitCapacitor));
    expect(spawned, hasLength(2));
    expect(spawned.first.damage, closeTo(2.56, 0.000001));
    expect(spawned.first.direction.y, lessThan(0));
    expect(spawned.last.direction.y, greaterThan(0));
  });
}

List<BulletProjectile> _fire(Weapon weapon, {double damageScale = 1}) {
  final spawned = <BulletProjectile>[];
  final fired = weapon.tryFire(
    WeaponFireContext(
      origin: Vector2.zero(),
      direction: Vector2(1, 0),
      damageScale: damageScale,
      spawn: spawned.add,
    ),
  );
  expect(fired, isTrue);
  return spawned;
}

bool _tryFire(Weapon weapon) {
  return weapon.tryFire(
    WeaponFireContext(
      origin: Vector2.zero(),
      direction: Vector2(1, 0),
      damageScale: 1,
      spawn: (_) {},
    ),
  );
}
