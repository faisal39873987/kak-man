import 'dart:ui' show PointerDeviceKind;

import 'package:flame/game.dart';
import 'package:flutter/gestures.dart' show kPrimaryMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../engine/nerve_runner_game.dart';
import '../../ui/nerve_hud.dart';
import '../../ui/nerve_shell.dart';
import '../../ui/touch_controls.dart';
import '../theme/game_theme.dart';

class NerveRunnerApp extends StatelessWidget {
  const NerveRunnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'One Shot: Nerve Runner',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: GameTheme.cyan,
          brightness: Brightness.dark,
        ),
        fontFamily: 'monospace',
      ),
      home: const NerveRunnerGameScreen(),
    );
  }
}

class NerveRunnerGameScreen extends StatefulWidget {
  const NerveRunnerGameScreen({super.key});

  @override
  State<NerveRunnerGameScreen> createState() => _NerveRunnerGameScreenState();
}

class _NerveRunnerGameScreenState extends State<NerveRunnerGameScreen>
    with WidgetsBindingObserver {
  late final NerveRunnerGame _game;
  late final FocusNode _focusNode;
  bool _shellVisible = true;
  NerveShellPanel _shellPanel = NerveShellPanel.main;
  TouchControlsMode _touchControlsMode = TouchControlsMode.auto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = NerveRunnerGame(shellPaused: true);
    _focusNode = FocusNode(debugLabel: 'nerve-runner-input');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _game.hud.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _game.runPaused = true;
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (_shellVisible) {
      if (event is! KeyDownEvent) {
        return;
      }
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.space ||
          key == LogicalKeyboardKey.keyP) {
        _playFromShell();
        return;
      }
      if (key == LogicalKeyboardKey.escape) {
        if (_shellPanel == NerveShellPanel.main) {
          _playFromShell();
        } else {
          setState(() {
            _shellPanel = NerveShellPanel.main;
          });
        }
      }
      return;
    }
    _game.handleKeyEvent(event);
  }

  void _showShell(NerveShellPanel panel) {
    setState(() {
      _shellVisible = true;
      _shellPanel = panel;
    });
    _game.setShellPaused(true);
    _game.stopFire();
    _focusNode.requestFocus();
  }

  void _playFromShell() {
    setState(() {
      _shellVisible = false;
    });
    _game.resumeRun();
    _game.setShellPaused(false);
    _focusNode.requestFocus();
  }

  Future<void> _unlockMetaNode(String nodeId) async {
    if (!_game.isReady) {
      return;
    }
    await _game.unlockMetaNode(nodeId);
  }

  void _setTouchControlsMode(TouchControlsMode mode) {
    setState(() {
      _touchControlsMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardListener(
        autofocus: true,
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: MouseRegion(
          onHover: (event) {
            if (!_shellVisible) {
              _game.setPointerAim(event.localPosition);
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              GameWidget<NerveRunnerGame>(game: _game),
              if (!_shellVisible)
                Positioned.fill(
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (event) {
                      _focusNode.requestFocus();
                      _game.setPointerAim(event.localPosition);
                      if (event.buttons == kPrimaryMouseButton ||
                          event.kind == PointerDeviceKind.touch ||
                          event.kind == PointerDeviceKind.stylus) {
                        _game.startFire();
                      }
                    },
                    onPointerMove: (event) =>
                        _game.setPointerAim(event.localPosition),
                    onPointerHover: (event) =>
                        _game.setPointerAim(event.localPosition),
                    onPointerUp: (_) => _game.stopFire(),
                    onPointerCancel: (_) => _game.stopFire(),
                    child: const SizedBox.expand(),
                  ),
                ),
              if (!_shellVisible)
                TouchControls(
                  onMove: _game.setTouchMovement,
                  onMoveEnd: _game.clearTouchMovement,
                  onAim: _game.setTouchAim,
                  onFireStart: _game.startFire,
                  onFireEnd: _game.stopFire,
                  onDash: _game.queueDash,
                  forceVisible:
                      _touchControlsMode == TouchControlsMode.alwaysOn,
                ),
              if (!_shellVisible)
                NerveHud(
                  listenable: _game.hud,
                  onPause: _game.togglePause,
                  onRestart: () => _game.restartRun(),
                  onSelectReward: _game.chooseReward,
                  onOpenProgression: _game.openProgression,
                  onCloseProgression: _game.closeProgression,
                  onUnlockMetaNode: _game.unlockMetaNode,
                  onOpenMenu: () => _showShell(NerveShellPanel.main),
                ),
              if (_shellVisible)
                ValueListenableBuilder(
                  valueListenable: _game.hud,
                  builder: (context, snapshot, _) {
                    return NerveGameShell(
                      panel: _shellPanel,
                      snapshot: snapshot,
                      settings: NerveShellSettings(
                        touchControlsMode: _touchControlsMode,
                      ),
                      gameReady: _game.isReady,
                      onPlay: _playFromShell,
                      onShowMain: () => _showShell(NerveShellPanel.main),
                      onShowProgression: () =>
                          _showShell(NerveShellPanel.progression),
                      onShowSettings: () =>
                          _showShell(NerveShellPanel.settings),
                      onUnlockMetaNode: _unlockMetaNode,
                      onTouchControlsModeChanged: _setTouchControlsMode,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
