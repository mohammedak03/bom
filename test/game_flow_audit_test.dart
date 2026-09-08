import 'package:bomb_questions/models/game_state.dart';
import 'package:bomb_questions/screens/boom_screen.dart';
import 'package:bomb_questions/screens/game_screen.dart';
import 'package:bomb_questions/theme/game_theme.dart';
import 'package:bomb_questions/widgets/game_ui.dart';
import 'package:bomb_questions/widgets/question_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in [
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers.global/events',
      'xyz.luan/audioplayers/events/bomb_tick_player',
      'xyz.luan/audioplayers/events/bomb_effect_player',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(name),
        (_) async => null,
      );
    }
    messenger.setMockMethodCallHandler(
      const MethodChannel('vibration'),
      (_) async => false,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        return call.method == 'getCurrentPosition' ||
                call.method == 'getDuration'
            ? 0
            : null;
      },
    );
  });

  Future<void> mountGame(
    WidgetTester tester, {
    required GameState state,
    required Duration Function() elapsedTime,
    NavigatorObserver? observer,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: GameTheme.light,
        navigatorObservers: observer == null ? [] : [observer],
        home: GameScreen(
          gameState: state,
          elapsedTime: elapsedTime,
          timerDuration: const Duration(seconds: 20),
          enableAudio: false,
        ),
      ),
    );
    await tester.runAsync(() => GoogleFonts.pendingFonts());
    await tester.pump();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  }

  Future<void> finishNavigation(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('accepts an answer immediately before the deadline', (
    tester,
  ) async {
    var elapsed = const Duration(seconds: 19, milliseconds: 999);
    final state = GameState(
      playerNames: ['Ali', 'Sara'],
      phase: GamePhase.playing,
    );

    await mountGame(tester, state: state, elapsedTime: () => elapsed);
    await tester.tap(find.byKey(const ValueKey('answer-question')));
    await tester.pump();

    expect(state.currentPlayerIndex, 1);
    expect(state.answeredCount, 1);
    expect(state.lossPoints, [0, 0]);
    expect(find.byType(BoomScreen), findsNothing);
    await unmount(tester);
  });

  testWidgets(
    'rejects an answer exactly at the deadline before timer callback',
    (tester) async {
      var elapsed = Duration.zero;
      final state = GameState(
        playerNames: ['Ali', 'Sara'],
        phase: GamePhase.playing,
      );

      await mountGame(tester, state: state, elapsedTime: () => elapsed);
      elapsed = const Duration(seconds: 20);
      await tester.tap(find.byKey(const ValueKey('answer-question')));
      await finishNavigation(tester);

      expect(state.currentPlayerIndex, 0);
      expect(state.answeredCount, 0);
      expect(state.lossPoints, [1, 0]);
      expect(find.byType(BoomScreen), findsOneWidget);
      await unmount(tester);
    },
  );

  testWidgets('rejects an overdue answer and records one loss only', (
    tester,
  ) async {
    var elapsed = Duration.zero;
    final observer = _ReplacementObserver();
    final state = GameState(
      playerNames: ['Ali', 'Sara'],
      phase: GamePhase.playing,
    );

    await mountGame(
      tester,
      state: state,
      elapsedTime: () => elapsed,
      observer: observer,
    );
    elapsed = const Duration(seconds: 21);
    final answer = find.byKey(const ValueKey('answer-question'));
    final button = tester.widget<GameButton>(answer);
    button.onPressed!();
    button.onPressed!();
    await finishNavigation(tester);

    expect(state.currentPlayerIndex, 0);
    expect(state.answeredCount, 0);
    expect(state.lossPoints, [1, 0]);
    expect(observer.replacements, 1);
    expect(find.byType(BoomScreen), findsOneWidget);
    await unmount(tester);
  });

  testWidgets(
    'ignores rapid answers then accepts the next answer after 400ms',
    (tester) async {
      var elapsed = Duration.zero;
      final state = GameState(
        playerNames: ['Ali', 'Sara', 'Omar'],
        phase: GamePhase.playing,
      );

      await mountGame(tester, state: state, elapsedTime: () => elapsed);
      final firstQuestion = tester
          .widget<QuestionCard>(find.byType(QuestionCard))
          .question;
      await tester.tap(find.byKey(const ValueKey('answer-question')));
      await tester.pump();
      final secondQuestion = tester
          .widget<QuestionCard>(find.byType(QuestionCard))
          .question;
      expect(identical(firstQuestion, secondQuestion), isFalse);
      expect(state.currentPlayerIndex, 1);
      expect(state.answeredCount, 1);

      elapsed = const Duration(milliseconds: 399);
      await tester.tap(find.byKey(const ValueKey('answer-question')));
      await tester.pump();
      expect(state.currentPlayerIndex, 1);
      expect(state.answeredCount, 1);
      expect(
        identical(
          tester.widget<QuestionCard>(find.byType(QuestionCard)).question,
          secondQuestion,
        ),
        isTrue,
      );

      elapsed = const Duration(milliseconds: 400);
      await tester.tap(find.byKey(const ValueKey('answer-question')));
      await tester.pump();
      expect(state.currentPlayerIndex, 2);
      expect(state.answeredCount, 2);
      await unmount(tester);
    },
  );

  testWidgets('expiration wins over the double-tap guard', (tester) async {
    var elapsed = Duration.zero;
    final state = GameState(
      playerNames: ['Ali', 'Sara'],
      phase: GamePhase.playing,
    );

    await mountGame(tester, state: state, elapsedTime: () => elapsed);
    await tester.tap(find.byKey(const ValueKey('answer-question')));
    await tester.pump();
    elapsed = const Duration(seconds: 20);
    await tester.tap(find.byKey(const ValueKey('answer-question')));
    await finishNavigation(tester);

    expect(state.currentPlayerIndex, 1);
    expect(state.answeredCount, 1);
    expect(state.lossPoints, [0, 1]);
    expect(find.byType(BoomScreen), findsOneWidget);
    await unmount(tester);
  });

  testWidgets(
    'a skip changes question but keeps the player and timer running',
    (tester) async {
      var elapsed = Duration.zero;
      final state = GameState(
        playerNames: ['Ali', 'Sara'],
        phase: GamePhase.playing,
      );
      await mountGame(tester, state: state, elapsedTime: () => elapsed);
      final first = tester
          .widget<QuestionCard>(find.byType(QuestionCard))
          .question;
      await tester.tap(find.byKey(const ValueKey('skip-question')));
      await tester.pump();
      expect(state.currentPlayerIndex, 0);
      expect(state.answeredCount, 0);
      expect(state.skipUsed, [true, false]);
      expect(
        identical(
          tester.widget<QuestionCard>(find.byType(QuestionCard)).question,
          first,
        ),
        isFalse,
      );
      elapsed = const Duration(seconds: 20);
    final answer = tester.widget<GameButton>(
      find.byKey(const ValueKey('answer-question')),
    );
    answer.onPressed!();
      await finishNavigation(tester);
      expect(state.lossPoints, [1, 0]);
      await unmount(tester);
    },
  );

  testWidgets('next round action runs once and preserves match state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final observer = _ReplacementObserver();
    final state = GameState(
      playerNames: ['Ali', 'Sara', 'Omar'],
      currentPlayerIndex: 2,
      initialStarterIndex: 2,
      lossPoints: [0, 1, 2],
      currentRound: 4,
      answeredCount: 11,
      phase: GamePhase.boom,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: GameTheme.light,
        navigatorObservers: [observer],
        home: BoomScreen(gameState: state),
      ),
    );
    await tester.pump();

    final nextRound = tester.widget<GameButton>(find.byType(GameButton).first);
    nextRound.onPressed!();
    nextRound.onPressed!();
    await finishNavigation(tester);

    expect(state.currentRound, 5);
    expect(state.currentPlayerIndex, 0);
    expect(state.lossPoints, [0, 1, 2]);
    expect(state.answeredCount, 11);
    expect(state.phase, GamePhase.playing);
    expect(observer.replacements, 1);
    expect(find.byType(GameScreen), findsOneWidget);
    await unmount(tester);
  });
}

class _ReplacementObserver extends NavigatorObserver {
  int replacements = 0;

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    replacements++;
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
