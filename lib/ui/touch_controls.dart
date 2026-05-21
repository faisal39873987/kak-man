import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../core/theme/game_theme.dart';

class TouchControls extends StatelessWidget {
  const TouchControls({
    required this.onMove,
    required this.onMoveEnd,
    required this.onAim,
    required this.onFireStart,
    required this.onFireEnd,
    required this.onDash,
    super.key,
  });

  final ValueChanged<Vector2> onMove;
  final VoidCallback onMoveEnd;
  final ValueChanged<Vector2> onAim;
  final VoidCallback onFireStart;
  final VoidCallback onFireEnd;
  final VoidCallback onDash;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width >= 900) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 18,
            bottom: 26,
            child: _Stick(
              icon: Icons.open_with_rounded,
              accent: GameTheme.cyan,
              onChanged: onMove,
              onEnd: onMoveEnd,
            ),
          ),
          Positioned(
            right: 22,
            bottom: 24,
            child: _Stick(
              icon: Icons.gps_fixed_rounded,
              accent: GameTheme.acid,
              onChanged: (value) {
                if (value.length2 > 0.04) {
                  onAim(value);
                }
              },
              onStart: onFireStart,
              onEnd: onFireEnd,
            ),
          ),
          Positioned(
            right: 132,
            bottom: 94,
            child: _ActionButton(
              icon: Icons.flash_on_rounded,
              accent: GameTheme.magenta,
              onPressed: onDash,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stick extends StatefulWidget {
  const _Stick({
    required this.icon,
    required this.accent,
    required this.onChanged,
    required this.onEnd,
    this.onStart,
  });

  final IconData icon;
  final Color accent;
  final ValueChanged<Vector2> onChanged;
  final VoidCallback onEnd;
  final VoidCallback? onStart;

  @override
  State<_Stick> createState() => _StickState();
}

class _StickState extends State<_Stick> {
  static const double _size = 118;
  static const double _knob = 48;
  Vector2 _value = Vector2.zero();

  void _update(Offset localPosition) {
    final center = const Offset(_size / 2, _size / 2);
    final delta = localPosition - center;
    final vector = Vector2(delta.dx, delta.dy);
    final normalized = vector.length > 42
        ? (vector.normalized()..scale(1))
        : vector / 42;
    setState(() {
      _value = normalized;
    });
    widget.onChanged(normalized);
  }

  void _end() {
    setState(() {
      _value = Vector2.zero();
    });
    widget.onEnd();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) {
        widget.onStart?.call();
        _update(details.localPosition);
      },
      onPanUpdate: (details) => _update(details.localPosition),
      onPanEnd: (_) => _end(),
      onPanCancel: _end,
      onTapDown: (details) {
        widget.onStart?.call();
        _update(details.localPosition);
      },
      onTapUp: (_) => _end(),
      onTapCancel: _end,
      child: SizedBox.square(
        dimension: _size,
        child: CustomPaint(
          painter: _StickPainter(
            value: _value,
            accent: widget.accent,
            icon: widget.icon,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.accent,
    required this.onPressed,
  });

  final IconData icon;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 58,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: accent,
        style: IconButton.styleFrom(
          backgroundColor: GameTheme.panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: accent.withValues(alpha: 0.36)),
          ),
        ),
      ),
    );
  }
}

class _StickPainter extends CustomPainter {
  const _StickPainter({
    required this.value,
    required this.accent,
    required this.icon,
  });

  final Vector2 value;
  final Color accent;
  final IconData icon;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final knobCenter = center + Offset(value.x, value.y) * 34;
    final shell = Paint()
      ..color = GameTheme.panel
      ..style = PaintingStyle.fill;
    final ring = Paint()
      ..color = accent.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final glow = Paint()
      ..color = accent.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final knob = Paint()..color = accent.withValues(alpha: 0.2);

    canvas.drawCircle(center, size.width / 2, glow);
    canvas.drawCircle(center, size.width / 2 - 2, shell);
    canvas.drawCircle(center, size.width / 2 - 3, ring);
    canvas.drawCircle(knobCenter, _StickState._knob / 2, knob);

    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: 24,
          color: accent.withValues(alpha: 0.8),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      knobCenter - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _StickPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.accent != accent;
  }
}
