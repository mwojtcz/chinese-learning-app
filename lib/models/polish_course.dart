import 'dart:convert';

import 'app_language.dart';

class PolishCourseText {
  const PolishCourseText({
    required this.polish,
    required this.simplifiedChinese,
    required this.traditionalChinese,
  });

  final String polish;
  final String simplifiedChinese;
  final String traditionalChinese;

  factory PolishCourseText.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Course text must be localized.');
    }
    return PolishCourseText(
      polish: _required(value, 'pl'),
      simplifiedChinese: _required(value, 'zhHans'),
      traditionalChinese: _required(value, 'zhHant'),
    );
  }

  String forLanguage(AppLanguage language) {
    if (language.isTraditional) return traditionalChinese;
    return language.isPolish ? polish : simplifiedChinese;
  }
}

class PolishCourseUnit {
  const PolishCourseUnit({
    required this.title,
    required this.outcome,
    required this.focus,
    required this.examples,
    required this.practice,
    required this.answer,
    required this.task,
  });

  final PolishCourseText title;
  final PolishCourseText outcome;
  final PolishCourseText focus;
  final List<PolishCourseText> examples;
  final PolishCourseText practice;
  final PolishCourseText answer;
  final PolishCourseText task;

  factory PolishCourseUnit.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Course unit must be an object.');
    }
    final rawExamples = value['examples'];
    if (rawExamples is! List || rawExamples.isEmpty) {
      throw const FormatException('Course unit must contain examples.');
    }
    return PolishCourseUnit(
      title: PolishCourseText.fromJson(value['title']),
      outcome: PolishCourseText.fromJson(value['outcome']),
      focus: PolishCourseText.fromJson(value['focus']),
      examples: rawExamples.map(PolishCourseText.fromJson).toList(growable: false),
      practice: PolishCourseText.fromJson(value['practice']),
      answer: PolishCourseText.fromJson(value['answer']),
      task: PolishCourseText.fromJson(value['task']),
    );
  }
}

class PolishCourseLevel {
  const PolishCourseLevel({
    required this.level,
    required this.title,
    required this.canDo,
    required this.units,
  });

  final String level;
  final PolishCourseText title;
  final PolishCourseText canDo;
  final List<PolishCourseUnit> units;

  factory PolishCourseLevel.fromJson(Object? value) {
    if (value is! Map<String, dynamic> || value['units'] is! List) {
      throw const FormatException('Course level must contain units.');
    }
    final level = _required(value, 'level');
    if (!const {'A1', 'A2', 'B1', 'B2', 'C1', 'C2'}.contains(level)) {
      throw FormatException('Unsupported Polish course level: $level');
    }
    final units = (value['units'] as List)
        .map(PolishCourseUnit.fromJson)
        .toList(growable: false);
    if (units.isEmpty) {
      throw FormatException('Polish course level $level has no units.');
    }
    return PolishCourseLevel(
      level: level,
      title: PolishCourseText.fromJson(value['title']),
      canDo: PolishCourseText.fromJson(value['canDo']),
      units: units,
    );
  }
}

List<PolishCourseLevel> polishCourseFromJson(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic> || decoded['levels'] is! List) {
    throw const FormatException('Polish course asset must contain levels.');
  }
  final levels = (decoded['levels'] as List)
      .map(PolishCourseLevel.fromJson)
      .toList(growable: false);
  const expected = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  if (levels.map((level) => level.level).join(',') != expected.join(',')) {
    throw const FormatException(
      'Polish course levels must be ordered A1, A2, B1, B2, C1, C2.',
    );
  }
  return levels;
}

String _required(Map<String, dynamic> value, String key) {
  final result = value[key];
  if (result is! String || result.trim().isEmpty) {
    throw FormatException('Polish course field "$key" must be non-empty.');
  }
  return result.trim();
}
