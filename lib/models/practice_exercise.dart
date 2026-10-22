import 'dart:convert';

import 'app_language.dart';
import 'learning_target.dart';

class PracticeExercise {
  const PracticeExercise({
    required this.id,
    required this.target,
    required this.courseLevel,
    required this.prompt,
    required this.answer,
    required this.acceptedAnswers,
    required this.explanation,
  });

  final String id;
  final LearningTarget target;
  final String courseLevel;
  final LocalizedPracticeText prompt;
  final String answer;
  final List<String> acceptedAnswers;
  final LocalizedPracticeText explanation;

  factory PracticeExercise.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Practice exercise must be an object.');
    }
    final target = switch (value['target']) {
      'polish' => LearningTarget.polish,
      'chinese' => LearningTarget.chinese,
      _ => throw const FormatException('Unknown practice target.'),
    };
    final accepted = value['acceptedAnswers'];
    if (accepted is! List || accepted.any((item) => item is! String)) {
      throw const FormatException('acceptedAnswers must be a list of strings.');
    }
    return PracticeExercise(
      id: _required(value, 'id'),
      target: target,
      courseLevel: _required(value, 'courseLevel'),
      prompt: LocalizedPracticeText.fromJson(value['prompt']),
      answer: _required(value, 'answer'),
      acceptedAnswers: accepted.cast<String>(),
      explanation: LocalizedPracticeText.fromJson(value['explanation']),
    );
  }

  static List<PracticeExercise> listFromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> || decoded['exercises'] is! List) {
      throw const FormatException('Practice asset must contain exercises.');
    }
    final exercises = (decoded['exercises'] as List)
        .map(PracticeExercise.fromJson)
        .toList(growable: false);
    final ids = <String>{};
    for (final exercise in exercises) {
      if (!ids.add(exercise.id)) {
        throw FormatException('Duplicate practice exercise ID: ${exercise.id}');
      }
    }
    return exercises;
  }
}

class LocalizedPracticeText {
  const LocalizedPracticeText({
    required this.polish,
    required this.simplifiedChinese,
    required this.traditionalChinese,
  });

  final String polish;
  final String simplifiedChinese;
  final String traditionalChinese;

  factory LocalizedPracticeText.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Practice text must be localized.');
    }
    return LocalizedPracticeText(
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

bool practiceAnswerMatches(String input, Iterable<String> acceptedAnswers) {
  final normalizedInput = _normalizeAnswer(input);
  if (normalizedInput.isEmpty) return false;
  return acceptedAnswers.any(
    (answer) => _normalizeAnswer(answer) == normalizedInput,
  );
}

String _normalizeAnswer(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[.!?。！？,，;；]+$'), '')
    .replaceAll(RegExp(r'\s+'), ' ');

String _required(Map<String, dynamic> value, String key) {
  final field = value[key];
  if (field is! String || field.trim().isEmpty) {
    throw FormatException('Practice field "$key" must be a non-empty string.');
  }
  return field.trim();
}
