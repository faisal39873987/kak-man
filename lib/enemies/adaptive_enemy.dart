import 'dart:math' as math;
import 'dart:ui';

import 'package:flame_forge2d/flame_forge2d.dart';

import '../core/config/game_constants.dart';
import '../core/math/vector_math.dart';
import '../core/theme/game_theme.dart';
import '../engine/nerve_runner_game.dart';
import 'enemy_archetype.dart';

class AdaptiveEnemy extends BodyComponent<NerveRunnerGame> {
  AdaptiveEnemy({
    required this.archetype,
    required Vector2 spawn,
    required double difficultyHealth,
    required this.roomSeed,
    double activationDelay = 0,
  }) : _spawn = spawn.clone(),
       maxHealth = archetype.health * difficultyHealth,
       health = archetype.health * difficultyHealth,
       _activationDelay = activationDelay,
       super(renderBody: false, priority: 18);

  final EnemyArchetype archetype;
  final Vector2 _spawn;
  final int roomSeed;
  final double maxHealth;
  double health;
  double attackCooldown = 0;
  bool isDead = false;
  double stun = 0;
  double _activationDelay;
  double _windupRemaining = 0;
  double _windupDuration = 0.1;
  double _activeRemaining = 0;
  double _recoveryRemaining = 0;
  bool _activeDamageResolved = false;
  Vector2 _attackDirection = Vector2(1, 0);

  double get hitRadius => GameConstants.enemyRadius;
  Vector2 get spawnPosition => _spawn.clone();
  bool get isTelegraphing => _windupRemaining > 0 || _activeRemaining > 0;

