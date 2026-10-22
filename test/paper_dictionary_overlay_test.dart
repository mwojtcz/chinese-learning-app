import 'package:chinese_flow/models/app_language.dart';
import 'package:chinese_flow/models/classroom_lesson.dart';
import 'package:chinese_flow/models/word.dart';
import 'package:chinese_flow/services/lesson_dictionary.dart';
import 'package:chinese_flow/widgets/classroom/annotated_text_controller.dart';
import 'package:chinese_flow/widgets/classroom/paper_dictionary_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final dictionary = LessonDictionary([
    Word(
        hanzi: '你好',
        pinyin: 'nǐ hǎo',
        englishTranslation: 'hello',
        polishTranslation: 'cześć',
        level: 'HSK-1'),
  ]);

  testWidgets('captions follow multiline writing without duplicating hanzi',
      (tester) async {
    final controller =
        AnnotatedTextController(text: '你好\n你好', annotations: const []);
    addTearDown(controller.dispose);
    Widget app(double scale, {double width = 250}) => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
                body: SizedBox(
              width: width,
              child: PaperDictionaryOverlay(
                controller: controller,
                dictionary: dictionary,
                language: AppLanguage.polish,
                showPinyin: true,
                showTranslations: true,
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  style: PaperDictionaryOverlay.textStyle,
                  strutStyle: PaperDictionaryOverlay.strut,
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero),
                ),
              ),
            )),
          ),
        );
    for (final scale in [1.0, 1.3]) {
      await tester.pumpWidget(app(scale));
      await tester.pump();
      expect(find.text('nǐ hǎo'), findsNWidgets(2));
      expect(find.text('cześć'), findsNWidgets(2));
      expect(find.text('你好\n你好'), findsOneWidget);
      final readings = tester.getTopLeft(find.text('nǐ hǎo').last).dy -
          tester.getTopLeft(find.text('nǐ hǎo').first).dy;
      expect(readings, closeTo(60 * scale, 1));
      final firstReading = tester.getTopLeft(find.text('nǐ hǎo').first);
      final firstGloss = tester.getTopLeft(find.text('cześć').first);
      expect(firstGloss.dy, greaterThan(firstReading.dy));
      expect(firstGloss.dx, closeTo(firstReading.dx, 1));
      expect(tester.takeException(), isNull);
    }
    controller.text = '你好你好你好';
    await tester.pumpWidget(app(1, width: 85));
    await tester.pump();
    expect(find.text('nǐ hǎo'), findsNWidgets(3));
    expect(tester.getTopLeft(find.text('nǐ hǎo').last).dy,
        greaterThan(tester.getTopLeft(find.text('nǐ hǎo').first).dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('range overrides label only selected words and survive typing',
      (tester) async {
    final controller =
        AnnotatedTextController(text: '你好。你好', annotations: const [
      LessonAnnotation(
          start: 0, end: 1, pinyinVisible: true, translationVisible: true),
    ]);
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: SizedBox(
          width: 400,
          child: PaperDictionaryOverlay(
            controller: controller,
            dictionary: dictionary,
            language: AppLanguage.polish,
            showPinyin: false,
            showTranslations: false,
            child: TextField(
              controller: controller,
              maxLines: null,
              style: PaperDictionaryOverlay.textStyle,
              strutStyle: PaperDictionaryOverlay.strut,
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero),
            ),
          )),
    )));
    expect(find.text('nǐ hǎo'), findsOneWidget);
    expect(find.text('cześć'), findsOneWidget);
    expect(find.text('你好。你好'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
