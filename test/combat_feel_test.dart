import 'dart:ui';

import 'package:flame/components.dart';
import 'package:one_shot_nerve_runner/core/input/input_state.dart';
import 'package:one_shot_nerve_runner/systems/combat/aim_assist_system.dart';
import 'package:test/test.dart';

void main() {
  group('InputState dash buffer', () {
    test('keeps a queued dash alive for the configured buffer window', () {
      final input = InputState()..queueDash(bufferSeconds: 0.12);

      expect(input.hasDashQueued, isTrue);
      expect(input.dashBufferRemaining, closeTo(0.12, 1e-9));

      input.update(0.05);

      expect(input.hasDashQueued, isTrue);
      expect(input.dashBufferRemaining, closeTo(0.07, 1e-9));
      expect(input.consumeDash(), isTrue);
      expect(input.hasDashQueued, isFalse);
    });

    test('expires buffered dash input instead of firing late', () {
      final input = InputState()..queueDash(bufferSeconds: 0.08);

      input.update(0.09);

      expect(input.hasDashQueued, isFalse);
      expect(input.consumeDash(), isFalse);
    });
  });

  group('AimAssistSystem', () {
    const assist = AimAssistSystem(range: 8, coneRadians: 0.25, blend: 0.5);

    test('nudges fire direction toward visible targets inside cone', () {
      final resolved = assist.resolve(
        origin: Vector2.zero(),
        rawDirection: Vector2(1, 0),
        targets: <AimAssistTarget>[
          AimAssistTarget(position: Vector2(6, 1), radius: 0.4),
        ],
      );

      expect(resolved.length, closeTo(1, 1e-6));
      expect(resolved.x, greaterThan(0.99));
      expect(resolved.y, greaterThan(0));
      expect(resolved.y, lessThan(0.1));
    });

    test('ignores targets outside the assist cone', () {
      final resolved = assist.resolve(
        origin: Vector2.zero(),
        rawDirection: Vector2(1, 0),
        targets: <AimAssistTarget>[
          AimAssistTarget(position: Vector2(4, 2.5), radius: 0.4),
        ],
      );

      expect(resolved.x, closeTo(1, 1e-9));
      expect(resolved.y, closeTo(0, 1e-9));
    });

    test('does not assist through projectile blockers', () {
      final resolved = assist.resolve(
        origin: Vector2.zero(),
        rawDirection: Vector2(1, 0),
        targets: <AimAssistTarget>[
          AimAssistTarget(position: Vector2(6, 0.6), radius: 0.4),
        ],
        blockers: <AimAssistBlocker>[
          AimAssistBlocker(bounds: Rect.fromLTRB(2.5, -0.4, 3.2, 0.8)),
        ],
      );

      expect(resolved.x, closeTo(1, 1e-9));
      expect(resolved.y, closeTo(0, 1e-9));
    });
  });
}
