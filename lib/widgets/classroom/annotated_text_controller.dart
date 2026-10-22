import 'package:flutter/material.dart';
import '../../models/classroom_lesson.dart';

/// Annotation offsets are UTF-16 offsets, matching Flutter's text selection.
class AnnotatedTextController extends TextEditingController {
  List<LessonAnnotation> annotations;
  AnnotatedTextController({required String text, required this.annotations})
      : super(text: text);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final colors = Theme.of(context).colorScheme;
    final valid = annotations
        .where((a) => a.start >= 0 && a.end <= text.length && a.start < a.end);
    final boundaries = <int>{0, text.length};
    for (final annotation in valid) {
      boundaries.addAll([annotation.start, annotation.end]);
    }
    final composing = value.composing;
    if (withComposing &&
        composing.isValid &&
        !composing.isCollapsed &&
        composing.end <= text.length) {
      boundaries.addAll([composing.start, composing.end]);
    }
    final sorted = boundaries.toList()..sort();
    return TextSpan(style: style, children: [
      for (var i = 0; i + 1 < sorted.length; i++)
        TextSpan(
          text: text.substring(sorted[i], sorted[i + 1]),
          style: TextStyle(
            fontWeight: valid.any((a) =>
                    a.start <= sorted[i] && a.end >= sorted[i + 1] && a.bold)
                ? FontWeight.bold
                : null,
            fontStyle: valid.any((a) =>
                    a.start <= sorted[i] && a.end >= sorted[i + 1] && a.italic)
                ? FontStyle.italic
                : null,
            decoration: valid.any((a) =>
                        a.start <= sorted[i] &&
                        a.end >= sorted[i + 1] &&
                        a.underline) ||
                    (withComposing &&
                        composing.isValid &&
                        composing.start <= sorted[i] &&
                        composing.end >= sorted[i + 1])
                ? TextDecoration.underline
                : null,
            backgroundColor: valid.any((a) =>
                    a.start <= sorted[i] &&
                    a.end >= sorted[i + 1] &&
                    a.highlight)
                ? colors.tertiaryContainer
                : null,
            color: valid.any((a) =>
                    a.start <= sorted[i] &&
                    a.end >= sorted[i + 1] &&
                    a.highlight)
                ? colors.onTertiaryContainer
                : null,
          ),
        ),
    ]);
  }
}
