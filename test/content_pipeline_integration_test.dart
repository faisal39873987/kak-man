import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:one_shot_nerve_runner/audio/audio_manifest.dart';
import 'package:one_shot_nerve_runner/maps/arena_obstacle.dart';
import 'package:one_shot_nerve_runner/maps/room_blueprint.dart';
import 'package:one_shot_nerve_runner/maps/room_catalog.dart';
import 'package:one_shot_nerve_runner/maps/room_generator.dart';
import 'package:one_shot_nerve_runner/progression/reward_choice.dart';
import 'package:one_shot_nerve_runner/systems/difficulty/dynamic_difficulty_system.dart';
import 'package:one_shot_nerve_runner/weapons/weapon_catalog.dart';
import 'package:one_shot_nerve_runner/weapons/weapon_factory.dart';
import 'package:one_shot_nerve_runner/weapons/weapon_upgrade.dart';

void main() {
  test('reward weapon swaps stay backed by weapon catalog blueprints', () {
    final deck = RewardDeck();
    const factory = WeaponFactory();
    final catalogIds = WeaponCatalog.all
        .map((blueprint) => blueprint.id)
        .toSet();
    final emittedSwapIds = <String>{};

    expect(catalogIds, isNotEmpty);

    for (final blueprint in WeaponCatalog.all) {
      final currentWeaponId = catalogIds.firstWhere(
        (id) => id != blueprint.id,
        orElse: () => '${blueprint.id}_current',
      );
      final rewards = deck.draft(
        random: math.Random(1),
        ownedWeaponUpgrades: WeaponUpgrade.values.toSet(),
        ownedRunEffects: RewardEffect.values.toSet(),
        currentHealth: 5,
        maxHealth: 5,
        currentWeaponId: currentWeaponId,
        availableWeaponIds: <String>{blueprint.id},
      );
      final swaps = rewards
          .where((reward) => reward.effect == RewardEffect.weaponSwap)
          .toList();

      expect(
        swaps,
        hasLength(1),
        reason: '${blueprint.id} should be reachable as a weapon swap reward',
      );

      final swap = swaps.single;
      expect(swap.id, 'weapon_swap_${blueprint.id}');
      expect(swap.weaponId, blueprint.id);
      expect(swap.title, blueprint.name);
      expect(WeaponCatalog.byId(swap.weaponId!), blueprint);

      final weapon = factory.create(swap.weaponId!);
      expect(weapon.id, blueprint.id);
      expect(weapon.name, blueprint.name);
      emittedSwapIds.add(swap.weaponId!);
    }

    expect(emittedSwapIds, unorderedEquals(catalogIds));
  });

  test('custom room catalog selection and fallback feed room generation', () {
    final customObstacle = Rect.fromCenter(
      center: Offset.zero,
      width: 2,
      height: 2,
    );
    final fallbackObstacle = Rect.fromCenter(
      center: const Offset(2.5, 0),
      width: 1.5,
      height: 2,
    );
    final customBlueprint = RoomBlueprint(
      id: 'qa_standard_lane',
      minTier: RoomTier.standard,
      maxTier: RoomTier.standard,
      buildObstacles: (_) => <Rect>[customObstacle],
    );
    final fallbackBlueprint = RoomBlueprint(
      id: 'qa_fallback_procedural',
      minTier: RoomTier.entry,
      maxTier: RoomTier.apex,
      kind: RoomBlueprintKind.procedural,
      buildObstacles: (_) => <Rect>[fallbackObstacle],
    );
    final catalog = RoomCatalog(
      blueprints: <RoomBlueprint>[customBlueprint],
      fallbackBlueprint: fallbackBlueprint,
    );
    final generator = RoomGenerator(catalog: catalog);
    final difficulty = DynamicDifficultySystem()
      ..roomsCleared = 2
      ..intensity = 0.4;

    expect(catalog.blueprintsFor(RoomTier.entry), isEmpty);
    expect(catalog.blueprintsFor(RoomTier.standard), <RoomBlueprint>[
      customBlueprint,
    ]);
    expect(catalog.select(tier: RoomTier.standard, seed: 99), customBlueprint);
    expect(catalog.select(tier: RoomTier.apex, seed: 99), fallbackBlueprint);

    final standardRoom = generator.generate(
      roomIndex: 3,
      seed: 4001,
      difficulty: difficulty,
    );
    final apexRoom = generator.generate(
      roomIndex: 10,
      seed: 4002,
      difficulty: difficulty,
    );

    expect(_obstacleBounds(standardRoom), contains(customObstacle));
    expect(_obstacleBounds(standardRoom), isNot(contains(fallbackObstacle)));
    expect(_obstacleBounds(apexRoom), contains(fallbackObstacle));
    expect(_obstacleBounds(apexRoom), isNot(contains(customObstacle)));
  });

  test('audio manifest covers every cue with sane asset and mix data', () {
    expect(AudioManifest.cueAssets.keys, unorderedEquals(AudioCue.values));
    expect(AudioManifest.cueMixes.keys, unorderedEquals(AudioCue.values));
    expect(AudioManifest.busVolumes.keys, unorderedEquals(AudioBus.values));

    for (final entry in AudioManifest.busVolumes.entries) {
      expect(entry.value.isFinite, isTrue, reason: '${entry.key.name} bus');
      expect(entry.value, greaterThan(0), reason: '${entry.key.name} bus');
      expect(
        entry.value,
        lessThanOrEqualTo(1),
        reason: '${entry.key.name} bus',
      );
    }

    final assetPaths = <String>{};
    for (final cue in AudioCue.values) {
      final asset = AudioManifest.cueAssets[cue]!;
      final mix = AudioManifest.cueMixes[cue]!;

      expect(asset.trim(), asset, reason: '${cue.name} asset has padding');
      expect(asset, startsWith('audio/'));
      expect(asset, endsWith('.wav'));
      expect(
        assetPaths.add(asset),
        isTrue,
        reason: '${cue.name} reuses an audio asset path: $asset',
      );
      expect(
        File('assets/$asset').existsSync(),
        isTrue,
        reason: 'Missing bundled audio asset for ${cue.name}: $asset',
      );
      expect(
        File('assets/$asset').lengthSync(),
        greaterThan(0),
        reason: '${cue.name} audio asset is empty: $asset',
      );

      expect(mix.volume.isFinite, isTrue, reason: '${cue.name} volume');
      expect(mix.volume, greaterThan(0), reason: '${cue.name} volume');
      expect(mix.volume, lessThanOrEqualTo(1), reason: '${cue.name} volume');
      expect(mix.cooldown.isFinite, isTrue, reason: '${cue.name} cooldown');
      expect(mix.cooldown, greaterThan(0), reason: '${cue.name} cooldown');
      expect(
        mix.cooldown,
        lessThanOrEqualTo(1),
        reason: '${cue.name} cooldown should stay responsive',
      );
      expect(
        AudioManifest.busVolumes[mix.bus],
        isNotNull,
        reason: '${cue.name} routes to an unmixed bus',
      );
      expect(mix.priority, greaterThanOrEqualTo(0), reason: cue.name);
      expect(mix.priority, lessThanOrEqualTo(100), reason: cue.name);
      expect(mix.pitchVariance.isFinite, isTrue, reason: cue.name);
      expect(mix.pitchVariance, greaterThanOrEqualTo(0), reason: cue.name);
      expect(mix.pitchVariance, lessThanOrEqualTo(0.08), reason: cue.name);
      expect(mix.intensityGain.isFinite, isTrue, reason: cue.name);
      expect(mix.intensityGain, greaterThanOrEqualTo(0), reason: cue.name);
      expect(mix.intensityGain, lessThanOrEqualTo(0.35), reason: cue.name);
      expect(mix.ducking.isFinite, isTrue, reason: cue.name);
      expect(mix.ducking, greaterThanOrEqualTo(0), reason: cue.name);
      expect(mix.ducking, lessThanOrEqualTo(0.7), reason: cue.name);
    }
  });
}

List<Rect> _obstacleBounds(GeneratedRoom room) {
  return room.components
      .whereType<ArenaObstacle>()
      .map((obstacle) => obstacle.bounds)
      .toList(growable: false);
}
