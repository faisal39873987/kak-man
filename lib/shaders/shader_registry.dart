import 'package:flutter/painting.dart';

import '../core/theme/game_theme.dart';

class ShaderRegistry {
  const ShaderRegistry._();

  static Gradient neonRoomGradient(Rect bounds) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        GameTheme.voidBlack,
        GameTheme.asphalt,
        GameTheme.voidBlack,
      ],
    );
  }
}
