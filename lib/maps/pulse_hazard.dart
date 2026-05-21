import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../core/theme/game_theme.dart';
import '../engine/nerve_runner_game.dart';

class PulseHazard extends Component with HasGameReference<NerveRunnerGame> {
  PulseHazard({
    required this.bounds,
    required this.period,
    required this.windup,
    required this.active,
    required this.seedOffset,
    this.damage = 1,
  }) : super(priority: -8);

  final Rect bounds;
  final double period;
  final double windup;
  final double active;
  final double seedOffset;
  final int damage;

  double _clock = 0;
  bool _damageResolved = false;
  bool _wasWinding = false;

  double get _phase => (_clock + seedOffset) % period;
  bool get _isWinding => _phase < windup;
  bool get _isActive => _phase >= windup && _phase < windup + active;

  @override
  void update(double dt) {
    super.update(dt);
    _clock += dt;
    final winding = _isWinding;
    if (winding && !_wasWinding) {
      final warningArea = bounds.inflate(1.35);
      if (warningArea.contains(game.player.position.toOffset())) {
        game.feedback.hazardWarning(
          Vector2(bounds.center.dx, bounds.center.dy),
        );
      }
    }
    _wasWinding = winding;
    if (!_isActive) {
      _damageResolved = false;
      return;
    }
    if (_damageResolved || game.player.isDead) {
      return;
    }
    if (bounds.contains(game.player.position.toOffset())) {
      _damageResolved = true;
      game.damagePlayer(damage, Vector2(bounds.center.dx, bounds.center.dy));
    }
  }

  @override
  void render(Canvas canvas) {
    final base = Paint()
      ..color = GameTheme.blood.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    final edge = Paint()
      ..color = GameTheme.blood.withValues(alpha: 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.035;
    canvas.drawRect(bounds, base);
    canvas.drawRect(bounds, edge);

    if (_isWinding || _isActive) {
      final progress = _isWinding
          ? (_phase / windup).clamp(0, 1).toDouble()
          : 1.0;
      final pulseAlpha = _isActive
          ? 0.46 + math.sin(game.elapsedTime * 38) * 0.18
          : 0.14 + progress * 0.3;
      final hot = Paint()
        ..color = (_isActive ? GameTheme.blood : GameTheme.warning).withValues(
          alpha: pulseAlpha,
        )
        ..style = PaintingStyle.fill;
      final inset = math.max(0.03, 0.24 * (1 - progress));
      canvas.drawRect(bounds.deflate(inset), hot);
    }
  }
}
