import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_flow/models/app_language.dart';
import 'package:chinese_flow/models/vocabulary_category.dart';
import 'package:chinese_flow/models/word.dart';

Word _word(
  List<String> categories, {
  String level = 'HSK-2',
  List<String> tags = const [],
}) =>
    Word(
      hanzi: '测试',
      pinyin: 'cè shì',
      englishTranslation: 'test',
      polishTranslation: 'test',
      level: level,
      tags: tags,
      categories: categories,
    );

void main() {
  test('uses explicit categories and ignores unreliable legacy tags', () {
    expect(
      VocabularyCategory.idsFor(
        _word(['food'], tags: ['Body', 'noun']),
      ),
      ['food'],
    );
    expect(VocabularyCategory.idsFor(_word(['body'])), ['body']);
  });

  test('uses a transparent other category for unclassified entries', () {
    expect(
      VocabularyCategory.idsFor(
        _word([], tags: ['Body', 'noun', 'essential']),
      ),
      ['other'],
    );
    expect(
      VocabularyCategory.all
          .singleWhere((category) => category.id == 'body')
          .label(AppLanguage.polish),
      'Części ciała',
    );
  });

  test('lists only categories represented at the requested HSK level', () {
    final words = [
      _word(['body']),
      _word(['food'], level: 'HSK-3'),
    ];

    expect(
      VocabularyCategory.availableFor(words, level: 'HSK-2')
          .map((category) => category.id),
      ['body'],
    );
  });
}
