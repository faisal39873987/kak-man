import 'dart:math' as math;

import 'package:flame/components.dart';

import '../../core/math/vector_math.dart';
import '../nerve_runner_game.dart';

class GameCameraController {
  GameCameraController(this.game);

  final NerveRunnerGame game;
  final math.Random _random = math.Random();
  double _shake = 0;
  double _trauma = 0;
  Vector2 _target = Vector2.zero();

  void snapTo(Vector2 position) {
    _target = position.clone();
    game.camera.viewfinder.position = position.clone();
  }

  void kick(double amount) {
    _trauma = (_trauma + amount).clamp(0, 1);
  }

  void update(double dt, Vector2 focus, Vector2 velocity) {
    _shake = _trauma * _trauma * 0.85;
    _trauma = (_trauma - dt * 2.8).clamp(0, 1);

    final lookAhead = velocity.limited(4)..scale(0.12);
    _target = focus + lookAhead;
    final current = game.camera.viewfinder.position;
    current.setFrom(current + (_target - current) * (dt * 8).clamp(0, 1));

    if (_shake > 0.001) {
      current.add(
        Vector2(
          (_random.nextDouble() * 2 - 1) * _shake,
          (_random.nextDouble() * 2 - 1) * _shake,
        ),
      );
    }

    final speedZoom = (1 - (velocity.length / 60).clamp(0, 0.08)).toDouble();
    game.camera.viewfinder.zoom +=
        ((game.baseZoom * speedZoom) - game.camera.viewfinder.zoom) *
        (dt * 3).clamp(0, 1);
  }
}
