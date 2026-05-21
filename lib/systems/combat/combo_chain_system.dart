import '../../core/config/game_constants.dart';

class ComboChainSystem {
  int chain = 0;
  int bestChain = 0;
  double _timer = 0;

  double get multiplier => 1 + (chain.clamp(0, 24) * 0.045);
  double get normalizedTimer =>
      (_timer / GameConstants.comboTimeout).clamp(0, 1);

  void update(double dt) {
    if (chain == 0) {
      return;
    }
    _timer -= dt;
    if (_timer <= 0) {
      chain = 0;
      _timer = 0;
    }
  }

  void registerHit() {
    _timer = GameConstants.comboTimeout;
  }

  void registerKill() {
    chain += 1;
    if (chain > bestChain) {
      bestChain = chain;
    }
    _timer = GameConstants.comboTimeout;
  }

  void breakChain() {
    chain = 0;
    _timer = 0;
  }
}
