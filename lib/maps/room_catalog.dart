import 'dart:math' as math;
import 'dart:ui';

import 'room_blueprint.dart';
import 'room_visual_theme.dart';

class RoomCatalog {
  RoomCatalog({
    required Iterable<RoomBlueprint> blueprints,
    RoomBlueprint? fallbackBlueprint,
  }) : _blueprints = List<RoomBlueprint>.unmodifiable(blueprints),
       fallbackBlueprint = fallbackBlueprint ?? _legacyProceduralBlueprint;

  static final RoomCatalog defaults = RoomCatalog(
    blueprints: <RoomBlueprint>[
      RoomBlueprint(
        id: 'split_capacitor',
        minTier: RoomTier.entry,
        maxTier: RoomTier.apex,
        weight: 3,
        visualTheme: RoomVisualTheme.capacitor,
        buildObstacles: _splitCapacitorObstacles,
      ),
      RoomBlueprint(
        id: 'parallel_rails',
        minTier: RoomTier.entry,
        maxTier: RoomTier.apex,
        weight: 3,
        visualTheme: RoomVisualTheme.railYard,
        buildObstacles: _parallelRailsObstacles,
      ),
      RoomBlueprint(
        id: 'cross_relay',
        minTier: RoomTier.standard,
        maxTier: RoomTier.apex,
        weight: 2,
        visualTheme: RoomVisualTheme.relay,
        buildObstacles: _crossRelayObstacles,
      ),
      RoomBlueprint(
        id: 'reactor_spine',
        minTier: RoomTier.standard,
        maxTier: RoomTier.apex,
        weight: 2,
        visualTheme: RoomVisualTheme.reactor,
        buildObstacles: _reactorSpineObstacles,
      ),
      RoomBlueprint(
        id: 'dead_clinic',
        minTier: RoomTier.escalated,
        maxTier: RoomTier.apex,
        weight: 2,
        visualTheme: RoomVisualTheme.clinic,
        buildObstacles: _deadClinicObstacles,
      ),
    ],
    fallbackBlueprint: _legacyProceduralBlueprint,
  );

  final List<RoomBlueprint> _blueprints;
  final RoomBlueprint fallbackBlueprint;

  List<RoomBlueprint> get blueprints => _blueprints;

  List<RoomBlueprint> blueprintsFor(RoomTier tier) {
    return List<RoomBlueprint>.unmodifiable(
      _blueprints.where((blueprint) => blueprint.supports(tier)),
    );
  }

  RoomBlueprint select({required RoomTier tier, required int seed}) {
    final candidates = blueprintsFor(tier);
    if (candidates.isEmpty) {
      return fallbackBlueprint;
    }

    final totalWeight = candidates.fold<int>(
      0,
      (total, blueprint) => total + blueprint.weight,
    );
    var roll = math.Random(_selectionSeed(seed, tier)).nextInt(totalWeight);
    for (final blueprint in candidates) {
      if (roll < blueprint.weight) {
        return blueprint;
      }
      roll -= blueprint.weight;
    }
    return candidates.last;
  }

  static int _selectionSeed(int seed, RoomTier tier) {
    final tierSalt = (tier.index + 1) * 0x45d9f3b;
    final salted = (seed ^ tierSalt) & 0x7fffffff;
    return (salted * 1103515245 + 12345) & 0x7fffffff;
  }
}

final RoomBlueprint _legacyProceduralBlueprint = RoomBlueprint(
  id: 'legacy_procedural',
  minTier: RoomTier.entry,
  maxTier: RoomTier.apex,
  kind: RoomBlueprintKind.procedural,
  visualTheme: RoomVisualTheme.undercity,
  buildObstacles: (context) {
    return switch (context.roomIndex % 3) {
      0 => _splitCapacitorObstacles(context),
      1 => _parallelRailsObstacles(context),
      _ => _crossRelayObstacles(context),
    };
  },
);

List<Rect> _splitCapacitorObstacles(RoomBuildContext context) {
  final centerY = context.centeredJitter();
  return _withEscalationObstacle(context, <Rect>[
    Rect.fromCenter(
      center: Offset(-1.6, centerY - 3.5),
      width: 2.2,
      height: 3.4,
    ),
    Rect.fromCenter(
      center: Offset(3.6, centerY + 3.1),
      width: 2.6,
      height: 3.1,
    ),
    Rect.fromCenter(
      center: Offset(6.8, centerY - 0.2),
      width: 1.8,
      height: 2.2,
    ),
  ]);
}

List<Rect> _parallelRailsObstacles(RoomBuildContext context) {
  final centerY = context.centeredJitter();
  return _withEscalationObstacle(context, <Rect>[
    Rect.fromCenter(
      center: Offset(-0.4, centerY),
      width: 1.8,
      height: context.bounds.height * 0.38,
    ),
    Rect.fromCenter(
      center: Offset(5.2, context.bounds.top + 3.0),
      width: 4.4,
      height: 1.2,
    ),
    Rect.fromCenter(
      center: Offset(5.2, context.bounds.bottom - 3.0),
      width: 4.4,
      height: 1.2,
    ),
  ]);
}

List<Rect> _crossRelayObstacles(RoomBuildContext context) {
  final centerY = context.centeredJitter();
  return _withEscalationObstacle(context, <Rect>[
    Rect.fromCenter(center: Offset(1.6, centerY), width: 4.6, height: 1.15),
    Rect.fromCenter(center: Offset(1.6, centerY), width: 1.15, height: 4.8),
    Rect.fromCenter(
      center: Offset(7.4, context.random.nextBool() ? -4.2 : 4.2),
      width: 2.4,
      height: 2.2,
    ),
  ]);
}

List<Rect> _reactorSpineObstacles(RoomBuildContext context) {
  final centerY = context.centeredJitter(0.6);
  return _withEscalationObstacle(context, <Rect>[
    Rect.fromCenter(center: Offset(-3.8, centerY), width: 2.1, height: 7.2),
    Rect.fromCenter(center: Offset(1.2, centerY - 3.9), width: 4.8, height: 1),
    Rect.fromCenter(center: Offset(1.2, centerY + 3.9), width: 4.8, height: 1),
    Rect.fromCenter(center: Offset(7.1, centerY), width: 2.4, height: 5.6),
  ]);
}

List<Rect> _deadClinicObstacles(RoomBuildContext context) {
  final yBias = context.centeredJitter(0.85);
  return _withEscalationObstacle(context, <Rect>[
    Rect.fromCenter(center: Offset(-4.4, yBias - 3.4), width: 5.2, height: 1),
    Rect.fromCenter(center: Offset(-4.4, yBias + 3.4), width: 5.2, height: 1),
    Rect.fromCenter(center: Offset(1.7, yBias), width: 1.1, height: 5.4),
    Rect.fromCenter(center: Offset(6.8, yBias - 2.8), width: 3.2, height: 1.2),
    Rect.fromCenter(center: Offset(9.2, yBias + 3.0), width: 2.2, height: 2.1),
  ]);
}

List<Rect> _withEscalationObstacle(
  RoomBuildContext context,
  List<Rect> obstacles,
) {
  if (context.tier.index < RoomTier.escalated.index) {
    return obstacles;
  }
  obstacles.add(
    Rect.fromCenter(
      center: Offset(
        context.bounds.right - 8.2,
        context.random.nextBool() ? -4.9 : 4.9,
      ),
      width: 3.0,
      height: 1.15,
    ),
  );
  return obstacles;
}
