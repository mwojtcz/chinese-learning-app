import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_flow/models/app_language.dart';
import 'package:chinese_flow/models/polish_word_forms.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled Polish forms catalog loads paradigms and localized examples',
      () async {
    final source =
        await rootBundle.loadString('assets/data/polish_word_forms.json');
    final catalog = PolishFormsCatalog.fromJson(source);

    final book = catalog.lookup('książka');
    expect(book, isNotNull);
    expect(catalog.entries, hasLength(61));
    expect(book!.forms, hasLength(14));
    expect(catalog.declensionParadigms, hasLength(29));
    expect(catalog.conjugationParadigms, hasLength(18));
    expect(PolishFormsCatalog.declensionFormsFor(book), hasLength(14));
    expect(
      catalog.conjugationParadigms.every(
        (entry) => PolishFormsCatalog.conjugationFormsFor(entry).every(
          (form) =>
              !['Aspekt', 'Użycie', 'Para aspektowa'].contains(form.label),
        ),
      ),
      isTrue,
    );
    final verb = catalog.lookup('chodzić')!;
    final variantForm =
        verb.forms.firstWhere((form) => form.value.contains('/'));
    expect(
      PolishFormsCatalog.answerVariantsFor(variantForm),
      hasLength(2),
    );
    expect(book.forms.first.value, 'książka');
    expect(
      book.example.forLanguage(AppLanguage.traditionalChinese),
      '我在讀一本關於波蘭的書。',
    );
    expect(catalog.lookup('dom; house'), isNotNull);
    expect(catalog.lookup('unknown'), isNull);
    expect(
      catalog.entries.every(
        (entry) =>
            entry.example.polish.trim().isNotEmpty &&
            entry.example.simplifiedChinese.trim().isNotEmpty &&
            entry.example.traditionalChinese.trim().isNotEmpty &&
            entry.forms.every(
              (form) =>
                  form.label.trim().isNotEmpty && form.value.trim().isNotEmpty,
            ),
      ),
      isTrue,
    );
  });

  test('new aspect pairs include future, gender, imperatives and conditionals',
      () async {
    final catalog = PolishFormsCatalog.fromJson(
      await rootBundle.loadString('assets/data/polish_word_forms.json'),
    );
    const expected = {
      'kupować': [
        'kupuję',
        'kupuj',
        'kupowali / kupowały',
        'będę kupować',
        'kupowałbym / kupowałabym'
      ],
      'kupić': [
        'kupię',
        'kup',
        'kupili / kupiły',
        'kupię',
        'kupiłbym / kupiłabym'
      ],
      'wracać': [
        'wracam',
        'wracaj',
        'wracali / wracały',
        'będę wracać',
        'wracałbym / wracałabym'
      ],
      'wrócić': [
        'wrócę',
        'wróć',
        'wrócili / wróciły',
        'wrócę',
        'wróciłbym / wróciłabym'
      ],
    };
    for (final entry in expected.entries) {
      final paradigm = catalog.lookup(entry.key)!;
      expect(paradigm.forms, hasLength(15));
      expect(paradigm.forms.take(6).map((form) => form.label),
          ['ja', 'ty', 'on/ona/ono', 'my', 'wy', 'oni/one']);
      expect(
        [
          for (final index in [0, 6, 11, 12, 13]) paradigm.forms[index].value
        ],
        entry.value,
      );
      expect(paradigm.forms.map((form) => form.label).toSet(), hasLength(15));
    }
    expect(catalog.lookup('kupić')!.forms.last.value,
        contains('pierwsze sześć form oznacza przyszłość'));
    expect(
        catalog.lookup('wrócić')!.forms.last.value, contains('para: wracać'));
  });

  test('noun paradigms list both numbers in seven-case order', () async {
    final source =
        await rootBundle.loadString('assets/data/polish_word_forms.json');
    final catalog = PolishFormsCatalog.fromJson(source);
    final singular = [
      '1. Mianownik (lp.)',
      '2. Dopełniacz (lp.)',
      '3. Celownik (lp.)',
      '4. Biernik (lp.)',
      '5. Narzędnik (lp.)',
      '6. Miejscownik (lp.)',
      '7. Wołacz (lp.)',
    ];
    final plural = [
      '1. Mianownik (lm.)',
      '2. Dopełniacz (lm.)',
      '3. Celownik (lm.)',
      '4. Biernik (lm.)',
      '5. Narzędnik (lm.)',
      '6. Miejscownik (lm.)',
      '7. Wołacz (lm.)',
    ];
    final nouns = catalog.entries
        .where(
          (entry) =>
              entry.forms.any((form) => form.label == singular.first) &&
              entry.forms.any((form) => form.label == plural.first),
        )
        .toList();

    expect(nouns, hasLength(27));
    for (final noun in nouns) {
      expect(
        noun.forms.map((form) => form.label).toList(),
        [...singular, ...plural],
        reason:
            'Expected ordered singular and plural cases for ${noun.lemmas.first}.',
      );
    }
  });

  test('service nouns retain irregular stems and complete case paradigms',
      () async {
    final catalog = PolishFormsCatalog.fromJson(
      await rootBundle.loadString('assets/data/polish_word_forms.json'),
    );
    const expected = {
      'urząd': [
        'urząd',
        'urzędu',
        'urzędowi',
        'urząd',
        'urzędem',
        'urzędzie',
        'urzędzie',
        'urzędy',
        'urzędów',
        'urzędom',
        'urzędy',
        'urzędami',
        'urzędach',
        'urzędy',
      ],
      'lekarz': [
        'lekarz',
        'lekarza',
        'lekarzowi',
        'lekarza',
        'lekarzem',
        'lekarzu',
        'lekarzu',
        'lekarze',
        'lekarzy',
        'lekarzom',
        'lekarzy',
        'lekarzami',
        'lekarzach',
        'lekarze',
      ],
      'odpowiedź': [
        'odpowiedź',
        'odpowiedzi',
        'odpowiedzi',
        'odpowiedź',
        'odpowiedzią',
        'odpowiedzi',
        'odpowiedzi',
        'odpowiedzi',
        'odpowiedzi',
        'odpowiedziom',
        'odpowiedzi',
        'odpowiedziami',
        'odpowiedziach',
        'odpowiedzi',
      ],
      'pieniądze': [
        'pieniądze',
        'pieniędzy',
        'pieniądzom',
        'pieniądze',
        'pieniędzmi',
        'pieniądzach',
        'pieniądze',
      ],
      'drzwi': [
        'drzwi',
        'drzwi',
        'drzwiom',
        'drzwi',
        'drzwiami',
        'drzwiach',
        'drzwi',
      ],
    };
    for (final entry in expected.entries) {
      final paradigm = catalog.lookup(entry.key)!;
      expect(paradigm.forms.take(entry.value.length).map((form) => form.value),
          entry.value,
          reason: entry.key);
      expect(paradigm.forms.map((form) => form.label).toSet(),
          hasLength(paradigm.forms.length));
    }
    for (final lemma in ['pieniądze', 'drzwi']) {
      expect(
        catalog
            .lookup(lemma)!
            .forms
            .any((form) => form.label.contains('(lp.)')),
        isFalse,
        reason: 'Do not invent singular paradigms for these catalog entries.',
      );
    }
    expect(catalog.lookup('pieniądze')!.forms.last.value,
        contains('Pieniądz w liczbie pojedynczej'));
    expect(catalog.lookup('drzwi')!.forms.last.value, contains('dwoje drzwi'));
    final reflexive = catalog.lookup('się')!;
    expect(reflexive.forms.take(6).map((form) => form.value), [
      'siebie / się',
      'sobie',
      'się / siebie',
      'sobą',
      'sobie',
      'do siebie, o sobie, ze sobą',
    ]);
    expect(reflexive.forms.last.value, contains('Brak mianownika'));
  });

  test('motion and sending verbs distinguish direction, aspect and mood',
      () async {
    final catalog = PolishFormsCatalog.fromJson(
      await rootBundle.loadString('assets/data/polish_word_forms.json'),
    );
    const presentOrFuture = {
      'chodzić': [
        'chodzę',
        'chodzisz',
        'chodzi',
        'chodzimy',
        'chodzicie',
        'chodzą'
      ],
      'jechać': ['jadę', 'jedziesz', 'jedzie', 'jedziemy', 'jedziecie', 'jadą'],
      'jeździć': [
        'jeżdżę',
        'jeździsz',
        'jeździ',
        'jeździmy',
        'jeździcie',
        'jeżdżą'
      ],
      'pojechać': [
        'pojadę',
        'pojedziesz',
        'pojedzie',
        'pojedziemy',
        'pojedziecie',
        'pojadą'
      ],
      'wysyłać': [
        'wysyłam',
        'wysyłasz',
        'wysyła',
        'wysyłamy',
        'wysyłacie',
        'wysyłają'
      ],
      'wysłać': ['wyślę', 'wyślesz', 'wyśle', 'wyślemy', 'wyślecie', 'wyślą'],
    };
    const moods = {
      'chodzić': [
        'chodź',
        'chodźmy',
        'chodźcie',
        'chodziłem / chodziłam',
        'chodził / chodziła / chodziło',
        'chodzili / chodziły',
        'będę chodzić',
        'chodziłbym / chodziłabym'
      ],
      'jechać': [
        'jedź',
        'jedźmy',
        'jedźcie',
        'jechałem / jechałam',
        'jechał / jechała / jechało',
        'jechali / jechały',
        'będę jechać',
        'jechałbym / jechałabym'
      ],
      'jeździć': [
        'jeździj',
        'jeździjmy',
        'jeździjcie',
        'jeździłem / jeździłam',
        'jeździł / jeździła / jeździło',
        'jeździli / jeździły',
        'będę jeździć',
        'jeździłbym / jeździłabym'
      ],
      'pojechać': [
        'pojedź',
        'pojedźmy',
        'pojedźcie',
        'pojechałem / pojechałam',
        'pojechał / pojechała / pojechało',
        'pojechali / pojechały',
        'pojadę',
        'pojechałbym / pojechałabym'
      ],
      'wysyłać': [
        'wysyłaj',
        'wysyłajmy',
        'wysyłajcie',
        'wysyłałem / wysyłałam',
        'wysyłał / wysyłała / wysyłało',
        'wysyłali / wysyłały',
        'będę wysyłać',
        'wysyłałbym / wysyłałabym'
      ],
      'wysłać': [
        'wyślij',
        'wyślijmy',
        'wyślijcie',
        'wysłałem / wysłałam',
        'wysłał / wysłała / wysłało',
        'wysłali / wysłały',
        'wyślę',
        'wysłałbym / wysłałabym'
      ],
    };
    for (final entry in presentOrFuture.entries) {
      final paradigm = catalog.lookup(entry.key)!;
      expect(paradigm.forms, hasLength(15));
      expect(paradigm.forms.take(14).map((form) => form.value),
          [...entry.value, ...moods[entry.key]!],
          reason: entry.key);
      expect(paradigm.forms.map((form) => form.label).toSet(), hasLength(15));
      final perfective = ['pojechać', 'wysłać'].contains(entry.key);
      expect(
          paradigm.forms[12].label,
          perfective
              ? 'Przyszły (dokonany): ja'
              : 'Przyszły (niedokonany): ja');
      expect(paradigm.forms.last.value,
          startsWith(perfective ? 'dokonany;' : 'niedokonany;'));
    }
    expect(catalog.lookup('jeździć')!.forms.last.value,
        contains('nie parą dokonaną'));
    expect(catalog.lookup('wysłać')!.forms.last.value,
        contains('nie gwarantuje doręczenia'));
  });

  test('rejects duplicate Polish lemma aliases', () {
    const source = '''
    {
      "entries": [
        {
          "lemmas": ["kot"],
          "forms": [{"label": "Mianownik", "value": "kot"}],
          "example": {"pl": "To kot.", "zhHans": "这是猫。", "zhHant": "這是貓。"}
        },
        {
          "lemmas": ["KOT"],
          "forms": [{"label": "Mianownik", "value": "kot"}],
          "example": {"pl": "To kot.", "zhHans": "这是猫。", "zhHant": "這是貓。"}
        }
      ]
    }
    ''';

    expect(() => PolishFormsCatalog.fromJson(source), throwsFormatException);
  });
}
