import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../core/theme/game_theme.dart';
import '../engine/nerve_runner_game.dart';

class NeonArenaBackground extends Component
    with HasGameReference<NerveRunnerGame> {
  NeonArenaBackground({required this.bounds, required this.seed})
    : super(priority: -50);

  final Rect bounds;
  final int seed;
  final math.Random _random = math.Random();
  late final List<_FloorScratch> _scratches;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _scratches = List<_FloorScratch>.generate(36, (index) {
      final x = bounds.left + _random.nextDouble() * bounds.width;
      final y = bounds.top + _random.nextDouble() * bounds.height;
      final length = 0.4 + _random.nextDouble() * 2.2;
      final angle = _random.nextDouble() * math.pi;
      return _FloorScratch(Vector2(x, y), length, angle);
    });
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(bounds.inflate(1.4), Paint()..color = GameTheme.voidBlack);
    canvas.drawRect(
      bounds,
      Paint()..color = GameTheme.asphalt.withValues(alpha: 0.94),
    );

    final grid = Paint()
      ..color = GameTheme.dimSteel.withValues(alpha: 0.18)
      ..strokeWidth = 0.022;
    for (var x = bounds.left.ceil(); x <= bounds.right; x += 1) {
      canvas.drawLine(
        Offset(x.toDouble(), bounds.top),
        Offset(x.toDouble(), bounds.bottom),
        grid,
      );
    }
    for (var y = bounds.top.ceil(); y <= bounds.bottom; y += 1) {
      canvas.drawLine(
        Offset(bounds.left, y.toDouble()),
        Offset(bounds.right, y.toDouble()),
        grid,
      );
    }

    final scratchPaint = Paint()
      ..color = GameTheme.magenta.withValues(alpha: 0.08)
      ..strokeWidth = 0.025
      ..strokeCap = StrokeCap.round;
    for (final scratch in _scratches) {
      final direction = Vector2(
        math.cos(scratch.angle),
        math.sin(scratch.angle),
      );
      final start = scratch.origin - direction * (scratch.length * 0.5);
      final end = scratch.origin + direction * (scratch.length * 0.5);
      canvas.drawLine(start.toOffset(), end.toOffset(), scratchPaint);
    }
  }
}

class _FloorScratch {
  const _FloorScratch(this.origin, this.length, this.angle);

  final Vector2 origin;
  final double length;
  final double angle;
}
