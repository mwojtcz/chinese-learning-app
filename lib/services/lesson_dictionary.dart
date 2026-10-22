import '../models/word.dart';

class LessonDictionaryMatch {
  final int start;
  final int end;
  final Word word;
  const LessonDictionaryMatch(this.start, this.end, this.word);
}

class _DictionaryNode {
  final children = <int, _DictionaryNode>{};
  final words = <Word>[];
}

/// Exact dictionary evidence only: Chinese longest matches and unambiguous
/// whole Polish glosses. Inflections and substrings are deliberately not guessed.
class LessonDictionary {
  final _root = _DictionaryNode();
  static final _letter = RegExp(r'[\p{L}\p{N}_]', unicode: true);
  static final _chinese = RegExp(r'[\u3400-\u9fff\uf900-\ufaff]');

  LessonDictionary(Iterable<Word> words) {
    for (final word in words) {
      final keys = <String>{word.displayHanzi, word.traditional};
      for (final gloss in word.polishTranslation.split(RegExp(r'[;,/\n]'))) {
        final key = gloss.trim().toLowerCase();
        if (key.isNotEmpty && !_chinese.hasMatch(key)) keys.add(key);
      }
      for (final key in keys.where((k) => k.isNotEmpty)) {
        var node = _root;
        for (final unit in key.toLowerCase().codeUnits) {
          node = node.children.putIfAbsent(unit, _DictionaryNode.new);
        }
        // Duplicate copies of the same lexical entry are not ambiguity.
        if (!node.words.any((w) =>
            w.displayHanzi == word.displayHanzi &&
            w.pinyin == word.pinyin &&
            w.polishTranslation == word.polishTranslation)) {
          node.words.add(word);
        }
      }
    }
  }

  List<LessonDictionaryMatch> lookup(String text) {
    final matches = <LessonDictionaryMatch>[];
    final lower = text.toLowerCase();
    for (var start = 0; start < lower.length;) {
      var node = _root;
      LessonDictionaryMatch? best;
      for (var end = start; end < lower.length; end++) {
        final next = node.children[lower.codeUnitAt(end)];
        if (next == null) break;
        node = next;
        if (node.words.isEmpty) continue;
        final segment = text.substring(start, end + 1);
        final chinese = _chinese.hasMatch(segment);
        final boundary = (start == 0 ||
                !_letter.hasMatch(text.substring(start - 1, start))) &&
            (end + 1 == text.length ||
                !_letter.hasMatch(text.substring(end + 1, end + 2)));
        if (chinese || boundary) {
          // An ambiguous longest match must not fall back to a shorter gloss.
          best = LessonDictionaryMatch(start, end + 1, node.words.first);
          if (node.words.length != 1) {
            best = LessonDictionaryMatch(start, end + 1, _ambiguous);
          }
        }
      }
      if (best == null) {
        start++;
      } else {
        if (!identical(best.word, _ambiguous)) matches.add(best);
        start = best.end;
      }
    }
    return matches;
  }

  static final _ambiguous = Word(
      hanzi: '',
      pinyin: '',
      englishTranslation: '',
      polishTranslation: '',
      level: '');
}
