import 'package:bomb_questions/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameState audit: player and score invariants', () {
    test('two players alternate across several complete turns', () {
      final state = GameState(
        playerNames: ['Ali', 'Sara'],
        phase: GamePhase.playing,
      );
      final playersAfterAnswers = <String>[];

      for (var answer = 0; answer < 5; answer++) {
        state.nextPlayer();
        playersAfterAnswers.add(state.playerNames[state.currentPlayerIndex]);
      }

      expect(playersAfterAnswers, ['Sara', 'Ali', 'Sara', 'Ali', 'Sara']);
      expect(state.answeredCount, 5);
      expect(state.lossPoints, [0, 0]);
      expect(state.phase, GamePhase.playing);
    });

    test('eight players each get a turn before the order repeats', () {
      final state = GameState(
        playerNames: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'],
        phase: GamePhase.playing,
      );
      final playersAfterAnswers = <String>[];

      for (var answer = 0; answer < 10; answer++) {
        state.nextPlayer();
        playersAfterAnswers.add(state.playerNames[state.currentPlayerIndex]);
      }

      expect(playersAfterAnswers, [
        'B',
        'C',
        'D',
        'E',
        'F',
        'G',
        'H',
        'A',
        'B',
        'C',
      ]);
      expect(state.answeredCount, 10);
      expect(state.lossPoints, List<int>.filled(8, 0));
    });

    for (final playerCount in [2, 8]) {
      test('losses accumulate separately for all $playerCount players', () {
        final state = GameState(
          playerNames: List.generate(playerCount, (index) => 'Player $index'),
          phase: GamePhase.playing,
        );

        // Exercise each player's score slot, then lose again as the first
        // player. This audits the model; screen navigation has separate tests.
        for (var player = 0; player < playerCount; player++) {
          state.phase = GamePhase.playing;
          state.recordLoss();

          expect(state.currentPlayerIndex, player);
          expect(state.phase, GamePhase.boom);
          expect(state.lossPoints[player], 1);
          state.nextPlayer();
        }

        expect(state.lossPoints, List<int>.filled(playerCount, 1));
        state.phase = GamePhase.playing;
        state.recordLoss();

        expect(state.lossPoints.first, 2);
        expect(state.lossPoints.skip(1), everyElement(1));
        expect(
          state.lossPoints.reduce((total, points) => total + points),
          playerCount + 1,
        );
      });
    }

    test('reset clears a completed game and can start another clean cycle', () {
      final state = GameState(
        playerNames: ['Ali', 'Sara'],
        currentPlayerIndex: 1,
        lossPoints: [3, 5],
        currentRound: 9,
        answeredCount: 17,
        phase: GamePhase.results,
      );

      state.reset();

      expect(state.playerNames, ['Ali', 'Sara']);
      expect(state.currentPlayerIndex, 0);
      expect(state.lossPoints, [0, 0]);
      expect(state.currentRound, 1);
      expect(state.answeredCount, 0);
      expect(state.phase, GamePhase.setup);

      state.phase = GamePhase.playing;
      state.nextPlayer();
      state.recordLoss();

      expect(state.currentPlayerIndex, 1);
      expect(state.lossPoints, [0, 1]);
      expect(state.answeredCount, 1);
      expect(state.phase, GamePhase.boom);
    });
  });

  group('GameState audit: bomb round behavior', () {
    for (final playerCount in [2, 8]) {
      test('round does not rise when an answer wraps $playerCount players', () {
        final state = GameState(
          playerNames: List.generate(playerCount, (index) => 'Player $index'),
          phase: GamePhase.playing,
        );

        for (var answer = 0; answer < playerCount - 1; answer++) {
          state.nextPlayer();
          expect(state.currentRound, 1);
        }

        state.nextPlayer();

        expect(state.currentRound, 1);
        expect(state.currentPlayerIndex, 0);
        expect(state.answeredCount, playerCount);
      });
    }

    test(
      'an explosion leaves the round, answer count and player unchanged',
      () {
        final state = GameState(
          playerNames: ['Ali', 'Sara'],
          currentPlayerIndex: 1,
          currentRound: 4,
          answeredCount: 7,
          phase: GamePhase.playing,
        );

        state.recordLoss();

        expect(state.currentRound, 4);
        expect(state.answeredCount, 7);
        expect(state.currentPlayerIndex, 1);
        expect(state.lossPoints, [0, 1]);
        expect(state.phase, GamePhase.boom);
      },
    );
  });
}
