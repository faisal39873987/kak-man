import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/game_theme.dart';
import '../progression/meta_progression.dart';
import 'hud_snapshot.dart';

enum NerveShellPanel { main, progression, settings }

enum TouchControlsMode { auto, alwaysOn }

class NerveShellSettings {
  const NerveShellSettings({required this.touchControlsMode});

  final TouchControlsMode touchControlsMode;
}

class NerveGameShell extends StatelessWidget {
  const NerveGameShell({
    required this.panel,
    required this.snapshot,
    required this.settings,
    required this.gameReady,
    required this.onPlay,
    required this.onShowMain,
    required this.onShowProgression,
    required this.onShowSettings,
    required this.onUnlockMetaNode,
    required this.onTouchControlsModeChanged,
    super.key,
  });

  final NerveShellPanel panel;
  final HudSnapshot snapshot;
  final NerveShellSettings settings;
  final bool gameReady;
  final VoidCallback onPlay;
  final VoidCallback onShowMain;
  final VoidCallback onShowProgression;
  final VoidCallback onShowSettings;
  final Future<void> Function(String nodeId) onUnlockMetaNode;
  final ValueChanged<TouchControlsMode> onTouchControlsModeChanged;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.72)),
        child: Stack(
          children: <Widget>[
            const Positioned.fill(child: CustomPaint(painter: _ShellGrid())),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1060),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 760;
                        final content = _ShellSurface(
                          child: _ShellContent(
                            panel: panel,
                            snapshot: snapshot,
                            settings: settings,
                            gameReady: gameReady,
                            onPlay: onPlay,
                            onShowProgression: onShowProgression,
                            onShowSettings: onShowSettings,
                            onUnlockMetaNode: onUnlockMetaNode,
                            onTouchControlsModeChanged:
                                onTouchControlsModeChanged,
                          ),
                        );
                        final nav = _ShellNav(
                          panel: panel,
                          horizontal: compact,
                          onShowMain: onShowMain,
                          onShowProgression: onShowProgression,
                          onShowSettings: onShowSettings,
                          onPlay: onPlay,
                        );
                        if (compact) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              nav,
                              const SizedBox(height: 10),
                              Flexible(child: content),
                            ],
                          );
                        }
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            nav,
                            const SizedBox(width: 10),
                            Expanded(child: content),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShellContent extends StatelessWidget {
  const _ShellContent({
    required this.panel,
    required this.snapshot,
    required this.settings,
    required this.gameReady,
    required this.onPlay,
    required this.onShowProgression,
    required this.onShowSettings,
    required this.onUnlockMetaNode,
    required this.onTouchControlsModeChanged,
  });

  final NerveShellPanel panel;
  final HudSnapshot snapshot;
  final NerveShellSettings settings;
  final bool gameReady;
  final VoidCallback onPlay;
  final VoidCallback onShowProgression;
  final VoidCallback onShowSettings;
  final Future<void> Function(String nodeId) onUnlockMetaNode;
  final ValueChanged<TouchControlsMode> onTouchControlsModeChanged;

  @override
  Widget build(BuildContext context) {
    switch (panel) {
      case NerveShellPanel.main:
        return _MainPanel(
          snapshot: snapshot,
          gameReady: gameReady,
          onPlay: onPlay,
          onShowProgression: onShowProgression,
          onShowSettings: onShowSettings,
        );
      case NerveShellPanel.progression:
        return _ProgressionShellPanel(
          snapshot: snapshot,
          gameReady: gameReady,
          onPlay: onPlay,
          onUnlockMetaNode: onUnlockMetaNode,
        );
      case NerveShellPanel.settings:
        return _SettingsPanel(
          settings: settings,
          onPlay: onPlay,
          onTouchControlsModeChanged: onTouchControlsModeChanged,
        );
    }
  }
}

class _MainPanel extends StatelessWidget {
  const _MainPanel({
    required this.snapshot,
    required this.gameReady,
    required this.onPlay,
    required this.onShowProgression,
    required this.onShowSettings,
  });

  final HudSnapshot snapshot;
  final bool gameReady;
  final VoidCallback onPlay;
  final VoidCallback onShowProgression;
  final VoidCallback onShowSettings;

