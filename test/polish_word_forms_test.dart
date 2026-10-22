import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_flow/models/app_language.dart';
import 'package:chinese_flow/models/polish_word_forms.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled Polish forms catalog loads paradigms and localized examples',
      () async {
    final source = await rootBundle.loadString('assets/data/polish_word_forms.json');
    final catalog = PolishFormsCatalog.fromJson(source);

    final book = catalog.lookup('książka');
    expect(book, isNotNull);
    expect(book!.forms, hasLength(8));
    expect(book.forms.first.value, 'książka');
    expect(
      book.example.forLanguage(AppLanguage.traditionalChinese),
      '我在讀一本關於波蘭的書。',
    );
    expect(catalog.lookup('dom; house'), isNotNull);
    expect(catalog.lookup('unknown'), isNull);
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
