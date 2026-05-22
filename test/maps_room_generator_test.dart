import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_shot_nerve_runner/core/config/game_constants.dart';
import 'package:one_shot_nerve_runner/maps/arena_obstacle.dart';
import 'package:one_shot_nerve_runner/maps/arena_set_dressing.dart';
import 'package:one_shot_nerve_runner/maps/arena_wall.dart';
import 'package:one_shot_nerve_runner/maps/neon_arena_background.dart';
import 'package:one_shot_nerve_runner/maps/pulse_hazard.dart';
import 'package:one_shot_nerve_runner/maps/room_blueprint.dart';
import 'package:one_shot_nerve_runner/maps/room_catalog.dart';
import 'package:one_shot_nerve_runner/maps/room_generator.dart';
import 'package:one_shot_nerve_runner/systems/difficulty/dynamic_difficulty_system.dart';

void main() {
  test('default room catalog has valid authored tier coverage', () {
    final catalog = RoomCatalog.defaults;
    final ids = <String>{};

    for (final blueprint in catalog.blueprints) {
      expect(blueprint.kind, RoomBlueprintKind.authored);
      expect(blueprint.weight, greaterThan(0));
      expect(blueprint.visualTheme.id.trim(), blueprint.visualTheme.id);
      expect(blueprint.visualTheme.id, isNotEmpty);
      expect(
        ids.add(blueprint.id),
        isTrue,
        reason: 'Duplicate room blueprint id: ${blueprint.id}',
      );
    }

    for (final tier in RoomTier.values) {
      expect(
        catalog.blueprintsFor(tier),
        isNotEmpty,
        reason: 'No room blueprints registered for $tier',
      );
    }

    expect(catalog.fallbackBlueprint.kind, RoomBlueprintKind.procedural);
    expect(catalog.fallbackBlueprint.visualTheme.id, isNotEmpty);
  });

  test('default room blueprints produce bounded obstacles', () {
    final catalog = RoomCatalog.defaults;
    final bounds = Rect.fromCenter(
      center: Offset.zero,
      width: GameConstants.roomWidth + 8,
      height: GameConstants.roomHeight + 3,
    );
    final playableBounds = bounds.deflate(2);

    for (final tier in RoomTier.values) {
      for (final blueprint in catalog.blueprintsFor(tier)) {
        for (final seed in <int>[17, 231, 991]) {
          final obstacles = blueprint.buildObstacles(
            RoomBuildContext(
              bounds: bounds,
              roomIndex: _roomIndexForTier(tier),
              tier: tier,
              random: math.Random(seed),
            ),
          );

          expect(obstacles, isNotEmpty);
          for (final obstacle in obstacles) {
            expect(
              playableBounds.contains(obstacle.topLeft),
              isTrue,
              reason: '${blueprint.id} top-left outside room: $obstacle',
            );
            expect(
              playableBounds.contains(obstacle.bottomRight),
              isTrue,
              reason: '${blueprint.id} bottom-right outside room: $obstacle',
            );
          }
        }
      }
    }
  });

  test('catalog selection is deterministic and seed-varied', () {
    final catalog = RoomCatalog.defaults;
    final selected = catalog.select(tier: RoomTier.standard, seed: 8128);

    expect(catalog.select(tier: RoomTier.standard, seed: 8128).id, selected.id);

    final selectedIds = <String>{
      for (var seed = 1; seed <= 96; seed += 1)
        catalog.select(tier: RoomTier.standard, seed: seed).id,
    };
    expect(selectedIds.length, greaterThan(1));
  });

  test('empty authored catalog falls back to procedural room content', () {
    final catalog = RoomCatalog(blueprints: const <RoomBlueprint>[]);
    final selected = catalog.select(tier: RoomTier.apex, seed: 11);

    expect(selected.kind, RoomBlueprintKind.procedural);
    expect(
      selected.buildObstacles(
        RoomBuildContext(
          bounds: Rect.fromCenter(
            center: Offset.zero,
            width: GameConstants.roomWidth,
            height: GameConstants.roomHeight,
          ),
          roomIndex: 9,
          tier: RoomTier.apex,
          random: math.Random(11),
        ),
      ),
      isNotEmpty,
    );
  });

  test('room generation is deterministic for matching seed and difficulty', () {
    final generator = RoomGenerator();
    final difficulty = DynamicDifficultySystem()
      ..roomsCleared = 5
      ..intensity = 0.82;

    final first = generator.generate(
      roomIndex: 6,
      seed: 44471,
      difficulty: difficulty,
    );
    final second = generator.generate(
      roomIndex: 6,
      seed: 44471,
      difficulty: difficulty,
    );

    expect(_roomSignature(first), equals(_roomSignature(second)));
  });
}

int _roomIndexForTier(RoomTier tier) {
  return switch (tier) {
    RoomTier.entry => 1,
    RoomTier.standard => 3,
    RoomTier.escalated => 6,
    RoomTier.apex => 10,
  };
}

Map<String, Object?> _roomSignature(GeneratedRoom generated) {
  return <String, Object?>{
    'index': generated.room.index,
    'visualTheme': generated.room.visualTheme.id,
    'bounds': _rect(generated.room.bounds),
    'playerSpawn': _vector(generated.room.playerSpawn),
    'enemySpawns': generated.room.enemySpawns.map(_vector).toList(),
    'obstacles': generated.components
        .whereType<ArenaObstacle>()
        .map((obstacle) => _rect(obstacle.bounds))
        .toList(),
    'hazards': generated.components
        .whereType<PulseHazard>()
        .map(
          (hazard) => <String, Object?>{
            'bounds': _rect(hazard.bounds),
            'period': hazard.period,
            'windup': hazard.windup,
            'active': hazard.active,
            'seedOffset': hazard.seedOffset,
          },
        )
        .toList(),
    'walls': generated.components
        .whereType<ArenaWall>()
        .map((wall) => <Object>[_vector(wall.start), _vector(wall.end)])
        .toList(),
    'backgrounds': generated.components.whereType<NeonArenaBackground>().length,
    'setDressing': generated.components.whereType<ArenaSetDressing>().length,
  };
}

List<double> _rect(Rect rect) {
  return <double>[rect.left, rect.top, rect.right, rect.bottom];
}

List<double> _vector(Vector2 vector) {
  return <double>[vector.x, vector.y];
}
