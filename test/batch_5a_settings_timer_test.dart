import 'package:bomb_questions/models/game_state.dart';
import 'package:bomb_questions/screens/boom_screen.dart';
import 'package:bomb_questions/screens/game_screen.dart';
import 'package:bomb_questions/services/settings_service.dart';
import 'package:bomb_questions/theme/game_theme.dart';
import 'package:bomb_questions/widgets/bomb_widget.dart';
import 'package:bomb_questions/widgets/game_ui.dart';
import 'package:bomb_questions/widgets/timer_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> mount(
    WidgetTester tester, {
    required GameState state,
    required Duration Function() elapsed,
    required GameSettings settings,
    required List<GameAudioRequest> audio,
    required List<GameHapticRequest> haptics,
  }) => tester.pumpWidget(
    MaterialApp(
      key: ValueKey(state),
      theme: GameTheme.light,
      home: GameScreen(
        gameState: state,
        elapsedTime: elapsed,
        timerDuration: const Duration(seconds: 20),
        enableAudio: true,
        settingsOverride: settings,
        timerDisplayModeOverride: settings.timerDisplayMode,
        onAudioRequest: audio.add,
        onHapticRequest: haptics.add,
      ),
    ),
  );

  testWidgets('sound and vibration settings gate every game request', (
    tester,
  ) async {
    var elapsed = Duration.zero;
    final audio = <GameAudioRequest>[];
    final haptics = <GameHapticRequest>[];
    final state = GameState(playerNames: ['A', 'B']);
    await mount(
      tester,
      state: state,
      elapsed: () => elapsed,
      settings: const GameSettings(timerDisplayMode: TimerDisplayMode.visible),
      audio: audio,
      haptics: haptics,
    );
    expect(audio, [GameAudioRequest.ticking]);
    await tester.tap(find.byKey(const ValueKey('answer-question')));
    expect(audio, contains(GameAudioRequest.success));
    expect(haptics, [GameHapticRequest.lightTap]);
    elapsed = const Duration(seconds: 20);
    tester
        .widget<GameButton>(find.byKey(const ValueKey('answer-question')))
        .onPressed!();
    await tester.pump();
    expect(audio, contains(GameAudioRequest.explosion));
    expect(haptics, contains(GameHapticRequest.explosion));

    elapsed = Duration.zero;
    final mutedAudio = <GameAudioRequest>[];
    final mutedHaptics = <GameHapticRequest>[];
    final muted = GameState(playerNames: ['C', 'D']);
    await mount(
      tester,
      state: muted,
      elapsed: () => elapsed,
      settings: const GameSettings(
        soundEnabled: false,
        vibrationEnabled: false,
        timerDisplayMode: TimerDisplayMode.visible,
      ),
      audio: mutedAudio,
      haptics: mutedHaptics,
    );
    await tester.tap(find.byKey(const ValueKey('answer-question')));
    elapsed = const Duration(seconds: 20);
    tester
        .widget<GameButton>(find.byKey(const ValueKey('answer-question')))
        .onPressed!();
    await tester.pump();
    expect(mutedAudio, isEmpty);
    expect(mutedHaptics, isEmpty);
  });

  testWidgets(
    'mystery hides progress while visible exposes it without changing expiry',
    (tester) async {
      var elapsed = const Duration(seconds: 5);
      final state = GameState(playerNames: ['A', 'B']);
      await mount(
        tester,
        state: state,
        elapsed: () => elapsed,
        settings: const GameSettings(),
        audio: [],
        haptics: [],
      );
      expect(find.byType(TimerBar), findsNothing);
      expect(
        tester.widget<BombWidget>(find.byType(BombWidget).first).progress,
        1,
      );
      elapsed = const Duration(seconds: 19);
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester.widget<BombWidget>(find.byType(BombWidget).first).progress,
        1,
      );
      elapsed = const Duration(seconds: 20);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(BoomScreen), findsOneWidget);

      elapsed = const Duration(seconds: 5);
      final visible = GameState(playerNames: ['C', 'D']);
      await mount(
        tester,
        state: visible,
        elapsed: () => elapsed,
        settings: const GameSettings(
          timerDisplayMode: TimerDisplayMode.visible,
        ),
        audio: [],
        haptics: [],
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(TimerBar), findsOneWidget);
      expect(
        tester.widget<TimerBar>(find.byType(TimerBar)).progress,
        closeTo(.75, .01),
      );
      expect(
        tester.widget<BombWidget>(find.byType(BombWidget).first).progress,
        closeTo(.75, .01),
      );
    },
  );
}
