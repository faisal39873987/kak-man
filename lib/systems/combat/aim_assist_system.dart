import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/math/vector_math.dart';

class AimAssistTarget {
  const AimAssistTarget({
    required this.position,
    required this.radius,
    this.active = true,
  });

  final Vector2 position;
  final double radius;
  final bool active;
}

class AimAssistBlocker {
  const AimAssistBlocker({required this.bounds, this.active = true});

  final Rect bounds;
  final bool active;
}

class AimAssistSystem {
  const AimAssistSystem({
    required this.range,
    required this.coneRadians,
    required this.blend,
    this.blockerInflation = 0.1,
  }) : assert(range > 0),
       assert(coneRadians > 0),
       assert(blend >= 0 && blend <= 1);

  final double range;
  final double coneRadians;
  final double blend;
  final double blockerInflation;

  Vector2 resolve({
    required Vector2 origin,
    required Vector2 rawDirection,
    required Iterable<AimAssistTarget> targets,
    Iterable<AimAssistBlocker> blockers = const <AimAssistBlocker>[],
  }) {
    final direction = rawDirection.normalizedOrZero();
    if (direction.length2 <= 0.0001 || blend <= 0) {
      return direction;
    }

    final minimumDot = math.cos(coneRadians);
    AimAssistTarget? bestTarget;
    Vector2 bestDirection = direction;
    var bestDistance = 0.0;
    var bestAngle = 0.0;
    var bestScore = double.infinity;

    for (final target in targets) {
      if (!target.active) {
        continue;
      }
      final toTarget = target.position - origin;
      final distance = toTarget.length;
      if (distance <= 0.0001 || distance > range) {
        continue;
      }
      final targetDirection = toTarget.normalizedOrZero();
      final dot = direction.dot(targetDirection).clamp(-1.0, 1.0);
      if (dot < minimumDot) {
        continue;
      }
      if (_isBlocked(origin, target.position, blockers)) {
        continue;
      }

      final angle = math.acos(dot);
      final score =
          (angle / coneRadians) * 0.78 +
          (distance / range) * 0.22 -
          target.radius * 0.035;
      if (score < bestScore) {
        bestTarget = target;
        bestDirection = targetDirection;
        bestDistance = distance;
        bestAngle = angle;
        bestScore = score;
      }
    }

    if (bestTarget == null) {
      return direction;
    }

    final angleWeight = 1 - (bestAngle / coneRadians).clamp(0, 1) * 0.35;
    final distanceWeight = 1 - (bestDistance / range).clamp(0, 1) * 0.2;
    final assistStrength = (blend * angleWeight * distanceWeight)
        .clamp(0, 1)
        .toDouble();
    return (direction * (1 - assistStrength) + bestDirection * assistStrength)
        .normalizedOrZero();
  }

  bool _isBlocked(
    Vector2 origin,
    Vector2 target,
    Iterable<AimAssistBlocker> blockers,
  ) {
    for (final blocker in blockers) {
      if (!blocker.active) {
        continue;
      }
      if (_segmentIntersectsRect(
        origin,
        target,
        blocker.bounds.inflate(blockerInflation),
      )) {
        return true;
      }
    }
    return false;
  }

  bool _segmentIntersectsRect(Vector2 start, Vector2 end, Rect rect) {
    if (rect.contains(start.toOffset()) || rect.contains(end.toOffset())) {
      return true;
    }

    var tMin = 0.0;
    var tMax = 1.0;
    final dx = end.x - start.x;
    final dy = end.y - start.y;

    bool clip(double p, double q) {
      if (p.abs() <= 0.000001) {
        return q >= 0;
      }
      final r = q / p;
      if (p < 0) {
        if (r > tMax) {
          return false;
        }
        if (r > tMin) {
          tMin = r;
        }
      } else {
        if (r < tMin) {
          return false;
        }
        if (r < tMax) {
          tMax = r;
        }
      }
      return true;
    }

    return clip(-dx, start.x - rect.left) &&
        clip(dx, rect.right - start.x) &&
        clip(-dy, start.y - rect.top) &&
        clip(dy, rect.bottom - start.y);
  }
}