  @override
  Body createBody() {
    final shape = CircleShape()..radius = GameConstants.enemyRadius;
    final fixture = FixtureDef(
      shape,
      density: 0.85,
      friction: 0.2,
      restitution: 0.02,
    );
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: _spawn,
      fixedRotation: true,
      linearDamping: 7.2,
      allowSleep: false,
    );
    return world.createBody(bodyDef)..createFixture(fixture);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead || game.player.isDead) {
      body.linearVelocity = Vector2.zero();
      return;
    }
    if (_activationDelay > 0) {
      _activationDelay -= dt;
      body.linearVelocity = Vector2.zero();
      return;
    }
    attackCooldown = (attackCooldown - dt).clamp(0, 10);
    stun = (stun - dt).clamp(0, 5);
    if (stun > 0) {
      body.linearVelocity = body.linearVelocity * 0.82;
      return;
    }

    final toPlayer = game.player.position - body.position;
    final distance = math.max(0.001, toPlayer.length);

    if (_updateAttackState(dt, toPlayer, distance)) {
      return;
    }

    final profile = game.evolution.profile;
    final sideBias = math.sin(
      game.elapsedTime * (2.4 + archetype.speed) + roomSeed,
    );
    final lateral = Vector2(-toPlayer.y, toPlayer.x).normalizedOrZero()
      ..scale(
        sideBias * profile.accuracy.clamp(0.1, 0.9) * archetype.orbitStrength,
      );
    final feint = profile.dashRate > 0.55 && distance < 4.5
        ? (toPlayer.normalizedOrZero()..scale(-1.4))
        : Vector2.zero();
    final pressure = _behaviorPressure(toPlayer, distance);
    final desired = (pressure + lateral + feint).limited(1);
    final speed =
        GameConstants.enemyBaseSpeed *
        archetype.speed *
        game.difficulty.enemySpeedMultiplier *
        (distance > 7 ? 1.18 : 1);
    body.linearVelocity = desired * speed;

    if (distance <= archetype.attackStartRange && attackCooldown <= 0) {
      _startAttack(toPlayer.normalizedOrZero());
    }
  }

  Vector2 _behaviorPressure(Vector2 toPlayer, double distance) {
    final forward = toPlayer.normalizedOrZero();
    switch (archetype.behavior) {
      case EnemyBehavior.stalker:
      case EnemyBehavior.boss:
        return forward..scale(5.4 + game.difficulty.intensity);
      case EnemyBehavior.cutter:
        final keepOut = distance < 1.55 ? -1.4 : 4.9;
        return forward..scale(keepOut + game.difficulty.intensity * 0.7);
      case EnemyBehavior.bulwark:
        final brace = distance < 3.0 ? -0.7 : 3.6;
        return forward..scale(brace + game.difficulty.intensity * 0.4);
    }
  }

  bool _updateAttackState(double dt, Vector2 toPlayer, double distance) {
    if (_windupRemaining > 0) {
      _windupRemaining -= dt;
      if (archetype.behavior == EnemyBehavior.stalker ||
          archetype.behavior == EnemyBehavior.boss) {
        _attackDirection = toPlayer.normalizedOrZero();
      }
      body.linearVelocity = _attackDirection * -0.35;
      if (_windupRemaining <= 0) {
        _activeRemaining = archetype.attackActiveTime;
        _activeDamageResolved = false;
        if (archetype.behavior == EnemyBehavior.bulwark ||
            archetype.behavior == EnemyBehavior.cutter) {
          body.linearVelocity =
              _attackDirection *
              archetype.lungeSpeed *
              game.difficulty.enemySpeedMultiplier;
        } else {
          _resolveStrike(distance);
        }
      }
      return true;
    }

    if (_activeRemaining > 0) {
      _activeRemaining -= dt;
      if (archetype.behavior == EnemyBehavior.bulwark ||
          archetype.behavior == EnemyBehavior.cutter) {
        body.linearVelocity =
            _attackDirection *
            archetype.lungeSpeed *
            game.difficulty.enemySpeedMultiplier;
      }
      _resolveStrike(distance);
      if (_activeRemaining <= 0) {
        _recoveryRemaining = archetype.attackRecovery;
        attackCooldown = archetype.attackCooldown / archetype.speed;
        body.linearVelocity = body.linearVelocity * 0.24;
      }
      return true;
    }

    if (_recoveryRemaining > 0) {
      _recoveryRemaining -= dt;
      body.linearVelocity = body.linearVelocity * 0.68;
      return true;
    }

    return false;
  }

  void _startAttack(Vector2 direction) {
    if (direction.length2 <= 0.0001) {
      direction = Vector2(1, 0);
    }
    _attackDirection = direction.normalizedOrZero();
    _windupDuration =
        (archetype.attackWindup * (1 - game.difficulty.intensity * 0.08)).clamp(
          0.22,
          archetype.attackWindup,
        );
    _windupRemaining = _windupDuration;
    body.linearVelocity = Vector2.zero();
  }

  void _resolveStrike(double distance) {
    if (_activeDamageResolved || !_playerInsideStrike(distance)) {
      return;
    }
    _activeDamageResolved = true;
    game.damagePlayer(archetype.damage, body.position);
    game.feedback.hit(body.position, color: archetype.color);
  }

  bool _playerInsideStrike(double distance) {
    if (distance > archetype.attackReach + GameConstants.playerRadius) {
      return false;
    }
    final toPlayer = game.player.position - body.position;
    final direction = toPlayer.normalizedOrZero();
    if (direction.length2 <= 0.0001) {
      return true;
    }
    return direction.dot(_attackDirection) > 0.35;
  }

  bool takeDamage(double amount, Vector2 hitDirection) {
    if (isDead) {
      return false;
    }
    health -= amount;
    stun = 0.055;
    body.applyLinearImpulse(hitDirection.normalizedOrZero()..scale(3.6));
    if (health <= 0) {
      isDead = true;
      body.linearVelocity = Vector2.zero();
      game.onEnemyKilled(this);
      removeFromParent();
      return true;
    }
    return false;
  }

  @override
  void render(Canvas canvas) {
    final healthRatio = (health / maxHealth).clamp(0, 1).toDouble();
    final activeAlpha = _activationDelay > 0 ? 0.34 : 1.0;
    final pulse =
        (0.86 + math.sin(game.elapsedTime * 8 + roomSeed) * 0.08) * activeAlpha;
    final glow = Paint()
      ..color = archetype.color.withValues(alpha: 0.2 * activeAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.25);
    final shell = Paint()..color = archetype.color.withValues(alpha: pulse);
    final core = Paint()..color = GameTheme.voidBlack;
    final healthPaint = Paint()
      ..color = healthRatio > 0.5 ? GameTheme.acid : GameTheme.warning
      ..strokeWidth = 0.04
      ..strokeCap = StrokeCap.round;
    final telegraphPaint = Paint()
      ..color = archetype.color.withValues(
        alpha: _windupRemaining > 0 ? 0.72 : 0.28,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = _windupRemaining > 0 ? 0.075 : 0.045
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset.zero, hitRadius * 1.65, glow);
    if (_activationDelay > 0) {
      canvas.drawCircle(
        Offset.zero,
        hitRadius * (1.05 + math.sin(game.elapsedTime * 18) * 0.08),
        Paint()
          ..color = archetype.color.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.04,
      );
    }
    if (isTelegraphing) {
      _renderTelegraph(canvas, telegraphPaint);
    }
    canvas.drawCircle(Offset.zero, hitRadius, shell);
    canvas.drawCircle(Offset.zero, hitRadius * 0.58, core);
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: hitRadius * 1.16),
      -math.pi / 2,
      math.pi * 2 * healthRatio,
      false,
      healthPaint,
    );
  }

  void _renderTelegraph(Canvas canvas, Paint paint) {
    final progress = _windupDuration <= 0
        ? 1.0
        : (1 - (_windupRemaining / _windupDuration)).clamp(0, 1).toDouble();
    final radius = hitRadius + archetype.attackReach * (0.55 + progress * 0.45);
    final forward = _attackDirection.normalizedOrZero();
    final right = Vector2(-forward.y, forward.x);
    final tip = forward * radius;
    final left = forward * hitRadius + right * (radius * 0.34);
    final rightPoint = forward * hitRadius - right * (radius * 0.34);

    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius),
      forward.angleRadians() - 0.58,
      1.16,
      false,
      paint,
    );
    if (archetype.behavior == EnemyBehavior.bulwark ||
        archetype.behavior == EnemyBehavior.cutter) {
      final path = Path()
        ..moveTo(tip.x, tip.y)
        ..lineTo(left.x, left.y)
        ..moveTo(tip.x, tip.y)
        ..lineTo(rightPoint.x, rightPoint.y);
      canvas.drawPath(path, paint);
    }
  }
}
