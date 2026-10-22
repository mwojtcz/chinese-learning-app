import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_flow/services/vocabulary_category_store.dart';

void main() {
  const row = {
    'level': 'HSK-2',
    'frequency': 137,
    'sourceWord': '手',
  };

  test('loads exact row-bound category assignments', () {
    final store = VocabularyCategoryStore.fromJson(
      '{"HSK-2|137":{"sourceWord":"手","categories":["body"]}}',
    );

    expect(store.categoriesFor(row), ['body']);
    expect(() => store.validateLoaded(level: 'HSK-2'), returnsNormally);
  });

  test('rejects category assignments for a different source word', () {
    final store = VocabularyCategoryStore.fromJson(
      '{"HSK-2|137":{"sourceWord":"头","categories":["body"]}}',
    );

    expect(() => store.categoriesFor(row), throwsFormatException);
  });

  test('rejects unknown categories and stale row keys', () {
    expect(
      () => VocabularyCategoryStore.fromJson(
        '{"HSK-2|137":{"sourceWord":"手","categories":["anatomy"]}}',
      ),
      throwsFormatException,
    );
    expect(
      () => VocabularyCategoryStore.fromJson(
        '{"HSK-2|138":{"sourceWord":"头","categories":["body"]}}',
      ).validateLoaded(level: 'HSK-2'),
      throwsFormatException,
    );
  });
}
