import 'package:one_shot_nerve_runner/progression/meta_progression.dart';
import 'package:one_shot_nerve_runner/progression/player_evolution_system.dart';
import 'package:one_shot_nerve_runner/systems/difficulty/dynamic_difficulty_system.dart';
import 'package:one_shot_nerve_runner/systems/time/slow_motion_system.dart';
import 'package:test/test.dart';

void main() {
  group('DynamicDifficultySystem', () {
    test(
      'ramps encounter pressure over time and escalates after room clear',
      () {
        final difficulty = DynamicDifficultySystem();
        final startingEnemyCount = difficulty.targetEnemyCount;

        for (var frame = 0; frame < 180; frame += 1) {
          difficulty.update(
            dt: 1 / 60,
            playerHealth: 5,
            playerAccuracy: 0.85,
            activeEnemies: 0,
            combo: 12,
          );
        }

        expect(difficulty.intensity, greaterThan(0.55));
        expect(difficulty.directorPressure, greaterThan(1));

        final enemyCountBeforeClear = difficulty.targetEnemyCount;
        final healthMultiplierBeforeClear = difficulty.enemyHealthMultiplier;
        final spawnBudgetBeforeClear = difficulty.spawnBudget;

        difficulty.registerRoomClear();

        expect(difficulty.roomsCleared, 1);
        expect(difficulty.directorPressure, 0);
        expect(difficulty.targetEnemyCount, greaterThan(startingEnemyCount));
        expect(
          difficulty.targetEnemyCount,
          greaterThanOrEqualTo(enemyCountBeforeClear),
        );
        expect(
          difficulty.enemyHealthMultiplier,
          greaterThan(healthMultiplierBeforeClear),
        );
        expect(difficulty.spawnBudget, greaterThan(spawnBudgetBeforeClear));
      },
    );

    test(
      'backs off intensity when the player is pressured and caps director',
      () {
        final difficulty = DynamicDifficultySystem()
          ..roomsCleared = 4
          ..intensity = 1.2
          ..directorPressure = 13.8;
        final startingSpeedMultiplier = difficulty.enemySpeedMultiplier;
        final overcrowdedEnemyCount = difficulty.targetEnemyCount + 4;

        for (var tick = 0; tick < 60; tick += 1) {
          difficulty.update(
            dt: 0.1,
            playerHealth: 1,
            playerAccuracy: 0.1,
            activeEnemies: overcrowdedEnemyCount,
            combo: 0,
          );
        }

        expect(difficulty.intensity, lessThan(0.25));
        expect(difficulty.directorPressure, closeTo(14, 1e-9));
        expect(
          difficulty.enemySpeedMultiplier,
          lessThan(startingSpeedMultiplier),
        );
      },
    );
  });

  group('SlowMotionSystem', () {
    test('scales active frames and recovers to full speed afterward', () {
      final slowMotion = SlowMotionSystem();

      slowMotion.trigger(duration: 0.1, scale: 0.25);

      expect(slowMotion.active, isTrue);
      expect(slowMotion.scale, closeTo(0.25, 1e-9));
      expect(slowMotion.updateAndScale(0.04), closeTo(0.01, 1e-9));
      expect(slowMotion.active, isTrue);
      expect(slowMotion.updateAndScale(0.061), closeTo(0.01525, 1e-9));
      expect(slowMotion.active, isFalse);

      final expiredScale = slowMotion.scale;
      expect(slowMotion.updateAndScale(0.1), closeTo(0.1, 1e-9));
      expect(slowMotion.scale, greaterThan(expiredScale));
      expect(slowMotion.scale, lessThan(1));

      for (var frame = 0; frame < 12; frame += 1) {
        slowMotion.updateAndScale(0.1);
      }

      expect(slowMotion.active, isFalse);
      expect(slowMotion.scale, 1);
    });

    test(
      'does not replace active slow motion with a weaker shorter trigger',
      () {
        final slowMotion = SlowMotionSystem();

        slowMotion.trigger(duration: 0.2, scale: 0.5);
        slowMotion.updateAndScale(0.05);
        slowMotion.trigger(duration: 0.04, scale: 0.8);

        expect(slowMotion.scale, closeTo(0.5, 1e-9));
        expect(slowMotion.updateAndScale(0.05), closeTo(0.025, 1e-9));

        slowMotion.trigger(duration: 0.04, scale: 0.25);

        expect(slowMotion.scale, closeTo(0.25, 1e-9));
        expect(slowMotion.updateAndScale(0.04), closeTo(0.01, 1e-9));
        expect(slowMotion.active, isFalse);
      },
    );
  });

  group('MetaProgressionSystem', () {
    test('fromJson ignores unknown unlocks and non-positive grants', () {
      final meta = MetaProgressionSystem.fromJson(const <String, Object?>{
        'currency': 5,
        'unlocked': <Object>['dash_efficiency', 'missing_node', 7],
      });

      expect(meta.unlockedIds, <String>{'dash_efficiency'});
      expect(meta.dashCostMultiplier, closeTo(0.88, 1e-9));
      expect(meta.weaponHeatMultiplier, 1);
      expect(meta.grantRunCurrency(0), 0);
      expect(meta.grantRunCurrency(-6), 0);
      expect(meta.currency, 5);
    });

    test('combat dividend payout bonuses cap at their designed ceilings', () {
      final meta = MetaProgressionSystem(currency: 100);

      expect(meta.unlock('nerve_magnet'), isTrue);
      expect(meta.unlock('combat_dividend'), isTrue);

      expect(meta.killPayout(enemyId: 'skitter', combo: 99), 6);
      expect(meta.killPayout(enemyId: 'nerve_warden', combo: 99), 13);
      expect(meta.roomClearPayout(room: 3, comboBest: 99), 18);
    });
  });

  group('PlayerEvolutionSystem', () {
    test('absorb keeps saved trait effects active after reload', () {
      final evolution = PlayerEvolutionSystem();

      evolution.absorb(const <String, Object?>{
        'profile': <String, Object>{
          'shotsFired': 16,
          'shotsHit': 12,
          'dashes': 6,
          'perfectDodges': 3,
        },
        'traits': <String>['deadeye', 'phaseSurge'],
      });

      expect(
        evolution.traits,
        containsAll(<EvolutionTrait>[
          EvolutionTrait.deadeye,
          EvolutionTrait.phaseSurge,
        ]),
      );
      expect(evolution.shotDamageMultiplier, closeTo(1.22, 1e-9));
      expect(evolution.dashCostMultiplier, closeTo(0.74, 1e-9));
      expect(evolution.staminaRegenMultiplier, closeTo(1.12, 1e-9));
    });
  });
}
