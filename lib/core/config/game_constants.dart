class GameConstants {
  const GameConstants._();

  static const double worldZoom = 26;
  static const double roomWidth = 31;
  static const double roomHeight = 18;
  static const double arenaPadding = 1.2;

  static const double playerRadius = 0.44;
  static const double playerMoveSpeed = 9.8;
  static const double playerDashSpeed = 28;
  static const double playerDashDuration = 0.11;
  static const double playerDashCooldown = 0.28;
  static const double staminaMax = 100;
  static const double staminaRegenPerSecond = 34;
  static const double dashStaminaCost = 28;
  static const double perfectDodgeThreatMargin = 0.36;
  static const double perfectDodgeStaminaRefund = 18;
  static const double perfectDodgeInvulnerabilitySeconds = 0.18;
  static const int perfectDodgeScore = 75;

  static const int playerMaxHealth = 5;
  static const double invulnerabilitySeconds = 0.62;

  static const double bulletRadius = 0.07;
  static const double bulletSpeed = 29;
  static const double bulletLifetime = 0.72;

  static const double enemyRadius = 0.43;
  static const double enemyBaseSpeed = 4.0;
  static const double enemyStrikeRange = 0.9;
  static const double enemyStrikeCooldown = 0.8;

  static const double bossRadius = 0.85;
  static const int bossRoomInterval = 3;

  static const double comboTimeout = 2.4;
  static const int lowHealthThreshold = 2;
}
