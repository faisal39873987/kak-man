import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../../core/config/game_constants.dart';
import '../../core/math/vector_math.dart';
import '../../core/theme/game_theme.dart';
import '../../engine/animation/rive_motion_controller.dart';
import '../../engine/nerve_runner_game.dart';

class RunnerPlayer extends BodyComponent<NerveRunnerGame> {
  RunnerPlayer({required Vector2 spawn})
    : _spawn = spawn.clone(),
      super(renderBody: false, priority: 20);

  final Vector2 _spawn;
  final RiveMotionController motion = RiveMotionController();
  int health = GameConstants.playerMaxHealth;
  double stamina = GameConstants.staminaMax;
  bool isDead = false;

  double _dashTimer = 0;
  double _dashCooldown = 0;
  double _invulnerability = 0;
  Vector2 _dashDirection = Vector2.zero();
  Vector2 _lastPosition = Vector2.zero();
  bool _hurtPulse = false;

  bool get isDashing => _dashTimer > 0;
  bool get isInvulnerable => _invulnerability > 0 || isDashing;
  int get maxHealth =>
      GameConstants.playerMaxHealth +
      game.runUpgrades.maxHealthBonus +
      game.metaProgression.maxHealthBonus;
  double get maxStamina =>
      GameConstants.staminaMax + game.runUpgrades.staminaCapacityBonus;
  double get staminaRatio => stamina / maxStamina;

  @override
  Body createBody() {
    final shape = CircleShape()..radius = GameConstants.playerRadius;
    final fixture = FixtureDef(
      shape,
      density: 1.1,
      friction: 0.2,
      restitution: 0.02,
    );
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: _spawn,
      linearDamping: 8,
      fixedRotation: true,
      allowSleep: false,
    );
    return world.createBody(bodyDef)..createFixture(fixture);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _lastPosition = body.position.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead) {
      body.linearVelocity = Vector2.zero();
      motion.update(
        speed: 0,
        firing: false,
        dashing: false,
        hurt: false,
        dead: true,
      );
      return;
    }

    _dashCooldown = (_dashCooldown - dt).clamp(0, 10);
    _invulnerability = (_invulnerability - dt).clamp(0, 10);

    final movement = game.input.movementVector();
    if (game.input.hasDashQueued && _canDash) {
      game.input.consumeDash();
      _startDash(movement);
    }

    Vector2 targetVelocity;
    if (_dashTimer > 0) {
      _dashTimer -= dt;
      targetVelocity = _dashDirection * GameConstants.playerDashSpeed;
    } else {
      final speed =
          GameConstants.playerMoveSpeed *
          (health <= GameConstants.lowHealthThreshold ? 1.06 : 1);
      targetVelocity = movement * speed;
    }

    body.linearVelocity = targetVelocity;
    final travelled = body.position.distanceTo(_lastPosition);
    _lastPosition = body.position.clone();

    health = health.clamp(0, maxHealth).toInt();
    final regen =
        GameConstants.staminaRegenPerSecond *
        game.evolution.staminaRegenMultiplier *
        game.runUpgrades.staminaRegenMultiplier *
        (movement.length2 > 0 ? 0.82 : 1.15);
    stamina = (stamina + regen * dt).clamp(0, maxStamina);
    game.evolution.update(
      dt,
      currentHealth: health,
      speed: travelled / math.max(dt, 0.0001),
    );

    motion.update(
      speed: targetVelocity.length / GameConstants.playerMoveSpeed,
      firing: game.input.isFiring || game.input.keyboardFire,
      dashing: isDashing,
      hurt: _hurtPulse,
      dead: false,
    );
    _hurtPulse = false;
  }

  bool get _canDash => _dashCooldown <= 0 && stamina >= dashCost;

  void _startDash(Vector2 movement) {
    final direction = movement.length2 > 0
        ? movement.normalizedOrZero()
        : game.input.aimWorld;
    _dashDirection = direction.normalizedOrZero();
    if (_dashDirection.length2 <= 0.0001) {
      _dashDirection = Vector2(1, 0);
    }
    _dashTimer = GameConstants.playerDashDuration;
    _dashCooldown = GameConstants.playerDashCooldown;
    stamina -= dashCost;
    game.evolution.registerDash();
    game.onPlayerDash(body.position, _dashDirection);
  }

  double get dashCost =>
      GameConstants.dashStaminaCost *
      game.evolution.dashCostMultiplier *
      game.metaProgression.dashCostMultiplier;

  void rewardPerfectDodge() {
    stamina = (stamina + GameConstants.perfectDodgeStaminaRefund).clamp(
      0,
      maxStamina,
    );
    _invulnerability = math.max(
      _invulnerability,
      GameConstants.perfectDodgeInvulnerabilitySeconds,
    );
  }

  bool takeDamage(int amount, Vector2 source) {
    if (isDead || isInvulnerable) {
      return false;
    }
    final reduction = health <= GameConstants.lowHealthThreshold
        ? game.evolution.lowHealthDamageReduction
        : 1.0;
    final effectiveDamage = math.max(1, (amount * reduction).round());
    health = math.max(0, health - effectiveDamage);
    _invulnerability = GameConstants.invulnerabilitySeconds;
    _hurtPulse = true;
    final knockback = (body.position - source).normalizedOrZero()..scale(7);
    body.applyLinearImpulse(knockback);
    game.onPlayerHurt(body.position);
    if (health <= 0) {
      isDead = true;
      game.onPlayerKilled();
    }
    return true;
  }

  void restoreForNewRun(Vector2 spawn) {
    health = maxHealth;
    stamina = maxStamina;
    isDead = false;
    _dashTimer = 0;
    _dashCooldown = 0;
    _invulnerability = 0;
    body.setTransform(spawn, 0);
    body.linearVelocity = Vector2.zero();
  }

  @override
  void render(Canvas canvas) {
    final invulnAlpha = isInvulnerable ? 0.52 : 1.0;
    final glow = Paint()
      ..color = GameTheme.cyan.withValues(alpha: 0.18 * invulnAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.28);
    final bodyPaint = Paint()
      ..color = (isDashing ? GameTheme.acid : GameTheme.cyan).withValues(
        alpha: invulnAlpha,
      );
    final corePaint = Paint()..color = GameTheme.voidBlack;
    final aimPaint = Paint()
      ..color = GameTheme.acid
      ..strokeWidth = 0.045
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset.zero, GameConstants.playerRadius * 1.8, glow);
    canvas.drawCircle(Offset.zero, GameConstants.playerRadius, bodyPaint);
    canvas.drawCircle(
      Offset.zero,
      GameConstants.playerRadius * 0.54,
      corePaint,
    );
    canvas.drawLine(
      (game.input.aimWorld * 0.18).toOffset(),
      (game.input.aimWorld * 0.78).toOffset(),
      aimPaint,
    );
  }
}
