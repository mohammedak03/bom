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
  test(
    'uses every question before repeating and avoids the cycle boundary',
    () {
      final pool = [
        question('a', 'one', QuestionDifficulty.easy),
        question('b', 'one', QuestionDifficulty.medium),
        question('c', 'one', QuestionDifficulty.hard),
      ];
      final deck = QuestionDeck(
        pool: pool,
        playerCount: 1,
        randomIndex: (_) => 0,
      );
      final firstCycle = [
        for (var i = 0; i < 3; i++) deck.takeForPlayer(0).stableId,
      ];
      expect(firstCycle.toSet(), hasLength(3));
      expect(deck.takeForPlayer(0).stableId, isNot(firstCycle.last));
    },
  );

  test('rotates topics and prefers the casual catalog ratio', () {
    final pool = [
      for (final topic in ['one', 'two'])
        for (final difficulty in QuestionDifficulty.values)
          question('$topic-${difficulty.name}', topic, difficulty),
    ];
    final deck = QuestionDeck(
      pool: pool,
      playerCount: 1,
      randomIndex: (_) => 0,
    );
    final shown = [for (var i = 0; i < 6; i++) deck.takeForPlayer(0)];
    for (var i = 1; i < shown.length; i++) {
      expect(shown[i].packageId, isNot(shown[i - 1].packageId));
    }
    // This intentionally equal-sized test pool exhausts each difficulty once.
    expect(deck.difficultyCounts.single, [2, 2, 2]);
  });

  test('keeps the 12/8/4 ratio and comparable player exposure', () {
    final pool = [
      for (var i = 0; i < 12; i++)
        question('easy-$i', 'one', QuestionDifficulty.easy),
      for (var i = 0; i < 8; i++)
        question('medium-$i', 'one', QuestionDifficulty.medium),
      for (var i = 0; i < 4; i++)
        question('hard-$i', 'one', QuestionDifficulty.hard),
    ];
    final deck = QuestionDeck(
      pool: pool,
      playerCount: 3,
      randomIndex: (_) => 0,
    );
    for (var i = 0; i < 240; i++) {
      deck.takeForPlayer(i % 3);
    }
    final totals = List<int>.filled(3, 0);
    for (final counts in deck.difficultyCounts) {
      for (var i = 0; i < 3; i++) totals[i] += counts[i];
    }
    expect(totals[0], inInclusiveRange(118, 122));
    expect(totals[1], inInclusiveRange(78, 82));
    expect(totals[2], inInclusiveRange(38, 42));
    for (var difficulty = 0; difficulty < 3; difficulty++) {
      final exposure = deck.difficultyCounts
          .map((counts) => counts[difficulty])
          .toList();
      expect(
        exposure.reduce((a, b) => a > b ? a : b) -
            exposure.reduce((a, b) => a < b ? a : b),
        lessThanOrEqualTo(1),
      );
    }
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
