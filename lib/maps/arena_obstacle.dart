import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../core/theme/game_theme.dart';
import '../engine/nerve_runner_game.dart';
import 'room_visual_theme.dart';

class ArenaObstacle extends BodyComponent<NerveRunnerGame> {
  ArenaObstacle({
    required this.bounds,
    this.blocksProjectiles = true,
    this.theme = RoomVisualTheme.undercity,
    this.seed = 0,
  }) : super(renderBody: false, priority: 8);

  final Rect bounds;
  final bool blocksProjectiles;
  final RoomVisualTheme theme;
  final int seed;

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
      ..color = theme.primary.withValues(alpha: 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.22);
    final fill = Paint()
      ..shader = Gradient.linear(rect.topLeft, rect.bottomRight, <Color>[
        Color.lerp(GameTheme.voidBlack, theme.floorBase, 0.38)!,
        GameTheme.voidBlack.withValues(alpha: 0.96),
      ]);
    final edge = Paint()
      ..color = GameTheme.dimSteel.withValues(alpha: 0.62)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.045;
    final hotEdge = Paint()
      ..color = theme.primary.withValues(alpha: 0.44)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.022;
    final secondary = Paint()
      ..color = theme.secondary.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.018;

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
    _renderPanels(canvas, rect, secondary);
    _renderBolts(canvas, rect);
    _renderHazardStripe(canvas, rect);
  }

  void _renderPanels(Canvas canvas, Rect rect, Paint paint) {
    final vertical = rect.height > rect.width;
    final count = vertical ? 4 : 3;
    for (var i = 1; i < count; i += 1) {
      final t = i / count;
      if (vertical) {
        final y = lerpDouble(rect.top, rect.bottom, t)!;
        canvas.drawLine(
          Offset(rect.left + 0.14, y),
          Offset(rect.right - 0.14, y),
          paint,
        );
      } else {
        final x = lerpDouble(rect.left, rect.right, t)!;
        canvas.drawLine(
          Offset(x, rect.top + 0.14),
          Offset(x, rect.bottom - 0.14),
          paint,
        );
      }
    }
  }

  void _renderBolts(Canvas canvas, Rect rect) {
    final bolt = Paint()..color = theme.primary.withValues(alpha: 0.38);
    for (final offset in <Offset>[
      rect.topLeft + const Offset(0.18, 0.18),
      rect.topRight + const Offset(-0.18, 0.18),
      rect.bottomLeft + const Offset(0.18, -0.18),
      rect.bottomRight + const Offset(-0.18, -0.18),
    ]) {
      canvas.drawCircle(offset, 0.035, bolt);
    }
  }

  void _renderHazardStripe(Canvas canvas, Rect rect) {
    if ((seed + bounds.width.round() + bounds.height.round()).isOdd) {
      return;
    }
    final paint = Paint()
      ..color = theme.hazard.withValues(alpha: 0.18)
      ..strokeWidth = 0.035
      ..strokeCap = StrokeCap.square;
    final top = rect.top + 0.2;
    for (var x = rect.left + 0.18; x < rect.right - 0.18; x += 0.42) {
      canvas.drawLine(Offset(x, top), Offset(x + 0.2, top + 0.2), paint);
    }
  }
}
