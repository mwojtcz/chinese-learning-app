import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_flow/models/app_language.dart';
import 'package:chinese_flow/models/grammar_lesson.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled grammar lessons parse with unique IDs', () async {
    const assets = {
      'assets/data/grammar_chinese.json': 'zh-',
      'assets/data/grammar_polish_cases.json': 'pl-cases-',
      'assets/data/grammar_polish_verbs.json': 'pl-verbs-',
      'assets/data/grammar_polish_numbers.json': 'pl-numbers-',
    };
    const expectedCounts = {
      'assets/data/grammar_chinese.json': 18,
      'assets/data/grammar_polish_cases.json': 9,
      'assets/data/grammar_polish_verbs.json': 12,
      'assets/data/grammar_polish_numbers.json': 7,
    };
    final ids = <String>{};

    for (final entry in assets.entries) {
      final source = await rootBundle.loadString(entry.key);
      final lessons = grammarLessonsFromJson(source);
      expect(lessons, hasLength(expectedCounts[entry.key]!));
      for (final lesson in lessons) {
        expect(lesson.id, startsWith(entry.value));
        expect(ids.add(lesson.id), isTrue);
        expect(lesson.sections, isNotEmpty);
        final texts = [
          lesson.title,
          lesson.summary,
          for (final section in lesson.sections) ...[
            section.heading,
            section.explanation,
            section.note,
            for (final table in section.tables) ...[
              ...table.headers,
              for (final row in table.rows) ...row,
            ],
          ],
        ];
        for (final text in texts) {
          for (final language in AppLanguage.values) {
            expect(text.forLanguage(language).trim(), isNotEmpty);
          }
        }
        for (final section in lesson.sections) {
          expect(section.examples, isNotEmpty);
          for (final example in section.examples) {
            for (final language in AppLanguage.values) {
              expect(example.forLanguage(language).trim(), isNotEmpty);
            }
          }
        }
      }
    }
    expect(ids, hasLength(46));
  });

  test('expanded grammar develops six contrastive lessons with paired examples',
      () async {
    const additions = {
      'assets/data/grammar_polish_verbs.json': [
        'pl-verbs-aspect-duration-negation',
        'pl-verbs-conditions-purpose',
      ],
      'assets/data/grammar_polish_cases.json': [
        'pl-cases-spatial-prepositions',
      ],
      'assets/data/grammar_polish_numbers.json': [
        'pl-numbers-measures-and-differences',
      ],
      'assets/data/grammar_chinese.json': [
        'zh-clause-connectors',
        'zh-time-sequence-and-scope',
      ],
    };
    for (final asset in additions.entries) {
      final lessons =
          grammarLessonsFromJson(await rootBundle.loadString(asset.key));
      for (final id in asset.value) {
        final lesson = lessons.singleWhere((lesson) => lesson.id == id);
        expect(lesson.sections, hasLength(3));
        for (final section in lesson.sections) {
          expect(section.examples, hasLength(2));
          if (id.startsWith('zh-')) {
            expect(
              section.examples.every(
                (example) => example.pinyin?.trim().isNotEmpty ?? false,
              ),
              isTrue,
            );
          }
        }
      }
    }
  });

  test('contrastive examples preserve aspect, motion and negation scope',
      () async {
    final verbs = grammarLessonsFromJson(
      await rootBundle.loadString('assets/data/grammar_polish_verbs.json'),
    );
    final aspect = verbs.singleWhere(
      (lesson) => lesson.id == 'pl-verbs-aspect-duration-negation',
    );
    expect(aspect.sections.first.examples.last.polish,
        'Przeczytałam cały artykuł w godzinę.');
    expect(aspect.sections[1].examples.last.polish,
        'Pisałem raport cały wieczór, ale go nie napisałem.');
    final cases = grammarLessonsFromJson(
      await rootBundle.loadString('assets/data/grammar_polish_cases.json'),
    );
    final spatial = cases.singleWhere(
      (lesson) => lesson.id == 'pl-cases-spatial-prepositions',
    );
    expect(spatial.sections[1].examples.first.polish,
        'Kot biega pod stołem, a potem wchodzi pod łóżko.');
    final chinese = grammarLessonsFromJson(
      await rootBundle.loadString('assets/data/grammar_chinese.json'),
    );
    final scope = chinese.singleWhere(
      (lesson) => lesson.id == 'zh-time-sequence-and-scope',
    );
    expect(scope.sections.last.examples.first.simplifiedChinese, '他们不都会说中文。');
    expect(scope.sections.last.examples.last.traditionalChinese, '他們都不會說中文。');
  });

  test('seven-case lesson includes ordered comparison and inflection tables',
      () async {
    final source =
        await rootBundle.loadString('assets/data/grammar_polish_cases.json');
    final lessons = grammarLessonsFromJson(source);
    final cases = lessons.singleWhere(
      (lesson) => lesson.id == 'pl-cases-seven-cases',
    );
    final tables = cases.sections.expand((section) => section.tables).toList();

    expect(tables, hasLength(2));
    expect(tables.first.rows, hasLength(7));
    expect(
      tables.first.rows.map((row) => row.first.polish).toList(),
      ['1', '2', '3', '4', '5', '6', '7'],
    );
    expect(tables.last.rows, hasLength(7));
    expect(tables.last.rows[3][2].polish, 'książkę');
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
    expect(
        lesson.sections.single.examples.single.pinyin, 'Xuéshēng zài dúshū.');
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
