import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_flow/models/word.dart';

void main() {
  test('keeps homograph identity separate from visible Chinese text', () {
    final first = Word.fromJson({
      'hanzi': '生#22',
      'sourceWord': '生2',
      'traditional': '生',
      'pinyin': 'shēng',
      'english': 'to give birth',
      'polish': 'rodzić',
      'level': 'HSK-7-9',
      'frequency': 22,
    });
    final second = Word.fromJson({
      'hanzi': '生#23',
      'sourceWord': '生3',
      'traditional': '生',
      'pinyin': 'shēng',
      'english': 'to give birth',
      'polish': 'rodzić',
      'level': 'HSK-7-9',
      'frequency': 23,
    });

    expect(first.hanzi, isNot(second.hanzi));
    expect(first.displayHanzi, '生');
    expect(second.displayHanzi, '生');
    expect(first.toJson()['sourceWord'], '生2');
  });

  test('hides source homograph suffix when source ID is not composite', () {
    final word = Word.fromJson({
      'hanzi': '别',
      'sourceWord': '别2',
      'traditional': '別',
      'pinyin': 'bié',
      'english': 'other',
      'polish': 'inny',
      'level': 'HSK-5',
      'frequency': 95,
    });

    expect(word.displayHanzi, '别');
  });
}
