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
