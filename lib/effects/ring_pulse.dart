import 'dart:ui';

import 'package:flame/components.dart';

class RingPulse extends PositionComponent {
  RingPulse({
    required Vector2 position,
    required this.color,
    required this.startRadius,
    required this.endRadius,
    this.lifetime = 0.36,
    this.strokeWidth = 0.08,
  }) : super(position: position.clone(), priority: 62);

  final Color color;
  final double startRadius;
  final double endRadius;
  final double lifetime;
  final double strokeWidth;
  double _age = 0;

  @override
  void update(double dt) {
    _age += dt;
    if (_age >= lifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / lifetime).clamp(0, 1).toDouble();
    final radius = lerpDouble(startRadius, endRadius, t) ?? endRadius;
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = color.withValues(alpha: 1 - t)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * (1 - t * 0.35),
    );
  }
}
