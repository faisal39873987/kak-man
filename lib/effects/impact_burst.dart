import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../core/math/vector_math.dart';

class ImpactBurst extends PositionComponent {
  ImpactBurst({
    required Vector2 position,
    required this.color,
    this.particleCount = 14,
    this.lifetime = 0.34,
    this.speed = 7.5,
  }) : super(position: position.clone(), priority: 70);

  final Color color;
  final int particleCount;
  final double lifetime;
  final double speed;
  final math.Random _random = math.Random();
  late final List<_Particle> _particles;
  double _age = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _particles = List<_Particle>.generate(particleCount, (index) {
      final radians = _random.nextDouble() * math.pi * 2;
      final velocity = fromRadians(radians)
        ..scale(speed * (0.35 + _random.nextDouble() * 0.9));
      return _Particle(
        velocity: velocity,
        length: 0.08 + _random.nextDouble() * 0.22,
        stroke: 0.035 + _random.nextDouble() * 0.045,
      );
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= lifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / lifetime).clamp(0, 1).toDouble();
    final paint = Paint()
      ..color = color.withValues(alpha: 1 - t)
      ..strokeCap = StrokeCap.round;
    for (final particle in _particles) {
      final start = particle.velocity * (_age * 0.45);
      final end =
          start + particle.velocity.normalizedOrZero() * particle.length;
      paint.strokeWidth = particle.stroke * (1 - t);
      canvas.drawLine(start.toOffset(), end.toOffset(), paint);
    }
  }
}

class _Particle {
  const _Particle({
    required this.velocity,
    required this.length,
    required this.stroke,
  });

  final Vector2 velocity;
  final double length;
  final double stroke;
}
