import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_shot_nerve_runner/progression/meta_progression.dart';
import 'package:one_shot_nerve_runner/ui/hud_snapshot.dart';
import 'package:one_shot_nerve_runner/ui/nerve_shell.dart';

void main() {
  testWidgets('main shell buttons render and invoke callbacks', (tester) async {
    var playCount = 0;
    var progressionCount = 0;
    var settingsCount = 0;

    await _pumpShell(
      tester,
      panel: NerveShellPanel.main,
      onPlay: () => playCount += 1,
      onShowProgression: () => progressionCount += 1,
      onShowSettings: () => settingsCount += 1,
    );

    expect(find.text('Play'), findsWidgets);
    expect(find.text('Progression'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Play').first);
    await tester.tap(find.widgetWithText(TextButton, 'Progression'));
    await tester.tap(find.widgetWithText(TextButton, 'Settings'));
    await tester.pump();

    expect(playCount, 1);
    expect(progressionCount, 1);
    expect(settingsCount, 1);
  });

  testWidgets('settings segmented control changes touch mode', (tester) async {
    TouchControlsMode? selectedMode;

    await _pumpShell(
      tester,
      panel: NerveShellPanel.settings,
      surface: const Size(420, 720),
      onTouchControlsModeChanged: (mode) => selectedMode = mode,
    );

    expect(find.text('Touch Controls'), findsOneWidget);
    expect(find.text('Auto'), findsOneWidget);
    expect(find.text('Always'), findsOneWidget);

    await tester.tap(find.text('Always'));
    await tester.pumpAndSettle();

    expect(selectedMode, TouchControlsMode.alwaysOn);
  });

  testWidgets('progression panel renders initial meta nodes responsively', (
    tester,
  ) async {
    final snapshot = HudSnapshot.initial();

    expect(snapshot.progression.nodes, isNotEmpty);

    for (final surface in <Size>[const Size(390, 760), const Size(1180, 820)]) {
      await _pumpShell(
        tester,
        panel: NerveShellPanel.progression,
        surface: surface,
        snapshot: snapshot,
      );

      expect(find.text('PROGRESSION'), findsOneWidget);
      for (final node in MetaProgressionSystem.nodes) {
        expect(find.text(node.title), findsOneWidget);
      }
      expect(
        find.text('LOCKED'),
        findsNWidgets(MetaProgressionSystem.nodes.length),
      );
    }
  });
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required NerveShellPanel panel,
  Size surface = const Size(1180, 820),
  HudSnapshot? snapshot,
  NerveShellSettings settings = const NerveShellSettings(
    touchControlsMode: TouchControlsMode.auto,
  ),
  bool gameReady = true,
  VoidCallback? onPlay,
  VoidCallback? onShowMain,
  VoidCallback? onShowProgression,
  VoidCallback? onShowSettings,
  Future<void> Function(String nodeId)? onUnlockMetaNode,
  ValueChanged<TouchControlsMode>? onTouchControlsModeChanged,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = surface;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: surface),
        child: Scaffold(
          body: NerveGameShell(
            panel: panel,
            snapshot: snapshot ?? HudSnapshot.initial(),
            settings: settings,
            gameReady: gameReady,
            onPlay: onPlay ?? () {},
            onShowMain: onShowMain ?? () {},
            onShowProgression: onShowProgression ?? () {},
            onShowSettings: onShowSettings ?? () {},
            onUnlockMetaNode: onUnlockMetaNode ?? (_) async {},
            onTouchControlsModeChanged: onTouchControlsModeChanged ?? (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
