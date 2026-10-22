import 'package:flutter/material.dart';
import '../../models/app_language.dart';
import '../../models/classroom_lesson.dart';
import '../../services/lesson_dictionary.dart';
import 'annotated_text_controller.dart';

/// Captions use reserved line leading so native caret, selection and IME
/// offsets still refer to the original text, never to an annotated copy.
class PaperDictionaryOverlay extends StatelessWidget {
  static const textStyle = TextStyle(fontSize: 20, height: 3);
  static const strut =
      StrutStyle(fontSize: 20, height: 3, forceStrutHeight: true);
  final AnnotatedTextController controller;
  final LessonDictionary dictionary;
  final AppLanguage language;
  final bool showPinyin;
  final bool showTranslations;
  final Widget child;

  const PaperDictionaryOverlay({
    super.key,
    required this.controller,
    required this.dictionary,
    required this.language,
    required this.showPinyin,
    required this.showTranslations,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = Theme.of(context)
        .textTheme
        .bodyLarge!
        .merge(textStyle.copyWith(color: colors.onSurface));
    return Stack(children: [
      child,
      Positioned.fill(
        child: LayoutBuilder(
            builder: (context, constraints) => _DictionaryCaptions(
                  span: controller.buildTextSpan(
                      context: context, style: style, withComposing: true),
                  text: controller.text,
                  annotations: List.of(controller.annotations),
                  matches: dictionary.lookup(controller.text),
                  direction: Directionality.of(context),
                  scaler: MediaQuery.textScalerOf(context),
                  language: language,
                  showPinyin: showPinyin,
                  showTranslations: showTranslations,
                  pinyinColor: colors.primary,
                  translationColor: colors.onSurfaceVariant,
                ).build(constraints.maxWidth)),
      ),
    ]);
  }
}

class _DictionaryCaptions {
  final TextSpan span;
  final String text;
  final List<LessonAnnotation> annotations;
  final List<LessonDictionaryMatch> matches;
  final TextDirection direction;
  final TextScaler scaler;
  final AppLanguage language;
  final bool showPinyin;
  final bool showTranslations;
  final Color pinyinColor;
  final Color translationColor;

  _DictionaryCaptions({
    required this.span,
    required this.text,
    required this.annotations,
    required this.matches,
    required this.direction,
    required this.scaler,
    required this.language,
    required this.showPinyin,
    required this.showTranslations,
    required this.pinyinColor,
    required this.translationColor,
  });

  Widget build(double width) {
    if (width <= 0) return const SizedBox.shrink();
    final captions = <Widget>[];
    final layout = TextPainter(
        text: span,
        textDirection: direction,
        textScaler: scaler,
        strutStyle: PaperDictionaryOverlay.strut)
      ..layout(maxWidth: width);
    final lines = layout.computeLineMetrics();
    for (final match in matches) {
      var pinyin = showPinyin;
      var translation = showTranslations;
      for (final annotation in annotations) {
        if (annotation.start < match.end && annotation.end > match.start) {
          pinyin = annotation.pinyinVisible ?? pinyin;
          translation = annotation.translationVisible ?? translation;
        }
      }
      final boxes = layout.getBoxesForSelection(
          TextSelection(baseOffset: match.start, extentOffset: match.end));
      if (boxes.isEmpty) continue;
      final box = boxes.first;
      final line = lines
          .where(
              (line) => line.baseline >= box.top && line.baseline <= box.bottom)
          .firstOrNull;
      if (line == null) continue;
      final details = '${match.word.displayHanzi} · ${match.word.traditional}\n'
          '${match.word.pinyin}\n${match.word.polishTranslation}\n'
          '${match.word.englishTranslation}';
      if (pinyin) {
        captions.add(_caption(
            match.word.pinyin,
            box.left,
            line.baseline - scaler.scale(35),
            box.right - box.left,
            pinyinColor,
            11,
            details));
      }
      if (translation) {
        final segment = text.substring(match.start, match.end);
        final gloss = RegExp(r'[\u3400-\u9fff\uf900-\ufaff]').hasMatch(segment)
            ? match.word.polishTranslation
            : language.isTraditional
                ? match.word.traditional
                : match.word.displayHanzi;
        captions.add(_caption(gloss, box.left, line.baseline + scaler.scale(6),
            box.right - box.left, translationColor, 10, details));
      }
    }
    layout.dispose();
    return Stack(clipBehavior: Clip.none, children: captions);
  }

  Widget _caption(String text, double x, double y, double width, Color color,
      double fontSize, String details) {
    return Positioned(
      left: x,
      top: y,
      width: width,
      child: Tooltip(
          message: details,
          child: Text(text,
              textAlign: TextAlign.center,
              textDirection: direction,
              textScaler: scaler,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: fontSize, height: 1.1, color: color))),
    );
  }
}
