import 'question.dart';

class QuestionPackage {
  const QuestionPackage({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.questions,
    this.isFree = false,
  });

  final String id;
  final String name;
  final String emoji;
  final String description;
  final List<Question> questions;
  final bool isFree;
}
