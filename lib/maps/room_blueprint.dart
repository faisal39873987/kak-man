import 'dart:math' as math;
import 'dart:ui';

enum RoomTier { entry, standard, escalated, apex }

enum RoomBlueprintKind { authored, procedural }

RoomTier roomTierForIndex(int roomIndex) {
  final index = math.max(1, roomIndex);
  if (index == 1) {
    return RoomTier.entry;
  }
  if (index <= 4) {
    return RoomTier.standard;
  }
  if (index <= 7) {
    return RoomTier.escalated;
  }
  return RoomTier.apex;
}

typedef RoomObstacleBuilder = List<Rect> Function(RoomBuildContext context);

class RoomBuildContext {
  RoomBuildContext({
    required this.bounds,
    required this.roomIndex,
    required this.tier,
    required this.random,
  });

  final Rect bounds;
  final int roomIndex;
  final RoomTier tier;
  final math.Random random;

  double centeredJitter([double radius = 1]) {
    return random.nextDouble() * radius * 2 - radius;
  }
}

class RoomBlueprint {
  RoomBlueprint({
    required this.id,
    required this.minTier,
    required this.maxTier,
    required RoomObstacleBuilder buildObstacles,
    this.kind = RoomBlueprintKind.authored,
    this.weight = 1,
  }) : _buildObstacles = buildObstacles {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Room blueprint id is required.');
    }
    if (minTier.index > maxTier.index) {
      throw ArgumentError.value(
        '$minTier..$maxTier',
        'tier range',
        'Minimum tier must not come after maximum tier.',
      );
    }
    if (weight < 1) {
      throw ArgumentError.value(weight, 'weight', 'Weight must be positive.');
    }
  }

  final String id;
  final RoomTier minTier;
  final RoomTier maxTier;
  final RoomBlueprintKind kind;
  final int weight;
  final RoomObstacleBuilder _buildObstacles;

  bool supports(RoomTier tier) {
    return tier.index >= minTier.index && tier.index <= maxTier.index;
  }

  List<Rect> buildObstacles(RoomBuildContext context) {
    return List<Rect>.unmodifiable(_buildObstacles(context));
  }
}
