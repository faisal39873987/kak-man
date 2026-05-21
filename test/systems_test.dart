import 'dart:math' as math;

import 'package:one_shot_nerve_runner/progression/meta_progression.dart';
import 'package:one_shot_nerve_runner/progression/player_evolution_system.dart';
import 'package:one_shot_nerve_runner/progression/reward_choice.dart';
import 'package:one_shot_nerve_runner/save/game_save_data.dart';
import 'package:one_shot_nerve_runner/save/save_data_ranker.dart';
import 'package:one_shot_nerve_runner/systems/combat/combo_chain_system.dart';
import 'package:one_shot_nerve_runner/weapons/weapon_catalog.dart';
import 'package:one_shot_nerve_runner/weapons/weapon_upgrade.dart';
import 'package:test/test.dart';

void main() {
  test('combo chain expires after timeout', () {
    final combo = ComboChainSystem();

    combo.registerKill();
    combo.registerKill();
    combo.update(1);

    expect(combo.chain, 2);
    expect(combo.bestChain, 2);

    combo.update(3);

    expect(combo.chain, 0);
    expect(combo.bestChain, 2);
  });

  test('perfect dodge contributes to combo without requiring a kill', () {
    final combo = ComboChainSystem();

    combo.registerPerfectDodge();
    combo.update(0.5);

    expect(combo.chain, 1);
    expect(combo.bestChain, 1);
    expect(combo.normalizedTimer, greaterThan(0));

    combo.update(2);

    expect(combo.chain, 0);
  });

  test('player evolution rewards high accuracy', () {
    final evolution = PlayerEvolutionSystem();

    for (var i = 0; i < 16; i += 1) {
      evolution.registerShot();
    }
    for (var i = 0; i < 12; i += 1) {
      evolution.registerHit();
    }

    expect(evolution.traits.contains(EvolutionTrait.deadeye), isTrue);
    expect(evolution.shotDamageMultiplier, greaterThan(1));
  });

  test('player evolution rewards consistent perfect dodges', () {
    final evolution = PlayerEvolutionSystem();

    for (var i = 0; i < 6; i += 1) {
      evolution.registerDash();
    }
    for (var i = 0; i < 3; i += 1) {
      evolution.registerPerfectDodge();
    }

    expect(evolution.traits.contains(EvolutionTrait.phaseSurge), isTrue);
    expect(evolution.dashCostMultiplier, lessThan(1));
    expect(evolution.staminaRegenMultiplier, greaterThan(1));
  });

  test(
    'reward deck avoids owned weapon upgrades and keeps fallback reward',
    () {
      final deck = RewardDeck();
      final rewards = deck.draft(
        random: math.Random(7),
        ownedWeaponUpgrades: WeaponUpgrade.values.toSet(),
        ownedRunEffects: {
          RewardEffect.dermalPlating,
          RewardEffect.adrenalBattery,
          RewardEffect.tensionDividend,
          RewardEffect.dashBattery,
        },
        currentHealth: 5,
        maxHealth: 5,
        availableWeaponIds: const <String>{WeaponCatalog.defaultWeaponId},
      );

      expect(rewards, isNotEmpty);
      expect(rewards.any((reward) => reward.weaponUpgrade != null), isFalse);
      expect(rewards.single.effect, RewardEffect.quickPatch);
    },
  );

  test('reward deck can offer concrete weapon swaps', () {
    final deck = RewardDeck();
    final rewards = deck.draft(
      random: math.Random(3),
      ownedWeaponUpgrades: WeaponUpgrade.values.toSet(),
      ownedRunEffects: const <RewardEffect>{
        RewardEffect.dermalPlating,
        RewardEffect.adrenalBattery,
        RewardEffect.tensionDividend,
        RewardEffect.dashBattery,
      },
      currentHealth: 5,
      maxHealth: 5,
      currentWeaponId: WeaponCatalog.defaultWeaponId,
    );

    expect(
      rewards.where((reward) => reward.effect == RewardEffect.weaponSwap),
      isNotEmpty,
    );
    expect(
      rewards
          .where((reward) => reward.effect == RewardEffect.weaponSwap)
          .every((reward) => reward.weaponId != WeaponCatalog.defaultWeaponId),
      isTrue,
    );
  });

  test('meta progression respects costs and prerequisites', () {
    final meta = MetaProgressionSystem(currency: 30);

    expect(meta.unlock('coolant_loop'), isFalse);
    expect(meta.unlock('dash_efficiency'), isTrue);
    expect(meta.currency, 16);
    expect(meta.unlock('coolant_loop'), isTrue);
    expect(meta.weaponHeatMultiplier, lessThan(1));
    expect(meta.weaponCoolingMultiplier, greaterThan(1));
  });

  test('meta progression currency multiplier applies to run payout', () {
    final meta = MetaProgressionSystem(currency: 100);

    expect(meta.unlock('nerve_magnet'), isTrue);
    final granted = meta.grantRunCurrency(10);

    expect(granted, 12);
    expect(meta.currency, 92);
  });

  test('save ranker keeps the richest local or remote save', () {
    final local = GameSaveData.fresh().mergeRun(
      combo: 4,
      room: 3,
      kills: 12,
      evolutionSystem: PlayerEvolutionSystem(),
      metaProgression: const <String, Object>{
        'currency': 4,
        'unlocked': <String>[],
      },
    );
    final remote = GameSaveData.fresh().mergeRun(
      combo: 8,
      room: 6,
      kills: 20,
      evolutionSystem: PlayerEvolutionSystem(),
      metaProgression: const <String, Object>{
        'currency': 18,
        'unlocked': <String>['dash_efficiency'],
      },
    );

    expect(SaveDataRanker.richest(local, remote), same(remote));
    expect(SaveDataRanker.richest(remote, local), same(remote));
  });
}
