import 'package:bomb_questions/models/question.dart';
import 'package:bomb_questions/services/question_deck.dart';
import 'package:flutter_test/flutter_test.dart';

Question question(String id, String topic, QuestionDifficulty difficulty) =>
    Question(
      id: id,
      text: id,
      category: topic,
      packageId: topic,
      referenceAnswer: 'إجابة $id',
      difficulty: difficulty,
    );

void main() {
  test('uses every question before repeating and avoids the cycle boundary', () {
    final pool = [
      question('a', 'one', QuestionDifficulty.easy),
      question('b', 'one', QuestionDifficulty.medium),
      question('c', 'one', QuestionDifficulty.hard),
    ];
    final deck = QuestionDeck(pool: pool, playerCount: 1, randomIndex: (_) => 0);
    final firstCycle = [for (var i = 0; i < 3; i++) deck.takeForPlayer(0).stableId];
    expect(firstCycle.toSet(), hasLength(3));
    expect(deck.takeForPlayer(0).stableId, isNot(firstCycle.last));
  });

  test('rotates topics and balances a player difficulty when available', () {
    final pool = [
      for (final topic in ['one', 'two'])
        for (final difficulty in QuestionDifficulty.values)
          question('$topic-${difficulty.name}', topic, difficulty),
    ];
    final deck = QuestionDeck(pool: pool, playerCount: 1, randomIndex: (_) => 0);
    final shown = [for (var i = 0; i < 6; i++) deck.takeForPlayer(0)];
    for (var i = 1; i < shown.length; i++) {
      expect(shown[i].packageId, isNot(shown[i - 1].packageId));
    }
    final counts = deck.difficultyCounts.single;
    expect(counts.reduce((a, b) => a > b ? a : b) - counts.reduce((a, b) => a < b ? a : b), lessThanOrEqualTo(1));
  });

  test('one-question pools are safe', () {
    final deck = QuestionDeck(
      pool: [question('only', 'one', QuestionDifficulty.easy)],
      playerCount: 1,
      randomIndex: (_) => 0,
    );
    expect(deck.takeForPlayer(0).stableId, 'only');
    expect(deck.takeForPlayer(0).stableId, 'only');
  });
}
