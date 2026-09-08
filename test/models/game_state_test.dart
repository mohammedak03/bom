import 'package:bomb_questions/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameState', () {
    test('player wrapping keeps the same bomb round', () {
      final gameState = GameState(playerNames: ['Ali', 'Sara', 'Omar']);

      for (var i = 0; i < 3; i++) {
        gameState.nextPlayer();
      }

      expect(gameState.currentPlayerIndex, 0);
      expect(gameState.answeredCount, 3);
      expect(gameState.currentRound, 1);
    });

    test('starting another bomb round increments once and rotates player', () {
      final gameState = GameState(
        playerNames: ['Ali', 'Sara', 'Omar'],
        currentPlayerIndex: 2,
        initialStarterIndex: 2,
        lossPoints: [0, 1, 2],
        currentRound: 4,
        answeredCount: 11,
        phase: GamePhase.boom,
      );

      gameState.startNextRound();

      expect(gameState.currentRound, 5);
      expect(gameState.currentPlayerIndex, 0);
      expect(gameState.lossPoints, [0, 1, 2]);
      expect(gameState.answeredCount, 11);
    });

    test('recordLoss adds a point to current player and changes phase', () {
      final gameState = GameState(
        playerNames: ['Ali', 'Sara', 'Omar'],
        currentPlayerIndex: 1,
        phase: GamePhase.playing,
      );

      gameState.recordLoss();

      expect(gameState.lossPoints, [0, 1, 0]);
      expect(gameState.phase, GamePhase.boom);
    });

    test('skips are once per player and reset with the next bomb', () {
      final state = GameState(
        playerNames: ['Ali', 'Sara', 'Omar'],
        initialStarterIndex: 1,
        currentPlayerIndex: 1,
      );
      expect(state.useSkip(), isTrue);
      expect(state.useSkip(), isFalse);
      state.nextPlayer();
      expect(state.useSkip(), isTrue);
      state.startNextRound();
      expect(state.skipUsed, [false, false, false]);
      expect(state.currentPlayerIndex, 2);
    });

    test('starters rotate from the initial starter, not the loser', () {
      final state = GameState(
        playerNames: ['Ali', 'Sara', 'Omar'],
        initialStarterIndex: 1,
        currentPlayerIndex: 0,
        phase: GamePhase.boom,
      );
      final starters = [state.initialStarterIndex];
      for (var round = 0; round < 2; round++) {
        state.startNextRound();
        starters.add(state.currentPlayerIndex);
      }
      expect(starters, [1, 2, 0]);
      expect(state.initialStarterIndex, 1);
    });

    test(
      'match modes set their limits and fixed matches stop at the limit',
      () {
        final quick = GameState(
          playerNames: ['Ali', 'Sara', 'Omar'],
          matchMode: MatchMode.quick,
        );
        final normal = GameState(playerNames: ['Ali', 'Sara', 'Omar']);
        final open = GameState(
          playerNames: ['Ali', 'Sara', 'Omar'],
          matchMode: MatchMode.open,
        );
        expect(quick.totalRounds, 3);
        expect(normal.totalRounds, 6);
        expect(open.totalRounds, isNull);
        quick.currentRound = 3;
        expect(quick.canStartNextRound, isFalse);
        expect(quick.canShowResults, isTrue);
        expect(open.canShowResults, isTrue);
      },
    );

    test('reset returns the game to the initial setup state', () {
      final gameState = GameState(
        playerNames: ['Ali', 'Sara', 'Omar'],
        currentPlayerIndex: 2,
        lossPoints: [1, 0, 2],
        currentRound: 4,
        answeredCount: 9,
        phase: GamePhase.results,
      );

      gameState.reset();

      expect(gameState.currentPlayerIndex, 0);
      expect(gameState.lossPoints, [0, 0, 0]);
      expect(gameState.currentRound, 1);
      expect(gameState.answeredCount, 0);
      expect(gameState.phase, GamePhase.setup);
    });
  });
}
