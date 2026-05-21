import 'dart:ui';

import 'package:flame/components.dart';

class MuzzleFlash extends PositionComponent {
  MuzzleFlash({
    required Vector2 position,
    required this.direction,
    required this.color,
  }) : super(position: position.clone(), priority: 65);

  final Vector2 direction;
  final Color color;
  double _age = 0;

  @override
  void update(double dt) {
    _age += dt;
    if (_age > 0.08) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1 - _age / 0.08).clamp(0, 1).toDouble();
    final paint = Paint()..color = color.withValues(alpha: alpha);
    final forward = direction.normalized();
    final right = Vector2(-forward.y, forward.x);
    final path = Path()
      ..moveTo((forward * 0.48).x, (forward * 0.48).y)
      ..lineTo((right * 0.13).x, (right * 0.13).y)
      ..lineTo((-forward * 0.08).x, (-forward * 0.08).y)
      ..lineTo((-right * 0.13).x, (-right * 0.13).y)
      ..close();
    canvas.drawPath(path, paint);
  }
}
