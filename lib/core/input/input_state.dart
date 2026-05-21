import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import '../math/vector_math.dart';

class InputState {
  final Set<LogicalKeyboardKey> _keys = <LogicalKeyboardKey>{};

  Vector2 aimWorld = Vector2(1, 0);
  Vector2 touchMovement = Vector2.zero();
  bool isFiring = false;
  bool dashQueued = false;

  void setKey(LogicalKeyboardKey key, {required bool pressed}) {
    if (pressed) {
      _keys.add(key);
    } else {
      _keys.remove(key);
    }
  }

  void setAimWorld(Vector2 origin, Vector2 target) {
    final direction = target - origin;
    if (direction.length2 > 0.0001) {
      aimWorld = direction.normalizedOrZero();
    }
  }

  void setAimDirection(Vector2 direction) {
    if (direction.length2 > 0.0001) {
      aimWorld = direction.normalizedOrZero();
    }
  }

  void setTouchMovement(Vector2 direction) {
    touchMovement = direction.length > 1
        ? direction.normalizedOrZero()
        : direction;
  }

  void clearTouchMovement() {
    touchMovement.setZero();
  }

  void setAimFromOffset(Offset offset, Vector2 origin, Vector2 worldTarget) {
    if (offset.distanceSquared > 0) {
      setAimWorld(origin, worldTarget);
    }
  }

  Vector2 movementVector() {
    var x = touchMovement.x;
    var y = touchMovement.y;
    if (_keys.contains(LogicalKeyboardKey.keyA) ||
        _keys.contains(LogicalKeyboardKey.arrowLeft)) {
      x -= 1;
    }
    if (_keys.contains(LogicalKeyboardKey.keyD) ||
        _keys.contains(LogicalKeyboardKey.arrowRight)) {
      x += 1;
    }
    if (_keys.contains(LogicalKeyboardKey.keyW) ||
        _keys.contains(LogicalKeyboardKey.arrowUp)) {
      y -= 1;
    }
    if (_keys.contains(LogicalKeyboardKey.keyS) ||
        _keys.contains(LogicalKeyboardKey.arrowDown)) {
      y += 1;
    }
    return Vector2(x, y).normalizedOrZero();
  }

  bool consumeDash() {
    final queued = dashQueued;
    dashQueued = false;
    return queued;
  }

  bool get keyboardFire =>
      _keys.contains(LogicalKeyboardKey.keyJ) ||
      _keys.contains(LogicalKeyboardKey.keyK) ||
      _keys.contains(LogicalKeyboardKey.enter);

  void clearTransient() {
    dashQueued = false;
  }
}
