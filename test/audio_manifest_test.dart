import 'dart:io';

import 'package:one_shot_nerve_runner/audio/audio_manifest.dart';
import 'package:test/test.dart';

void main() {
  test('audio manifest covers every cue with a bundled asset and mix', () {
    for (final cue in AudioCue.values) {
      final asset = AudioManifest.cueAssets[cue];

      expect(asset, isNotNull, reason: '${cue.name} needs an audio asset');
      expect(
        AudioManifest.cueMixes[cue],
        isNotNull,
        reason: '${cue.name} needs mix tuning',
      );
      expect(
        File('assets/$asset').existsSync(),
        isTrue,
        reason: 'Missing bundled audio asset for ${cue.name}: $asset',
      );
    }
  });
}
