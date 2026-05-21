import 'dart:ui' show PointerDeviceKind;

import 'package:flame/game.dart';
import 'package:flutter/gestures.dart' show kPrimaryMouseButton;
import 'package:flutter/material.dart';

import '../../engine/nerve_runner_game.dart';
import '../../ui/nerve_hud.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = NerveRunnerGame();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardListener(
        autofocus: true,
        focusNode: _focusNode,
        onKeyEvent: _game.handleKeyEvent,
        child: MouseRegion(
          onHover: (event) => _game.setPointerAim(event.localPosition),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              GameWidget<NerveRunnerGame>(game: _game),
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
              TouchControls(
                onMove: _game.setTouchMovement,
                onMoveEnd: _game.clearTouchMovement,
                onAim: _game.setTouchAim,
                onFireStart: _game.startFire,
                onFireEnd: _game.stopFire,
                onDash: _game.queueDash,
              ),
              NerveHud(
                listenable: _game.hud,
                onPause: _game.togglePause,
                onRestart: () => _game.restartRun(),
                onSelectReward: _game.chooseReward,
                onOpenProgression: _game.openProgression,
                onCloseProgression: _game.closeProgression,
                onUnlockMetaNode: _game.unlockMetaNode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
