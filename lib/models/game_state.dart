import '../data/questions.dart';
import 'question.dart';

enum GamePhase { setup, playing, boom, results }

class GameState {
  GameState({
    required List<String> playerNames,
    this.currentPlayerIndex = 0,
    List<int>? lossPoints,
    this.currentRound = 1,
    this.answeredCount = 0,
    this.phase = GamePhase.setup,
    List<Question>? questionPool,
  }) : playerNames = List<String>.from(playerNames),
       questionPool = List<Question>.unmodifiable(questionPool ?? questions),
       lossPoints = lossPoints != null
           ? List<int>.from(lossPoints)
           : List<int>.filled(playerNames.length, 0) {
    if (this.questionPool.isEmpty) {
      throw ArgumentError.value(
        questionPool,
        'questionPool',
        'Choose at least one non-empty package.',
      );
    }
  }

  final List<String> playerNames;
  final List<Question> questionPool;
  int currentPlayerIndex;
  final List<int> lossPoints;
  int currentRound;
  int answeredCount;
  GamePhase phase;

  void nextPlayer() {
    if (playerNames.isEmpty) {
      return;
    }

    answeredCount++;
    currentPlayerIndex = (currentPlayerIndex + 1) % playerNames.length;
  }

  void startNextRound() {
    currentRound++;
    if (playerNames.isNotEmpty) {
      currentPlayerIndex = (currentPlayerIndex + 1) % playerNames.length;
    }
  }

  void recordLoss() {
    if (lossPoints.isEmpty) {
      return;
    }

    lossPoints[currentPlayerIndex]++;
    phase = GamePhase.boom;
  }

  void reset() {
    currentPlayerIndex = 0;
    currentRound = 1;
    answeredCount = 0;
    phase = GamePhase.setup;

    for (var index = 0; index < lossPoints.length; index++) {
      lossPoints[index] = 0;
    }
  }
}
