import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'app_language.dart';

@immutable
class GrammarText {
  const GrammarText({
    required this.polish,
    required this.simplifiedChinese,
    required this.traditionalChinese,
  });

  final String polish;
  final String simplifiedChinese;
  final String traditionalChinese;

  factory GrammarText.fromJson(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Grammar text must be a localized object.');
    }
    return GrammarText(
      polish: _requiredString(value, 'pl'),
      simplifiedChinese: _requiredString(value, 'zhHans'),
      traditionalChinese: _requiredString(value, 'zhHant'),
    );
  }

  String forLanguage(AppLanguage language) {
    if (language.isTraditional) return traditionalChinese;
    return language.isPolish ? polish : simplifiedChinese;
  }
}

@immutable
class GrammarExample {
  const GrammarExample({
    required this.polish,
    required this.simplifiedChinese,
    required this.traditionalChinese,
    this.pinyin,
  });

  final String polish;
  final String simplifiedChinese;
  final String traditionalChinese;
  final String? pinyin;

  factory GrammarExample.fromJson(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Grammar example must be an object.');
    }
    return GrammarExample(
      polish: _requiredString(value, 'pl'),
      simplifiedChinese: _requiredString(value, 'zhHans'),
      traditionalChinese: _requiredString(value, 'zhHant'),
      pinyin: value['pinyin'] is String ? value['pinyin'] as String : null,
    );
  }

  String forLanguage(AppLanguage language) {
    if (language.isTraditional) return traditionalChinese;
    return language.isPolish ? polish : simplifiedChinese;
  }
}

@immutable
class GrammarSection {
  const GrammarSection({
    required this.heading,
    required this.explanation,
    required this.examples,
    required this.note,
    this.tables = const [],
  });

  final GrammarText heading;
  final GrammarText explanation;
  final List<GrammarExample> examples;
  final GrammarText note;
  final List<GrammarTable> tables;

  factory GrammarSection.fromJson(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Grammar section must be an object.');
    }
    final examplesValue = value['examples'];
    if (examplesValue is! List) {
      throw const FormatException('Grammar section examples must be a list.');
    }
    final tablesValue = value['tables'];
    if (tablesValue != null && tablesValue is! List) {
      throw const FormatException('Grammar section tables must be a list.');
    }
    return GrammarSection(
      heading: GrammarText.fromJson(value['heading']),
      explanation: GrammarText.fromJson(value['explanation']),
      examples: examplesValue.map(GrammarExample.fromJson).toList(growable: false),
      note: GrammarText.fromJson(value['note']),
      tables: (tablesValue as List? ?? const [])
          .map(GrammarTable.fromJson)
          .toList(growable: false),
    );
  }
}

@immutable
class GrammarTable {
  const GrammarTable({required this.headers, required this.rows});

  final List<GrammarText> headers;
  final List<List<GrammarText>> rows;

  factory GrammarTable.fromJson(dynamic value) {
    if (value is! Map<String, dynamic> ||
        value['headers'] is! List ||
        value['rows'] is! List) {
      throw const FormatException('Grammar table needs headers and rows.');
    }
    final headers = (value['headers'] as List)
        .map(GrammarText.fromJson)
        .toList(growable: false);
    final rows = (value['rows'] as List).map((row) {
      if (row is! List || row.length != headers.length) {
        throw const FormatException(
          'Grammar table rows must match the number of headers.',
        );
      }
      return row.map(GrammarText.fromJson).toList(growable: false);
    }).toList(growable: false);
    if (headers.isEmpty || rows.isEmpty) {
      throw const FormatException('Grammar table cannot be empty.');
    }
    return GrammarTable(headers: headers, rows: rows);
  }
}

@immutable
class GrammarLesson {
  const GrammarLesson({
    required this.id,
    required this.title,
    required this.summary,
    required this.sections,
  });

  final String id;
  final GrammarText title;
  final GrammarText summary;
  final List<GrammarSection> sections;

  factory GrammarLesson.fromJson(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Grammar lesson must be an object.');
    }
    final sectionsValue = value['sections'];
    if (sectionsValue is! List) {
      throw const FormatException('Grammar lesson sections must be a list.');
    }
    return GrammarLesson(
      id: _requiredString(value, 'id'),
      title: GrammarText.fromJson(value['title']),
      summary: GrammarText.fromJson(value['summary']),
      sections: sectionsValue.map(GrammarSection.fromJson).toList(growable: false),
    );
  }
}

List<GrammarLesson> grammarLessonsFromJson(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic> || decoded['lessons'] is! List) {
    throw const FormatException('Grammar asset must contain a lessons list.');
  }
  return (decoded['lessons'] as List)
      .map(GrammarLesson.fromJson)
      .toList(growable: false);
}

String _requiredString(Map<String, dynamic> value, String key) {
  final result = value[key];
  if (result is! String || result.trim().isEmpty) {
    throw FormatException('Grammar field "$key" must be a non-empty string.');
  }
  return result.trim();
}
