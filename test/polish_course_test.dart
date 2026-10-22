import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_flow/models/polish_course.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the complete ordered CEFR course with localized module content',
      () async {
    final source = await rootBundle.loadString('assets/data/polish_course.json');
    final levels = polishCourseFromJson(source);

    expect(levels.map((level) => level.level), ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']);
    expect(levels, hasLength(6));
    expect(levels.expand((level) => level.units), hasLength(24));
    expect(
      levels.expand((level) => level.units).every(
            (unit) =>
                unit.outcome.polish.isNotEmpty &&
                unit.outcome.simplifiedChinese.isNotEmpty &&
                unit.outcome.traditionalChinese.isNotEmpty &&
                unit.focus.polish.isNotEmpty &&
                unit.examples.isNotEmpty &&
                unit.examples.every(
                  (example) =>
                      example.polish.isNotEmpty &&
                      example.simplifiedChinese.isNotEmpty &&
                      example.traditionalChinese.isNotEmpty,
                ) &&
                unit.practice.polish.isNotEmpty &&
                unit.practice.simplifiedChinese.isNotEmpty &&
                unit.practice.traditionalChinese.isNotEmpty &&
                unit.answer.polish.isNotEmpty &&
                unit.answer.simplifiedChinese.isNotEmpty &&
                unit.answer.traditionalChinese.isNotEmpty &&
                unit.task.polish.isNotEmpty,
          ),
      isTrue,
    );
  });

  test('rejects course levels in the wrong order', () {
    const source = '''
    {
      "levels": [
        {
          "level": "A2",
          "title": {"pl": "A2", "zhHans": "A2", "zhHant": "A2"},
          "canDo": {"pl": "Cel", "zhHans": "目标", "zhHant": "目標"},
          "units": [{
            "title": {"pl": "Lekcja", "zhHans": "课程", "zhHant": "課程"},
            "outcome": {"pl": "Wynik", "zhHans": "结果", "zhHant": "結果"},
            "focus": {"pl": "Temat", "zhHans": "重点", "zhHant": "重點"},
            "examples": [{"pl": "Przykład", "zhHans": "例句", "zhHant": "例句"}],
            "practice": {"pl": "Ćwiczenie", "zhHans": "练习", "zhHant": "練習"},
            "answer": {"pl": "Odpowiedź", "zhHans": "答案", "zhHant": "答案"},
            "task": {"pl": "Zadanie", "zhHans": "任务", "zhHant": "任務"}
          }]
        }
      ]
    }
    ''';

    expect(() => polishCourseFromJson(source), throwsFormatException);
  });
}
