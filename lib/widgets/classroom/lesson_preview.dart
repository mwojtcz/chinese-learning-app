import 'package:flutter/material.dart';
import '../../models/app_language.dart';
import '../../models/classroom_lesson.dart';
import '../../services/lesson_dictionary.dart';

class LessonPreview extends StatelessWidget {
  final LessonBlock block;
  final LessonDictionary dictionary;
  final AppLanguage language;
  final bool showPinyin;
  final bool presentation;
  final bool showTranslations;
  final VoidCallback? onEdit;
  const LessonPreview({
    super.key,
    required this.block,
    required this.dictionary,
    required this.language,
    required this.showPinyin,
    this.presentation = false,
    this.showTranslations = true,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final matches = dictionary.lookup(block.text);
    final boundaries = <int>{0, block.text.length};
    for (final match in matches) {
      boundaries.addAll([match.start, match.end]);
    }
    for (final annotation in block.annotations) {
      boundaries.addAll([annotation.start, annotation.end]);
    }
    final sorted = boundaries.toList()..sort();
    final spans = <InlineSpan>[];
    final base = TextStyle(
      fontSize: presentation ? 30 : 20,
      height: 1.8,
      color: colors.onSurface,
    );
    for (var i = 0; i + 1 < sorted.length; i++) {
      final start = sorted[i];
      final match =
          matches.where((m) => m.start <= start && m.end > start).firstOrNull;
      if (match != null && start != match.start) continue;
      final end = match?.end ?? sorted[i + 1];
      final annotations = block.annotations
          .where((a) => a.start < end && a.end > start)
          .toList();
      final note =
          annotations.map((a) => a.note).where((s) => s.isNotEmpty).join('\n');
      final style = base.copyWith(
        fontWeight: annotations.any((a) => a.bold) ? FontWeight.bold : null,
        fontStyle: annotations.any((a) => a.italic) ? FontStyle.italic : null,
        decoration: annotations.any((a) => a.underline)
            ? TextDecoration.underline
            : null,
        decorationColor: colors.primary,
        backgroundColor: annotations.any((a) => a.highlight)
            ? colors.tertiaryContainer
            : null,
        color: annotations.any((a) => a.highlight)
            ? colors.onTertiaryContainer
            : colors.onSurface,
      );
      final segment = block.text.substring(start, end);
      if (match == null && note.isEmpty) {
        spans.add(TextSpan(text: segment, style: style));
        continue;
      }
      final word = match?.word;
      final details = [
        if (word != null)
          '${word.displayHanzi} · ${word.traditional}\n${word.pinyin}\n${word.polishTranslation}\n${word.englishTranslation}',
        if (note.isNotEmpty)
          '${language.text('Korekta nauczyciela', '教师修正', '教師修正')}: $note',
      ].join('\n\n');
      var visible = showPinyin;
      var translated = showTranslations;
      for (final annotation in annotations) {
        visible = annotation.pinyinVisible ?? visible;
        translated = annotation.translationVisible ?? translated;
      }
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Tooltip(
          message: details,
          child: Semantics(
            button: true,
            label: '$segment. $details',
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: onEdit ??
                  () => showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(segment),
                          content: SingleChildScrollView(child: Text(details)),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child:
                                    Text(language.text('Zamknij', '关闭', '關閉')))
                          ],
                        ),
                      ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (word != null && visible && end == match!.end)
                    Text(word.pinyin,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: presentation ? 14 : 11,
                            color: colors.primary,
                            height: 1.1)),
                  Text.rich(TextSpan(children: [
                    for (var part = i;
                        part + 1 < sorted.length && sorted[part] < end;
                        part++)
                      TextSpan(
                          text: block.text
                              .substring(sorted[part], sorted[part + 1]),
                          style: _rangeStyle(
                              base, colors, sorted[part], sorted[part + 1])),
                  ])),
                  if (word != null && translated && end == match!.end)
                    Text(
                        RegExp(r'[\u3400-\u9fff\uf900-\ufaff]')
                                .hasMatch(segment)
                            ? word.polishTranslation
                            : language.isTraditional
                                ? word.traditional
                                : word.displayHanzi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: presentation ? 13 : 10,
                            color: colors.onSurfaceVariant,
                            height: 1.2)),
                ]),
              ),
            ),
          ),
        ),
      ));
    }
    return Text.rich(
      TextSpan(children: spans),
      style: base,
      textScaler: MediaQuery.textScalerOf(context),
    );
  }

  TextStyle _rangeStyle(
      TextStyle base, ColorScheme colors, int start, int end) {
    final active =
        block.annotations.where((a) => a.start <= start && a.end >= end);
    final highlighted = active.any((a) => a.highlight);
    return base.copyWith(
        fontWeight: active.any((a) => a.bold) ? FontWeight.bold : null,
        fontStyle: active.any((a) => a.italic) ? FontStyle.italic : null,
        decoration:
            active.any((a) => a.underline) ? TextDecoration.underline : null,
        decorationColor: colors.primary,
        backgroundColor: highlighted ? colors.tertiaryContainer : null,
        color: highlighted ? colors.onTertiaryContainer : colors.onSurface);
  }
}
