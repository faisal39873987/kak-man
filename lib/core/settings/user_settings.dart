enum TouchControlsPreference { auto, alwaysOn }

class UserSettings {
  const UserSettings({
    required this.touchControls,
    required this.masterVolume,
    required this.hapticsEnabled,
  });

  static const UserSettings defaults = UserSettings(
    touchControls: TouchControlsPreference.auto,
    masterVolume: 0.82,
    hapticsEnabled: true,
  );

  final TouchControlsPreference touchControls;
  final double masterVolume;
  final bool hapticsEnabled;

  factory UserSettings.fromJson(Map<String, Object?> json) {
    return UserSettings(
      touchControls: _touchControlsFromName(json['touchControls'] as String?),
      masterVolume: _volumeFromJson(json['masterVolume']),
      hapticsEnabled:
          (json['hapticsEnabled'] as bool?) ?? defaults.hapticsEnabled,
    );
  }

  Map<String, Object> toJson() {
    return <String, Object>{
      'touchControls': touchControls.name,
      'masterVolume': masterVolume,
      'hapticsEnabled': hapticsEnabled,
    };
  }

  UserSettings copyWith({
    TouchControlsPreference? touchControls,
    double? masterVolume,
    bool? hapticsEnabled,
  }) {
    return UserSettings(
      touchControls: touchControls ?? this.touchControls,
      masterVolume: _clampVolume(masterVolume ?? this.masterVolume),
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }

  static TouchControlsPreference _touchControlsFromName(String? name) {
    for (final preference in TouchControlsPreference.values) {
      if (preference.name == name) {
        return preference;
      }
    }
    return defaults.touchControls;
  }

  static double _volumeFromJson(Object? value) {
    return _clampVolume((value as num?)?.toDouble() ?? defaults.masterVolume);
  }

  static double _clampVolume(double value) {
    return value.clamp(0, 1).toDouble();
  }
}
