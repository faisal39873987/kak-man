import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:one_shot_nerve_runner/core/settings/user_settings.dart';
import 'package:one_shot_nerve_runner/core/settings/user_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('user settings sanitize invalid persisted values', () {
    final settings = UserSettings.fromJson(const <String, Object?>{
      'touchControls': 'missing',
      'masterVolume': 4.5,
      'hapticsEnabled': false,
    });

    expect(settings.touchControls, TouchControlsPreference.auto);
    expect(settings.masterVolume, 1);
    expect(settings.hapticsEnabled, isFalse);
  });

  test(
    'user settings service round trips settings through preferences',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final service = UserSettingsService();
      final saved = UserSettings.defaults.copyWith(
        touchControls: TouchControlsPreference.alwaysOn,
        masterVolume: 0.34,
        hapticsEnabled: false,
      );

      await service.save(saved);
      final loaded = await service.load();

      expect(loaded.touchControls, TouchControlsPreference.alwaysOn);
      expect(loaded.masterVolume, closeTo(0.34, 1e-9));
      expect(loaded.hapticsEnabled, isFalse);
    },
  );

  test('user settings service falls back after corrupted json', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'one_shot_nerve_runner.settings.v1': '{"touchControls"',
    });

    final loaded = await UserSettingsService().load();

    expect(loaded.toJson(), UserSettings.defaults.toJson());
  });

  test('user settings service clamps legacy saved volume on load', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'one_shot_nerve_runner.settings.v1': jsonEncode(<String, Object>{
        'touchControls': TouchControlsPreference.alwaysOn.name,
        'masterVolume': -2,
        'hapticsEnabled': true,
      }),
    });

    final loaded = await UserSettingsService().load();

    expect(loaded.touchControls, TouchControlsPreference.alwaysOn);
    expect(loaded.masterVolume, 0);
    expect(loaded.hapticsEnabled, isTrue);
  });
}
