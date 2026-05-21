import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../audio/audio_manifest.dart';
import '../core/config/game_constants.dart';
import '../core/input/input_state.dart';
import '../core/math/vector_math.dart';
import '../core/theme/game_theme.dart';
import '../enemies/adaptive_enemy.dart';
import '../enemies/enemy_factory.dart';
import '../entities/player/runner_player.dart';
import '../entities/projectiles/bullet_projectile.dart';
import '../maps/arena_obstacle.dart';
import '../maps/combat_room.dart';
import '../maps/room_generator.dart';
import '../progression/meta_progression.dart';
import '../progression/player_evolution_system.dart';
import '../progression/reward_choice.dart';
import '../save/game_save_data.dart';
import '../save/save_service.dart';
import '../systems/audio/reactive_audio_system.dart';
import '../systems/combat/combo_chain_system.dart';
import '../systems/difficulty/dynamic_difficulty_system.dart';
import '../systems/feedback/hit_feedback_system.dart';
import '../systems/time/slow_motion_system.dart';
import '../ui/hud_snapshot.dart';
import '../weapons/nerve_pistol.dart';
import '../weapons/weapon.dart';
import '../weapons/weapon_factory.dart';
import '../weapons/weapon_upgrade.dart';
import 'camera/game_camera_controller.dart';

class NerveRunnerGame extends Forge2DGame {
  NerveRunnerGame({bool shellPaused = false})
    : _shellPaused = shellPaused,
      super(gravity: Vector2.zero(), zoom: GameConstants.worldZoom) {
    cameraController = GameCameraController(this);
    feedback = HitFeedbackSystem(this);
  }

  final InputState input = InputState();
  final ValueNotifier<HudSnapshot> hud = ValueNotifier<HudSnapshot>(
    HudSnapshot.initial(),
  );
  final RoomGenerator roomGenerator = RoomGenerator();
  final RewardDeck rewardDeck = RewardDeck();
  final WeaponFactory weaponFactory = const WeaponFactory();
  final SaveService _saveService = SaveService();
  final math.Random _random = math.Random();

  late final GameCameraController cameraController;
  late final HitFeedbackSystem feedback;
  late RunnerPlayer player;
  late CombatRoom currentRoom;
  late EnemyFactory enemyFactory;

  DynamicDifficultySystem difficulty = DynamicDifficultySystem();
  ComboChainSystem combo = ComboChainSystem();
  PlayerEvolutionSystem evolution = PlayerEvolutionSystem();
  MetaProgressionSystem metaProgression = MetaProgressionSystem();
  RunUpgradeSystem runUpgrades = RunUpgradeSystem();
  SlowMotionSystem slowMotion = SlowMotionSystem();
  ReactiveAudioSystem audio = ReactiveAudioSystem();
  Weapon weapon = NervePistol();

  final List<AdaptiveEnemy> enemies = <AdaptiveEnemy>[];
  final List<BulletProjectile> bullets = <BulletProjectile>[];
  final List<ArenaObstacle> obstructions = <ArenaObstacle>[];
  final List<Component> _roomComponents = <Component>[];
  final Set<AdaptiveEnemy> _perfectDodgeClaims = <AdaptiveEnemy>{};
  List<RewardChoice> _activeRewards = <RewardChoice>[];

  GameSaveData _saveData = GameSaveData.fresh();
  bool _loaded = false;
  bool _transitioningRoom = false;
  bool _showingProgression = false;
  bool _shellPaused;
  bool runPaused = false;
  double elapsedTime = 0;
  double _weaponBlockedFeedbackCooldown = 0;
  int roomIndex = 1;
  int score = 0;
  int runKills = 0;
  int _persistedRunKills = 0;
  int runNerve = 0;
  int _persistedRunNerve = 0;
  int _seed = 1;

  double get baseZoom => GameConstants.worldZoom;
  bool get isReady => _loaded;

