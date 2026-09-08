import 'question.dart';

class QuestionPackage {
  QuestionPackage({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required List<Question> questions,
    this.isFree = false,
  }) : questions = List<Question>.unmodifiable(questions);

  final String id;
  final String name;
  final String emoji;
  final String description;
  final List<Question> questions;
  final bool isFree;
}
