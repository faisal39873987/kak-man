import 'dart:math' as math;

import '../weapons/weapon_blueprint.dart';
import '../weapons/weapon_catalog.dart';
import '../weapons/weapon_upgrade.dart';

enum RewardEffect {
  weaponUpgrade,
  weaponSwap,
  dermalPlating,
  adrenalBattery,
  tensionDividend,
  dashBattery,
  quickPatch,
}

class RewardChoice {
  const RewardChoice({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.effect,
    required this.accentArgb,
    this.weaponUpgrade,
    this.weaponId,
  });

  final String id;
  final String title;
  final String subtitle;
  final RewardEffect effect;
  final int accentArgb;
  final WeaponUpgrade? weaponUpgrade;
  final String? weaponId;
}

class RewardPalette {
  const RewardPalette._();

  static const int cyan = 0xFF39F7FF;
  static const int magenta = 0xFFFF2F8D;
  static const int acid = 0xFFD6FF3F;
  static const int warning = 0xFFFFB03A;
  static const int blood = 0xFFFF3154;
}

class RunUpgradeSystem {
  final Set<RewardEffect> acquired = <RewardEffect>{};

  int get maxHealthBonus =>
      acquired.contains(RewardEffect.dermalPlating) ? 1 : 0;
  double get staminaCapacityBonus =>
      acquired.contains(RewardEffect.adrenalBattery) ? 26 : 0;
  double get staminaRegenMultiplier =>
      acquired.contains(RewardEffect.adrenalBattery) ? 1.13 : 1;
  double get scoreMultiplier =>
      acquired.contains(RewardEffect.tensionDividend) ? 1.22 : 1;
  bool get refundsStaminaOnDashKill =>
      acquired.contains(RewardEffect.dashBattery);

  void reset() {
    acquired.clear();
  }

  void acquire(RewardChoice choice) {
    if (choice.effect == RewardEffect.quickPatch ||
        choice.effect == RewardEffect.weaponUpgrade ||
        choice.effect == RewardEffect.weaponSwap) {
      return;
    }
    acquired.add(choice.effect);
  }
}

class RewardDeck {
  List<RewardChoice> draft({
    required math.Random random,
    required Set<WeaponUpgrade> ownedWeaponUpgrades,
    required Set<RewardEffect> ownedRunEffects,
    required int currentHealth,
    required int maxHealth,
    String currentWeaponId = WeaponCatalog.defaultWeaponId,
    Set<String>? availableWeaponIds,
  }) {
    final weaponIds =
        availableWeaponIds ??
        WeaponCatalog.all.map((blueprint) => blueprint.id).toSet();
    final pool = <RewardChoice>[
      for (final blueprint in WeaponCatalog.all)
        if (weaponIds.contains(blueprint.id) && blueprint.id != currentWeaponId)
          _weaponSwapChoice(blueprint),
      for (final upgrade in WeaponUpgrade.values)
        if (!ownedWeaponUpgrades.contains(upgrade)) _weaponChoice(upgrade),
      if (!ownedRunEffects.contains(RewardEffect.dermalPlating))
        const RewardChoice(
          id: 'dermal_plating',
          title: 'DERMAL PLATING',
          subtitle: '+1 max health and immediate repair',
          effect: RewardEffect.dermalPlating,
          accentArgb: RewardPalette.blood,
        ),
      if (!ownedRunEffects.contains(RewardEffect.adrenalBattery))
        const RewardChoice(
          id: 'adrenal_battery',
          title: 'ADRENAL BATTERY',
          subtitle: '+26 stamina capacity and faster regen',
          effect: RewardEffect.adrenalBattery,
          accentArgb: RewardPalette.cyan,
        ),
      if (!ownedRunEffects.contains(RewardEffect.tensionDividend))
        const RewardChoice(
          id: 'tension_dividend',
          title: 'TENSION DIVIDEND',
          subtitle: '+22% score from kills and room clears',
          effect: RewardEffect.tensionDividend,
          accentArgb: RewardPalette.acid,
        ),
      if (!ownedRunEffects.contains(RewardEffect.dashBattery))
        const RewardChoice(
          id: 'dash_battery',
          title: 'DASH BATTERY',
          subtitle: 'Kills restore stamina after high-mobility plays',
          effect: RewardEffect.dashBattery,
          accentArgb: RewardPalette.magenta,
        ),
      RewardChoice(
        id: 'quick_patch',
        title: 'QUICK PATCH',
        subtitle: currentHealth < maxHealth
            ? 'Restore 2 health and refill stamina'
            : 'Refill stamina and bank a safer next room',
        effect: RewardEffect.quickPatch,
        accentArgb: RewardPalette.warning,
      ),
    ];

    pool.shuffle(random);
    return pool.take(3).toList(growable: false);
  }

  RewardChoice _weaponChoice(WeaponUpgrade upgrade) {
    return switch (upgrade) {
      WeaponUpgrade.overpressure => const RewardChoice(
        id: 'weapon_overpressure',
        title: 'OVERPRESSURE',
        subtitle: '+28% bullet damage',
        effect: RewardEffect.weaponUpgrade,
        weaponUpgrade: WeaponUpgrade.overpressure,
        accentArgb: RewardPalette.blood,
      ),
      WeaponUpgrade.splitCapacitor => const RewardChoice(
        id: 'weapon_split_capacitor',
        title: 'SPLIT CAPACITOR',
        subtitle: 'Fire paired neon rounds with each shot',
        effect: RewardEffect.weaponUpgrade,
        weaponUpgrade: WeaponUpgrade.splitCapacitor,
        accentArgb: RewardPalette.magenta,
      ),
      WeaponUpgrade.nerveRail => const RewardChoice(
        id: 'weapon_nerve_rail',
        title: 'NERVE RAIL',
        subtitle: 'Shorter weapon cooldown',
        effect: RewardEffect.weaponUpgrade,
        weaponUpgrade: WeaponUpgrade.nerveRail,
        accentArgb: RewardPalette.cyan,
      ),
      WeaponUpgrade.bloodRefund => const RewardChoice(
        id: 'weapon_blood_refund',
        title: 'BLOOD REFUND',
        subtitle: 'Kills refund stamina',
        effect: RewardEffect.weaponUpgrade,
        weaponUpgrade: WeaponUpgrade.bloodRefund,
        accentArgb: RewardPalette.acid,
      ),
    };
  }

  RewardChoice _weaponSwapChoice(WeaponBlueprint blueprint) {
    return RewardChoice(
      id: 'weapon_swap_${blueprint.id}',
      title: blueprint.name,
      subtitle: 'Swap weapon platform for this run',
      effect: RewardEffect.weaponSwap,
      weaponId: blueprint.id,
      accentArgb: switch (blueprint.id) {
        WeaponCatalog.ionStitcherId => RewardPalette.cyan,
        WeaponCatalog.voltLanceId => RewardPalette.acid,
        _ => RewardPalette.magenta,
      },
    );
  }
}
