import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_flow/models/polish_course.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the ordered CEFR learning pathway with localized module content',
      () async {
    final source =
        await rootBundle.loadString('assets/data/polish_course.json');
    final levels = polishCourseFromJson(source);

    expect(levels.map((level) => level.level),
        ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']);
    expect(levels, hasLength(6));
    final units = levels.expand((level) => level.units).toList();
    expect(units, hasLength(38));
    expect(levels.map((level) => level.units.length), [6, 7, 8, 7, 5, 5]);
    for (final level in levels) {
      expect(level.units.map((unit) => unit.title.polish).toSet(),
          hasLength(level.units.length));
      for (var index = 0; index < level.units.length; index++) {
        expect(level.units[index].title.polish, startsWith('${index + 1}. '));
      }
    }
    for (final unit in units) {
      final localizedTexts = [
        unit.title,
        unit.outcome,
        unit.focus,
        unit.practice,
        unit.answer,
        unit.task,
        ...unit.examples,
      ];
      expect(unit.examples, isNotEmpty);
      expect(
        localizedTexts.every(
          (text) =>
              text.polish.trim().isNotEmpty &&
              text.simplifiedChinese.trim().isNotEmpty &&
              text.traditionalChinese.trim().isNotEmpty,
        ),
        isTrue,
        reason: 'Every course field must be localized for all three languages.',
      );
    }
  });

  test('added pathway units connect explanations with corrected model answers',
      () async {
    final levels = polishCourseFromJson(
      await rootBundle.loadString('assets/data/polish_course.json'),
    );
    final route = levels.singleWhere((level) => level.level == 'A2').units[5];
    expect(route.title.polish, '6. Trasa dnia: miejsce, cel i powrót');
    expect(route.answer.polish,
        contains('Idę na pocztę, wracam z poczty i spotykam się z kolegą.'));
    final measures =
        levels.singleWhere((level) => level.level == 'B1').units[5];
    expect(measures.title.polish, '6. Ile czasu, ile rzeczy, o ile więcej?');
    expect(measures.answer.polish, contains('półtorej godziny'));
    final condition =
        levels.singleWhere((level) => level.level == 'B2').units[4];
    expect(
        condition.title.polish, '5. Decyzje: warunek otwarty, hipoteza i cel');
    expect(
      condition.answer.polish,
      startsWith(
        'Gdybym wczoraj wróciła wcześniej, wysłałabym ci adres, '
        'żebyś trafiła bez problemu.',
      ),
    );
  });

  test('practical expansion supplies model answers across all six levels',
      () async {
    final levels = polishCourseFromJson(
      await rootBundle.loadString('assets/data/polish_course.json'),
    );
    const addedUnits = {
      'A1': {
        '6. Gdy nie rozumiesz: pytania i uprzejmość': 'Czy pan mówi po polsku?',
      },
      'A2': {
        '7. Terminy, daty i codzienne dojazdy': 'drugiego maja o ósmej',
      },
      'B1': {
        '7. Dokumenty i reklamacja bez nieporozumień':
            'Zależy mi na szybkiej odpowiedzi.',
        '8. Kto co powiedział: relacja i zdania względne':
            'To lekarka, której wysłałem wyniki.',
      },
      'B2': {
        '6. Raport: wykonawca, proces i rezultat':
            'Czytając raport, zauważyłam błąd.',
        '7. Dane zespołu: liczebniki i zgodność':
            'Dwaj lekarze przyszli, ale pięć osób przyszło.',
      },
      'C1': {
        '5. Dowód, zastrzeżenie i odpowiedzialność za wniosek':
            'Mimo małej próby i dzięki pomocy zespołu',
      },
      'C2': {
        '5. Mediacja: zakres negacji i ukryte założenia':
            'nie podaje liczby zwolenników',
      },
    };
    for (final level in levels) {
      for (final expected in addedUnits[level.level]!.entries) {
        final unit = level.units
            .singleWhere((unit) => unit.title.polish == expected.key);
        expect(unit.answer.polish, contains(expected.value));
        expect(unit.examples.length, greaterThanOrEqualTo(2));
      }
    }
    final mediation = levels.last.units.last;
    expect(mediation.task.polish, contains('nie kompletnym certyfikowanym'));
    expect(mediation.task.simplifiedChinese, contains('并非完整的认证教材'));
    expect(mediation.task.traditionalChinese, contains('並非完整的認證教材'));
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
