enum QuestionDifficulty { easy, medium, hard }

class Question {
  const Question({
    required this.text,
    required this.category,
    this.packageId = '',
    this.id = '',
    this.referenceAnswer = 'الإجابة المرجعية تُراجع مع المجموعة.',
    this.difficulty = QuestionDifficulty.medium,
    this.acceptedAlternatives = const [],
  });

  final String text;
  final String category;
  final String packageId;

  /// Stable catalog identifier. Legacy entries derive a stable, package-scoped id.
  final String id;
  final String referenceAnswer;
  final QuestionDifficulty difficulty;
  final List<String> acceptedAlternatives;

  Question copyWithDifficulty(QuestionDifficulty value) => Question(
    text: text,
    category: category,
    packageId: packageId,
    id: id,
    referenceAnswer: referenceAnswer,
    difficulty: value,
    acceptedAlternatives: acceptedAlternatives,
  );

  String get stableId =>
      id.isNotEmpty ? id : '${packageId}_${_stableHash(text)}';

  static String _stableHash(String value) {
    var hash = 2166136261;
    for (final codeUnit in value.codeUnits) {
      hash = (hash ^ codeUnit) * 16777619;
      hash &= 0x7fffffff;
    }
    return hash.toRadixString(16);
  }
}
