import 'dart:ui';

import '../core/theme/game_theme.dart';

class RoomVisualTheme {
  const RoomVisualTheme({
    required this.id,
    required this.floorBase,
    required this.floorDeep,
    required this.primary,
    required this.secondary,
    required this.hazard,
    required this.fog,
    this.gridAlpha = 0.18,
    this.grimeAlpha = 0.1,
  });

  final String id;
  final Color floorBase;
  final Color floorDeep;
  final Color primary;
  final Color secondary;
  final Color hazard;
  final Color fog;
  final double gridAlpha;
  final double grimeAlpha;

  static const RoomVisualTheme undercity = RoomVisualTheme(
    id: 'undercity',
    floorBase: Color(0xFF111821),
    floorDeep: GameTheme.voidBlack,
    primary: GameTheme.cyan,
    secondary: GameTheme.magenta,
    hazard: GameTheme.blood,
    fog: Color(0xFF142535),
  );

  static const RoomVisualTheme capacitor = RoomVisualTheme(
    id: 'split_capacitor',
    floorBase: Color(0xFF11171F),
    floorDeep: Color(0xFF070A0F),
    primary: GameTheme.cyan,
    secondary: GameTheme.acid,
    hazard: GameTheme.warning,
    fog: Color(0xFF0E3140),
    gridAlpha: 0.22,
    grimeAlpha: 0.12,
  );

  static const RoomVisualTheme railYard = RoomVisualTheme(
    id: 'rail_yard',
    floorBase: Color(0xFF14161C),
    floorDeep: Color(0xFF08090E),
    primary: GameTheme.warning,
    secondary: GameTheme.cyan,
    hazard: GameTheme.blood,
    fog: Color(0xFF30210F),
    gridAlpha: 0.16,
    grimeAlpha: 0.15,
  );

  static const RoomVisualTheme relay = RoomVisualTheme(
    id: 'relay_cross',
    floorBase: Color(0xFF13151F),
    floorDeep: Color(0xFF070911),
    primary: GameTheme.magenta,
    secondary: GameTheme.cyan,
    hazard: GameTheme.warning,
    fog: Color(0xFF30162D),
    gridAlpha: 0.2,
    grimeAlpha: 0.11,
  );

  static const RoomVisualTheme reactor = RoomVisualTheme(
    id: 'reactor_spine',
    floorBase: Color(0xFF101A19),
    floorDeep: Color(0xFF060C0D),
    primary: GameTheme.acid,
    secondary: GameTheme.cyan,
    hazard: GameTheme.blood,
    fog: Color(0xFF18341E),
    gridAlpha: 0.14,
    grimeAlpha: 0.16,
  );

  static const RoomVisualTheme clinic = RoomVisualTheme(
    id: 'dead_clinic',
    floorBase: Color(0xFF171820),
    floorDeep: Color(0xFF080A10),
    primary: Color(0xFFE7F0FF),
    secondary: GameTheme.blood,
    hazard: GameTheme.magenta,
    fog: Color(0xFF252C3A),
    gridAlpha: 0.12,
    grimeAlpha: 0.18,
  );
}
