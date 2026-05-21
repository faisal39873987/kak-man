enum MetaUnlockEffect {
  extraHeart,
  dashEfficiency,
  coolantLoop,
  nerveMagnet,
  combatDividend,
}

class MetaUnlockNode {
  const MetaUnlockNode({
    required this.id,
    required this.title,
    required this.description,
    required this.cost,
    required this.effect,
    required this.accentArgb,
    this.requires = const <String>[],
  });

  final String id;
  final String title;
  final String description;
  final int cost;
  final MetaUnlockEffect effect;
  final int accentArgb;
  final List<String> requires;
}

class MetaNodeState {
  const MetaNodeState({
    required this.node,
    required this.unlocked,
    required this.canUnlock,
  });

  final MetaUnlockNode node;
  final bool unlocked;
  final bool canUnlock;
}

class MetaProgressionSnapshot {
  const MetaProgressionSnapshot({required this.currency, required this.nodes});

  final int currency;
  final List<MetaNodeState> nodes;
}

class MetaProgressionSystem {
  MetaProgressionSystem({int currency = 0, Set<String>? unlocked})
    : _currency = currency,
      _unlocked = unlocked ?? <String>{};

  static const List<MetaUnlockNode> nodes = <MetaUnlockNode>[
    MetaUnlockNode(
      id: 'extra_heart',
      title: 'SECOND HEART',
      description: '+1 permanent starting health.',
      cost: 18,
      effect: MetaUnlockEffect.extraHeart,
      accentArgb: 0xFFFF3154,
    ),
    MetaUnlockNode(
      id: 'dash_efficiency',
      title: 'FRICTION KILL',
      description: 'Dash costs 12% less stamina.',
      cost: 14,
      effect: MetaUnlockEffect.dashEfficiency,
      accentArgb: 0xFF39F7FF,
    ),
    MetaUnlockNode(
      id: 'coolant_loop',
      title: 'COOLANT LOOP',
      description: 'Weapon heat builds slower and vents faster.',
      cost: 16,
      effect: MetaUnlockEffect.coolantLoop,
      accentArgb: 0xFFD6FF3F,
      requires: <String>['dash_efficiency'],
    ),
    MetaUnlockNode(
      id: 'nerve_magnet',
      title: 'NERVE MAGNET',
      description: '+20% persistent currency from rooms and kills.',
      cost: 20,
      effect: MetaUnlockEffect.nerveMagnet,
      accentArgb: 0xFFFFB03A,
    ),
    MetaUnlockNode(
      id: 'combat_dividend',
      title: 'COMBAT DIVIDEND',
      description: 'Combo chains increase persistent currency payout.',
      cost: 26,
      effect: MetaUnlockEffect.combatDividend,
      accentArgb: 0xFFFF2F8D,
      requires: <String>['nerve_magnet'],
    ),
  ];

  int _currency;
  final Set<String> _unlocked;

  int get currency => _currency;
  Set<String> get unlockedIds => Set<String>.unmodifiable(_unlocked);
  int get maxHealthBonus => _isUnlocked(MetaUnlockEffect.extraHeart) ? 1 : 0;
  double get dashCostMultiplier =>
      _isUnlocked(MetaUnlockEffect.dashEfficiency) ? 0.88 : 1;
  double get weaponHeatMultiplier =>
      _isUnlocked(MetaUnlockEffect.coolantLoop) ? 0.82 : 1;
  double get weaponCoolingMultiplier =>
      _isUnlocked(MetaUnlockEffect.coolantLoop) ? 1.24 : 1;
  double get currencyMultiplier =>
      _isUnlocked(MetaUnlockEffect.nerveMagnet) ? 1.2 : 1;
  bool get comboImprovesCurrency =>
      _isUnlocked(MetaUnlockEffect.combatDividend);

  MetaProgressionSnapshot snapshot() {
    return MetaProgressionSnapshot(
      currency: _currency,
      nodes: <MetaNodeState>[
        for (final node in nodes)
          MetaNodeState(
            node: node,
            unlocked: _unlocked.contains(node.id),
            canUnlock: canUnlock(node.id),
          ),
      ],
    );
  }

  bool canUnlock(String id) {
    final node = _nodeById(id);
    if (node == null || _unlocked.contains(id) || _currency < node.cost) {
      return false;
    }
    return node.requires.every(_unlocked.contains);
  }

  bool unlock(String id) {
    final node = _nodeById(id);
    if (node == null || !canUnlock(id)) {
      return false;
    }
    _currency -= node.cost;
    _unlocked.add(id);
    return true;
  }

  int grantRunCurrency(int amount) {
    if (amount <= 0) {
      return 0;
    }
    final scaled = (amount * currencyMultiplier).round();
    _currency += scaled;
    return scaled;
  }

  int killPayout({required String enemyId, required int combo}) {
    final base = enemyId == 'nerve_warden' ? 9 : 2;
    final comboBonus = comboImprovesCurrency ? (combo ~/ 4).clamp(0, 4) : 0;
    return base + comboBonus;
  }

  int roomClearPayout({required int room, required int comboBest}) {
    final comboBonus = comboImprovesCurrency ? (comboBest ~/ 3).clamp(0, 7) : 0;
    return 5 + room * 2 + comboBonus;
  }

  Map<String, Object> toJson() => <String, Object>{
    'currency': _currency,
    'unlocked': _unlocked.toList(growable: false),
  };

  factory MetaProgressionSystem.fromJson(Map<String, Object?> json) {
    final unlocked =
        (json['unlocked'] as List?)
            ?.whereType<String>()
            .where((id) => _nodeById(id) != null)
            .toSet() ??
        <String>{};
    return MetaProgressionSystem(
      currency: (json['currency'] as num?)?.toInt() ?? 0,
      unlocked: unlocked,
    );
  }

  bool _isUnlocked(MetaUnlockEffect effect) {
    return nodes.any(
      (node) => node.effect == effect && _unlocked.contains(node.id),
    );
  }

  static MetaUnlockNode? _nodeById(String id) {
    for (final node in nodes) {
      if (node.id == id) {
        return node;
      }
    }
    return null;
  }
}
