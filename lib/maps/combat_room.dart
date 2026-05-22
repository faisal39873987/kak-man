import 'dart:ui';

import 'package:flame/components.dart';

import 'room_visual_theme.dart';

class CombatRoom {
  const CombatRoom({
    required this.index,
    required this.bounds,
    required this.playerSpawn,
    required this.enemySpawns,
    required this.seed,
    required this.visualTheme,
  });

  final int index;
  final Rect bounds;
  final Vector2 playerSpawn;
  final List<Vector2> enemySpawns;
  final int seed;
  final RoomVisualTheme visualTheme;

  bool contains(Vector2 point) {
    return bounds.inflate(1.4).contains(point.toOffset());
  }
}
