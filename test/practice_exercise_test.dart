import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_flow/models/learning_target.dart';
import 'package:chinese_flow/models/practice_exercise.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads localized practice exercises from the bundled asset', () async {
    final source = await rootBundle.loadString('assets/data/practice_exercises.json');
    final exercises = PracticeExercise.listFromJson(source);

    expect(exercises, hasLength(15));
    expect(
      exercises.where((exercise) => exercise.target == LearningTarget.polish),
      hasLength(8),
    );
    expect(
      exercises.where((exercise) => exercise.target == LearningTarget.chinese),
      hasLength(7),
    );
  });

  test('normalizes case, whitespace, and trailing punctuation only', () {
    expect(practiceAnswerMatches('  KSIĄŻKĘ! ', ['książkę']), isTrue);
    expect(practiceAnswerMatches('  我  是。 ', ['我是']), isFalse);
    expect(practiceAnswerMatches('książka', ['książkę']), isFalse);
  });

  test('rejects duplicate exercise IDs', () {
    const source = '''
    {
      "exercises": [
        {
          "id": "same",
          "target": "polish",
          "courseLevel": "A1",
          "prompt": {"pl": "A", "zhHans": "A", "zhHant": "A"},
          "answer": "a",
          "acceptedAnswers": [],
          "explanation": {"pl": "A", "zhHans": "A", "zhHant": "A"}
        },
        {
          "id": "same",
          "target": "polish",
          "courseLevel": "A1",
          "prompt": {"pl": "B", "zhHans": "B", "zhHant": "B"},
          "answer": "b",
          "acceptedAnswers": [],
          "explanation": {"pl": "B", "zhHans": "B", "zhHant": "B"}
        }
      ]
    }
    ''';

    expect(
      () => PracticeExercise.listFromJson(source),
      throwsFormatException,
    );
  });
}
