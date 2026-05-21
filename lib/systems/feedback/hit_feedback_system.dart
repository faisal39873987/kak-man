import 'dart:ui';

import 'package:flame/components.dart';

import '../../audio/audio_manifest.dart';
import '../../core/theme/game_theme.dart';
import '../../effects/impact_burst.dart';
import '../../effects/muzzle_flash.dart';
import '../../effects/ring_pulse.dart';
import '../../engine/nerve_runner_game.dart';

class HitFeedbackSystem {
  HitFeedbackSystem(this.game);

  final NerveRunnerGame game;

  void muzzle(Vector2 position, Vector2 direction) {
    game.world.add(
      MuzzleFlash(
        position: position,
        direction: direction,
        color: GameTheme.acid,
      ),
    );
    game.cameraController.kick(0.05);
  }

  void hit(Vector2 position, {Color color = GameTheme.magenta}) {
    game.world.add(
      ImpactBurst(position: position, color: color, particleCount: 13),
    );
    game.cameraController.kick(0.09);
    game.audio.cue(AudioCue.hit);
  }

  void coverHit(Vector2 position) {
    game.world.add(
      ImpactBurst(
        position: position,
        color: GameTheme.dimSteel,
        particleCount: 8,
        lifetime: 0.18,
        speed: 4.2,
      ),
    );
    game.cameraController.kick(0.035);
    game.audio.cue(AudioCue.coverHit);
  }

  void kill(Vector2 position) {
    game.world.add(
      ImpactBurst(
        position: position,
        color: GameTheme.acid,
        particleCount: 24,
        lifetime: 0.45,
        speed: 10,
      ),
    );
    game.cameraController.kick(0.22);
    game.slowMotion.trigger();
    game.audio.cue(AudioCue.kill);
  }

  void dash(Vector2 position, Vector2 direction) {
    game.world.add(
      ImpactBurst(
        position: position - direction * 0.45,
        color: GameTheme.cyan,
        particleCount: 16,
        lifetime: 0.22,
        speed: 8.5,
      ),
    );
    game.world.add(
      RingPulse(
        position: position,
        color: GameTheme.cyan,
        startRadius: 0.28,
        endRadius: 1.2,
        lifetime: 0.2,
        strokeWidth: 0.055,
      ),
    );
    game.cameraController.kick(0.12);
  }

  void roomClear(Vector2 position) {
    game.world.add(
      RingPulse(
        position: position,
        color: GameTheme.acid,
        startRadius: 0.9,
        endRadius: 5.6,
        lifetime: 0.52,
        strokeWidth: 0.09,
      ),
    );
    game.cameraController.kick(0.16);
    game.audio.cue(AudioCue.roomClear);
  }

  void hazardWarning(Vector2 position) {
    game.world.add(
      RingPulse(
        position: position,
        color: GameTheme.warning,
        startRadius: 0.22,
        endRadius: 1.0,
        lifetime: 0.28,
        strokeWidth: 0.05,
      ),
    );
    game.audio.cue(AudioCue.hazardWarning);
  }

  void weaponOverheat(Vector2 position) {
    game.world.add(
      RingPulse(
        position: position,
        color: GameTheme.warning,
        startRadius: 0.26,
        endRadius: 0.92,
        lifetime: 0.24,
        strokeWidth: 0.065,
      ),
    );
    game.cameraController.kick(0.04);
    game.audio.cue(AudioCue.weaponOverheat);
  }

  void playerHurt(Vector2 position) {
    game.world.add(
      ImpactBurst(
        position: position,
        color: GameTheme.blood,
        particleCount: 26,
        lifetime: 0.5,
        speed: 9,
      ),
    );
    game.cameraController.kick(0.28);
    game.slowMotion.trigger(duration: 0.1, scale: 0.42);
    game.audio.cue(AudioCue.playerHurt);
  }
}
