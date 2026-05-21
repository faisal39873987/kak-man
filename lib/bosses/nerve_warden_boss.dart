import 'dart:math' as math;
import 'dart:ui';

import 'package:flame_forge2d/flame_forge2d.dart';

import '../audio/audio_manifest.dart';
import '../core/config/game_constants.dart';
import '../core/theme/game_theme.dart';
import '../enemies/adaptive_enemy.dart';
import '../enemies/enemy_archetype.dart';
import 'boss_phase.dart';

class NerveWardenBoss extends AdaptiveEnemy {
  NerveWardenBoss({
    required super.spawn,
    required super.difficultyHealth,
    required super.roomSeed,
  }) : super(archetype: _archetype);

  static const EnemyArchetype _archetype = EnemyArchetype(
    id: 'nerve_warden',
    behavior: EnemyBehavior.boss,
    health: 16,
    speed: 0.78,
    damage: 2,
    color: GameTheme.cyan,
    score: 1200,
    attackStartRange: 2.1,
    attackReach: 1.58,
    attackWindup: 0.52,
    attackActiveTime: 0.12,
    attackRecovery: 0.42,
    attackCooldown: 0.95,
    lungeSpeed: 10.5,
    orbitStrength: 1.8,
  );

  static const List<BossPhase> phases = <BossPhase>[
    BossPhase(
      name: 'Awake',
      healthThreshold: 0.66,
      speedMultiplier: 1.0,
      spawnAdds: 0,
    ),
    BossPhase(
      name: 'Panic',
      healthThreshold: 0.34,
      speedMultiplier: 1.24,
      spawnAdds: 2,
    ),
    BossPhase(
      name: 'Rupture',
      healthThreshold: 0.0,
      speedMultiplier: 1.55,
      spawnAdds: 3,
    ),
  ];

  int _phaseIndex = 0;
  double _shockwaveCooldown = 1.4;
  double _shockwaveWindup = 0;
  double _shockwaveWindupDuration = 0.72;
  double _shockwaveRadius = 4.2;

  @override
  double get hitRadius => GameConstants.bossRadius;

  @override
  Body createBody() {
    final shape = CircleShape()..radius = GameConstants.bossRadius;
    final fixture = FixtureDef(
      shape,
      density: 2.2,
      friction: 0.35,
      restitution: 0.01,
    );
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: spawnPosition,
      fixedRotation: true,
      linearDamping: 6.5,
      allowSleep: false,
    );
    return world.createBody(bodyDef)..createFixture(fixture);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead) {
      return;
    }

    _evaluatePhase();
    body.linearVelocity =
        body.linearVelocity * phases[_phaseIndex].speedMultiplier;

    if (_shockwaveWindup > 0) {
      _shockwaveWindup -= dt;
      body.linearVelocity = body.linearVelocity * 0.55;
      if (_shockwaveWindup <= 0) {
        if (body.position.distanceTo(game.player.position) < _shockwaveRadius) {
          game.damagePlayer(1 + _phaseIndex, body.position);
        }
        game.feedback.hit(body.position, color: _phaseColor);
        _shockwaveCooldown = math.max(0.62, 1.58 - _phaseIndex * 0.28);
      }
      return;
    }

    _shockwaveCooldown -= dt;
    if (_shockwaveCooldown <= 0) {
      _shockwaveRadius = 4.2 + _phaseIndex * 0.85;
      _shockwaveWindupDuration = math.max(0.44, 0.72 - _phaseIndex * 0.08);
      _shockwaveWindup = _shockwaveWindupDuration;
    }
  }

  void _evaluatePhase() {
    final ratio = health / maxHealth;
    final nextIndex = phases.indexWhere(
      (phase) => ratio > phase.healthThreshold,
    );
    final resolved = nextIndex == -1 ? phases.length - 1 : nextIndex;
    if (resolved > _phaseIndex) {
      _phaseIndex = resolved;
      game.audio.cue(AudioCue.bossPhase);
      game.spawnAdds(phases[_phaseIndex].spawnAdds, around: body.position);
    }
  }

  @override
  void render(Canvas canvas) {
    final ratio = (health / maxHealth).clamp(0, 1).toDouble();
    final phaseColor = _phaseColor;
    final glow = Paint()
      ..color = phaseColor.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);
    final shell = Paint()
      ..color = phaseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.12;
    final core = Paint()..color = GameTheme.voidBlack;
    final eye = Paint()..color = GameTheme.acid;
    if (_shockwaveWindup > 0) {
      final progress = (1 - (_shockwaveWindup / _shockwaveWindupDuration))
          .clamp(0, 1);
      canvas.drawCircle(
        Offset.zero,
        _shockwaveRadius * (0.35 + progress * 0.65),
        Paint()
          ..color = phaseColor.withValues(alpha: 0.2 + progress * 0.24)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.08,
      );
    }

    canvas.drawCircle(Offset.zero, hitRadius * 2.2, glow);
    canvas.drawCircle(Offset.zero, hitRadius, core);
    canvas.drawCircle(Offset.zero, hitRadius, shell);
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: hitRadius * 1.18),
      -math.pi / 2,
      math.pi * 2 * ratio,
      false,
      Paint()
        ..color = phaseColor
        ..strokeWidth = 0.08
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(-0.24, -0.08), 0.09, eye);
    canvas.drawCircle(Offset(0.24, -0.08), 0.09, eye);
  }

  Color get _phaseColor {
    return switch (_phaseIndex) {
      0 => GameTheme.cyan,
      1 => GameTheme.warning,
      _ => GameTheme.blood,
    };
  }
}
