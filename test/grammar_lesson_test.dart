import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_flow/models/app_language.dart';
import 'package:chinese_flow/models/grammar_lesson.dart';

void main() {
  testWidgets('bundled grammar lessons parse with unique IDs', (tester) async {
    const assets = {
      'assets/data/grammar_chinese.json': 'zh-',
      'assets/data/grammar_polish_cases.json': 'pl-cases-',
      'assets/data/grammar_polish_verbs.json': 'pl-verbs-',
      'assets/data/grammar_polish_numbers.json': 'pl-numbers-',
    };
    final ids = <String>{};

    for (final entry in assets.entries) {
      final source = await rootBundle.loadString(entry.key);
      final lessons = grammarLessonsFromJson(source);
      expect(lessons, isNotEmpty);
      for (final lesson in lessons) {
        expect(lesson.id, startsWith(entry.value));
        expect(ids.add(lesson.id), isTrue);
      }
    }
  });

  test('parses and selects localized grammar lesson text', () {
    const source = '''
    {
      "lessons": [
        {
          "id": "pl-cases-example",
          "title": {"pl": "Przypadki", "zhHans": "格", "zhHant": "格"},
          "summary": {"pl": "Opis", "zhHans": "说明", "zhHant": "說明"},
          "sections": [
            {
              "heading": {"pl": "Mianownik", "zhHans": "主格", "zhHant": "主格"},
              "explanation": {"pl": "Podmiot", "zhHans": "主语", "zhHant": "主語"},
              "examples": [
                {
                  "pl": "Student czyta.",
                  "zhHans": "学生在读书。",
                  "zhHant": "學生在讀書。",
                  "pinyin": "Xuéshēng zài dúshū."
                }
              ],
              "note": {"pl": "Uwaga", "zhHans": "注意", "zhHant": "注意"}
            }
          ]
        }
      ]
    }
    ''';

    final lesson = grammarLessonsFromJson(source).single;

    expect(lesson.title.forLanguage(AppLanguage.polish), 'Przypadki');
    expect(lesson.title.forLanguage(AppLanguage.simplifiedChinese), '格');
    expect(lesson.title.forLanguage(AppLanguage.traditionalChinese), '格');
    expect(lesson.sections.single.examples.single.pinyin, 'Xuéshēng zài dúshū.');
  });

  test('rejects grammar text without all interface languages', () {
    const source = '''
    {
      "lessons": [
        {
          "id": "pl-invalid",
          "title": {"pl": "Przypadki"},
          "summary": {"pl": "Opis"},
          "sections": []
        }
      ]
    }
    ''';

    expect(() => grammarLessonsFromJson(source), throwsFormatException);
  });
}
