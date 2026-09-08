import '../models/question.dart';

typedef RandomIndex = int Function(int max);

/// Selects catalog questions without repeats and keeps topic and difficulty fair.
class QuestionDeck {
  QuestionDeck({
    required List<Question> pool,
    required int playerCount,
    RandomIndex? randomIndex,
    Iterable<String> usedIds = const [],
    Iterable<String> topicOrder = const [],
    this.topicPosition = 0,
    List<List<int>>? difficultyCounts,
    this.lastQuestionId,
  }) : _pool = List.unmodifiable(pool),
       _randomIndex =
           randomIndex ?? ((max) => DateTime.now().microsecond % max),
       usedIds = Set<String>.from(usedIds),
       topicOrder = List<String>.from(topicOrder),
       difficultyCounts = difficultyCounts == null
           ? List.generate(playerCount, (_) => List.filled(3, 0))
           : difficultyCounts.map(List<int>.from).toList() {
    if (_pool.isEmpty ||
        playerCount < 1 ||
        this.difficultyCounts.length != playerCount ||
        this.difficultyCounts.any(
          (counts) => counts.length != 3 || counts.any((v) => v < 0),
        )) {
      throw ArgumentError('Invalid question deck state.');
    }
    final ids = _pool.map((q) => q.stableId).toSet();
    if (ids.length != _pool.length ||
        !usedIds.every(ids.contains) ||
        (lastQuestionId != null && !ids.contains(lastQuestionId))) {
      throw ArgumentError('Unknown or duplicate question id.');
    }
    final availableTopics = _pool.map((q) => q.packageId).toSet();
    if (this.topicOrder.isEmpty) {
      this.topicOrder.addAll(availableTopics.toList()..sort());
      _shuffle(this.topicOrder);
    }
    if (this.topicOrder.toSet().length != this.topicOrder.length ||
        !this.topicOrder.every(availableTopics.contains)) {
      throw ArgumentError('Invalid topic rotation.');
    }
  }

  final List<Question> _pool;
  final RandomIndex _randomIndex;
  final Set<String> usedIds;
  final List<String> topicOrder;
  int topicPosition;
  final List<List<int>> difficultyCounts;
  String? lastQuestionId;

  Question takeForPlayer(int playerIndex) {
    if (playerIndex < 0 || playerIndex >= difficultyCounts.length) {
      throw RangeError.index(playerIndex, difficultyCounts, 'playerIndex');
    }
    if (usedIds.length == _pool.length) {
      final boundary = lastQuestionId;
      usedIds.clear();
      if (_pool.length > 1 && boundary != null) lastQuestionId = boundary;
    }
    final unused = _pool.where((q) => !usedIds.contains(q.stableId)).toList();
    final topic = _nextTopic(unused);
    final inTopic = unused.where((q) => q.packageId == topic).toList();
    final counts = difficultyCounts[playerIndex];
    final least = counts.reduce((a, b) => a < b ? a : b);
    final preferred = <int>[
      for (var i = 0; i < 3; i++)
        if (counts[i] == least) i,
    ];
    final eligible = inTopic
        .where((q) => preferred.contains(q.difficulty.index))
        .toList();
    final candidates = eligible.isNotEmpty ? eligible : inTopic;
    final withoutBoundary = candidates
        .where((q) => q.stableId != lastQuestionId)
        .toList();
    final selected =
        (withoutBoundary.isNotEmpty
        ? withoutBoundary
        : candidates)[_randomIndex(
          (withoutBoundary.isNotEmpty ? withoutBoundary : candidates).length,
        )];
    usedIds.add(selected.stableId);
    lastQuestionId = selected.stableId;
    difficultyCounts[playerIndex][selected.difficulty.index]++;
    return selected;
  }

  String _nextTopic(List<Question> unused) {
    for (var offset = 0; offset < topicOrder.length; offset++) {
      final index = (topicPosition + offset) % topicOrder.length;
      final topic = topicOrder[index];
      if (unused.any((q) => q.packageId == topic)) {
        topicPosition = (index + 1) % topicOrder.length;
        return topic;
      }
    }
    throw StateError('No unused question');
  }

  void _shuffle(List<String> values) {
    for (var i = values.length - 1; i > 0; i--) {
      final other = _randomIndex(i + 1);
      final value = values[i];
      values[i] = values[other];
      values[other] = value;
    }
  }
}
