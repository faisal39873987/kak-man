import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../core/theme/game_theme.dart';
import '../engine/nerve_runner_game.dart';

class ArenaObstacle extends BodyComponent<NerveRunnerGame> {
  ArenaObstacle({required this.bounds, this.blocksProjectiles = true})
    : super(renderBody: false, priority: 8);

  final Rect bounds;
  final bool blocksProjectiles;

  Vector2 get obstacleCenter => Vector2(bounds.center.dx, bounds.center.dy);
  Vector2 get size => Vector2(bounds.width, bounds.height);

  bool blocksPoint(Vector2 point) {
    if (!blocksProjectiles) {
      return false;
    }
    return bounds.inflate(0.08).contains(point.toOffset());
  }

  @override
  Body createBody() {
    final shape = PolygonShape()
      ..setAsBoxXY(bounds.width / 2, bounds.height / 2);
    final fixture = FixtureDef(shape, friction: 0.42, restitution: 0.01);
    final bodyDef = BodyDef(position: obstacleCenter);
    return world.createBody(bodyDef)..createFixture(fixture);
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: bounds.width,
      height: bounds.height,
    );
    final glow = Paint()
      ..color = GameTheme.cyan.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.22);
    final fill = Paint()..color = GameTheme.voidBlack.withValues(alpha: 0.94);
    final edge = Paint()
      ..color = GameTheme.dimSteel.withValues(alpha: 0.62)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.045;
    final hotEdge = Paint()
      ..color = GameTheme.cyan.withValues(alpha: 0.36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.022;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(0.12), const Radius.circular(0.08)),
      glow,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(0.06)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(0.06)),
      edge,
    );
    canvas.drawLine(rect.topLeft, rect.topRight, hotEdge);
  }
}
