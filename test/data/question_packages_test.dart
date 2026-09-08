import 'package:bomb_questions/data/question_packages.dart';
import 'package:bomb_questions/data/questions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Question package catalog', () {
    test('contains six distinct topics and exactly two free packages', () {
      expect(
        questionPackages.map((package) => package.id),
        unorderedEquals([
          'general',
          'countries',
          'football',
          'screen',
          'food',
          'science',
        ]),
      );
      expect(
        questionPackages
            .where((package) => package.isFree)
            .map((package) => package.id),
        unorderedEquals(['general', 'countries']),
      );
    });

    test('every topic has a usable bank belonging only to that topic', () {
      for (final package in questionPackages) {
        expect(package.name.trim(), isNotEmpty, reason: package.id);
        expect(package.description.trim(), isNotEmpty, reason: package.id);
        expect(
          package.questions.length,
          greaterThanOrEqualTo(20),
          reason: package.id,
        );
        for (final question in package.questions) {
          expect(question.text.trim(), isNotEmpty, reason: package.id);
          expect(question.packageId, package.id, reason: question.text);
          expect(question.category, package.name, reason: question.text);
        }
      }
    });

    test('questions are unique within each topic and across the catalog', () {
      final allTexts = <String>{};
      for (final package in questionPackages) {
        final packageTexts = <String>{};
        for (final question in package.questions) {
          final normalized = question.text.trim().replaceAll(
            RegExp(r'\s+'),
            ' ',
          );
          expect(
            packageTexts.add(normalized),
            isTrue,
            reason: 'Duplicate in ${package.id}: $normalized',
          );
          expect(
            allTexts.add(normalized),
            isTrue,
            reason: 'Duplicate in catalog: $normalized',
          );
        }
      }
    });

    test('the compatibility bank includes only free topic questions', () {
      final freeQuestions = questionPackages
          .where((package) => package.isFree)
          .expand((package) => package.questions);
      expect(questions, orderedEquals(freeQuestions));
      expect(questions, isNotEmpty);
      for (final question in questions) {
        expect(question.packageId, isIn(['general', 'countries']));
      }
      expect(() => questions.clear(), throwsUnsupportedError);
    });
  });
}
