import 'dart:math' as math;

import 'package:one_shot_nerve_runner/audio/audio_manifest.dart';
import 'package:one_shot_nerve_runner/systems/audio/audio_mix_director.dart';
import 'package:test/test.dart';

void main() {
  test('combat pressure ramps music intensity and relaxes cleanly', () {
    final director = AudioMixDirector(random: math.Random(1));

    director.update(dt: 0.1, activeEnemies: 6, playerHealth: 1, combo: 12);

    expect(director.musicIntensity, greaterThan(0.4));
    expect(director.musicIntensity, lessThanOrEqualTo(1));

    director.update(dt: 0.1, activeEnemies: 0, playerHealth: 6, combo: 0);

    expect(director.musicIntensity, greaterThan(0));
    expect(director.musicIntensity, lessThan(0.4));
  });

  test('cue planning applies cooldowns, routing, and playback variation', () {
    final director = AudioMixDirector(masterVolume: 1, random: math.Random(2));

    final first = director.cue(AudioCue.shot);

    expect(first, isNotNull);
    expect(first!.asset, AudioManifest.cueAssets[AudioCue.shot]);
    expect(first.bus, AudioBus.weapon);
    expect(first.volume, greaterThan(0));
    expect(first.priority, AudioManifest.cueMixes[AudioCue.shot]!.priority);
    expect(first.playbackRate, greaterThanOrEqualTo(0.982));
    expect(first.playbackRate, lessThanOrEqualTo(1.018));
    expect(director.cue(AudioCue.shot), isNull);

    director.update(dt: 0.02, activeEnemies: 0, playerHealth: 6, combo: 0);

    expect(director.cue(AudioCue.shot), isNotNull);
  });

  test('high priority stingers duck combat buses then release', () {
    final director = AudioMixDirector(masterVolume: 1, random: math.Random(3));
    final dryDirector = AudioMixDirector(
      masterVolume: 1,
      random: math.Random(3),
    );

    final bossPlan = director.cue(AudioCue.bossPhase);

    expect(bossPlan, isNotNull);
    expect(bossPlan!.protectVoice, isTrue);
    expect(director.duckingFor(AudioBus.weapon), greaterThan(0.35));
    expect(director.duckingFor(AudioBus.movement), greaterThan(0.35));
    expect(director.duckingFor(AudioBus.ui), 0);

    final duckedShot = director.cue(AudioCue.shot);
    final dryShot = dryDirector.cue(AudioCue.shot);

    expect(duckedShot, isNotNull);
    expect(dryShot, isNotNull);
    expect(duckedShot!.volume, lessThan(dryShot!.volume));

    director.update(dt: 0.1, activeEnemies: 0, playerHealth: 6, combo: 0);

    expect(director.duckingFor(AudioBus.weapon), greaterThan(0));
    expect(director.duckingFor(AudioBus.weapon), lessThan(0.35));

    director.update(dt: 0.25, activeEnemies: 0, playerHealth: 6, combo: 0);

    expect(director.duckingFor(AudioBus.weapon), 0);
  });
}
