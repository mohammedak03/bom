import 'package:bomb_questions/main.dart';
import 'package:bomb_questions/models/game_state.dart';
import 'package:bomb_questions/screens/boom_screen.dart';
import 'package:bomb_questions/screens/game_screen.dart';
import 'package:bomb_questions/screens/packages_screen.dart';
import 'package:bomb_questions/screens/results_screen.dart';
import 'package:bomb_questions/screens/setup_screen.dart';
import 'package:bomb_questions/theme/game_theme.dart';
import 'package:bomb_questions/widgets/question_card.dart';
import 'package:bomb_questions/widgets/timer_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

// Audit characterization tests. Tests named "current behavior" document
// existing defects rather than endorsing them as the intended game rules.
// Audio/haptics are mocked: these tests do not verify native playback.
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
        if (call.method == 'setSourceBytes') {
          final id = (call.arguments as Map)['playerId'];
          await messenger.handlePlatformMessage(
            'xyz.luan/audioplayers/events/$id',
            const StandardMethodCodec().encodeSuccessEnvelope({
              'event': 'audio.onPrepared',
              'value': true,
            }),
            (_) {},
          );
        }
        return call.method == 'getCurrentPosition' ||
                call.method == 'getDuration'
            ? 0
            : null;
      },
    );
  });

  Future<void> mount(WidgetTester tester, Widget app) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app);
    await tester.runAsync(() => GoogleFonts.pendingFonts());
    await tester.pump();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  }

  testWidgets(
    'setup accepts eight players, trims names and fills blank names',
    (tester) async {
      await mount(tester, const BombQuestionsApp());
      expect(tester.takeException(), isNull, reason: 'Initial setup layout');
      final addPlayer = find.byKey(const ValueKey('add-player'));
      final removePlayer = find.byKey(const ValueKey('remove-player'));
      await tester.tap(removePlayer);
      await tester.pump();
      expect(find.byType(TextField), findsNWidgets(2));
      for (var i = 0; i < 7; i++) {
        await tester.tap(addPlayer);
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Adding player ${i + 3}',
        );
      }
      expect(find.byType(TextField), findsNWidgets(8));
      await tester.tap(removePlayer);
      await tester.pump();
      expect(find.byType(TextField), findsNWidgets(7));
      await tester.tap(addPlayer);
      await tester.pump();
      expect(find.byType(TextField), findsNWidgets(8));
      await tester.enterText(find.byType(TextField).at(0), '  Ali  ');
      expect(tester.takeException(), isNull, reason: 'Entering first name');
      await tester.enterText(find.byType(TextField).at(1), '   ');
      expect(tester.takeException(), isNull, reason: 'Entering second name');
      tester.testTextInput.hide();
      await tester.tap(find.byKey(const ValueKey('start-game')));
      await tester.pumpAndSettle();
      expect(find.byType(PackagesScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('start-selected-game')));
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: 'Starting game first frame',
      );
      await tester.runAsync(() => GoogleFonts.pendingFonts());
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester.takeException(),
        isNull,
        reason: 'Starting game transition',
      );
      final state = tester
          .widget<GameScreen>(find.byType(GameScreen))
          .gameState;
      expect(state.playerNames.length, 8);
      expect(state.questionPool.map((question) => question.packageId).toSet(), {
        'general',
      });
      expect(state.playerNames[0], 'Ali');
      expect(state.playerNames[1], 'اللاعب 2');
      expect(state.playerNames[7], 'اللاعب 8');
      expect(state.lossPoints, List.filled(8, 0));
      expect(state.phase, GamePhase.playing);
      expect(state.currentPlayerIndex, 0);
      await unmount(tester);
    },
  );

  testWidgets(
    'answers move the turn, preserve losses and avoid immediate question repeats',
    (tester) async {
      final state = GameState(
        playerNames: ['Ali', 'Sara', 'Omar'],
        phase: GamePhase.playing,
      );
      await mount(
        tester,
        MaterialApp(
          theme: GameTheme.light,
          home: GameScreen(gameState: state),
        ),
      );
      for (var i = 0; i < 12; i++) {
        final previous = tester
            .widget<QuestionCard>(find.byType(QuestionCard))
            .question;
        await tester.tap(find.byKey(const ValueKey('answer-question')));
        await tester.pump();
        final next = tester
            .widget<QuestionCard>(find.byType(QuestionCard))
            .question;
        expect(identical(previous, next), isFalse);
        expect(state.currentPlayerIndex, (i + 1) % 3);
        expect(state.answeredCount, i + 1);
        expect(state.lossPoints, [0, 0, 0]);
      }
      expect(state.currentRound, 5); // Counts player laps, not bomb rounds.
      await unmount(tester);
    },
  );

  testWidgets(
    'current behavior: a new bomb preserves the old round and answer counters',
    (tester) async {
      final state = GameState(
        playerNames: ['Ali', 'Sara', 'Omar'],
        currentPlayerIndex: 2,
        lossPoints: [0, 1, 2],
        currentRound: 4,
        answeredCount: 11,
        phase: GamePhase.boom,
      );
      await mount(
        tester,
        MaterialApp(
          theme: GameTheme.light,
          home: BoomScreen(gameState: state),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('جولة كمان'));
      await tester.pump();
      await tester.runAsync(() => GoogleFonts.pendingFonts());
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(GameScreen), findsOneWidget);
      expect(state.phase, GamePhase.playing);
      expect(state.currentPlayerIndex, 0);
      expect(state.lossPoints, [0, 1, 2]);
      expect(state.currentRound, 4);
      expect(state.answeredCount, 11);
      expect(
        tester.widget<TimerBar>(find.byType(TimerBar)).progress,
        greaterThan(.9),
      );
      await unmount(tester);
    },
  );

  testWidgets(
    'results button shows every tied winner and restart clears the game',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final state = GameState(
          playerNames: ['Ali', 'Sara', 'Omar'],
          lossPoints: [1, 0, 0],
          phase: GamePhase.boom,
        );
        await mount(
          tester,
          MaterialApp(
            theme: GameTheme.light,
            home: BoomScreen(gameState: state),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        await tester.tap(find.text('النتائج'));
        await tester.pumpAndSettle();
        expect(find.byType(ResultsScreen), findsOneWidget);
        expect(state.phase, GamePhase.results);
        expect(find.text('الصدارة مشتركة'), findsOneWidget);
        expect(find.text('Sara، Omar'), findsOneWidget);
        expect(find.text('في الصدارة'), findsNWidgets(2));
        expect(
          find.bySemanticsLabel('المركز 1، Sara، 0 انفجارات، في الصدارة'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('المركز 1، Omar، 0 انفجارات، في الصدارة'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('المركز 3، Ali، 1 انفجارات'),
          findsOneWidget,
        );
        expect(
          tester.getTopLeft(find.text('Sara')).dy,
          lessThan(tester.getTopLeft(find.text('Omar')).dy),
        );
        expect(
          tester.getTopLeft(find.text('Omar')).dy,
          lessThan(tester.getTopLeft(find.text('Ali')).dy),
        );
        await tester.tap(find.text('نلعب من جديد'));
        await tester.pumpAndSettle();
        expect(find.byType(SetupScreen), findsOneWidget);
        expect(state.lossPoints, [0, 0, 0]);
        expect(state.currentRound, 1);
        expect(state.answeredCount, 0);
        expect(state.phase, GamePhase.setup);
      } finally {
        semantics.dispose();
      }
      await unmount(tester);
    },
  );

  testWidgets(
    'current behavior: a late answer before the next timer callback transfers the loss',
    (tester) async {
      final state = GameState(
        playerNames: ['Ali', 'Sara'],
        phase: GamePhase.playing,
      );
      await mount(
        tester,
        MaterialApp(
          theme: GameTheme.light,
          home: GameScreen(gameState: state),
        ),
      );
      // Production uses DateTime.now, so fake timer advancement cannot expire it.
      // Wait beyond the maximum duration while intentionally holding timer callbacks.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 61)),
      );
      await tester.tap(find.byKey(const ValueKey('answer-question')));
      expect(state.currentPlayerIndex, 1); // Defect: expired turn was accepted.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(() => GoogleFonts.pendingFonts());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(BoomScreen), findsOneWidget);
      expect(state.lossPoints, [0, 1]); // Loss moved to the next player.
      await tester.pump(const Duration(seconds: 2));
      expect(state.lossPoints, [0, 1]); // Expiration only records one loss.
      await unmount(tester);
    },
    skip: !const bool.fromEnvironment('AUDIT_REAL_TIME_TIMER'),
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
