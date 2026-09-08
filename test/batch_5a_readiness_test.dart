import 'package:bomb_questions/models/game_state.dart';
import 'package:bomb_questions/screens/game_screen.dart';
import 'package:bomb_questions/theme/game_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> mount(WidgetTester tester, GameState state) => tester.pumpWidget(
    MaterialApp(
      theme: GameTheme.light,
      home: GameScreen(
        gameState: state,
        enableAudio: false,
        countdownDelay: const Duration(milliseconds: 1),
        timerDuration: const Duration(seconds: 20),
      ),
    ),
  );

  testWidgets('readiness blocks actions and one start creates one countdown', (
    tester,
  ) async {
    final state = GameState(playerNames: ['A', 'B']);
    await mount(tester, state);
    expect(find.byKey(const ValueKey('start-round')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('answer-question')));
    await tester.tap(find.byKey(const ValueKey('skip-question')));
    expect(state.answeredCount, 0);
    expect(state.skipUsed, [false, false]);
    await tester.tap(find.byKey(const ValueKey('start-round')));
    await tester.tap(find.byKey(const ValueKey('start-round')));
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('2'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2));
    expect(find.byKey(const ValueKey('start-round')), findsNothing);
    expect(state.lossPoints, [0, 0]);
  });

  testWidgets('interruption during countdown returns to readiness', (
    tester,
  ) async {
    final state = GameState(playerNames: ['A', 'B']);
    await mount(tester, state);
    await tester.tap(find.byKey(const ValueKey('start-round')));
    await tester.pump(const Duration(milliseconds: 1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(milliseconds: 5));
    expect(find.byKey(const ValueKey('start-round')), findsOneWidget);
    expect(state.lossPoints, [0, 0]);
  });
}
