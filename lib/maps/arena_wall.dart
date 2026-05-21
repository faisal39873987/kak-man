import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../core/theme/game_theme.dart';
import '../engine/nerve_runner_game.dart';

class ArenaWall extends BodyComponent<NerveRunnerGame> {
  ArenaWall(this.start, this.end) : super(renderBody: false, priority: 12);

  final Vector2 start;
  final Vector2 end;

  @override
  Body createBody() {
    final shape = EdgeShape()..set(start, end);
    final fixture = FixtureDef(shape, friction: 0.35, restitution: 0.02);
    final bodyDef = BodyDef(position: Vector2.zero());
    return world.createBody(bodyDef)..createFixture(fixture);
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = GameTheme.cyan.withValues(alpha: 0.65)
      ..strokeWidth = 0.06
      ..strokeCap = StrokeCap.square;
    final glow = Paint()
      ..color = GameTheme.cyan.withValues(alpha: 0.18)
      ..strokeWidth = 0.22
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.3);
    canvas.drawLine(start.toOffset(), end.toOffset(), glow);
    canvas.drawLine(start.toOffset(), end.toOffset(), paint);
  }
}
