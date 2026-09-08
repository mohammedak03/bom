import 'package:bomb_questions/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameState', () {
    test('nextPlayer advances players, answered count, and rounds', () {
      final gameState = GameState(playerNames: ['Ali', 'Sara', 'Omar']);

      gameState.nextPlayer();

      expect(gameState.currentPlayerIndex, 1);
      expect(gameState.answeredCount, 1);
      expect(gameState.currentRound, 1);

      gameState.nextPlayer();
      gameState.nextPlayer();

      expect(gameState.currentPlayerIndex, 0);
      expect(gameState.answeredCount, 3);
      expect(gameState.currentRound, 2);
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

      expect(gameState.playerNames, ['Ali', 'Sara', 'Omar']);
      expect(gameState.currentPlayerIndex, 0);
      expect(gameState.lossPoints, [0, 0, 0]);
      expect(gameState.currentRound, 1);
      expect(gameState.answeredCount, 0);
      expect(gameState.phase, GamePhase.setup);
    });
  });
}
