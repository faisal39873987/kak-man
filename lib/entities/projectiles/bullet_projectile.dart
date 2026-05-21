import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../../core/config/game_constants.dart';
import '../../core/theme/game_theme.dart';
import '../../engine/nerve_runner_game.dart';

class BulletProjectile extends BodyComponent<NerveRunnerGame> {
  BulletProjectile({
    required Vector2 position,
    required this.direction,
    required this.damage,
    required this.speed,
  }) : _spawn = position.clone(),
       super(renderBody: false, priority: 30);

  final Vector2 _spawn;
  final Vector2 direction;
  final double damage;
  final double speed;
  double _life = GameConstants.bulletLifetime;
  bool spent = false;

  @override
  Body createBody() {
    final shape = CircleShape()..radius = GameConstants.bulletRadius;
    final fixture = FixtureDef(shape, isSensor: true, density: 0.1);
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: _spawn,
      linearVelocity: direction * speed,
      bullet: true,
      fixedRotation: true,
      linearDamping: 0,
    );
    return world.createBody(bodyDef)..createFixture(fixture);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (spent) {
      removeFromParent();
      return;
    }
    _life -= dt;
    body.linearVelocity = direction * speed;
    if (_life <= 0 || !game.currentRoom.contains(body.position)) {
      spent = true;
      removeFromParent();
      return;
    }
    for (final obstruction in game.obstructions) {
      if (obstruction.blocksPoint(body.position)) {
        spent = true;
        game.feedback.coverHit(body.position);
        removeFromParent();
        return;
      }
    }
    for (final enemy in List.of(game.enemies)) {
      if (enemy.isDead) {
        continue;
      }
      final hitDistance = GameConstants.bulletRadius + enemy.hitRadius;
      if (body.position.distanceToSquared(enemy.position) <=
          hitDistance * hitDistance) {
        spent = true;
        game.resolveProjectileHit(this, enemy);
        removeFromParent();
        return;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final glow = Paint()
      ..color = GameTheme.acid.withValues(alpha: 0.24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.18);
    final core = Paint()..color = GameTheme.acid;
    final trail = Paint()
      ..color = GameTheme.cyan.withValues(alpha: 0.7)
      ..strokeWidth = 0.035
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      (direction * -0.46).toOffset(),
      (direction * -0.08).toOffset(),
      trail,
    );
    canvas.drawCircle(Offset.zero, GameConstants.bulletRadius * 3.0, glow);
    canvas.drawCircle(Offset.zero, GameConstants.bulletRadius, core);
  }
}
