import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/vocabulary_category.dart';

class VocabularyCategoryStore {
  VocabularyCategoryStore._(this._assignments);

  static const assetPath =
      'assets/data/sources/hsk-2025/vocabulary_categories.json';
  static final RegExp _rowKey = RegExp(r'^(HSK-[1-6]|HSK-7-9)\|([1-9]\d*)$');
  static final Set<String> _allowedCategories = VocabularyCategory.all
      .map((category) => category.id)
      .where((id) => id != VocabularyCategory.allId)
      .toSet();

  final Map<String, _CategoryAssignment> _assignments;
  final Set<String> _seenKeys = {};

  static Future<VocabularyCategoryStore> load() async {
    final source = await rootBundle.loadString(assetPath);
    return VocabularyCategoryStore.fromJson(source);
  }

  factory VocabularyCategoryStore.fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
          'Vocabulary categories must be a JSON object.');
    }

    final assignments = <String, _CategoryAssignment>{};
    for (final entry in decoded.entries) {
      if (!_rowKey.hasMatch(entry.key)) {
        throw FormatException(
            'Invalid vocabulary category row key: ${entry.key}');
      }
      final value = entry.value;
      if (value is! Map<String, dynamic>) {
        throw FormatException(
            'Category assignment ${entry.key} must be an object.');
      }
      final sourceWord = value['sourceWord'];
      final categories = value['categories'];
      if (sourceWord is! String ||
          sourceWord.trim().isEmpty ||
          categories is! List ||
          categories.isEmpty ||
          categories.any((category) =>
              category is! String || !_allowedCategories.contains(category)) ||
          categories.toSet().length != categories.length) {
        throw FormatException('Invalid category assignment for ${entry.key}.');
      }
      assignments[entry.key] = _CategoryAssignment(
        sourceWord: sourceWord,
        categories: List<String>.unmodifiable(categories.cast<String>()),
      );
    }
    return VocabularyCategoryStore._(Map.unmodifiable(assignments));
  }

  List<String> categoriesFor(Map<String, dynamic> row) {
    final level = row['level'];
    final frequency = row['frequency'];
    if (level is! String || frequency is! int) {
      throw const FormatException(
          'Vocabulary row lacks its category identity.');
    }
    final key = '$level|$frequency';
    final assignment = _assignments[key];
    if (assignment == null) return const [];
    if (row['sourceWord'] != assignment.sourceWord) {
      throw FormatException('Category assignment identity mismatch for $key.');
    }
    _seenKeys.add(key);
    return assignment.categories;
  }

  void validateLoaded({String? level}) {
    final unseen = _assignments.keys
        .where((key) => (level == null || key.startsWith('$level|')))
        .where((key) => !_seenKeys.contains(key))
        .toList();
    if (unseen.isNotEmpty) {
      throw FormatException(
          'Category assignments do not match loaded vocabulary rows: ${unseen.join(', ')}');
    }
  }
}

class _CategoryAssignment {
  const _CategoryAssignment({
    required this.sourceWord,
    required this.categories,
  });

  final String sourceWord;
  final List<String> categories;
}
