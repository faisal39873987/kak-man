import 'dart:math' as math;

import 'package:flame/components.dart';

extension SafeVector2 on Vector2 {
  Vector2 normalizedOrZero() {
    final magnitude = length;
    if (magnitude <= 0.0001) {
      return Vector2.zero();
    }
    return clone()..scale(1 / magnitude);
  }

  Vector2 limited(double maxLength) {
    final magnitude = length;
    if (magnitude <= maxLength || magnitude <= 0.0001) {
      return clone();
    }
    return normalizedOrZero()..scale(maxLength);
  }

  double angleRadians() => math.atan2(y, x);
}

Vector2 fromRadians(double radians) =>
    Vector2(math.cos(radians), math.sin(radians));
