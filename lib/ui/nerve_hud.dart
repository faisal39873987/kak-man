import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/theme/game_theme.dart';
import 'hud_snapshot.dart';

class NerveHud extends StatelessWidget {
  const NerveHud({
    required this.listenable,
    required this.onPause,
    required this.onRestart,
    required this.onSelectReward,
    required this.onOpenProgression,
    required this.onCloseProgression,
    required this.onUnlockMetaNode,
    super.key,
  });

  final ValueListenable<HudSnapshot> listenable;
  final VoidCallback onPause;
  final Future<void> Function() onRestart;
  final Future<void> Function(String rewardId) onSelectReward;
  final VoidCallback onOpenProgression;
  final VoidCallback onCloseProgression;
  final Future<void> Function(String nodeId) onUnlockMetaNode;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HudSnapshot>(
      valueListenable: listenable,
      builder: (context, snapshot, _) {
        return SafeArea(
          child: Stack(
            children: <Widget>[
              Positioned(left: 16, top: 14, child: _Vitals(snapshot: snapshot)),
              Positioned(
                right: 14,
                top: 14,
                child: _RunControls(
                  snapshot: snapshot,
                  onPause: onPause,
                  onRestart: onRestart,
                  onOpenProgression: onOpenProgression,
                ),
              ),
              Positioned(
                left: 16,
                bottom: 16,
                child: _WeaponReadout(snapshot: snapshot),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: _DirectorReadout(snapshot: snapshot),
              ),
              if (snapshot.paused || snapshot.dead)
                Positioned.fill(
                  child: _RunStatePanel(
                    snapshot: snapshot,
                    onRestart: onRestart,
                    onPause: onPause,
                  ),
                ),
              if (snapshot.showingProgression)
                Positioned.fill(
                  child: _ProgressionPanel(
                    snapshot: snapshot,
                    onClose: onCloseProgression,
                    onUnlock: onUnlockMetaNode,
                  ),
                ),
              if (snapshot.choosingReward)
                Positioned.fill(
                  child: _RewardPanel(
                    snapshot: snapshot,
                    onSelectReward: onSelectReward,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressionPanel extends StatelessWidget {
  const _ProgressionPanel({
    required this.snapshot,
    required this.onClose,
    required this.onUnlock,
  });

  final HudSnapshot snapshot;
  final VoidCallback onClose;
  final Future<void> Function(String nodeId) onUnlock;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.68),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: _GlassPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'NERVE NETWORK',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: GameTheme.cyan,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    _Readout(
                      label: 'NERVE',
                      value:
                          '${snapshot.progression.currency} +${snapshot.runNerve}',
                      accent: GameTheme.acid,
                    ),
                    const SizedBox(width: 10),
                    _HudIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Close progression',
                      onPressed: onClose,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    for (final state in snapshot.progression.nodes)
                      _MetaUnlockCard(
                        title: state.node.title,
                        description: state.node.description,
                        cost: state.node.cost,
                        accent: Color(state.node.accentArgb),
                        unlocked: state.unlocked,
                        canUnlock: state.canUnlock,
                        onPressed: () => onUnlock(state.node.id),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaUnlockCard extends StatelessWidget {
  const _MetaUnlockCard({
    required this.title,
    required this.description,
    required this.cost,
    required this.accent,
    required this.unlocked,
    required this.canUnlock,
    required this.onPressed,
  });

  final String title;
  final String description;
  final int cost;
  final Color accent;
  final bool unlocked;
  final bool canUnlock;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final inactive = !unlocked && !canUnlock;
    return SizedBox(
      width: 170,
      height: 164,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: canUnlock ? onPressed : null,
          child: Ink(
            decoration: BoxDecoration(
              color: GameTheme.panel.withValues(alpha: inactive ? 0.7 : 1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: (unlocked ? GameTheme.acid : accent).withValues(
                  alpha: inactive ? 0.18 : 0.48,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        unlocked
                            ? Icons.check_circle_rounded
                            : Icons.account_tree_rounded,
                        color: unlocked ? GameTheme.acid : accent,
                        size: 19,
                      ),
                      const Spacer(),
                      Text(
                        unlocked ? 'ON' : '$cost',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: unlocked
                                  ? GameTheme.acid
                                  : GameTheme.steel,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: inactive ? GameTheme.dimSteel : GameTheme.steel,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Expanded(
                    child: Text(
                      description,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: GameTheme.steel.withValues(
                          alpha: inactive ? 0.48 : 0.72,
                        ),
                        height: 1.18,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardPanel extends StatelessWidget {
  const _RewardPanel({required this.snapshot, required this.onSelectReward});

  final HudSnapshot snapshot;
  final Future<void> Function(String rewardId) onSelectReward;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.62),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'NEURAL REWARD',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: GameTheme.acid,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    for (final reward in snapshot.rewards)
                      _RewardCard(
                        title: reward.title,
                        subtitle: reward.subtitle,
                        accent: Color(reward.accentArgb),
                        onPressed: () => onSelectReward(reward.id),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 252,
      height: 154,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              color: GameTheme.panel,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: accent.withValues(alpha: 0.5)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: accent.withValues(alpha: 0.14),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.bolt_rounded, color: accent, size: 22),
                  const Spacer(),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: GameTheme.steel,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: GameTheme.steel.withValues(alpha: 0.74),
                      height: 1.25,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Vitals extends StatelessWidget {
  const _Vitals({required this.snapshot});

  final HudSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(snapshot.maxHealth, (index) {
              final full = index < snapshot.health;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 90),
                width: 22,
                height: 9,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: full
                      ? GameTheme.blood
                      : GameTheme.dimSteel.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: full
                      ? <BoxShadow>[
                          BoxShadow(
                            color: GameTheme.blood.withValues(alpha: 0.35),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 9),
          _Meter(
            value: snapshot.stamina,
            width: 220,
            height: 5,
            color: GameTheme.cyan,
            background: GameTheme.dimSteel.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _Readout(label: 'ROOM', value: '${snapshot.room}'),
              const SizedBox(width: 10),
              _Readout(label: 'KILLS', value: '${snapshot.kills}'),
              const SizedBox(width: 10),
              _Readout(label: 'BEST', value: '${snapshot.bestRoom}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeaponReadout extends StatelessWidget {
  const _WeaponReadout({required this.snapshot});

  final HudSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: SizedBox(
        width: 230,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: _Readout(
                    label: snapshot.weaponOverheated ? 'OVERHEAT' : 'WEAPON',
                    value: snapshot.weaponName,
                    accent: snapshot.weaponOverheated
                        ? GameTheme.warning
                        : GameTheme.steel,
                  ),
                ),
                _Readout(label: 'SCORE', value: '${snapshot.score}'),
              ],
            ),
            const SizedBox(height: 10),
            _Meter(
              value: snapshot.heat,
              width: 210,
              height: 4,
              color: snapshot.weaponOverheated || snapshot.heat > 0.75
                  ? GameTheme.warning
                  : GameTheme.magenta,
              background: GameTheme.dimSteel.withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectorReadout extends StatelessWidget {
  const _DirectorReadout({required this.snapshot});

  final HudSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: SizedBox(
        width: 238,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                _Readout(label: 'COMBO', value: 'x${snapshot.combo}'),
                const SizedBox(width: 12),
                Expanded(
                  child: _Meter(
                    value: snapshot.comboTimer,
                    width: double.infinity,
                    height: 4,
                    color: GameTheme.acid,
                    background: GameTheme.dimSteel.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: _Readout(label: 'TRAIT', value: snapshot.traitLabel),
                ),
                _Meter(
                  value: snapshot.difficulty.clamp(0, 1),
                  width: 54,
                  height: 4,
                  color: GameTheme.blood,
                  background: GameTheme.dimSteel.withValues(alpha: 0.2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RunControls extends StatelessWidget {
  const _RunControls({
    required this.snapshot,
    required this.onPause,
    required this.onRestart,
    required this.onOpenProgression,
  });

  final HudSnapshot snapshot;
  final VoidCallback onPause;
  final Future<void> Function() onRestart;
  final VoidCallback onOpenProgression;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _HudIconButton(
          icon: snapshot.paused
              ? Icons.play_arrow_rounded
              : Icons.pause_rounded,
          tooltip: snapshot.paused ? 'Resume' : 'Pause',
          onPressed: onPause,
        ),
        const SizedBox(width: 8),
        _HudIconButton(
          icon: Icons.restart_alt_rounded,
          tooltip: 'Restart run',
          onPressed: () => onRestart(),
        ),
        const SizedBox(width: 8),
        _HudIconButton(
          icon: Icons.account_tree_rounded,
          tooltip: 'Progression',
          onPressed: onOpenProgression,
        ),
      ],
    );
  }
}

class _RunStatePanel extends StatelessWidget {
  const _RunStatePanel({
    required this.snapshot,
    required this.onRestart,
    required this.onPause,
  });

  final HudSnapshot snapshot;
  final Future<void> Function() onRestart;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.54),
      child: Center(
        child: _GlassPanel(
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  snapshot.dead ? 'RUN TERMINATED' : 'RUN PAUSED',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: snapshot.dead ? GameTheme.blood : GameTheme.cyan,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _HudIconButton(
                      icon: Icons.restart_alt_rounded,
                      tooltip: 'Restart run',
                      onPressed: () => onRestart(),
                    ),
                    if (!snapshot.dead) ...<Widget>[
                      const SizedBox(width: 12),
                      _HudIconButton(
                        icon: Icons.play_arrow_rounded,
                        tooltip: 'Resume',
                        onPressed: onPause,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameTheme.panel,
        border: Border.all(color: GameTheme.cyan.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(6),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: GameTheme.cyan.withValues(alpha: 0.08),
            blurRadius: 18,
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout({required this.label, required this.value, this.accent});

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: GameTheme.dimSteel,
            fontSize: 9,
            letterSpacing: 0,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: accent ?? GameTheme.steel,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({
    required this.value,
    required this.width,
    required this.height,
    required this.color,
    required this.background,
  });

  final double value;
  final double width;
  final double height;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _MeterPainter(
          value: value.clamp(0, 1),
          color: color,
          background: background,
        ),
      ),
    );
  }
}

class _MeterPainter extends CustomPainter {
  const _MeterPainter({
    required this.value,
    required this.color,
    required this.background,
  });

  final double value;
  final Color color;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    final track = RRect.fromRectAndRadius(Offset.zero & size, radius);
    canvas.drawRRect(track, Paint()..color = background);
    final fillWidth = size.width * value;
    if (fillWidth > 0) {
      final fill = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, fillWidth, size.height),
        radius,
      );
      canvas.drawRRect(fill, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _MeterPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.background != background;
  }
}

class _HudIconButton extends StatelessWidget {
  const _HudIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: 42,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          color: GameTheme.cyan,
          style: IconButton.styleFrom(
            backgroundColor: GameTheme.panel,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(color: GameTheme.cyan.withValues(alpha: 0.2)),
            ),
          ),
        ),
      ),
    );
  }
}
