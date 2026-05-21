import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../core/config/game_constants.dart';
import '../systems/difficulty/dynamic_difficulty_system.dart';
import 'arena_obstacle.dart';
import 'arena_wall.dart';
import 'combat_room.dart';
import 'neon_arena_background.dart';
import 'pulse_hazard.dart';

class GeneratedRoom {
  const GeneratedRoom({required this.room, required this.components});

  final CombatRoom room;
  final List<Component> components;
}

class RoomGenerator {
  GeneratedRoom generate({
    required int roomIndex,
    required int seed,
    required DynamicDifficultySystem difficulty,
  }) {
    final random = math.Random(seed);
    final width =
        GameConstants.roomWidth + random.nextDouble() * 4 + roomIndex * 0.45;
    final height = GameConstants.roomHeight + random.nextDouble() * 3;
    final bounds = Rect.fromCenter(
      center: Offset.zero,
      width: width,
      height: height,
    );
    final spawn = Vector2(bounds.left + 3.2, 0);
    final obstacleRects = _obstacles(
      bounds: bounds,
      random: random,
      roomIndex: roomIndex,
    );
    final hazards = _hazards(
      bounds: bounds,
      random: random,
      roomIndex: roomIndex,
      obstacleRects: obstacleRects,
    );
    final enemySpawns = _enemySpawns(
      bounds: bounds,
      random: random,
      count: difficulty.targetEnemyCount + (roomIndex == 1 ? 0 : 1),
      obstacleRects: obstacleRects,
      playerSpawn: spawn,
    );

    final topLeft = Vector2(bounds.left, bounds.top);
    final topRight = Vector2(bounds.right, bounds.top);
    final bottomRight = Vector2(bounds.right, bounds.bottom);
    final bottomLeft = Vector2(bounds.left, bounds.bottom);
    final components = <Component>[
      NeonArenaBackground(bounds: bounds, seed: seed),
      ...hazards,
      for (final obstacle in obstacleRects) ArenaObstacle(bounds: obstacle),
      ArenaWall(topLeft, topRight),
      ArenaWall(topRight, bottomRight),
      ArenaWall(bottomRight, bottomLeft),
      ArenaWall(bottomLeft, topLeft),
    ];

    return GeneratedRoom(
      room: CombatRoom(
        index: roomIndex,
        bounds: bounds,
        playerSpawn: spawn,
        enemySpawns: enemySpawns,
        seed: seed,
      ),
      components: components,
    );
  }

  List<Vector2> _enemySpawns({
    required Rect bounds,
    required math.Random random,
    required int count,
    required List<Rect> obstacleRects,
    required Vector2 playerSpawn,
  }) {
    return List<Vector2>.generate(count, (index) {
      for (var attempt = 0; attempt < 16; attempt += 1) {
        final lane = (index + attempt) % 3;
        final x =
            bounds.right - 3.0 - random.nextDouble() * (bounds.width * 0.42);
        final y = switch (lane) {
          0 => bounds.top + 2.2 + random.nextDouble() * 3.0,
          1 => -2.6 + random.nextDouble() * 5.2,
          _ => bounds.bottom - 2.2 - random.nextDouble() * 3.0,
        };
        final candidate = Vector2(x, y);
        if (_isOpenSpawn(candidate, obstacleRects, playerSpawn)) {
          return candidate;
        }
      }
      return Vector2(bounds.right - 4.2, (index.isEven ? -1 : 1) * 3.0);
    });
  }

  List<Rect> _obstacles({
    required Rect bounds,
    required math.Random random,
    required int roomIndex,
  }) {
    final layout = roomIndex % 3;
    final centerY = random.nextDouble() * 2 - 1;
    final obstacles = <Rect>[];

    switch (layout) {
      case 0:
        obstacles
          ..add(
            Rect.fromCenter(
              center: Offset(-1.6, centerY - 3.5),
              width: 2.2,
              height: 3.4,
            ),
          )
          ..add(
            Rect.fromCenter(
              center: Offset(3.6, centerY + 3.1),
              width: 2.6,
              height: 3.1,
            ),
          )
          ..add(
            Rect.fromCenter(
              center: Offset(6.8, centerY - 0.2),
              width: 1.8,
              height: 2.2,
            ),
          );
      case 1:
        obstacles
          ..add(
            Rect.fromCenter(
              center: Offset(-0.4, centerY),
              width: 1.8,
              height: bounds.height * 0.38,
            ),
          )
          ..add(
            Rect.fromCenter(
              center: Offset(5.2, bounds.top + 3.0),
              width: 4.4,
              height: 1.2,
            ),
          )
          ..add(
            Rect.fromCenter(
              center: Offset(5.2, bounds.bottom - 3.0),
              width: 4.4,
              height: 1.2,
            ),
          );
      default:
        obstacles
          ..add(
            Rect.fromCenter(
              center: Offset(1.6, centerY),
              width: 4.6,
              height: 1.15,
            ),
          )
          ..add(
            Rect.fromCenter(
              center: Offset(1.6, centerY),
              width: 1.15,
              height: 4.8,
            ),
          )
          ..add(
            Rect.fromCenter(
              center: Offset(7.4, random.nextBool() ? -4.2 : 4.2),
              width: 2.4,
              height: 2.2,
            ),
          );
    }

    if (roomIndex > 4) {
      obstacles.add(
        Rect.fromCenter(
          center: Offset(bounds.right - 8.2, random.nextBool() ? -4.9 : 4.9),
          width: 3.0,
          height: 1.15,
        ),
      );
    }

    return obstacles
        .where((rect) => bounds.deflate(2.0).contains(rect.topLeft))
        .where((rect) => bounds.deflate(2.0).contains(rect.bottomRight))
        .toList(growable: false);
  }

  List<PulseHazard> _hazards({
    required Rect bounds,
    required math.Random random,
    required int roomIndex,
    required List<Rect> obstacleRects,
  }) {
    if (roomIndex < 2) {
      return <PulseHazard>[];
    }
    final hazardCount = roomIndex > 5 ? 2 : 1;
    final hazards = <PulseHazard>[];
    for (var i = 0; i < hazardCount; i += 1) {
      final horizontal = (roomIndex + i).isEven;
      final rect = horizontal
          ? Rect.fromCenter(
              center: Offset(
                2.2 + random.nextDouble() * 7.2,
                (random.nextBool() ? -1 : 1) * (2.2 + random.nextDouble() * 3),
              ),
              width: 6.8,
              height: 0.52,
            )
          : Rect.fromCenter(
              center: Offset(3.8 + random.nextDouble() * 7.0, 0),
              width: 0.52,
              height: bounds.height * 0.48,
            );
      if (obstacleRects.any(
        (obstacle) => obstacle.inflate(0.8).overlaps(rect),
      )) {
        continue;
      }
      hazards.add(
        PulseHazard(
          bounds: rect,
          period: 2.7 + random.nextDouble() * 0.9,
          windup: 0.64,
          active: 0.32,
          seedOffset: random.nextDouble() * 2,
        ),
      );
    }
    return hazards;
  }

  bool _isOpenSpawn(
    Vector2 candidate,
    List<Rect> obstacleRects,
    Vector2 playerSpawn,
  ) {
    if (candidate.distanceTo(playerSpawn) < 8.0) {
      return false;
    }
    return obstacleRects.every(
      (obstacle) => !obstacle.inflate(1.2).contains(candidate.toOffset()),
    );
  }
}
