import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_shot_nerve_runner/ui/hud_snapshot.dart';
import 'package:one_shot_nerve_runner/ui/nerve_hud.dart';

void main() {
  testWidgets('dead run panel renders summary and restarts', (tester) async {
    var restartCount = 0;
    final snapshot = HudSnapshot.initial().copyWith(
      dead: true,
      score: 12840,
      room: 4,
      kills: 23,
      runNerve: 37,
      traitLabel: 'DEADEYE',
      runSummary: const RunSummary(
        score: 12840,
        roomReached: 4,
        kills: 23,
        nerveEarned: 37,
        bestCombo: 11,
        bestRoom: 4,
        secondsSurvived: 94,
        shotsFired: 40,
        shotsHit: 30,
        dashes: 18,
        perfectDodges: 4,
        lowHealthSeconds: 9,
        traitLabel: 'DEADEYE',
      ),
    );

    await _pumpHud(
      tester,
      ValueNotifier<HudSnapshot>(snapshot),
      onRestart: () async {
        restartCount += 1;
      },
    );

    expect(find.text('RUN TERMINATED'), findsOneWidget);
    expect(find.text('RUN SUMMARY'), findsOneWidget);
    expect(find.text('1:34'), findsOneWidget);
    expect(find.text('12840'), findsWidgets);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('DEADEYE'), findsWidgets);

    await tester.tap(find.byTooltip('Restart run').last);
    await tester.pump();

    expect(restartCount, 1);
  });
}

Future<void> _pumpHud(
  WidgetTester tester,
  ValueNotifier<HudSnapshot> notifier, {
  Future<void> Function()? onRestart,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(960, 720);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(notifier.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: NerveHud(
          listenable: notifier,
          onPause: () {},
          onRestart: onRestart ?? () async {},
          onSelectReward: (_) async {},
          onOpenProgression: () {},
          onCloseProgression: () {},
          onUnlockMetaNode: (_) async {},
        ),
      ),
    ),
  );
  await tester.pump();
}