  @override
  Widget build(BuildContext context) {
    return _PanelScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'ONE SHOT: NERVE RUNNER',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: GameTheme.cyan,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      gameReady
                          ? 'Room ${snapshot.room} is armed. The run resumes on Play.'
                          : 'Loading combat systems.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: GameTheme.steel,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              _PulseBadge(value: snapshot.dead ? 'DOWN' : 'LIVE'),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _MetricCard(
                label: 'BEST ROOM',
                value: '${snapshot.bestRoom}',
                accent: GameTheme.cyan,
              ),
              _MetricCard(
                label: 'BEST COMBO',
                value: 'x${snapshot.bestCombo}',
                accent: GameTheme.acid,
              ),
              _MetricCard(
                label: 'NERVE',
                value: '${snapshot.progression.currency + snapshot.runNerve}',
                accent: GameTheme.magenta,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _ShellActionButton(
                icon: Icons.play_arrow_rounded,
                label: gameReady ? 'Play' : 'Play when ready',
                detail: 'Start or resume the current run',
                accent: GameTheme.acid,
                primary: true,
                onPressed: onPlay,
              ),
              _ShellActionButton(
                icon: Icons.account_tree_rounded,
                label: 'Progression',
                detail: 'Spend Nerve on permanent nodes',
                accent: GameTheme.cyan,
                onPressed: onShowProgression,
              ),
              _ShellActionButton(
                icon: Icons.tune_rounded,
                label: 'Settings',
                detail: 'Controls and feedback options',
                accent: GameTheme.magenta,
                onPressed: onShowSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressionShellPanel extends StatelessWidget {
  const _ProgressionShellPanel({
    required this.snapshot,
    required this.gameReady,
    required this.onPlay,
    required this.onUnlockMetaNode,
  });

  final HudSnapshot snapshot;
  final bool gameReady;
  final VoidCallback onPlay;
  final Future<void> Function(String nodeId) onUnlockMetaNode;

  @override
  Widget build(BuildContext context) {
    return _PanelScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _PanelTitle(
                  title: 'Progression',
                  subtitle: 'Permanent upgrades spend stored Nerve.',
                ),
              ),
              _ReadoutPill(
                icon: Icons.bolt_rounded,
                value: '${snapshot.progression.currency + snapshot.runNerve}',
                accent: GameTheme.acid,
              ),
              const SizedBox(width: 10),
              _IconShellButton(
                icon: Icons.play_arrow_rounded,
                tooltip: 'Play',
                onPressed: onPlay,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              for (final state in snapshot.progression.nodes)
                _MetaNodeTile(
                  state: state,
                  gameReady: gameReady,
                  onUnlock: () => onUnlockMetaNode(state.node.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.settings,
    required this.onPlay,
    required this.onTouchControlsModeChanged,
  });

  final NerveShellSettings settings;
  final VoidCallback onPlay;
  final ValueChanged<TouchControlsMode> onTouchControlsModeChanged;

  @override
  Widget build(BuildContext context) {
    return _PanelScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: _PanelTitle(
                  title: 'Settings',
                  subtitle: 'Input visibility and combat feedback.',
                ),
              ),
              _IconShellButton(
                icon: Icons.play_arrow_rounded,
                tooltip: 'Play',
                onPressed: onPlay,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingBlock(
            icon: Icons.touch_app_rounded,
            title: 'Touch Controls',
            child: Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<TouchControlsMode>(
                showSelectedIcon: false,
                selected: <TouchControlsMode>{settings.touchControlsMode},
                onSelectionChanged: (selection) {
                  onTouchControlsModeChanged(selection.first);
                },
                segments: const <ButtonSegment<TouchControlsMode>>[
                  ButtonSegment<TouchControlsMode>(
                    value: TouchControlsMode.auto,
                    icon: Icon(Icons.devices_rounded),
                    label: Text('Auto'),
                  ),
                  ButtonSegment<TouchControlsMode>(
                    value: TouchControlsMode.alwaysOn,
                    icon: Icon(Icons.gamepad_rounded),
                    label: Text('Always'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const <Widget>[
              _ControlHint(
                icon: Icons.keyboard_rounded,
                title: 'Keyboard',
                detail:
                    'WASD or arrows move. Space or Shift dash. J, K, or Enter fire.',
              ),
              _ControlHint(
                icon: Icons.mouse_rounded,
                title: 'Mouse',
                detail: 'Move pointer to aim. Hold primary button to fire.',
              ),
              _ControlHint(
                icon: Icons.gamepad_rounded,
                title: 'Touch',
                detail:
                    'Left stick moves. Right stick aims and fires. Bolt dashes.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShellNav extends StatelessWidget {
  const _ShellNav({
    required this.panel,
    required this.horizontal,
    required this.onShowMain,
    required this.onShowProgression,
    required this.onShowSettings,
    required this.onPlay,
  });

  final NerveShellPanel panel;
  final bool horizontal;
  final VoidCallback onShowMain;
  final VoidCallback onShowProgression;
  final VoidCallback onShowSettings;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      _NavButton(
        icon: Icons.grid_view_rounded,
        label: 'Menu',
        selected: panel == NerveShellPanel.main,
        onPressed: onShowMain,
      ),
      _NavButton(
        icon: Icons.account_tree_rounded,
        label: 'Nodes',
        selected: panel == NerveShellPanel.progression,
        onPressed: onShowProgression,
      ),
      _NavButton(
        icon: Icons.tune_rounded,
        label: 'Setup',
        selected: panel == NerveShellPanel.settings,
        onPressed: onShowSettings,
      ),
      _NavButton(
        icon: Icons.play_arrow_rounded,
        label: 'Play',
        selected: false,
        accent: GameTheme.acid,
        onPressed: onPlay,
      ),
    ];
    return _ShellSurface(
      child: horizontal
          ? Wrap(alignment: WrapAlignment.center, children: buttons)
          : SizedBox(
              width: 126,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: buttons,
              ),
            ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.accent = GameTheme.cyan,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = selected ? accent : GameTheme.steel;
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Tooltip(
        message: label,
        child: TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: TextButton.styleFrom(
            foregroundColor: color,
            backgroundColor: selected
                ? accent.withValues(alpha: 0.12)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(
                color: selected
                    ? accent.withValues(alpha: 0.42)
                    : Colors.transparent,
              ),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaNodeTile extends StatelessWidget {
  const _MetaNodeTile({
    required this.state,
    required this.gameReady,
    required this.onUnlock,
  });

  final MetaNodeState state;
  final bool gameReady;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final node = state.node;
    final accent = Color(node.accentArgb);
    final inactive = !state.unlocked && !state.canUnlock;
    final enabled = gameReady && state.canUnlock;
    return SizedBox(
      width: 184,
      height: 172,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: enabled ? onUnlock : null,
          child: Ink(
            decoration: BoxDecoration(
              color: GameTheme.asphalt.withValues(alpha: inactive ? 0.72 : 1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: (state.unlocked ? GameTheme.acid : accent).withValues(
                  alpha: inactive ? 0.2 : 0.52,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        state.unlocked
                            ? Icons.check_circle_rounded
                            : Icons.hub_rounded,
                        color: state.unlocked ? GameTheme.acid : accent,
                        size: 20,
                      ),
                      const Spacer(),
                      Text(
                        state.unlocked ? 'ON' : '${node.cost}',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: state.unlocked
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
                    node.title,
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
                      node.description,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: GameTheme.steel.withValues(
                          alpha: inactive ? 0.5 : 0.76,
                        ),
                        height: 1.18,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  Text(
                    state.unlocked
                        ? 'ACTIVE'
                        : state.canUnlock
                        ? 'UNLOCK'
                        : 'LOCKED',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: state.canUnlock ? accent : GameTheme.dimSteel,
                      fontWeight: FontWeight.w900,
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

class _SettingBlock extends StatelessWidget {
  const _SettingBlock({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameTheme.asphalt.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: GameTheme.cyan.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: GameTheme.cyan, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: GameTheme.steel,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlHint extends StatelessWidget {
  const _ControlHint({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 226,
      height: 116,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: GameTheme.asphalt.withValues(alpha: 0.74),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: GameTheme.dimSteel.withValues(alpha: 0.22)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(icon, color: GameTheme.acid, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: GameTheme.steel,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Expanded(
                child: Text(
                  detail,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: GameTheme.steel.withValues(alpha: 0.72),
                    height: 1.2,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: GameTheme.cyan,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: GameTheme.steel.withValues(alpha: 0.74),
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _ShellActionButton extends StatelessWidget {
  const _ShellActionButton({
    required this.icon,
    required this.label,
    required this.detail,
    required this.accent,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final String detail;
  final Color accent;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 82,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: primary ? GameTheme.voidBlack : accent,
          backgroundColor: primary
              ? accent
              : GameTheme.asphalt.withValues(alpha: 0.88),
          disabledForegroundColor: GameTheme.dimSteel,
          disabledBackgroundColor: GameTheme.asphalt.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: accent.withValues(alpha: 0.48)),
          ),
          padding: const EdgeInsets.all(12),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primary
                          ? GameTheme.voidBlack.withValues(alpha: 0.7)
                          : GameTheme.steel.withValues(alpha: 0.72),
                      fontSize: 11,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 72,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: GameTheme.asphalt.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: accent.withValues(alpha: 0.28)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: GameTheme.dimSteel,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseBadge extends StatelessWidget {
  const _PulseBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameTheme.asphalt,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: GameTheme.magenta.withValues(alpha: 0.34)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: GameTheme.magenta,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _ReadoutPill extends StatelessWidget {
  const _ReadoutPill({
    required this.icon,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameTheme.asphalt,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: accent, size: 18),
            const SizedBox(width: 7),
            Text(
              value,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: accent,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconShellButton extends StatelessWidget {
  const _IconShellButton({
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
          color: GameTheme.acid,
          style: IconButton.styleFrom(
            backgroundColor: GameTheme.asphalt,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(color: GameTheme.acid.withValues(alpha: 0.26)),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellSurface extends StatelessWidget {
  const _ShellSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameTheme.panel,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: GameTheme.cyan.withValues(alpha: 0.22)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: GameTheme.cyan.withValues(alpha: 0.08),
            blurRadius: 20,
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}

class _PanelScroll extends StatelessWidget {
  const _PanelScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(padding: const EdgeInsets.all(4), child: child),
    );
  }
}

class _ShellGrid extends CustomPainter {
  const _ShellGrid();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = GameTheme.cyan.withValues(alpha: 0.045);
    const spacing = 38.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final sweep = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = GameTheme.magenta.withValues(alpha: 0.08);
    final radius = math.min(size.width, size.height) * 0.32;
    canvas.drawCircle(size.center(Offset.zero), radius, sweep);
  }

  @override
  bool shouldRepaint(covariant _ShellGrid oldDelegate) => false;
}
