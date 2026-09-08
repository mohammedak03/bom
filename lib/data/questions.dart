import '../models/question.dart';
import 'question_packages.dart';

/// Safe default for flows that do not yet supply a selected question bank.
final List<Question> questions = List<Question>.unmodifiable(
  questionPackages
      .where((package) => package.isFree)
      .expand((package) => package.questions),
);
