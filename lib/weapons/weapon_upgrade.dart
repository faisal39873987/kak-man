enum WeaponUpgrade { overpressure, splitCapacitor, nerveRail, bloodRefund }

extension WeaponUpgradeTuning on Set<WeaponUpgrade> {
  double get damageMultiplier =>
      contains(WeaponUpgrade.overpressure) ? 1.28 : 1;
  double get cooldownMultiplier => contains(WeaponUpgrade.nerveRail) ? 0.78 : 1;
  int get pelletCount => contains(WeaponUpgrade.splitCapacitor) ? 2 : 1;
  bool get refundsStaminaOnKill => contains(WeaponUpgrade.bloodRefund);
}
