class SlowMotionSystem {
  double _remaining = 0;
  double _scale = 1;

  double get scale => _scale;
  bool get active => _remaining > 0;

  void trigger({double duration = 0.13, double scale = 0.34}) {
    if (duration > _remaining || scale < _scale) {
      _remaining = duration;
      _scale = scale;
    }
  }

  double updateAndScale(double dt) {
    if (_remaining <= 0) {
      _scale += (1 - _scale) * 0.35;
      if ((1 - _scale).abs() < 0.01) {
        _scale = 1;
      }
      return dt;
    }
    _remaining -= dt;
    if (_remaining <= 0) {
      _remaining = 0;
    }
    return dt * _scale;
  }
}
