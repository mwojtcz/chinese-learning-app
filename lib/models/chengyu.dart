import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'app_language.dart';
import 'word.dart';

enum ChengyuMotif { snake, field, well, horse, boat, bell, dragon, music, mountain, bow, forest }

@immutable
class ChengyuText {
  const ChengyuText({
    required this.polish,
    required this.simplifiedChinese,
    required this.traditionalChinese,
  });

  final String polish;
  final String simplifiedChinese;
  final String traditionalChinese;

  factory ChengyuText.fromJson(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Expected localized chengyu text.');
    }
    return ChengyuText(
      polish: _required(value, 'pl'),
      simplifiedChinese: _required(value, 'zhHans'),
      traditionalChinese: _required(value, 'zhHant'),
    );
  }

  String forLanguage(AppLanguage language) => language.text(
        polish,
        simplifiedChinese,
        traditionalChinese,
      );
}

@immutable
class Chengyu {
  const Chengyu({
    required this.id,
    required this.simplified,
    required this.traditional,
    required this.pinyin,
    required this.englishMeaning,
    required this.meaning,
    required this.literal,
    required this.example,
    required this.story,
    required this.caution,
    required this.motif,
  });

  final String id;
  final String simplified;
  final String traditional;
  final String pinyin;
  final String englishMeaning;
  final ChengyuText meaning;
  final ChengyuText literal;
  final ChengyuText example;
  final ChengyuText story;
  final ChengyuText caution;
  final ChengyuMotif motif;

  factory Chengyu.fromJson(Map<String, dynamic> json) {
    final motifName = _required(json, 'motif');
    final motifs = ChengyuMotif.values.where((m) => m.name == motifName);
    if (motifs.isEmpty) {
      throw FormatException('Unknown chengyu motif: $motifName');
    }
    return Chengyu(
      id: _required(json, 'id'),
      simplified: _required(json, 'simplified'),
      traditional: _required(json, 'traditional'),
      pinyin: _required(json, 'pinyin'),
      englishMeaning: _required(json, 'englishMeaning'),
      meaning: ChengyuText.fromJson(json['meaning']),
      literal: ChengyuText.fromJson(json['literal']),
      example: ChengyuText.fromJson(json['example']),
      story: ChengyuText.fromJson(json['story']),
      caution: ChengyuText.fromJson(json['caution']),
      motif: motifs.single,
    );
  }

  String characters(AppLanguage language) =>
      language.isTraditional ? traditional : simplified;

  /// Dictionary entry for this idiom, or a standalone entry tagged `chengyu`.
  Word studyWord(Iterable<Word> dictionary) {
    Word? displayMatch;
    for (final word in dictionary) {
      if (word.hanzi == simplified) return word;
      if (displayMatch == null && word.displayHanzi == simplified) {
        displayMatch = word;
      }
    }
    return displayMatch ??
        Word(
          hanzi: simplified,
          traditional: traditional,
          pinyin: pinyin,
          englishTranslation: englishMeaning,
          polishTranslation: meaning.polish,
          level: 'Chengyu',
          notes: literal.polish,
          tags: const ['chengyu'],
          partOfSpeech: 'idiom',
          sourceWord: simplified,
        );
  }

  /// Searches all scripts and translations, including unaccented pinyin.
  bool matches(String query) {
    final text = [
      simplified, traditional, pinyin, englishMeaning,
      for (final field in [meaning, literal, example, story, caution]) ...[
        field.polish, field.simplifiedChinese, field.traditionalChinese,
      ],
    ].join(' ');
    final haystack = _normalize(text);
    return _normalize(query)
        .split(RegExp(r'\s+'))
        .every((word) => haystack.contains(word));
  }
}

List<Chengyu> chengyuFromJson(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic> || decoded['idioms'] is! List) {
    throw const FormatException('Chengyu data must contain an idioms list.');
  }
  final ids = <String>{};
  final simplified = <String>{};
  final traditional = <String>{};
  final idioms = (decoded['idioms'] as List).map((value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Each chengyu must be an object.');
    }
    final idiom = Chengyu.fromJson(value);
    if (!ids.add(idiom.id) ||
        !simplified.add(idiom.simplified) ||
        !traditional.add(idiom.traditional)) {
      throw FormatException('Duplicate chengyu: ${idiom.id}');
    }
    return idiom;
  }).toList(growable: false);
  if (idioms.isEmpty) {
    throw const FormatException('Chengyu collection cannot be empty.');
  }
  return List.unmodifiable(idioms);
}

String _required(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing chengyu text: $key');
  }
  return value.trim();
}

String _normalize(String value) {
  const groups = {
    'a': 'āáǎàą', 'e': 'ēéěèę', 'i': 'īíǐì',
    'o': 'ōóǒò', 'u': 'ūúǔùǖǘǚǜü', 'n': 'ń',
    'l': 'ł', 's': 'ś', 'c': 'ć', 'z': 'źż',
  };
  var result = value.toLowerCase().trim();
  for (final entry in groups.entries) {
    for (final character in entry.value.split('')) {
      result = result.replaceAll(character, entry.key);
    }
  }
  return result;
}
