import 'dart:io';

import 'package:one_shot_nerve_runner/audio/audio_manifest.dart';
import 'package:test/test.dart';

void main() {
  test('audio manifest covers every cue with a bundled asset and mix', () {
    expect(AudioManifest.busVolumes.keys, unorderedEquals(AudioBus.values));

    for (final cue in AudioCue.values) {
      final asset = AudioManifest.cueAssets[cue];
      final mix = AudioManifest.cueMixes[cue];

      expect(asset, isNotNull, reason: '${cue.name} needs an audio asset');
      expect(mix, isNotNull, reason: '${cue.name} needs mix tuning');
      expect(
        File('assets/$asset').existsSync(),
        isTrue,
        reason: 'Missing bundled audio asset for ${cue.name}: $asset',
      );
      expect(
        AudioManifest.busVolumes[mix!.bus],
        isNotNull,
        reason: '${cue.name} routes to an unmixed bus',
      );
    }
  });
}
