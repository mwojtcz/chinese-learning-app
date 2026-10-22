import 'dart:convert';

import 'app_language.dart';

class PolishWordForms {
  const PolishWordForms({
    required this.lemmas,
    required this.forms,
    required this.example,
  });

  final List<String> lemmas;
  final List<PolishForm> forms;
  final LocalizedPolishExample example;
}

class PolishForm {
  const PolishForm({required this.label, required this.value});

  final String label;
  final String value;
}

class LocalizedPolishExample {
  const LocalizedPolishExample({
    required this.polish,
    required this.simplifiedChinese,
    required this.traditionalChinese,
  });

  final String polish;
  final String simplifiedChinese;
  final String traditionalChinese;

  String forLanguage(AppLanguage language) {
    if (language.isTraditional) return traditionalChinese;
    return language.isPolish ? polish : simplifiedChinese;
  }
}

class PolishFormsCatalog {
  PolishFormsCatalog(List<PolishWordForms> entries)
      : entries = List.unmodifiable(entries) {
    final lemmas = <String>{};
    for (final entry in entries) {
      for (final lemma in entry.lemmas) {
        if (!lemmas.add(_normalizeLemma(lemma))) {
          throw FormatException('Duplicate Polish forms lemma: $lemma');
        }
      }
    }
    _byLemma = {
      for (final entry in entries)
        for (final lemma in entry.lemmas) _normalizeLemma(lemma): entry,
    };
  }

  final List<PolishWordForms> entries;
  late final Map<String, PolishWordForms> _byLemma;

  List<PolishWordForms> get declensionParadigms => entries
      .where((entry) => declensionFormsFor(entry).length >= 7)
      .toList(growable: false);

  List<PolishWordForms> get conjugationParadigms => entries
      .where((entry) => conjugationFormsFor(entry).length >= 8)
      .toList(growable: false);

  static List<PolishForm> declensionFormsFor(PolishWordForms entry) =>
      entry.forms
          .where((form) => RegExp(r'^[1-7]\. ').hasMatch(form.label))
          .toList(growable: false);

  static List<PolishForm> conjugationFormsFor(PolishWordForms entry) =>
      entry.forms.where((form) {
        const persons = {'ja', 'ty', 'on/ona/ono', 'my', 'wy', 'oni/one'};
        return persons.contains(form.label) ||
            form.label.startsWith('Rozkazujący:') ||
            form.label.startsWith('Przeszły:') ||
            form.label.startsWith('Przyszły') ||
            form.label.startsWith('Przypuszczający:') ||
            form.label.startsWith('Tryb przypuszczający:');
      }).toList(growable: false);

  static List<String> answerVariantsFor(PolishForm form) => form.value
      .split('/')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);

  PolishWordForms? lookup(String polishGloss) {
    final firstGloss = polishGloss.split(';').first.trim();
    return _byLemma[_normalizeLemma(firstGloss)];
  }

  static PolishFormsCatalog fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> || decoded['entries'] is! List) {
      throw const FormatException('Polish forms asset must contain entries.');
    }
    return PolishFormsCatalog(
      (decoded['entries'] as List).map(_parseEntry).toList(growable: false),
    );
  }
}

PolishWordForms _parseEntry(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Polish forms entry must be an object.');
  }
  final rawLemmas = value['lemmas'];
  final rawForms = value['forms'];
  if (rawLemmas is! List ||
      rawLemmas.isEmpty ||
      rawLemmas.any((lemma) => lemma is! String || lemma.trim().isEmpty) ||
      rawForms is! List ||
      rawForms.isEmpty) {
    throw const FormatException('Polish forms entry needs lemmas and forms.');
  }
  final rawExample = value['example'];
  if (rawExample is! Map<String, dynamic>) {
    throw const FormatException('Polish forms example must be localized.');
  }

  return PolishWordForms(
    lemmas: rawLemmas.cast<String>().map((lemma) => lemma.trim()).toList(),
    forms: rawForms.map((form) {
      if (form is! Map<String, dynamic>) {
        throw const FormatException('Polish form must be an object.');
      }
      return PolishForm(
        label: _required(form, 'label'),
        value: _required(form, 'value'),
      );
    }).toList(growable: false),
    example: LocalizedPolishExample(
      polish: _required(rawExample, 'pl'),
      simplifiedChinese: _required(rawExample, 'zhHans'),
      traditionalChinese: _required(rawExample, 'zhHant'),
    ),
  );
}

String _required(Map<String, dynamic> value, String key) {
  final field = value[key];
  if (field is! String || field.trim().isEmpty) {
    throw FormatException(
        'Polish forms field "$key" must be a non-empty string.');
  }
  return field.trim();
}

String _normalizeLemma(String lemma) => lemma.trim().toLowerCase();
