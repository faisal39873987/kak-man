class BossPhase {
  const BossPhase({
    required this.name,
    required this.healthThreshold,
    required this.speedMultiplier,
    required this.spawnAdds,
  });

  final String name;
  final double healthThreshold;
  final double speedMultiplier;
  final int spawnAdds;
}
