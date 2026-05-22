import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../core/theme/game_theme.dart';
import '../engine/nerve_runner_game.dart';
import 'room_visual_theme.dart';

class NeonArenaBackground extends Component
    with HasGameReference<NerveRunnerGame> {
  NeonArenaBackground({
    required this.bounds,
    required this.seed,
    this.theme = RoomVisualTheme.undercity,
  }) : super(priority: -50);

  final Rect bounds;
  final int seed;
  final RoomVisualTheme theme;
  late final List<_FloorScratch> _scratches;
  late final List<_FloorStain> _stains;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final random = math.Random(seed);
    _scratches = List<_FloorScratch>.generate(36, (index) {
      final x = bounds.left + random.nextDouble() * bounds.width;
      final y = bounds.top + random.nextDouble() * bounds.height;
      final length = 0.4 + random.nextDouble() * 2.2;
      final angle = random.nextDouble() * math.pi;
      return _FloorScratch(Vector2(x, y), length, angle);
    });
    _stains = List<_FloorStain>.generate(12, (index) {
      return _FloorStain(
        Offset(
          bounds.left + random.nextDouble() * bounds.width,
          bounds.top + random.nextDouble() * bounds.height,
        ),
        0.5 + random.nextDouble() * 2.2,
        0.16 + random.nextDouble() * 0.16,
      );
    });
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(bounds.inflate(1.4), Paint()..color = GameTheme.voidBlack);
    canvas.drawRect(bounds, Paint()..shader = _floorShader());
    canvas.drawRect(bounds, Paint()..shader = _vignetteShader());
    _renderStains(canvas);
    _renderGrid(canvas);
    _renderScratches(canvas);
    _renderScanlines(canvas);
  }

  Shader _floorShader() {
    return Gradient.linear(
      bounds.topLeft,
      bounds.bottomRight,
      <Color>[
        theme.floorBase,
        theme.floorDeep,
        Color.lerp(theme.floorBase, theme.primary, 0.08)!,
        theme.floorDeep,
      ],
      <double>[0, 0.42, 0.74, 1],
    );
  }

  Shader _vignetteShader() {
    return Gradient.radial(
      bounds.center,
      bounds.width * 0.62,
      <Color>[
        GameTheme.voidBlack.withValues(alpha: 0),
        theme.fog.withValues(alpha: 0.08),
        GameTheme.voidBlack.withValues(alpha: 0.66),
      ],
      <double>[0.2, 0.72, 1],
    );
  }

  void _renderGrid(Canvas canvas) {
    final grid = Paint()
      ..color = theme.primary.withValues(alpha: theme.gridAlpha * 0.42)
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
    final coarse = Paint()
      ..color = GameTheme.steel.withValues(alpha: 0.05)
      ..strokeWidth = 0.035;
    for (var x = bounds.left.ceil(); x <= bounds.right; x += 4) {
      canvas.drawLine(
        Offset(x.toDouble(), bounds.top),
        Offset(x.toDouble(), bounds.bottom),
        coarse,
      );
    }
    for (var y = bounds.top.ceil(); y <= bounds.bottom; y += 4) {
      canvas.drawLine(
        Offset(bounds.left, y.toDouble()),
        Offset(bounds.right, y.toDouble()),
        coarse,
      );
    }
  }

  void _renderScratches(Canvas canvas) {
    final scratchPaint = Paint()
      ..color = theme.secondary.withValues(alpha: theme.grimeAlpha)
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

  void _renderStains(Canvas canvas) {
    for (final stain in _stains) {
      canvas.drawCircle(
        stain.center,
        stain.radius,
        Paint()
          ..color = GameTheme.voidBlack.withValues(alpha: stain.alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.45),
      );
    }
  }

  void _renderScanlines(Canvas canvas) {
    final paint = Paint()
      ..color = theme.secondary.withValues(alpha: 0.035)
      ..strokeWidth = 0.014;
    for (var y = bounds.top + 0.25; y < bounds.bottom; y += 0.55) {
      canvas.drawLine(Offset(bounds.left, y), Offset(bounds.right, y), paint);
    }
  }
}

class _FloorScratch {
  const _FloorScratch(this.origin, this.length, this.angle);

  final Vector2 origin;
  final double length;
  final double angle;
}

class _FloorStain {
  const _FloorStain(this.center, this.radius, this.alpha);

  final Offset center;
  final double radius;
  final double alpha;
}
