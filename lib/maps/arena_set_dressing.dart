import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../core/theme/game_theme.dart';
import '../engine/nerve_runner_game.dart';
import 'room_visual_theme.dart';

class ArenaSetDressing extends Component
    with HasGameReference<NerveRunnerGame> {
  ArenaSetDressing({
    required this.bounds,
    required this.seed,
    required this.theme,
  }) : super(priority: -42);

  final Rect bounds;
  final int seed;
  final RoomVisualTheme theme;

  late final List<_FloorPanel> _panels;
  late final List<_CableRun> _cables;
  late final List<_SignalLight> _signalLights;
  late final List<_GlyphMark> _glyphs;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final random = math.Random(seed ^ _stableThemeSeed(theme.id));
    _panels = _buildPanels(random);
    _cables = _buildCables(random);
    _signalLights = _buildSignalLights(random);
    _glyphs = _buildGlyphs(random);
  }

  @override
  void render(Canvas canvas) {
    _renderPanels(canvas);
    _renderCables(canvas);
    _renderGlyphs(canvas);
    _renderSignalLights(canvas);
  }

  List<_FloorPanel> _buildPanels(math.Random random) {
    final panels = <_FloorPanel>[];
    final columns = math.max(4, (bounds.width / 5.6).floor());
    final rows = math.max(3, (bounds.height / 4.4).floor());
    final cellW = bounds.width / columns;
    final cellH = bounds.height / rows;
    for (var x = 0; x < columns; x += 1) {
      for (var y = 0; y < rows; y += 1) {
        if (random.nextDouble() < 0.34) {
          continue;
        }
        final center = Offset(
          bounds.left + cellW * (x + 0.5) + random.centered(0.28),
          bounds.top + cellH * (y + 0.5) + random.centered(0.22),
        );
        panels.add(
          _FloorPanel(
            rect: Rect.fromCenter(
              center: center,
              width: cellW * (0.48 + random.nextDouble() * 0.24),
              height: cellH * (0.42 + random.nextDouble() * 0.22),
            ),
            alpha: 0.035 + random.nextDouble() * 0.055,
          ),
        );
      }
    }
    return panels;
  }

  List<_CableRun> _buildCables(math.Random random) {
    return List<_CableRun>.generate(7, (index) {
      final horizontal = index.isEven;
      final anchor = horizontal
          ? bounds.top + 1.8 + random.nextDouble() * (bounds.height - 3.6)
          : bounds.left + 2.2 + random.nextDouble() * (bounds.width - 4.4);
      final points = <Offset>[];
      for (var i = 0; i < 5; i += 1) {
        final t = i / 4;
        final x = horizontal
            ? lerpDouble(bounds.left + 1.4, bounds.right - 1.4, t)!
            : anchor + random.centered(0.42);
        final y = horizontal
            ? anchor + random.centered(0.42)
            : lerpDouble(bounds.top + 1.2, bounds.bottom - 1.2, t)!;
        points.add(Offset(x, y));
      }
      return _CableRun(
        points: points,
        color: index % 3 == 0 ? theme.secondary : theme.primary,
        alpha: 0.09 + random.nextDouble() * 0.08,
      );
    });
  }

  List<_SignalLight> _buildSignalLights(math.Random random) {
    final lights = <_SignalLight>[];
    for (var i = 0; i < 12; i += 1) {
      final onHorizontal = i % 4 < 2;
      final position = onHorizontal
          ? Offset(
              bounds.left + (i + 1) * bounds.width / 13,
              i.isEven ? bounds.top + 0.42 : bounds.bottom - 0.42,
            )
          : Offset(
              i.isEven ? bounds.left + 0.42 : bounds.right - 0.42,
              bounds.top + (i + 1) * bounds.height / 13,
            );
      lights.add(
        _SignalLight(
          position: position,
          radius: 0.06 + random.nextDouble() * 0.035,
          phase: random.nextDouble() * math.pi * 2,
        ),
      );
    }
    return lights;
  }

  List<_GlyphMark> _buildGlyphs(math.Random random) {
    return List<_GlyphMark>.generate(5, (index) {
      return _GlyphMark(
        center: Offset(
          bounds.left + 4.0 + random.nextDouble() * (bounds.width - 8.0),
          bounds.top + 2.6 + random.nextDouble() * (bounds.height - 5.2),
        ),
        radius: 0.45 + random.nextDouble() * 0.45,
        rotation: random.nextDouble() * math.pi,
        color: index.isEven ? theme.primary : theme.secondary,
      );
    });
  }

  void _renderPanels(Canvas canvas) {
    final stroke = Paint()
      ..color = GameTheme.steel.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.018;
    for (final panel in _panels) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(panel.rect, const Radius.circular(0.08)),
        Paint()..color = theme.fog.withValues(alpha: panel.alpha),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(panel.rect, const Radius.circular(0.08)),
        stroke,
      );
    }
  }

  void _renderCables(Canvas canvas) {
    for (final cable in _cables) {
      final path = Path()..moveTo(cable.points.first.dx, cable.points.first.dy);
      for (var i = 1; i < cable.points.length; i += 1) {
        path.lineTo(cable.points[i].dx, cable.points[i].dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = GameTheme.voidBlack.withValues(alpha: 0.42)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.16
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = cable.color.withValues(alpha: cable.alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.045
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  void _renderSignalLights(Canvas canvas) {
    for (final light in _signalLights) {
      final alpha =
          0.24 + math.sin(game.elapsedTime * 2.2 + light.phase) * 0.08;
      canvas.drawCircle(
        light.position,
        light.radius * 3.8,
        Paint()
          ..color = theme.primary.withValues(alpha: alpha * 0.24)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.18),
      );
      canvas.drawCircle(
        light.position,
        light.radius,
        Paint()..color = theme.primary.withValues(alpha: alpha),
      );
    }
  }

  void _renderGlyphs(Canvas canvas) {
    for (final glyph in _glyphs) {
      canvas.save();
      canvas.translate(glyph.center.dx, glyph.center.dy);
      canvas.rotate(glyph.rotation);
      final paint = Paint()
        ..color = glyph.color.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.035
        ..strokeCap = StrokeCap.square;
      canvas.drawCircle(Offset.zero, glyph.radius, paint);
      canvas.drawLine(Offset(-glyph.radius, 0), Offset(glyph.radius, 0), paint);
      canvas.drawLine(
        Offset(0, -glyph.radius * 0.55),
        Offset(0, glyph.radius * 0.55),
        paint,
      );
      canvas.restore();
    }
  }
}

class _FloorPanel {
  const _FloorPanel({required this.rect, required this.alpha});

  final Rect rect;
  final double alpha;
}

class _CableRun {
  const _CableRun({
    required this.points,
    required this.color,
    required this.alpha,
  });

  final List<Offset> points;
  final Color color;
  final double alpha;
}

class _SignalLight {
  const _SignalLight({
    required this.position,
    required this.radius,
    required this.phase,
  });

  final Offset position;
  final double radius;
  final double phase;
}

class _GlyphMark {
  const _GlyphMark({
    required this.center,
    required this.radius,
    required this.rotation,
    required this.color,
  });

  final Offset center;
  final double radius;
  final double rotation;
  final Color color;
}

extension on math.Random {
  double centered(double radius) => nextDouble() * radius * 2 - radius;
}

int _stableThemeSeed(String value) {
  var hash = 0x811C9DC5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7FFFFFFF;
  }
  return hash;
}
