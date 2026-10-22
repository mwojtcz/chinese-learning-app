import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_flow/models/classroom_lesson.dart';

void main() {
  ClassroomLesson sample() =>
      ClassroomLesson(id: 'lesson-1', title: '你好', blocks: [
        LessonBlock(id: 'text-1', text: '你好朋友', annotations: const [
          LessonAnnotation(
              start: 0,
              end: 2,
              underline: true,
              bold: true,
              italic: true,
              highlight: true,
              pinyinVisible: false,
              translationVisible: true,
              note: 'uwaga'),
        ]),
      ]);
  Map<String, dynamic> payload() =>
      jsonDecode(utf8.decode(ClassroomPackage([sample()]).encode()))
          as Map<String, dynamic>;
  List<int> encode(Map<String, dynamic> json) => utf8.encode(jsonEncode(json));

  test('versioned package round trips shared content and range annotations',
      () {
    final decoded =
        ClassroomPackage.decode(ClassroomPackage([sample()]).encode());
    expect(decoded.lessons.single.toJson(), sample().toJson());
    expect(decoded.lessons.single.edit(title: 'Nowy').revision, 2);
  });

  test('unknown schema, unexpected/private fields and paths are rejected', () {
    for (final bad in [
      payload()..['version'] = 2,
      payload()..['version'] = 1.0,
      payload()..['teacherNotes'] = {'lesson-1': 'secret'},
      payload()..['executable'] = 'javascript:alert(1)',
    ]) {
      expect(() => ClassroomPackage.decode(encode(bad)), throwsFormatException);
    }
    final badLesson = payload();
    (badLesson['lessons'] as List).first['privateNotes'] = 'secret';
    expect(() => ClassroomPackage.decode(encode(badLesson)),
        throwsFormatException);
    final badBlock = payload();
    (badBlock['lessons'] as List).first['blocks'][0]['imagePath'] =
        'C:\\private.png';
    expect(
        () => ClassroomPackage.decode(encode(badBlock)), throwsFormatException);
  });

  test('bad JSON, duplicate ids, invalid revision and stale range rejected',
      () {
    expect(() => ClassroomPackage.decode(utf8.encode('{bad')),
        throwsFormatException);
    expect(() => ClassroomPackage.decode([0xff]), throwsFormatException);
    final duplicate = payload();
    (duplicate['lessons'] as List).add((duplicate['lessons'] as List).first);
    expect(() => ClassroomPackage.decode(encode(duplicate)),
        throwsFormatException);
    for (final revision in [0, -1, 1.5, '2']) {
      final bad = payload();
      (bad['lessons'] as List).first['revision'] = revision;
      expect(() => ClassroomPackage.decode(encode(bad)), throwsFormatException);
    }
    final range = payload();
    (range['lessons'] as List).first['blocks'][0]['annotations'][0]['end'] =
        999;
    expect(() => ClassroomPackage.decode(encode(range)), throwsFormatException);
    expect(sample().blocks.first.withText('').annotations, isEmpty);
  });

  test('range styles survive outside edits, extend inside and clip on deletion',
      () {
    final block = LessonBlock(text: 'abCDEfg', annotations: const [
      LessonAnnotation(
          start: 2,
          end: 5,
          underline: true,
          highlight: true,
          bold: true,
          italic: true,
          pinyinVisible: false,
          translationVisible: false,
          note: 'correction'),
    ]);
    void range(String text, int start, int end) {
      final updated = block.withText(text);
      final annotation = updated.annotations.single;
      expect([annotation.start, annotation.end], [start, end], reason: text);
      expect(
          annotation.underline &&
              annotation.highlight &&
              annotation.bold &&
              annotation.italic,
          isTrue);
      expect(annotation.pinyinVisible, isFalse);
      expect(annotation.translationVisible, isFalse);
      expect(annotation.note, 'correction');
      expect(() => LessonBlock.fromJson(updated.toJson()), returnsNormally);
    }

    range('XabCDEfg', 3, 6); // insertion before
    range('abCDEfgX', 2, 5); // insertion after
    range('abCXDEfg', 2, 6); // insertion inside
    range('abXCDEfg', 3, 6); // insertion at start stays outside
    range('abCDEXfg', 2, 5); // insertion at end stays outside
    range('aCDEfg', 1, 4); // deletion before
    range('abCDEf', 2, 5); // deletion after
    range('abCEfg', 2, 4); // deletion inside
    range('aDEfg', 1, 3); // deletion overlaps start
    range('abCg', 2, 3); // deletion overlaps end
    range('abCXYZ Efg', 2, 8); // replacement inside
    expect(block.withText('abfg').annotations, isEmpty);
    expect(block.withText('').annotations, isEmpty);
    expect(block.withText(block.text).annotations, block.annotations);
    final chinese = LessonBlock(text: '你好朋友', annotations: const [
      LessonAnnotation(start: 2, end: 4, bold: true),
    ]).withText('🙂你好朋友');
    expect([chinese.annotations.single.start, chinese.annotations.single.end],
        [4, 6]);
  });

  test('canvas geometry and paper styles persist; legacy pages still load', () {
    final page = ClassroomLesson(title: 'Canvas', paperStyle: 'grid', blocks: [
      LessonBlock(text: 'caption', x: 0.2, y: 0.6, width: 0.4, height: 0.15),
    ]);
    final restored = ClassroomPackage.decode(ClassroomPackage([page]).encode())
        .lessons
        .single;
    expect(restored.paperStyle, 'grid');
    expect(restored.blocks.single.x, 0.2);
    expect(restored.blocks.single.withText('edited').y, 0.6);
    final legacy = page.toJson()..remove('paperStyle');
    final raw = (legacy['blocks'] as List).single as Map;
    for (final key in ['x', 'y', 'width', 'height']) {
      raw.remove(key);
    }
    expect(ClassroomLesson.fromJson(legacy).paperStyle, 'blank');
    expect(ClassroomLesson.fromJson(legacy).blocks.single.x, 0.07);
    raw['x'] = 0.99;
    raw['width'] = 0.5;
    expect(() => ClassroomLesson.fromJson(legacy), throwsFormatException);
  });

  test('translation visibility is optional, typed and portable', () {
    final original = sample().blocks.single.annotations.single.toJson();
    final legacy = Map<String, dynamic>.from(original)
      ..remove('translationVisible');
    expect(LessonAnnotation.fromJson(legacy, 4).translationVisible, isNull);
    for (final value in [true, false]) {
      final restored = LessonAnnotation.fromJson(
          {...original, 'translationVisible': value}, 4);
      expect(restored.translationVisible, value);
    }
    for (final invalid in ['true', 1, [], {}]) {
      expect(
          () => LessonAnnotation.fromJson(
              {...original, 'translationVisible': invalid}, 4),
          throwsFormatException);
    }
  });

  test('image bytes inline in package; bad MIME, size and dimensions rejected',
      () {
    // A valid 1×1 PNG, not a file path or remote reference.
    final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jWZkAAAAASUVORK5CYII=');
    final lesson = ClassroomLesson(id: 'image-lesson', title: 'image', blocks: [
      LessonBlock(
          id: 'image-1',
          kind: LessonBlockKind.image,
          imageBytes: png,
          imageMime: 'image/png'),
    ]);
    final decoded =
        ClassroomPackage.decode(ClassroomPackage([lesson]).encode());
    expect(decoded.lessons.single.blocks.single.imageBytes, png);
    expect(() => ClassroomPackage.validateImage(png, 'image/svg+xml'),
        throwsFormatException);
    expect(
        () => ClassroomPackage.validateImage(png.sublist(0, 24), 'image/png'),
        throwsFormatException);
    expect(
        () => ClassroomPackage.validateImage(
            Uint8List(ClassroomPackage.maxImageBytes + 1), 'image/png'),
        throwsFormatException);
    final huge = Uint8List.fromList(png);
    ByteData.sublistView(huge).setUint32(16, 999999);
    expect(() => ClassroomPackage.validateImage(huge, 'image/png'),
        throwsFormatException);
    expect(
        () => ClassroomPackage.decode(
            Uint8List(ClassroomPackage.maxFileBytes + 1)),
        throwsFormatException);
  });
}
