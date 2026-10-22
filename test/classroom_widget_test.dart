import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chinese_flow/models/app_language.dart';
import 'package:chinese_flow/models/classroom_lesson.dart';
import 'package:chinese_flow/models/word.dart';
import 'package:chinese_flow/providers/word_provider.dart';
import 'package:chinese_flow/screens/classroom_screen.dart';
import 'package:chinese_flow/services/classroom_store.dart';
import 'package:chinese_flow/services/lesson_dictionary.dart';
import 'package:chinese_flow/widgets/classroom/lesson_block_card.dart';
import 'package:chinese_flow/widgets/classroom/annotated_text_controller.dart';
import 'package:chinese_flow/widgets/classroom/notebook_canvas.dart';

void main() {
  setUp(ClassroomStore.invalidateAfterRestore);

  testWidgets(
      'top toolbar formats pasted text and controls live dictionary hints',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1440, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final words = WordProvider();
    words.allWords.add(Word(
        hanzi: '你好',
        pinyin: 'nǐ hǎo',
        polishTranslation: 'cześć',
        englishTranslation: 'hello',
        level: 'HSK-1'));
    addTearDown(words.dispose);
    await tester.pumpWidget(ChangeNotifierProvider<WordProvider>.value(
        value: words,
        child: const MaterialApp(
            home: ClassroomScreen(
                language: AppLanguage.polish,
                profileId: 'toolbar-learner',
                studentName: 'Anna',
                teacherMode: true))));
    await tester.pumpAndSettle();
    final input = find.descendant(
        of: find.byType(NotebookCanvas), matching: find.byType(TextField));
    await tester.enterText(input, '你好');
    await tester.pumpAndSettle();
    expect(find.text('nǐ hǎo'), findsOneWidget);
    expect(find.text('cześć'), findsOneWidget);
    expect(find.text('Podgląd podpisów'), findsNothing);
    final editable =
        find.descendant(of: input, matching: find.byType(EditableText));
    final rendered = tester.renderObject<RenderBox>(editable);
    final glyphs = tester.widget<EditableText>(editable).controller;
    expect(glyphs.text, '你好');
    expect(tester.getTopLeft(find.text('nǐ hǎo')).dy,
        lessThan(rendered.localToGlobal(Offset.zero).dy + 30));
    expect(tester.getTopLeft(find.text('cześć')).dy,
        greaterThan(tester.getTopLeft(find.text('nǐ hǎo')).dy));
    final field = tester.widget<TextField>(input);
    field.controller!.selection =
        const TextSelection(baseOffset: 0, extentOffset: 2);
    await tester.pump();
    await tester.pump();
    final underline = find.byTooltip('Podkreśl');
    expect(tester.getTopLeft(underline).dy,
        lessThan(tester.getTopLeft(find.byType(NotebookCanvas)).dy));
    await tester.tap(underline);
    await tester.pumpAndSettle();
    expect(
        (field.controller! as AnnotatedTextController)
            .annotations
            .single
            .underline,
        isTrue);
    await tester.tap(find.byTooltip('Ukryj pinyin zaznaczenia'));
    await tester.pumpAndSettle();
    expect(find.text('nǐ hǎo'), findsNothing);
    await tester.tap(find.byTooltip('Pokaż pinyin zaznaczenia'));
    await tester.pumpAndSettle();
    expect(find.text('nǐ hǎo'), findsOneWidget);
    await tester.tap(find.byTooltip('Wyczyść oznaczenia'));
    await tester.pumpAndSettle();
    expect((field.controller! as AnnotatedTextController).annotations, isEmpty);
    await tester.tap(underline);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Pinyin'));
    await tester.pumpAndSettle();
    expect(find.text('nǐ hǎo'), findsNothing);
    expect(find.text('cześć'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'Tłumaczenia'));
    await tester.pumpAndSettle();
    expect(find.text('cześć'), findsNothing);
    await tester.tap(find.byTooltip('Pokaż tłumaczenie zaznaczenia'));
    await tester.pumpAndSettle();
    expect(find.text('cześć'), findsOneWidget);
    await tester.tap(find.byTooltip('Ukryj tłumaczenie zaznaczenia'));
    await tester.pumpAndSettle();
    expect(find.text('cześć'), findsNothing);
    await tester.tap(find.byTooltip('Wyczyść oznaczenia'));
    await tester.pumpAndSettle();
    await tester.tap(underline);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Pinyin'));
    await tester.tap(find.widgetWithText(FilterChip, 'Tłumaczenia'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Gotowe'));
    await tester.pumpAndSettle();
    expect(input, findsNothing);
    expect(find.text('nǐ hǎo'), findsOneWidget);
    expect(find.text('cześć'), findsOneWidget);
    await ClassroomStore.flushAll();
    final key =
        'classroom.v1.${base64Url.encode(utf8.encode('toolbar-learner'))}';
    final saved =
        jsonDecode(preferences.getString(key)!) as Map<String, dynamic>;
    final lesson = ClassroomLesson.fromJson((saved['shared'] as List).single);
    expect(lesson.blocks.single.text, '你好');
    expect(lesson.blocks.single.annotations.single.underline, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'clicking a blank paper line starts typing without movable fields',
      (tester) async {
    final blocks = <LessonBlock>[];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: SizedBox(
                    width: 794,
                    child: StatefulBuilder(
                        builder: (context, update) => NotebookCanvas(
                              page: ClassroomLesson(
                                  title: 'Page', blocks: blocks),
                              language: AppLanguage.polish,
                              dictionary: LessonDictionary([]),
                              editable: true,
                              showPinyin: true,
                              onChanged: (value) => update(() {
                                final index =
                                    blocks.indexWhere((b) => b.id == value.id);
                                blocks[index] = value;
                              }),
                              onDelete: (_) {},
                              onInsert: (value) =>
                                  update(() => blocks.add(value)),
                            )))))));
    final origin = tester.getTopLeft(find.byType(NotebookCanvas));
    await tester.tapAt(origin + const Offset(150, 210));
    await tester.pumpAndSettle();
    expect(blocks, hasLength(1));
    expect(blocks.single.y, closeTo(210 / 1123, 0.001));
    expect(find.byIcon(Icons.open_with), findsNothing);
    expect(find.byIcon(Icons.edit), findsNothing);
    await tester.enterText(find.byType(TextField), 'Pierwsze zdanie');
    await tester.pump();
    expect(blocks.single.text, 'Pierwsze zdanie');
    final position = blocks.single.y;
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(blocks, hasLength(1));
    expect(blocks.single.y, position);
    await tester.tapAt(origin + const Offset(150, 294));
    await tester.pumpAndSettle();
    expect(blocks, hasLength(2));
    await tester.enterText(find.byType(TextField).last, 'Kolejna linia');
    await tester.pump();
    expect(blocks.last.text, 'Kolejna linia');
    expect(blocks.first.text, 'Pierwsze zdanie');
    expect(tester.takeException(), isNull);
  });

  testWidgets('canvas drag and resize commit normalized bounded geometry',
      (tester) async {
    var block = LessonBlock(
        kind: LessonBlockKind.image,
        imageBytes: base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII='),
        imageMime: 'image/png',
        x: 0.1,
        y: 0.2,
        width: 0.4,
        height: 0.2);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
      child: SizedBox(
          width: 794,
          child: StatefulBuilder(
              builder: (context, update) => NotebookCanvas(
                    page: ClassroomLesson(title: 'Page', blocks: [block]),
                    language: AppLanguage.polish,
                    dictionary: LessonDictionary([]),
                    editable: true,
                    showPinyin: true,
                    onChanged: (value) => update(() => block = value),
                    onDelete: (_) {},
                    onInsert: (_) {},
                  ))),
    ))));
    await tester.tap(find.byType(Image));
    await tester.pump();
    await tester.drag(find.byIcon(Icons.open_with), const Offset(60, 40));
    await tester.pump();
    expect(block.x, greaterThan(0.1));
    expect(block.y, greaterThan(0.2));
    final previousWidth = block.width;
    await tester.drag(find.byIcon(Icons.south_east), const Offset(80, 50));
    await tester.pump();
    expect(block.width, greaterThan(previousWidth));
    expect(block.x + block.width, lessThanOrEqualTo(1));
    expect(block.y + block.height, lessThanOrEqualTo(1));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'range formatting appears only for selection and renders in editable text',
      (tester) async {
    var block = LessonBlock(text: '你好朋友');
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
      child: LessonBlockCard(
        block: block,
        language: AppLanguage.polish,
        dictionary: LessonDictionary([]),
        editable: true,
        presentation: false,
        showPinyin: false,
        onChanged: (value) => block = value,
        onDelete: () {},
      ),
    ))));
    final input = tester.widget<TextField>(find.byType(TextField));
    expect(find.text('Podkreśl'), findsNothing);
    input.controller!.selection =
        const TextSelection(baseOffset: 0, extentOffset: 2);
    await tester.pump();
    await tester.tap(find.text('Podkreśl'));
    await tester.pump();
    expect(block.annotations.single.start, 0);
    expect(block.annotations.single.end, 2);
    expect(block.annotations.single.underline, isTrue);
    final controller = input.controller! as AnnotatedTextController;
    final context = tester.element(find.byType(TextField));
    final span =
        controller.buildTextSpan(context: context, withComposing: true);
    expect((span.children!.first as TextSpan).style!.decoration,
        TextDecoration.underline);
    input.controller!.selection = const TextSelection.collapsed(offset: 2);
    await tester.pump();
    expect(find.text('Podkreśl'), findsNothing);
    expect(block.withText('').annotations, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('teacher opens direct A4 paper and navigates page thumbnails',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = WordProvider();
    addTearDown(provider.dispose);
    await tester.pumpWidget(ChangeNotifierProvider<WordProvider>.value(
      value: provider,
      child: const MaterialApp(
          home: ClassroomScreen(
        language: AppLanguage.polish,
        profileId: 'a4-pages',
        studentName: 'Anna',
        teacherMode: true,
      )),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Biblioteka lekcji'), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.text('Strona 1 z 1'), findsOneWidget);
    final paper = find.byKey(const ValueKey('a4-notebook-paper'));
    expect(tester.getSize(paper).width, 794);
    expect(tester.getSize(paper).height, closeTo(1123, 4));
    expect(find.text('Podkreśl'), findsNothing);
    await tester.tap(find.text('Dodaj stronę'));
    await tester.pumpAndSettle();
    expect(find.text('Strona 2 z 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Poprzednia strona'));
    await tester.pumpAndSettle();
    expect(find.text('Strona 1 z 2'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    final store =
        ClassroomStore(profileId: 'a4-pages', preferences: preferences);
    await ClassroomStore.flushAll();
    await store.load();
    expect(store.lessons.length, 2);
    expect(store.lessons.first.blocks.length, 1);
    store.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'mobile dark notebook keeps private notes out of pupil and board views',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store =
        ClassroomStore(profileId: 'widget-private', preferences: preferences);
    store.put(ClassroomLesson(id: 'lesson', title: 'Pierwsza lekcja'));
    store.setTeacherNote('lesson', 'teacher-only-secret');
    store.setPupilNote('lesson', 'student-only-note');
    await store.flush();
    store.dispose();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = WordProvider();
    addTearDown(provider.dispose);
    Widget app(bool teacher, {String profile = 'widget-private'}) =>
        ChangeNotifierProvider<WordProvider>.value(
          value: provider,
          child: MaterialApp(
              theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                      seedColor: Colors.indigo, brightness: Brightness.dark)),
              home: ClassroomScreen(
                  language: AppLanguage.polish,
                  profileId: profile,
                  studentName: 'Uczeń',
                  teacherMode: teacher)),
        );
    await tester.pumpWidget(app(true));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('Prywatne notatki nauczyciela'), 300,
        scrollable: find
            .descendant(
                of: find.byKey(const ValueKey('paper-scroll:lesson:false')),
                matching: find.byType(Scrollable))
            .first);
    expect(find.text('teacher-only-secret'), findsNothing);
    await tester.ensureVisible(find.text('Prywatne notatki nauczyciela').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prywatne notatki nauczyciela').first);
    await tester.pumpAndSettle();
    expect(find.text('teacher-only-secret'), findsOneWidget);
    expect(find.text('student-only-note'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Tryb tablicy'));
    await tester.pumpAndSettle();
    expect(find.text('teacher-only-secret'), findsNothing);
    expect(find.text('Prywatne notatki nauczyciela'), findsNothing);
    await tester.tap(find.byTooltip('Zakończ prezentację'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(app(false));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Moje osobiste notatki'), 250,
        scrollable: find
            .descendant(
                of: find.byKey(const ValueKey('paper-scroll:lesson:false')),
                matching: find.byType(Scrollable))
            .first);
    await tester.ensureVisible(find.text('Moje osobiste notatki').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moje osobiste notatki').first);
    await tester.pumpAndSettle();
    expect(find.text('student-only-note'), findsOneWidget);
    expect(find.text('teacher-only-secret'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(app(false, profile: 'different-learner'));
    await tester.pumpAndSettle();
    expect(find.text('student-only-note'), findsNothing);
    expect(find.text('Ten notatnik nie ma jeszcze stron.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
