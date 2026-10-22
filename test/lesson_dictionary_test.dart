import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_flow/models/word.dart';
import 'package:chinese_flow/services/lesson_dictionary.dart';

Word word(String hanzi, String polish,
        {String? traditional, String pinyin = 'pīn yīn'}) =>
    Word(
        hanzi: hanzi,
        traditional: traditional,
        pinyin: pinyin,
        englishTranslation: '',
        polishTranslation: polish,
        level: 'HSK-1');

void main() {
  test('Chinese uses exact longest matches and traditional entries', () {
    final dictionary = LessonDictionary([
      word('中', 'środek'),
      word('中国', 'Chiny', traditional: '中國'),
      word('人', 'człowiek'),
    ]);
    final matches = dictionary.lookup('中国人／中國人');
    expect(matches.map((m) => m.word.displayHanzi), ['中国', '人', '中国', '人']);
    expect(matches.first.start, 0);
    expect(matches.first.end, 2);
  });

  test('Polish exact gloss boundaries include Unicode letters and ignore case',
      () {
    final dictionary =
        LessonDictionary([word('猫', 'kot; kocur'), word('爱', 'lubić')]);
    expect(dictionary.lookup('Kot, KOCUR! lubić.').map((m) => m.word.hanzi),
        ['猫', '猫', '爱']);
    expect(dictionary.lookup('koty maskotka kotłownia kot_1 lubi'), isEmpty);
  });

  test('multiword gloss is not split into invented individual translations',
      () {
    final dictionary = LessonDictionary([word('早上好', 'dzień dobry')]);
    expect(dictionary.lookup('dobry dzień'), isEmpty);
    expect(dictionary.lookup('Dzień dobry!').single.word.hanzi, '早上好');
  });

  test('ambiguous Polish gloss suppressed, duplicate lexical copies accepted',
      () {
    final dictionary = LessonDictionary([
      word('锁', 'zamek'),
      word('城堡', 'zamek'),
      word('猫', 'kot'),
      word('猫', 'kot'),
      word('猫#27', 'kot', traditional: '貓'),
    ]);
    expect(dictionary.lookup('zamek'), isEmpty);
    expect(dictionary.lookup('kot').single.word.hanzi, '猫');
  });

  test('different readings of one headword stay ambiguous despite row IDs', () {
    final dictionary = LessonDictionary([
      word('重#105', 'ponownie', pinyin: 'chóng', traditional: '重'),
      word('重#977', 'ciężki', pinyin: 'zhòng', traditional: '重'),
    ]);
    expect(dictionary.lookup('重'), isEmpty);
    expect(dictionary.lookup('ponownie').single.word.pinyin, 'chóng');
    expect(dictionary.lookup('ciężki').single.word.pinyin, 'zhòng');
  });

  test('longest ambiguous gloss never falls back to shorter misleading gloss',
      () {
    final dictionary = LessonDictionary([
      word('一', 'dzień'),
      word('二', 'dzień dobry'),
      word('三', 'dzień dobry'),
    ]);
    expect(dictionary.lookup('dzień dobry'), isEmpty);
  });
}
