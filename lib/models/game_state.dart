import '../data/questions.dart';
import 'question.dart';

enum GamePhase { setup, playing, boom, results }

enum MatchMode { quick, normal, open }

class GameState {
  GameState({
    required List<String> playerNames,
    this.currentPlayerIndex = 0,
    List<int>? lossPoints,
    this.currentRound = 1,
    this.answeredCount = 0,
    this.phase = GamePhase.setup,
    this.matchMode = MatchMode.normal,
    this.initialStarterIndex = 0,
    List<bool>? skipUsed,
    List<Question>? questionPool,
    List<String>? selectedPackageIds,
  }) : playerNames = List<String>.from(playerNames),
       questionPool = List<Question>.unmodifiable(questionPool ?? questions),
       selectedPackageIds = List<String>.unmodifiable(
         selectedPackageIds ?? const [],
       ),
       lossPoints = lossPoints != null
           ? List<int>.from(lossPoints)
           : List<int>.filled(playerNames.length, 0),
       skipUsed = skipUsed != null
           ? List<bool>.from(skipUsed)
           : List<bool>.filled(playerNames.length, false) {
    if (this.questionPool.isEmpty) {
      throw ArgumentError.value(
        questionPool,
        'questionPool',
        'Choose at least one non-empty package.',
      );
    }
    if (playerNames.isEmpty ||
        initialStarterIndex < 0 ||
        initialStarterIndex >= playerNames.length ||
        this.lossPoints.length != playerNames.length ||
        this.skipUsed.length != playerNames.length) {
      throw ArgumentError('Invalid player state.');
    }
  }

  final List<String> playerNames;
  final List<Question> questionPool;

  /// Catalog IDs are persisted instead of arbitrary question data.
  final List<String> selectedPackageIds;
  int currentPlayerIndex;
  final List<int> lossPoints;
  int currentRound;
  int answeredCount;
  GamePhase phase;
  final MatchMode matchMode;
  final int initialStarterIndex;
  final List<bool> skipUsed;

  int? get totalRounds => switch (matchMode) {
    MatchMode.quick => playerNames.length,
    MatchMode.normal => playerNames.length * 2,
    MatchMode.open => null,
  };

  bool get isFinalRound => totalRounds != null && currentRound >= totalRounds!;
  bool get canShowResults => matchMode == MatchMode.open || isFinalRound;
  bool get canStartNextRound => !isFinalRound;

  bool canSkipCurrentPlayer() =>
      currentPlayerIndex >= 0 &&
      currentPlayerIndex < skipUsed.length &&
      !skipUsed[currentPlayerIndex];

  bool useSkip() {
    if (!canSkipCurrentPlayer()) return false;
    skipUsed[currentPlayerIndex] = true;
    return true;
  }

  void nextPlayer() {
    if (playerNames.isEmpty) {
      return;
    }

    answeredCount++;
    currentPlayerIndex = (currentPlayerIndex + 1) % playerNames.length;
  }

  void startNextRound() {
    if (!canStartNextRound) return;
    currentRound++;
    currentPlayerIndex =
        (initialStarterIndex + currentRound - 1) % playerNames.length;
    for (var index = 0; index < skipUsed.length; index++) {
      skipUsed[index] = false;
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
      skipUsed[index] = false;
    }
  }
}
