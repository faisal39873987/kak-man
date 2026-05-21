import 'package:rive/rive.dart';

enum MotionState { idle, run, dash, shoot, hurt, dead }

class RiveMotionController {
  RiveWidgetController? _controller;
  MotionFrame frame = MotionFrame.idle;
  MotionState state = MotionState.idle;

  void bindController(RiveWidgetController controller) {
    _controller = controller;
    _controller?.active = true;
  }

  void update({
    required double speed,
    required bool firing,
    required bool dashing,
    required bool hurt,
    required bool dead,
  }) {
    frame = MotionFrame(
      speed: speed,
      firing: firing,
      dashing: dashing,
      hurt: hurt,
      dead: dead,
    );
    state = dead
        ? MotionState.dead
        : hurt
        ? MotionState.hurt
        : dashing
        ? MotionState.dash
        : firing
        ? MotionState.shoot
        : speed > 0.1
        ? MotionState.run
        : MotionState.idle;
  }

  void dispose() {
    _controller?.active = false;
    _controller = null;
  }
}

class MotionFrame {
  const MotionFrame({
    required this.speed,
    required this.firing,
    required this.dashing,
    required this.hurt,
    required this.dead,
  });

  static const MotionFrame idle = MotionFrame(
    speed: 0,
    firing: false,
    dashing: false,
    hurt: false,
    dead: false,
  );

  final double speed;
  final bool firing;
  final bool dashing;
  final bool hurt;
  final bool dead;
}