  @override
  Color backgroundColor() => GameTheme.voidBlack;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.center;
    enemyFactory = EnemyFactory(_random);
    await audio.initialize();
    _saveData = await _saveService.load();
    evolution.absorb(_saveData.evolution);
    metaProgression = MetaProgressionSystem.fromJson(
      _saveData.metaProgression.cast<String, Object?>(),
    );
    await restartRun(preserveEvolution: true);
    _loaded = true;
    _refreshHud();
  }

  Future<void> restartRun({bool preserveEvolution = false}) async {
    runPaused = false;
    input.isFiring = false;
    input.clearTouchMovement();
    _activeRewards = <RewardChoice>[];
    _showingProgression = false;
    elapsedTime = 0;
    roomIndex = 1;
    score = 0;
    runKills = 0;
    _persistedRunKills = 0;
    runNerve = 0;
    _persistedRunNerve = 0;
    _seed = DateTime.now().millisecondsSinceEpoch;
    difficulty = DynamicDifficultySystem();
    combo = ComboChainSystem();
    slowMotion = SlowMotionSystem();
    weapon = weaponFactory.createDefault();
    _applyMetaWeaponTuning();
    _weaponBlockedFeedbackCooldown = 0;
    runUpgrades = RunUpgradeSystem();
    if (!preserveEvolution) {
      evolution = PlayerEvolutionSystem();
    }
    await _loadRoom();
    _refreshHud();
  }

  void setPointerAim(Offset localPosition) {
    if (!_loaded || player.isDead) {
      return;
    }
    final target = screenToWorld(Vector2(localPosition.dx, localPosition.dy));
    input.setAimWorld(player.position, target);
  }

  void setTouchMovement(Vector2 direction) {
    input.setTouchMovement(direction);
  }

  void clearTouchMovement() {
    input.clearTouchMovement();
  }

  void setTouchAim(Vector2 direction) {
    input.setAimDirection(direction);
  }

  void queueDash() {
    input.dashQueued = true;
  }

  void startFire() {
    input.isFiring = true;
  }

  void stopFire() {
    input.isFiring = false;
  }

  void handleKeyEvent(KeyEvent event) {
    if (!_loaded) {
      return;
    }
    final key = event.logicalKey;
    final pressed = event is KeyDownEvent || event is KeyRepeatEvent;
    if (event is KeyUpEvent) {
      input.setKey(key, pressed: false);
      return;
    }
    input.setKey(key, pressed: pressed);
    if (event is KeyDownEvent) {
      if (key == LogicalKeyboardKey.space ||
          key == LogicalKeyboardKey.shiftLeft ||
          key == LogicalKeyboardKey.shiftRight) {
        input.dashQueued = true;
      }
      if (key == LogicalKeyboardKey.keyP || key == LogicalKeyboardKey.escape) {
        togglePause();
      }
      if (key == LogicalKeyboardKey.keyR && player.isDead) {
        unawaited(restartRun());
      }
    }
  }

  void togglePause() {
    if (!_loaded || player.isDead || _activeRewards.isNotEmpty) {
      return;
    }
    runPaused = !runPaused;
    _refreshHud();
  }

  void setShellPaused(bool paused) {
    _shellPaused = paused;
    if (paused) {
      input.isFiring = false;
      input.clearTouchMovement();
      input.clearTransient();
    }
    _refreshHud();
  }

  void resumeRun() {
    runPaused = false;
    _showingProgression = false;
    _refreshHud();
  }

  @override
  void update(double dt) {
    if (!_loaded) {
      super.update(dt);
      return;
    }
    if (_shellPaused ||
        runPaused ||
        _activeRewards.isNotEmpty ||
        _showingProgression) {
      _refreshHud();
      return;
    }

    final scaledDt = slowMotion.updateAndScale(dt);
    elapsedTime += scaledDt;
    _weaponBlockedFeedbackCooldown = (_weaponBlockedFeedbackCooldown - scaledDt)
        .clamp(0, 10);
    weapon.update(scaledDt);
    if (!player.isDead && (input.isFiring || input.keyboardFire)) {
      _tryFire();
    }

    super.update(scaledDt);
    _cleanupLists();
    _detectPerfectDodges();

    difficulty.update(
      dt: scaledDt,
      playerHealth: player.health,
      playerAccuracy: evolution.profile.accuracy,
      activeEnemies: enemies.length,
      combo: combo.chain,
    );
    combo.update(scaledDt);
    audio.update(
      dt: scaledDt,
      activeEnemies: enemies.length,
      playerHealth: player.health,
      combo: combo.chain,
    );
    cameraController.update(dt, player.position, player.body.linearVelocity);

    if (!_transitioningRoom && enemies.isEmpty && !player.isDead) {
      _completeRoom();
    }
    _refreshHud();
  }

  void _tryFire() {
    final origin = player.position + input.aimWorld * 0.55;
    final fired = weapon.tryFire(
      WeaponFireContext(
        origin: origin,
        direction: input.aimWorld.normalizedOrZero(),
        damageScale: evolution.shotDamageMultiplier * combo.multiplier,
        spawn: spawnProjectile,
      ),
    );
    if (!fired) {
      if (weapon.overheated && _weaponBlockedFeedbackCooldown <= 0) {
        feedback.weaponOverheat(origin);
        _weaponBlockedFeedbackCooldown = 0.32;
      }
      return;
    }
    evolution.registerShot();
    feedback.muzzle(origin, input.aimWorld);
    unawaited(audio.cue(AudioCue.shot));
  }

  void spawnProjectile(BulletProjectile projectile) {
    bullets.add(projectile);
    world.add(projectile);
  }

  void resolveProjectileHit(BulletProjectile projectile, AdaptiveEnemy enemy) {
    evolution.registerHit();
    combo.registerHit();
    final hitDirection = projectile.direction.normalizedOrZero();
    feedback.hit(enemy.position);
    enemy.takeDamage(projectile.damage, hitDirection);
  }

  void onEnemyKilled(AdaptiveEnemy enemy) {
    enemies.remove(enemy);
    runKills += 1;
    combo.registerKill();
    final distanceToPlayer = player.position.distanceTo(enemy.position);
    evolution.registerKill(distanceToPlayer: distanceToPlayer);
    runNerve += metaProgression.killPayout(
      enemyId: enemy.archetype.id,
      combo: combo.chain,
    );
    score +=
        (enemy.archetype.score * combo.multiplier * runUpgrades.scoreMultiplier)
            .round();
    if (weapon.upgrades.refundsStaminaOnKill ||
        runUpgrades.refundsStaminaOnDashKill) {
      player.stamina = (player.stamina + 12).clamp(0, player.maxStamina);
    }
    feedback.kill(enemy.position);
  }

  void damagePlayer(int amount, Vector2 source) {
    final tookDamage = player.takeDamage(amount, source);
    if (tookDamage) {
      combo.breakChain();
    }
  }

  void onPlayerDash(Vector2 position, Vector2 direction) {
    _perfectDodgeClaims.clear();
    feedback.dash(position, direction);
    world.add(
      // Reuse impact particles as a directional exhaust burst.
      // The system remains data-driven through HitFeedbackSystem for hits.
      // This direct add keeps dash latency under one frame.
      _DashAfterImage(position: position, direction: direction),
    );
    unawaited(audio.cue(AudioCue.dash));
  }

  void onPlayerHurt(Vector2 position) {
    feedback.playerHurt(position);
  }

  void onPlayerKilled() {
    unawaited(_persistRun());
  }

  void spawnAdds(int count, {required Vector2 around}) {
    if (count <= 0) {
      return;
    }
    for (var i = 0; i < count; i += 1) {
      final radians = (math.pi * 2 / count) * i + _random.nextDouble() * 0.4;
      final offset = fromRadians(radians)
        ..scale(2.6 + _random.nextDouble() * 1.4);
      final spawn = around + offset;
      if (!currentRoom.bounds.deflate(1.4).contains(spawn.toOffset())) {
        continue;
      }
      final enemy = enemyFactory.create(
        spawn: spawn,
        difficulty: difficulty,
        roomSeed: currentRoom.seed + i * 17,
        activationDelay: i * 0.16,
      );
      enemies.add(enemy);
      world.add(enemy);
    }
  }

  Future<void> _loadRoom() async {
    _transitioningRoom = true;
    for (final component in <Component>[
      ..._roomComponents,
      ...enemies,
      ...bullets,
      if (_loaded && player.isMounted) player,
    ]) {
      component.removeFromParent();
    }
    _roomComponents.clear();
    obstructions.clear();
    enemies.clear();
    bullets.clear();

    final generated = roomGenerator.generate(
      roomIndex: roomIndex,
      seed: _seed + roomIndex * 9973,
      difficulty: difficulty,
    );
    currentRoom = generated.room;
    _roomComponents.addAll(generated.components);
    obstructions.addAll(generated.components.whereType<ArenaObstacle>());
    await world.addAll(generated.components);

    player = RunnerPlayer(spawn: generated.room.playerSpawn);
    await world.add(player);
    cameraController.snapTo(player.position);

    if (enemyFactory.shouldSpawnBoss(roomIndex)) {
      final boss = enemyFactory.createBoss(
        spawn: Vector2(generated.room.bounds.right - 5.2, 0),
        difficulty: difficulty,
        roomSeed: generated.room.seed,
      );
      enemies.add(boss);
      await world.add(boss);
    } else {
      for (var i = 0; i < generated.room.enemySpawns.length; i += 1) {
        final spawn = generated.room.enemySpawns[i];
        final enemy = enemyFactory.create(
          spawn: spawn,
          difficulty: difficulty,
          roomSeed: generated.room.seed + i * 31,
          activationDelay: math.min(0.92, i * 0.16),
        );
        enemies.add(enemy);
        await world.add(enemy);
      }
    }
    _transitioningRoom = false;
  }

  void _completeRoom() {
    _transitioningRoom = true;
    score +=
        ((400 + (roomIndex * 150) + (combo.chain * 30)) *
                runUpgrades.scoreMultiplier)
            .round();
    difficulty.registerRoomClear();
    evolution.registerRoomClear();
    runNerve += metaProgression.roomClearPayout(
      room: roomIndex,
      comboBest: combo.bestChain,
    );
    feedback.roomClear(player.position);
    unawaited(_persistRun());
    _activeRewards = rewardDeck.draft(
      random: _random,
      ownedWeaponUpgrades: weapon.upgrades,
      ownedRunEffects: runUpgrades.acquired,
      currentHealth: player.health,
      maxHealth: player.maxHealth,
      currentWeaponId: weapon.id,
    );
    _refreshHud();
  }

  Future<void> chooseReward(String rewardId) async {
    if (_activeRewards.isEmpty || player.isDead) {
      return;
    }
    final reward = _activeRewards.firstWhere(
      (choice) => choice.id == rewardId,
      orElse: () => _activeRewards.first,
    );
    _applyReward(reward);
    _activeRewards = <RewardChoice>[];
    roomIndex += 1;
    _refreshHud();
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!player.isDead) {
      await _loadRoom();
    }
  }

  void _applyReward(RewardChoice reward) {
    final weaponUpgrade = reward.weaponUpgrade;
    if (weaponUpgrade != null) {
      weapon.addUpgrade(weaponUpgrade);
    }
    final weaponId = reward.weaponId;
    if (weaponId != null) {
      final carriedUpgrades = weapon.upgrades.toSet();
      weapon = weaponFactory.create(
        weaponId,
        tuning: weapon.tuning,
        upgrades: carriedUpgrades,
      );
      _applyMetaWeaponTuning();
    }
    switch (reward.effect) {
      case RewardEffect.weaponUpgrade:
      case RewardEffect.weaponSwap:
        break;
      case RewardEffect.dermalPlating:
        runUpgrades.acquire(reward);
        player.health = (player.health + 1).clamp(0, player.maxHealth).toInt();
        break;
      case RewardEffect.adrenalBattery:
        runUpgrades.acquire(reward);
        player.stamina = player.maxStamina;
        break;
      case RewardEffect.tensionDividend:
      case RewardEffect.dashBattery:
        runUpgrades.acquire(reward);
        break;
      case RewardEffect.quickPatch:
        player.health = (player.health + 2).clamp(0, player.maxHealth).toInt();
        player.stamina = player.maxStamina;
        break;
    }
    feedback.hit(player.position, color: Color(reward.accentArgb));
    unawaited(audio.cue(AudioCue.rewardSelect));
  }

  void openProgression() {
    if (_activeRewards.isNotEmpty) {
      return;
    }
    runPaused = true;
    _showingProgression = true;
    _refreshHud();
  }

  void closeProgression() {
    _showingProgression = false;
    _refreshHud();
  }

  Future<void> unlockMetaNode(String id) async {
    if (!metaProgression.unlock(id)) {
      _refreshHud();
      return;
    }
    _applyMetaWeaponTuning();
    if (_loaded && player.isMounted) {
      player.health = player.health.clamp(0, player.maxHealth).toInt();
      player.stamina = player.stamina.clamp(0, player.maxStamina);
    }
    await _persistRun();
    unawaited(audio.cue(AudioCue.rewardSelect));
    _refreshHud();
  }

  void _applyMetaWeaponTuning() {
    weapon.tuning = WeaponTuning(
      heatPerShotMultiplier: metaProgression.weaponHeatMultiplier,
      coolingMultiplier: metaProgression.weaponCoolingMultiplier,
    );
  }

  Future<void> _persistRun() async {
    final killDelta = runKills - _persistedRunKills;
    _persistedRunKills = runKills;
    final currencyDelta = runNerve - _persistedRunNerve;
    if (currencyDelta > 0) {
      metaProgression.grantRunCurrency(currencyDelta);
      _persistedRunNerve = runNerve;
    }
    _saveData = _saveData.mergeRun(
      combo: combo.bestChain,
      room: roomIndex,
      kills: killDelta,
      evolutionSystem: evolution,
      metaProgression: metaProgression.toJson(),
    );
    await _saveService.save(_saveData);
    _refreshHud();
  }

  void _cleanupLists() {
    enemies.removeWhere((enemy) => enemy.isDead || !enemy.isMounted);
    bullets.removeWhere((bullet) => bullet.spent || !bullet.isMounted);
    _perfectDodgeClaims.removeWhere(
      (enemy) => enemy.isDead || !enemy.isMounted,
    );
  }

  void _detectPerfectDodges() {
    if (!player.isDashing) {
      _perfectDodgeClaims.clear();
      return;
    }
    for (final enemy in enemies) {
      if (_perfectDodgeClaims.contains(enemy) ||
          enemy.isDead ||
          !enemy.threatensPoint(player.position)) {
        continue;
      }
      _perfectDodgeClaims.add(enemy);
      player.rewardPerfectDodge();
      evolution.registerPerfectDodge();
      combo.registerPerfectDodge();
      score += (GameConstants.perfectDodgeScore * combo.multiplier).round();
      feedback.perfectDodge(player.position);
      break;
    }
  }

  void _refreshHud() {
    if (!_loaded) {
      return;
    }
    hud.value = HudSnapshot(
      health: player.health,
      maxHealth: player.maxHealth,
      stamina: player.staminaRatio,
      combo: combo.chain,
      comboTimer: combo.normalizedTimer,
      score: score,
      room: roomIndex,
      kills: runKills,
      runNerve: runNerve,
      bestCombo: math.max(_saveData.bestCombo, combo.bestChain),
      bestRoom: math.max(_saveData.bestRoom, roomIndex),
      heat: weapon.heat,
      weaponOverheated: weapon.overheated,
      difficulty: difficulty.intensity,
      musicIntensity: audio.musicIntensity,
      traitLabel: evolution.activeTraitLabel,
      weaponName: weapon.name,
      paused: runPaused,
      dead: player.isDead,
      rewards: _activeRewards,
      progression: metaProgression.snapshot(),
      showingProgression: _showingProgression,
      saveSyncStatus: _saveService.syncStatus,
    );
  }
}

class _DashAfterImage extends PositionComponent {
  _DashAfterImage({required Vector2 position, required this.direction})
    : super(position: position.clone(), priority: 60);

  final Vector2 direction;
  double _age = 0;

  @override
  void update(double dt) {
    _age += dt;
    if (_age > 0.16) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1 - _age / 0.16).clamp(0, 1).toDouble();
    final paint = Paint()
      ..color = GameTheme.cyan.withValues(alpha: 0.34 * alpha)
      ..strokeWidth = 0.16
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.16);
    canvas.drawLine(
      (direction * -1.0).toOffset(),
      (direction * 0.35).toOffset(),
      paint,
    );
  }
}
