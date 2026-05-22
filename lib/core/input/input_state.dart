import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import '../config/game_constants.dart';
import '../math/vector_math.dart';

class InputState {
  final Set<LogicalKeyboardKey> _keys = <LogicalKeyboardKey>{};

  Vector2 aimWorld = Vector2(1, 0);
  Vector2 touchMovement = Vector2.zero();
  bool isFiring = false;
  bool dashQueued = false;
  double _dashBufferRemaining = 0;

  double get dashBufferRemaining => _dashBufferRemaining;
  bool get hasDashQueued => dashQueued && _dashBufferRemaining > 0;

  void update(double dt) {
    if (_dashBufferRemaining <= 0) {
      dashQueued = false;
      return;
    }
    _dashBufferRemaining = (_dashBufferRemaining - dt).clamp(0, 10);
    if (_dashBufferRemaining <= 0) {
      dashQueued = false;
    }
  }

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

  void queueDash({double bufferSeconds = GameConstants.playerDashInputBuffer}) {
    dashQueued = true;
    _dashBufferRemaining = bufferSeconds.clamp(0, 10);
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
    final queued = hasDashQueued;
    dashQueued = false;
    _dashBufferRemaining = 0;
    return queued;
  }

  bool get keyboardFire =>
      _keys.contains(LogicalKeyboardKey.keyJ) ||
      _keys.contains(LogicalKeyboardKey.keyK) ||
      _keys.contains(LogicalKeyboardKey.enter);

  void clearTransient() {
    dashQueued = false;
    _dashBufferRemaining = 0;
  }
}
