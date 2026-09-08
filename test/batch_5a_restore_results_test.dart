import 'package:bomb_questions/models/game_state.dart';
import 'package:bomb_questions/screens/game_screen.dart';
import 'package:bomb_questions/screens/results_screen.dart';
import 'package:bomb_questions/screens/setup_screen.dart';
import 'package:bomb_questions/services/match_persistence.dart';
import 'package:bomb_questions/services/settings_service.dart';
import 'package:bomb_questions/theme/game_theme.dart';
import 'package:bomb_questions/widgets/game_ui.dart';
import 'package:bomb_questions/widgets/timer_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('restored active match waits at readiness and keeps settings', (
    tester,
  ) async {
    final stored = GameState(
      playerNames: ['A', 'B'],
      lossPoints: [1, 0],
      currentPlayerIndex: 1,
      currentRound: 2,
      answeredCount: 4,
      skipUsed: [true, false],
      phase: GamePhase.playing,
      selectedPackageIds: ['countries'],
    );
    await MatchPersistence().save(stored);
    await SettingsService().update(
      const GameSettings(
        soundEnabled: false,
        vibrationEnabled: false,
        timerDisplayMode: TimerDisplayMode.visible,
      ),
    );
    final restored = await MatchPersistence().restore();
    expect(restored, isNotNull);
    await tester.pumpWidget(
      MaterialApp(
        theme: GameTheme.light,
        home: GameScreen(
          gameState: restored!,
          enableAudio: true,
          countdownDelay: const Duration(milliseconds: 1),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('start-round')), findsOneWidget);
    expect(find.byType(TimerBar), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('answer-question')));
    expect(restored.answeredCount, 4);
    expect(restored.skipUsed, [true, false]);
    await tester.tap(find.byKey(const ValueKey('start-round')));
    await tester.pump(const Duration(milliseconds: 3));
    expect(find.byKey(const ValueKey('start-round')), findsNothing);
    expect(restored.lossPoints, [1, 0]);
    expect(restored.currentRound, 2);
  });

  testWidgets('results replay creates a fresh ready match and clears save', (
    tester,
  ) async {
    final finished = GameState(
      playerNames: ['A', 'B', 'C'],
      lossPoints: [2, 0, 1],
      answeredCount: 9,
      currentRound: 4,
      matchMode: MatchMode.normal,
      initialStarterIndex: 1,
      skipUsed: [true, true, false],
      phase: GamePhase.playing,
      selectedPackageIds: ['countries'],
    );
    await MatchPersistence().save(finished);
    await tester.pumpWidget(
      MaterialApp(
        theme: GameTheme.light,
        home: ResultsScreen(gameState: finished, nextStarter: (_) => 2),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('same-group-replay')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final replay = tester.widget<GameScreen>(find.byType(GameScreen)).gameState;
    expect(identical(replay, finished), isFalse);
    expect(replay.playerNames, finished.playerNames);
    expect(replay.selectedPackageIds, finished.selectedPackageIds);
    expect(replay.questionPool, finished.questionPool);
    expect(replay.matchMode, finished.matchMode);
    expect(replay.initialStarterIndex, 2);
    expect(replay.lossPoints, [0, 0, 0]);
    expect(replay.answeredCount, 0);
    expect(replay.skipUsed, [false, false, false]);
    expect(replay.currentRound, 1);
    expect(replay.roundQuestionIds, isEmpty);
    expect(find.byKey(const ValueKey('start-round')), findsOneWidget);
    expect(
      await MatchPersistence().restore(),
      isNotNull,
    ); // readiness saved as unfinished
  });

  testWidgets('new settings clears persistence and returns to setup', (
    tester,
  ) async {
    final state = GameState(
      playerNames: ['A', 'B'],
      phase: GamePhase.playing,
      selectedPackageIds: ['countries'],
    );
    await MatchPersistence().save(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: GameTheme.light,
        home: ResultsScreen(gameState: state),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('new-settings')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SetupScreen), findsOneWidget);
    expect(await MatchPersistence().restore(), isNull);
  });
}
