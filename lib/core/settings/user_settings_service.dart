import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'user_settings.dart';

class UserSettingsService {
  static const String _settingsKey = 'one_shot_nerve_runner.settings.v1';

  Future<UserSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_settingsKey);
    if (raw == null || raw.isEmpty) {
      return UserSettings.defaults;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return UserSettings.defaults;
      }
      return UserSettings.fromJson(decoded.cast<String, Object?>());
    } on FormatException {
      return UserSettings.defaults;
    }
  }

  Future<void> save(UserSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_settingsKey, jsonEncode(settings.toJson()));
  }
}
